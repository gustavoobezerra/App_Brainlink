import 'dart:async';
import 'dart:math' as math;

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/teste/fonte_simulada.dart';
import 'package:brainlink_app/services/teste/fonte_sinal.dart';
import 'package:brainlink_app/services/teste/relogio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relógio controlado pelo teste, avançado junto com o tempo falso.
class _RelogioFalso implements Relogio {
  int nanos = 5 * 1000 * 1000 * 1000;

  @override
  int agoraNanos() => nanos;

  @override
  int nanosDoToque(PointerEvent evento) => nanos;
}

const int _ms = 1000000;
const Duration _passo = Duration(milliseconds: 10);

/// Fonte simulada com tudo o que ela emite registrado.
class _Cenario {
  _Cenario(CenarioSimulado cenario) : this._(cenario, _RelogioFalso());

  _Cenario._(CenarioSimulado cenario, this.relogio)
      : fonte = FonteSimulada(cenario: cenario, relogio: relogio) {
    _assinaturas = [
      fonte.lotes.listen(lotes.add),
      fonte.qualidade.listen(qualidades.add),
      fonte.conexao.listen(conexoes.add),
    ];
  }

  final _RelogioFalso relogio;
  final FonteSimulada fonte;
  final List<RawBatch> lotes = [];
  final List<int> qualidades = [];
  final List<EstadoConexao> conexoes = [];
  late final List<StreamSubscription<Object?>> _assinaturas;

  /// Avança o relógio e o tempo falso juntos, em passos de 10 ms.
  Future<void> avancar(WidgetTester tester, Duration duracao) async {
    var restante = duracao;
    while (restante > Duration.zero) {
      final passo = restante < _passo ? restante : _passo;
      relogio.nanos += passo.inMicroseconds * 1000;
      await tester.pump(passo);
      restante -= passo;
    }
  }

  Future<void> conectar(WidgetTester tester) async {
    final resultado = fonte.autoConectar();
    await avancar(tester, const Duration(milliseconds: 300));
    expect(await resultado, isA<AutoConectado>());
  }

  Future<void> encerrar() async {
    await fonte.dispose();
    // Sem `await`: o cancelamento de assinatura broadcast completa na zona
    // raiz, que o tempo falso do testWidgets não processa.
    for (final a in _assinaturas) {
      unawaited(a.cancel());
    }
  }
}

/// Amostras (instante, µV) de todos os [lotes], em ordem.
List<(int, double)> _amostras(List<RawBatch> lotes) => [
      for (final lote in lotes)
        for (final (i, uv) in lote.toMicrovolts().indexed)
          (
            lote.t0MonoNanos! -
                (lote.samples.length - 1 - i) *
                    (1000000000 ~/ RawBatch.sampleRateHz),
            uv,
          ),
    ];

/// Amplitude do componente de 10 Hz de um lote (projeção de Fourier).
double _amplitude10Hz(RawBatch lote) {
  final uv = lote.toMicrovolts();
  var seno = 0.0, cosseno = 0.0;
  for (var i = 0; i < uv.length; i++) {
    final fase = 2 * math.pi * 10 * i / RawBatch.sampleRateHz;
    seno += uv[i] * math.sin(fase);
    cosseno += uv[i] * math.cos(fase);
  }
  return 2 * math.sqrt(seno * seno + cosseno * cosseno) / uv.length;
}

/// Picos acima de 100 µV, agrupados (um por piscada).
List<int> _picos(List<RawBatch> lotes) {
  final picos = <int>[];
  var maior = 0.0;
  int? instanteMaior;
  int? ultimoAcima;
  for (final (instante, uv) in _amostras(lotes)) {
    if (uv <= 100) continue;
    if (ultimoAcima != null && instante - ultimoAcima > 300 * _ms) {
      picos.add(instanteMaior!);
      maior = 0;
    }
    if (uv > maior) {
      maior = uv;
      instanteMaior = instante;
    }
    ultimoAcima = instante;
  }
  if (instanteMaior != null) picos.add(instanteMaior);
  return picos;
}

/// Teste com a fonte sempre encerrada no fim, mesmo se algo falhar
/// (timer periódico pendente travaria o tempo falso).
void _testar(
  String nome,
  CenarioSimulado cenario,
  Future<void> Function(WidgetTester tester, _Cenario c) corpo,
) {
  testWidgets(nome, (tester) async {
    final c = _Cenario(cenario);
    try {
      await corpo(tester, c);
    } finally {
      await c.encerrar();
    }
  });
}

void main() {
  _testar('conecta, 1 lote/s com t0MonoNanos e qualidade 120→0',
      CenarioSimulado.tudoCerto, (tester, c) async {
    expect(c.fonte.simulada, isTrue);
    expect(c.fonte.estadoConexao, EstadoConexao.desconectado);
    expect(await c.fonte.buscar(), isEmpty);

    final inicio = c.relogio.nanos;
    await c.conectar(tester);
    expect(c.conexoes, [EstadoConexao.conectando, EstadoConexao.conectado]);
    expect(c.fonte.estadoConexao, EstadoConexao.conectado);
    final conectadoEm = inicio + 300 * _ms;

    await c.avancar(tester, const Duration(milliseconds: 4050));
    expect(c.lotes, hasLength(4));
    for (final (k, lote) in c.lotes.indexed) {
      expect(lote.seq, k);
      expect(lote.samples, hasLength(512));
      expect(lote.observedSampleRateHz, 512);
      expect(lote.dropped, 0);
      expect(lote.t0MonoNanos, conectadoEm + (k + 1) * 1000 * _ms);
    }
    expect([for (final l in c.lotes) l.poorSignal], [120, 0, 0, 0]);
    // Uma na conexão e uma por segundo.
    expect(c.qualidades, [120, 120, 0, 0, 0]);
    // Fora das piscadas, nada além de ±100 µV.
    for (final (_, uv) in _amostras(c.lotes)) {
      expect(uv.abs(), lessThan(100));
    }
  });

  _testar('alfa maior de olhos fechados', CenarioSimulado.tudoCerto,
      (tester, c) async {
    await c.conectar(tester);
    c.fonte.definirEstado(EstadoSimulado.olhosAbertos);
    await c.avancar(tester, const Duration(seconds: 8));
    final abertos = [...c.lotes];
    c.lotes.clear();
    c.fonte.definirEstado(EstadoSimulado.olhosFechados);
    await c.avancar(tester, const Duration(seconds: 8));
    final fechados = [...c.lotes];
    c.lotes.clear();
    c.fonte.definirEstado(EstadoSimulado.tarefaOlhosFechados);
    await c.avancar(tester, const Duration(seconds: 8));
    final tarefa = [...c.lotes];

    double media(List<RawBatch> lotes) =>
        lotes.map(_amplitude10Hz).reduce((a, b) => a + b) / lotes.length;
    final a = media(abertos), f = media(fechados), t = media(tarefa);
    expect(f, greaterThan(2 * a));
    expect(f, closeTo(14, 3));
    expect(t, inExclusiveRange(a, f));
    for (final (_, uv) in _amostras([...abertos, ...fechados, ...tarefa])) {
      expect(uv.abs(), lessThan(100));
    }
  });

  _testar('piscada ~350 ms após o bipe, com rebote', CenarioSimulado.tudoCerto,
      (tester, c) async {
    await c.conectar(tester);
    // Pico perto da virada de lote: parte cai no lote seguinte.
    await c.avancar(tester, const Duration(milliseconds: 1650));
    final bipe = c.relogio.nanos;
    c.fonte.aoBipeCalibracao(bipe);
    await c.avancar(tester, const Duration(seconds: 3));

    final picos = _picos(c.lotes);
    expect(picos, hasLength(1));
    expect((picos.single - bipe) / _ms, closeTo(350, 15));
    final amostras = _amostras(c.lotes);
    final pico = amostras
        .where((a) => (a.$1 - picos.single).abs() < 20 * _ms)
        .map((a) => a.$2)
        .reduce(math.max);
    expect(pico, greaterThan(120));
    // Rebote negativo ~150 ms depois do pico.
    final rebote = amostras
        .where((a) => (a.$1 - picos.single - 150 * _ms).abs() < 40 * _ms)
        .map((a) => a.$2)
        .reduce(math.min);
    expect(rebote, lessThan(-15));
  });

  /// Duas séries de 5 bipes; devolve as piscadas da primeira.
  Future<int> piscadasNaCalibracao(WidgetTester tester, _Cenario c) async {
    await c.conectar(tester);
    await c.avancar(tester, const Duration(seconds: 1));
    Future<int> serie() async {
      c.lotes.clear();
      for (var i = 0; i < 5; i++) {
        c.fonte.aoBipeCalibracao(c.relogio.nanos);
        await c.avancar(tester, const Duration(milliseconds: 1500));
      }
      await c.avancar(tester, const Duration(seconds: 2));
      return _picos(c.lotes).length;
    }

    final primeira = await serie();
    // Segunda série: todas as piscadas aparecem.
    expect(await serie(), 5);
    return primeira;
  }

  _testar('tudo certo: 5 piscadas em 5 bipes', CenarioSimulado.tudoCerto,
      (tester, c) async {
    expect(await piscadasNaCalibracao(tester, c), 5);
  });

  _testar(
    'poucas piscadas: o 3º bipe da 1ª série fica sem piscada',
    CenarioSimulado.poucasPiscadas,
    (tester, c) async {
      expect(await piscadasNaCalibracao(tester, c), 4);
    },
  );

  _testar('perda de contato: 200 por 5 s, 6 s após entrar na tarefa',
      CenarioSimulado.perdaContato, (tester, c) async {
    await c.conectar(tester);
    await c.avancar(tester, const Duration(seconds: 3));
    // Repouso não dispara a perda.
    c.fonte.definirEstado(EstadoSimulado.olhosFechados);
    await c.avancar(tester, const Duration(seconds: 8));
    expect(c.lotes.map((l) => l.poorSignal).skip(2), everyElement(0));

    // Meio segundo fora de fase com os lotes, para não cair na borda.
    await c.avancar(tester, const Duration(milliseconds: 500));
    c.lotes.clear();
    c.qualidades.clear();
    final entrada = c.relogio.nanos;
    c.fonte.definirEstado(EstadoSimulado.tarefaOlhosFechados);
    await c.avancar(tester, const Duration(seconds: 14));
    expect(c.lotes, hasLength(14));
    for (final lote in c.lotes) {
      final desde = lote.t0MonoNanos! - entrada;
      final ruim = desde >= 6000 * _ms && desde < 11000 * _ms;
      expect(lote.poorSignal, ruim ? 200 : 0, reason: 'em ${desde / _ms} ms');
    }
    expect(c.lotes.where((l) => l.poorSignal == 200), hasLength(5));
    expect(c.qualidades.where((q) => q == 200), hasLength(5));

    // Só na primeira entrada.
    c.lotes.clear();
    c.fonte.definirEstado(EstadoSimulado.tarefaOlhosAbertos);
    await c.avancar(tester, const Duration(seconds: 12));
    expect(c.lotes.map((l) => l.poorSignal), everyElement(0));
  });

  _testar('bluetooth cai: lotes param e a 2ª reconexão volta do seq 0',
      CenarioSimulado.bluetoothCai, (tester, c) async {
    await c.conectar(tester);
    await c.avancar(tester, const Duration(milliseconds: 2500));
    c.conexoes.clear();
    c.fonte.definirEstado(EstadoSimulado.olhosFechados);
    await c.avancar(tester, const Duration(milliseconds: 3900));
    expect(c.fonte.estadoConexao, EstadoConexao.conectado);
    await c.avancar(tester, const Duration(milliseconds: 100));
    expect(c.fonte.estadoConexao, EstadoConexao.desconectado);
    expect(c.conexoes, [EstadoConexao.desconectado]);

    final antes = c.lotes.length;
    expect(antes, greaterThan(4));
    await c.avancar(tester, const Duration(seconds: 5));
    expect(c.lotes, hasLength(antes));

    final primeira = c.fonte.reconectar();
    await c.avancar(tester, const Duration(milliseconds: 400));
    expect(await primeira, isFalse);
    expect(c.fonte.estadoConexao, EstadoConexao.desconectado);

    final segunda = c.fonte.reconectar();
    await c.avancar(tester, const Duration(milliseconds: 400));
    expect(await segunda, isTrue);
    expect(c.fonte.estadoConexao, EstadoConexao.conectado);
    expect(c.qualidades.last, 0);

    await c.avancar(tester, const Duration(seconds: 2));
    final novos = c.lotes.sublist(antes);
    expect([for (final l in novos) l.seq], [0, 1]);
    expect(novos.map((l) => l.poorSignal), everyElement(0));

    // Não cai de novo numa segunda entrada de olhos fechados.
    c.fonte.definirEstado(EstadoSimulado.olhosAbertos);
    c.fonte.definirEstado(EstadoSimulado.olhosFechados);
    await c.avancar(tester, const Duration(seconds: 6));
    expect(c.fonte.estadoConexao, EstadoConexao.conectado);
  });

  _testar(
      'conectar, desconectar e dispose idempotente', CenarioSimulado.tudoCerto,
      (tester, c) async {
    final conexao = c.fonte.conectar(
      const DispositivoSinal(id: 'x', nome: 'Simulado', pareado: true),
    );
    await c.avancar(tester, const Duration(milliseconds: 300));
    await conexao;
    expect(c.fonte.estadoConexao, EstadoConexao.conectado);
    await c.avancar(tester, const Duration(seconds: 2));
    expect(c.lotes, hasLength(2));

    await c.fonte.desconectar();
    expect(c.fonte.estadoConexao, EstadoConexao.desconectado);
    await c.avancar(tester, const Duration(seconds: 3));
    expect(c.lotes, hasLength(2));

    // Reconexão comum (sem queda simulada) conecta na hora certa.
    final volta = c.fonte.reconectar();
    await c.avancar(tester, const Duration(milliseconds: 400));
    expect(await volta, isTrue);

    // Uma reconexão pendente é encerrada pelo dispose.
    await c.fonte.desconectar();
    final pendente = c.fonte.reconectar();
    await c.fonte.dispose();
    expect(await pendente, isFalse);
    await c.fonte.dispose();
  });
}
