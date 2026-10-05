import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/teste/alfa_por_fase.dart';
import 'package:flutter_test/flutter_test.dart';

const _fs = 512;
const _base = 5000000000000;

void main() {
  int nanos(double segundos) => _base + (segundos * 1e9).round();

  test('alfa 20 µV contra 5 µV dá ≈ 12 dB', () {
    final abertos = medirAlfa(
      lotes: _lotes(40, (_) => 5),
      janelas: [(nanos(0), nanos(40))],
      minimoSegundosLimpos: 10,
    );
    final fechados = medirAlfa(
      lotes: _lotes(40, (_) => 20),
      janelas: [(nanos(0), nanos(40))],
      minimoSegundosLimpos: 10,
    );
    expect(abertos.disponivel, isTrue);
    expect(fechados.disponivel, isTrue);
    expect(abertos.motivo, isNull);
    expect(fechados.segundosLimpos, closeTo(40, 0.01));
    expect(
      reatividadeAlfaDb(olhosAbertos: abertos, olhosFechados: fechados),
      inInclusiveRange(11, 13),
    );
  });

  test('trecho curto informa sinal limpo insuficiente', () {
    final m = medirAlfa(
      lotes: _lotes(10, (_) => 20),
      janelas: [(nanos(2), nanos(5))],
      minimoSegundosLimpos: 10,
    );
    expect(m.potencia, isNull);
    expect(m.disponivel, isFalse);
    expect(m.motivo, 'Sinal limpo insuficiente');
    expect(m.segundosLimpos, greaterThan(0));
    expect(m.segundosLimpos, lessThan(4));
  });

  test('sem épocas ou sem t0MonoNanos não há número', () {
    final semRelogio = [for (final l in _lotes(20, (_) => 20)) _semMono(l)];
    final m = medirAlfa(
      lotes: semRelogio,
      janelas: [(nanos(0), nanos(20))],
      minimoSegundosLimpos: 1,
    );
    expect(m.potencia, isNull);
    expect(m.segundosLimpos, 0);
    expect(m.motivo, 'Sinal limpo insuficiente');
  });

  test('janelas recortam o sinal', () {
    // 0–20 s com alfa de 5 µV, 20–40 s com 20 µV.
    final lotes = _lotes(40, (t) => t < 20 ? 5 : 20);
    final forte = medirAlfa(
      lotes: _lotes(20, (_) => 20),
      janelas: [(nanos(0), nanos(20))],
      minimoSegundosLimpos: 5,
    );
    final recorte = medirAlfa(
      lotes: lotes,
      janelas: [(nanos(21), nanos(39))],
      minimoSegundosLimpos: 5,
    );
    expect(recorte.potencia! / forte.potencia!, closeTo(1, 0.05));
    expect(recorte.segundosLimpos, inInclusiveRange(16, 18));

    // Duas janelas separadas: o salto entre elas não invalida lotes.
    final duas = medirAlfa(
      lotes: lotes,
      janelas: [(nanos(21), nanos(26)), (nanos(32), nanos(38))],
      minimoSegundosLimpos: 5,
    );
    expect(duas.potencia! / forte.potencia!, closeTo(1, 0.05));
    expect(duas.segundosLimpos, inInclusiveRange(9, 11));
  });

  test('remover piscadas reduz as épocas e mantém o alfa', () {
    final piscadas = [3.3, 7.6, 11.2, 15.7, 19.4, 23.1, 27.8];
    final limpo = medirAlfa(
      lotes: _lotes(30, (_) => 20),
      janelas: [(nanos(0), nanos(30))],
      minimoSegundosLimpos: 5,
    );
    final lotes = _lotes(30, (_) => 20, piscadas: piscadas);
    final comRemocao = medirAlfa(
      lotes: lotes,
      janelas: [(nanos(0), nanos(30))],
      minimoSegundosLimpos: 5,
    );
    final semRemocao = medirAlfa(
      lotes: lotes,
      janelas: [(nanos(0), nanos(30))],
      minimoSegundosLimpos: 5,
      removerPiscadas: false,
    );
    expect(comRemocao.segundosLimpos, lessThan(semRemocao.segundosLimpos));
    expect(comRemocao.segundosLimpos, greaterThan(10));
    expect(comRemocao.potencia! / limpo.potencia!, closeTo(1, 0.05));
  });

  test('reatividade nula quando falta medida ou potência não positiva', () {
    const ok = MedidaAlfa(potencia: 10, segundosLimpos: 30);
    const nada = MedidaAlfa(
      potencia: null,
      segundosLimpos: 0,
      motivo: 'Sinal limpo insuficiente',
    );
    const zero = MedidaAlfa(potencia: 0, segundosLimpos: 30);
    expect(reatividadeAlfaDb(olhosAbertos: ok, olhosFechados: nada), isNull);
    expect(reatividadeAlfaDb(olhosAbertos: nada, olhosFechados: ok), isNull);
    expect(reatividadeAlfaDb(olhosAbertos: zero, olhosFechados: ok), isNull);
    expect(
      reatividadeAlfaDb(
        olhosAbertos: ok,
        olhosFechados: const MedidaAlfa(potencia: 100, segundosLimpos: 30),
      ),
      10,
    );
  });
}

/// Lotes de 1 s com alfa de 10 Hz (amplitude em µV por instante), ruído de
/// 2 µV e piscadas de +110 µV (rebote −37 µV) nos instantes dados.
List<RawBatch> _lotes(
  int segundos,
  double Function(double t) alfa, {
  List<double> piscadas = const [],
}) {
  final aleatorio = math.Random(23);
  double gauss() {
    final u = 1 - aleatorio.nextDouble();
    return math.sqrt(-2 * math.log(u)) *
        math.cos(2 * math.pi * aleatorio.nextDouble());
  }

  final lotes = <RawBatch>[];
  for (var k = 0; k < segundos; k++) {
    final amostras = Int32List(_fs);
    for (var i = 0; i < _fs; i++) {
      final t = (k * _fs + i) / _fs;
      var v = 2 * gauss() + alfa(t) * math.sin(2 * math.pi * 10 * t);
      for (final c in piscadas) {
        final d = t - c;
        v += 110 * math.exp(-0.5 * math.pow(d / 0.06, 2)) -
            37 * math.exp(-0.5 * math.pow((d - 0.25) / 0.1, 2));
      }
      amostras[i] = (v / RawBatch.microvoltsPerUnit).round();
    }
    lotes.add(
      RawBatch(
        seq: k,
        t0: DateTime.fromMillisecondsSinceEpoch(k * 1000),
        poorSignal: 0,
        dropped: 0,
        samples: amostras,
        observedSampleRateHz: 512,
        t0MonoNanos: _base + (((k + 1) * _fs - 1) * 1e9 / _fs).round(),
      ),
    );
  }
  return lotes;
}

RawBatch _semMono(RawBatch l) => RawBatch(
      seq: l.seq,
      t0: l.t0,
      poorSignal: l.poorSignal,
      dropped: l.dropped,
      samples: l.samples,
      observedSampleRateHz: l.observedSampleRateHz,
    );
