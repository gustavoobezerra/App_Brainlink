import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/teste/calibracao_piscadas.dart';
import 'package:flutter_test/flutter_test.dart';

const _fs = 512;
const _base = 1000000000000;

void main() {
  final bipes = [2.0, 4.0, 6.0, 8.0, 10.0];
  final bipesNanos = [for (final b in bipes) _nanos(b)];
  final fim = _nanos(13);

  test('5/5 quando há piscada depois de cada bipe', () {
    final lotes = _lotes(13, [for (final b in bipes) b + 0.5]);
    final r = avaliarCalibracao(
      lotes: lotes,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(r.porBipe, [true, true, true, true, true]);
    expect(r.detectadas, 5);
    expect(r.extras, 0);
  });

  test('4/5 quando o 3º bipe fica sem piscada', () {
    final lotes = _lotes(13, [2.5, 4.4, 8.6, 10.3]);
    final r = avaliarCalibracao(
      lotes: lotes,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(r.porBipe, [true, true, false, true, true]);
    expect(r.detectadas, 4);
    expect(r.extras, 0);
  });

  test('piscadas fora das janelas viram extras', () {
    // 6,05 s: cedo demais para o bipe de 6 s; 12 s: nenhum bipe.
    final lotes = _lotes(13, [1.0, 2.5, 4.5, 6.05, 8.5, 10.5, 12.0]);
    final r = avaliarCalibracao(
      lotes: lotes,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(r.porBipe, [true, true, false, true, true]);
    expect(r.extras, 3);
  });

  test('lotes sem t0MonoNanos são ignorados', () {
    final lotes = _lotes(13, [for (final b in bipes) b + 0.5]);
    final semRelogio = [for (final l in lotes) _semMono(l)];
    final r = avaliarCalibracao(
      lotes: semRelogio,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(r.porBipe, [false, false, false, false, false]);
    expect(r.extras, 0);
    expect(
      contarPiscadas(lotes: semRelogio, inicioNanos: _base, fimNanos: fim),
      0,
    );

    // Um lote sem relógio no meio só derruba a piscada que ele continha.
    final misto = List<RawBatch>.of(lotes)..[6] = _semMono(lotes[6]);
    final m = avaliarCalibracao(
      lotes: misto,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(m.porBipe, [true, true, false, true, true]);
  });

  test('salto de seq separa trechos sem perder as piscadas', () {
    final lotes = _lotes(13, [for (final b in bipes) b + 0.5]);
    final comSalto = [
      for (final l in lotes) l.seq >= 7 ? _comSeq(l, l.seq + 3) : l,
    ];
    final r = avaliarCalibracao(
      lotes: comSalto,
      bipesNanos: bipesNanos,
      inicioNanos: _base,
      fimNanos: fim,
    );
    expect(r.detectadas, 5);
  });

  test('contarPiscadas respeita o intervalo', () {
    final lotes = _lotes(13, [1.0, 3.0, 5.0, 7.0, 9.0, 11.0]);
    expect(contarPiscadas(lotes: lotes, inicioNanos: _base), 6);
    expect(contarPiscadas(lotes: lotes, inicioNanos: _nanos(4)), 4);
    expect(
      contarPiscadas(
        lotes: lotes,
        inicioNanos: _nanos(4),
        fimNanos: _nanos(8),
      ),
      2,
    );
  });
}

int _nanos(double segundos) => _base + (segundos * 1e9).round();

/// Lotes de 1 s a 512 Hz com ruído de 5 µV e piscadas (+150 µV, σ 60 ms,
/// rebote −50 µV) nos [instantes] em segundos.
List<RawBatch> _lotes(int segundos, List<double> instantes) {
  final aleatorio = math.Random(17);
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
      var v = 5 * gauss() + 8 * math.sin(2 * math.pi * 10 * t);
      for (final c in instantes) {
        final d = t - c;
        v += 150 * math.exp(-0.5 * math.pow(d / 0.06, 2)) -
            50 * math.exp(-0.5 * math.pow((d - 0.25) / 0.1, 2));
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

RawBatch _comSeq(RawBatch l, int seq) => RawBatch(
      seq: seq,
      t0: l.t0,
      poorSignal: l.poorSignal,
      dropped: l.dropped,
      samples: l.samples,
      observedSampleRateHz: l.observedSampleRateHz,
      t0MonoNanos: l.t0MonoNanos,
    );
