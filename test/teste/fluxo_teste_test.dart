import 'dart:async';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/teste/controlador_teste.dart';
import 'package:brainlink_app/services/teste/estimulos.dart';
import 'package:brainlink_app/services/teste/fonte_simulada.dart';
import 'package:brainlink_app/services/teste/fonte_sinal.dart';
import 'package:brainlink_app/ui/teste/fluxo_teste_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'suporte/captura.dart';
import 'suporte/duble_teste.dart';

/// Headset ausente: a lista de aparelhos abre vazia.
class _SemHeadset implements FonteSinal {
  @override
  bool get simulada => false;
  @override
  Stream<RawBatch> get lotes => const Stream.empty();
  @override
  Stream<int> get qualidade => const Stream.empty();
  @override
  Stream<EstadoConexao> get conexao => const Stream.empty();
  @override
  EstadoConexao get estadoConexao => EstadoConexao.desconectado;
  @override
  Future<ResultadoAutoConexao> autoConectar() async => const AutoEscolher([]);
  @override
  Future<List<DispositivoSinal>> buscar() async => const [];
  @override
  Future<void> conectar(DispositivoSinal dispositivo) async {}
  @override
  Future<bool> reconectar() async => false;
  @override
  Future<void> desconectar() async {}
  @override
  Future<void> dispose() async {}
}

class _Ambiente {
  _Ambiente({VolumeMidia volume = const VolumeMidia(12, 15)})
      : relogio = RelogioManual() {
    estimulos = EstimulosFalsos(relogio, volume: volume);
    controlador = ControladorTeste(
      estimulos: estimulos,
      relogio: relogio,
      criarFonteHeadset: _SemHeadset.new,
      criarFonteSimulada: (cenario, duracoes) => FonteSimulada(
        cenario: cenario,
        relogio: relogio,
        duracoes: duracoes,
      ),
      semente: () => 42,
    );
  }

  final RelogioManual relogio;
  late final EstimulosFalsos estimulos;
  late final ControladorTeste controlador;

  Future<void> montar(WidgetTester tester) => montarTela(
        tester,
        FluxoTesteScreen(
          controlador: controlador,
          relogio: relogio,
          coletaAnterior: (_) => const Scaffold(body: Text('COLETA ANTERIOR')),
        ),
      );

  Future<void> passar(WidgetTester tester, Duration duracao) =>
      passarTempo(tester, relogio, duracao);

  Future<void> tocarTexto(WidgetTester tester, String texto) async {
    final alvo = find.text(texto).last;
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await passar(tester, const Duration(milliseconds: 100));
  }

  /// Espera até [texto] aparecer, avançando o tempo em passos.
  Future<void> esperarTexto(
    WidgetTester tester,
    String texto, {
    Duration limite = const Duration(seconds: 90),
  }) async {
    var decorrido = Duration.zero;
    while (find.text(texto).evaluate().isEmpty) {
      if (decorrido > limite) {
        fail('"$texto" não apareceu em $limite '
            '(etapa ${controlador.etapa}, pausa ${controlador.pausa}).');
      }
      await passar(tester, const Duration(milliseconds: 500));
      decorrido += const Duration(milliseconds: 500);
    }
  }

  /// Desmonta o fluxo (cancela temporizadores e a simulação).
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await passar(tester, const Duration(seconds: 1));
  }

  /// Do início até o fim do treino, com dados simulados.
  Future<void> ateOTreino(WidgetTester tester,
      {required String botaoTreino}) async {
    await tocarTexto(tester, 'Começar');
    await esperarTexto(tester, 'Escolha o headset');
    await tocarTexto(tester, 'Usar dados simulados');
    await esperarTexto(tester, 'Contato bom');
    await passar(tester, const Duration(seconds: 4));
    expect(controlador.contatoLiberado, isTrue);
    await tocarTexto(tester, 'Continuar');
    await tocarTexto(tester, 'Entendi');
    expect(controlador.etapa, EtapaTeste.calibracao);
    await esperarTexto(tester, 'Calibração concluída');
    await tocarTexto(tester, 'Continuar');
    await tocarTexto(tester, 'Começar repouso');
    expect(controlador.etapa, EtapaTeste.repouso);
    await esperarTexto(tester, 'Pode abrir os olhos.');
    await tocarTexto(tester, 'Continuar');
    await tocarTexto(tester, botaoTreino);
    expect(controlador.etapa, EtapaTeste.treino);
  }

  Future<void> tocarArea(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 500));
    await tester.pump();
  }

  /// Do fim do treino até o fim dos questionários.
  Future<void> daTarefaAoFim(WidgetTester tester) async {
    await esperarTexto(tester, 'Começar o teste');
    await tocarTexto(tester, 'Começar o teste');
    expect(controlador.etapa, EtapaTeste.tarefa);
    // Toca algumas vezes durante a tarefa.
    for (var i = 0; i < 12; i++) {
      await passar(tester, const Duration(milliseconds: 1200));
      if (controlador.etapa != EtapaTeste.tarefa) break;
      await tocarArea(tester);
    }
    await esperarTexto(tester, 'Começar');
    expect(controlador.etapa, EtapaTeste.ritmoInstrucoes);
    await tocarTexto(tester, 'Começar');
    expect(controlador.etapa, EtapaTeste.ritmo);
    await esperarTexto(tester, 'Começar repouso');
    await tocarTexto(tester, 'Começar repouso');
    expect(controlador.etapa, EtapaTeste.repousoFinal);
    await esperarTexto(tester, 'Pode abrir os olhos.');
    await tocarTexto(tester, 'Continuar');
    for (var i = 0; i < 6; i++) {
      expect(controlador.asrsIndice, i);
      await tocarTexto(tester, 'Algumas vezes');
      await tocarTexto(tester, 'Próxima');
    }
    expect(controlador.etapa, EtapaTeste.contexto);
    await tocarTexto(tester, '5–7');
    await tocarTexto(tester, 'Não tomo');
    // "Sim"/"Não" aparecem em duas perguntas: café (primeira) e lente.
    final cafe = find.text('Sim').first;
    await tester.ensureVisible(cafe);
    await tester.tap(cafe);
    await tester.pump();
    await tocarTexto(tester, 'Não');
    expect(controlador.contexto.completas, isTrue);
    await tocarTexto(tester, 'Concluir');
  }
}

Future<void> passarTempo(
  WidgetTester tester,
  RelogioManual relogio,
  Duration duracao,
) =>
    passar(tester, relogio, duracao);

void main() {
  testWidgets('fluxo auditivo completo em modo pesquisa, com simulação',
      (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    expect(find.textContaining('com sons'), findsOneWidget);
    await ambiente.ateOTreino(tester, botaoTreino: 'Fazer o treino (10 sons)');
    // Responde a alguns sons do treino para ver o retorno.
    await ambiente.passar(tester, const Duration(milliseconds: 1300));
    await ambiente.tocarArea(tester);
    await ambiente.passar(tester, const Duration(milliseconds: 200));
    expect(ambiente.controlador.feedbackTreino, isNotNull);
    await ambiente.daTarefaAoFim(tester);
    expect(find.text('Obrigado!'), findsOneWidget);
    expect(find.text('Ver serviços de atendimento'), findsNothing);

    final sessao = ambiente.controlador.sessao!;
    expect(sessao.tarefa, isNotEmpty);
    expect(sessao.tarefa.every((e) => e.inicioNanos != null), isTrue);
    expect(sessao.lotes, isNotEmpty);
    expect(ambiente.estimulos.sons, contains(SomTeste.grave));
    expect(ambiente.estimulos.sons, contains(SomTeste.sinoDuplo));
    expect(ambiente.estimulos.telaAcesa.first, isTrue);
    expect(ambiente.estimulos.telaAcesa.last, isFalse);

    await ambiente.tocarTexto(tester, 'Concluir');
    expect(ambiente.controlador.etapa, EtapaTeste.inicio);
    await ambiente.desmontar(tester);
  });

  testWidgets('fluxo visual em modo demonstração mostra os resultados',
      (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Visual');
    expect(find.textContaining('com imagens'), findsOneWidget);
    ambiente.controlador.alternarDemonstracao();
    await tester.pump();
    await ambiente.ateOTreino(tester,
        botaoTreino: 'Fazer o treino (10 figuras)');
    await ambiente.daTarefaAoFim(tester);
    expect(find.text('O que o sensor registrou'), findsOneWidget);
    expect(find.text('Dados simulados'), findsOneWidget);
    expect(find.text('Demonstração de pesquisa. Não é diagnóstico.'),
        findsOneWidget);
    final resumo = ambiente.controlador.resumo!;
    expect(resumo.piscadasTotal, 5);
    expect(resumo.comuns + resumo.raros, greaterThan(0));
    await ambiente.tocarTexto(tester, 'Nova demonstração');
    expect(ambiente.controlador.etapa, EtapaTeste.inicio);
    await ambiente.desmontar(tester);
  });

  testWidgets('volume baixo pede para aumentar antes do sensor',
      (tester) async {
    final ambiente = _Ambiente(volume: const VolumeMidia(3, 15));
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Começar');
    expect(find.text('Aumente o volume'), findsOneWidget);
    await ambiente.tocarTexto(tester, 'Tocar som de teste');
    await ambiente.passar(tester, const Duration(milliseconds: 500));
    expect(ambiente.estimulos.sons, [SomTeste.grave, SomTeste.agudo]);
    await ambiente.tocarTexto(tester, 'Já aumentei, continuar');
    expect(ambiente.controlador.etapa, EtapaTeste.sensor);
    await ambiente.desmontar(tester);
  });

  testWidgets('voltar abre a confirmação e segurar 2 s encerra o teste',
      (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Começar');
    await ambiente.tocarTexto(tester, 'Usar dados simulados');
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.passar(tester, const Duration(seconds: 4));
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Entendi');
    await ambiente.passar(tester, const Duration(seconds: 2));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Encerrar o teste?'), findsOneWidget);
    final bipesAntes = ambiente.controlador.bipesTocados;
    await ambiente.passar(tester, const Duration(seconds: 5));
    expect(ambiente.controlador.bipesTocados, bipesAntes,
        reason: 'a fase fica congelada enquanto a confirmação está aberta');

    await ambiente.tocarTexto(tester, 'Continuar o teste');
    expect(find.text('Encerrar o teste?'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    final alvo = find.text('Segure 2 s para encerrar');
    final gesto = await tester.startGesture(tester.getCenter(alvo));
    await tester.pump();
    await ambiente.passar(tester, const Duration(milliseconds: 2200));
    await gesto.up();
    await tester.pump();
    expect(ambiente.controlador.etapa, EtapaTeste.inicio);
    await ambiente.desmontar(tester);
  });

  testWidgets('perda de contato pausa e permite retomar', (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Começar');
    await ambiente.esperarTexto(tester, 'Escolha o headset');
    await ambiente.tocarTexto(tester, 'Perda de contato');
    await ambiente.tocarTexto(tester, 'Usar dados simulados');
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.passar(tester, const Duration(seconds: 4));
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Entendi');
    await ambiente.esperarTexto(tester, 'Calibração concluída');
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Começar repouso');
    await ambiente.esperarTexto(tester, 'Pode abrir os olhos.');
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Fazer o treino (10 sons)');
    await ambiente.esperarTexto(tester, 'Começar o teste');
    await ambiente.tocarTexto(tester, 'Começar o teste');
    await ambiente.esperarTexto(tester, 'Reposicione o sensor');
    expect(ambiente.controlador.pausa, MotivoPausa.contato);
    expect(ambiente.estimulos.vibracoes, contains(VibracaoTeste.longa));
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.tocarTexto(tester, 'Retomar');
    expect(ambiente.controlador.pausa, isNull);
    expect(ambiente.controlador.etapa, EtapaTeste.tarefa);
    await ambiente.esperarTexto(tester, 'Começar');
    expect(ambiente.controlador.etapa, EtapaTeste.ritmoInstrucoes);
    expect(
      ambiente.controlador.sessao!.tarefa.any((e) => e.interrompido),
      isTrue,
    );
    await ambiente.desmontar(tester);
  });

  testWidgets('Bluetooth cai, reconecta e checa o contato', (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Começar');
    await ambiente.esperarTexto(tester, 'Escolha o headset');
    await ambiente.tocarTexto(tester, 'Bluetooth cai');
    await ambiente.tocarTexto(tester, 'Usar dados simulados');
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.passar(tester, const Duration(seconds: 4));
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Entendi');
    await ambiente.esperarTexto(tester, 'Calibração concluída');
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Começar repouso');
    await ambiente.esperarTexto(tester, 'Reconectando ao headset…');
    expect(ambiente.controlador.pausa, MotivoPausa.bluetooth);
    await ambiente.esperarTexto(tester, 'Reposicione o sensor');
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.tocarTexto(tester, 'Retomar');
    expect(ambiente.controlador.etapa, EtapaTeste.repouso);
    await ambiente.esperarTexto(tester, 'Pode abrir os olhos.');
    await ambiente.desmontar(tester);
  });

  testWidgets('poucas piscadas sugere repetir a calibração', (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Começar');
    await ambiente.esperarTexto(tester, 'Escolha o headset');
    await ambiente.tocarTexto(tester, 'Poucas piscadas');
    await ambiente.tocarTexto(tester, 'Usar dados simulados');
    await ambiente.esperarTexto(tester, 'Contato bom');
    await ambiente.passar(tester, const Duration(seconds: 4));
    await ambiente.tocarTexto(tester, 'Continuar');
    await ambiente.tocarTexto(tester, 'Entendi');
    await ambiente.esperarTexto(tester, 'Vamos repetir a calibração?');
    await ambiente.tocarTexto(tester, 'Repetir calibração');
    expect(ambiente.controlador.etapa, EtapaTeste.calibracao);
    await ambiente.esperarTexto(tester, 'Calibração concluída');
    await ambiente.desmontar(tester);
  });

  testWidgets('o link do rodapé abre a coleta anterior', (tester) async {
    final ambiente = _Ambiente();
    await ambiente.montar(tester);
    await ambiente.tocarTexto(tester, 'Abrir coleta anterior');
    await tester.pumpAndSettle();
    expect(find.text('COLETA ANTERIOR'), findsOneWidget);
    unawaited(Future<void>.value());
  });
}
