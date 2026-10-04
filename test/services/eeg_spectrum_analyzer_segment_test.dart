import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/eeg_spectrum_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = EegSpectrumAnalyzer();

  test('sem máscara equivale à fase de analyze()', () {
    final batches = _batches(12);
    final fase =
        analyzer.analyze(eyesOpen: batches, eyesClosed: const []).eyesOpen;
    final segmento = analyzer.analyzeSegment(batches);
    expect(segmento.acceptedEpochs, fase.acceptedEpochs);
    expect(segmento.rejectedEpochs, fase.rejectedEpochs);
    for (final band in EegBand.values) {
      expect(
        segmento.absoluteBands.valueFor(band),
        fase.absoluteBands.valueFor(band),
      );
      expect(segmento.bands.valueFor(band), fase.bands.valueFor(band));
    }
    expect(segmento.spectrum.length, fase.spectrum.length);
  });

  test('máscara rejeita toda época com amostra excluída', () {
    final batches = _batches(12);
    final total = 12 * 512;
    final semMascara = analyzer.analyzeSegment(batches);
    expect(semMascara.acceptedEpochs, 23);

    // Uma amostra excluída em 1100 cai nas épocas que começam em 768 e 1024.
    final mascara = List<bool>.filled(total, false)..[1100] = true;
    final umaAmostra =
        analyzer.analyzeSegment(batches, excludedSamples: mascara);
    expect(umaAmostra.acceptedEpochs, 21);
    expect(umaAmostra.rejectedEpochs, 2);
    expect(
      umaAmostra.absoluteBands.alpha,
      closeTo(semMascara.absoluteBands.alpha,
          semMascara.absoluteBands.alpha * 0.02),
    );

    final tudo = analyzer.analyzeSegment(
      batches,
      excludedSamples: List<bool>.filled(total, true),
    );
    expect(tudo.acceptedEpochs, 0);
    expect(tudo.rejectedEpochs, 23);

    final nada = analyzer.analyzeSegment(
      batches,
      excludedSamples: List<bool>.filled(total, false),
    );
    expect(nada.acceptedEpochs, semMascara.acceptedEpochs);
  });

  test('máscara com tamanho errado é recusada', () {
    expect(
      () => analyzer.analyzeSegment(
        _batches(2),
        excludedSamples: List<bool>.filled(10, false),
      ),
      throwsArgumentError,
    );
  });
}

List<RawBatch> _batches(int seconds) {
  final random = math.Random(3);
  return [
    for (var k = 0; k < seconds; k++)
      RawBatch(
        seq: k,
        t0: DateTime.fromMillisecondsSinceEpoch(k * 1000),
        poorSignal: 0,
        dropped: 0,
        observedSampleRateHz: 512,
        t0MonoNanos: ((k + 1) * 512 - 1) * 1953125,
        samples: Int32List.fromList([
          for (var i = 0; i < 512; i++)
            ((20 * math.sin(2 * math.pi * 10 * (k * 512 + i) / 512) +
                        3 * (random.nextDouble() - 0.5)) /
                    RawBatch.microvoltsPerUnit)
                .round(),
        ]),
      ),
  ];
}
