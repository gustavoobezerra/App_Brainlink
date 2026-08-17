import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/services/eeg_spectrum_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = EegSpectrumAnalyzer();

  test('separa senoides nas bandas theta, alfa e beta', () {
    final theta = analyzer.analyze(
      eyesOpen: _sineBatches(6),
      eyesClosed: _sineBatches(10),
      minimumEpochsPerPhase: 1,
    );
    final beta = analyzer.analyze(
      eyesOpen: _sineBatches(20),
      eyesClosed: _sineBatches(20),
      minimumEpochsPerPhase: 1,
    );
    final alphaChange = analyzer.analyze(
      eyesOpen: _sineBatches(10, amplitudeMicrovolts: 5),
      eyesClosed: _sineBatches(10, amplitudeMicrovolts: 20),
      minimumEpochsPerPhase: 1,
    );
    final historicalPattern = analyzer.analyze(
      eyesOpen: _sineBatches(6),
      eyesClosed: _sineBatches(6),
      minimumEpochsPerPhase: 1,
    );

    expect(theta.isUsable, isTrue);
    expect(theta.eyesOpen.bands.theta, greaterThan(95));
    expect(theta.eyesClosed.bands.alpha, greaterThan(95));
    expect(alphaChange.alphaChangePercent, greaterThan(1000));
    expect(beta.eyesOpen.bands.beta, greaterThan(95));
    expect(historicalPattern.thetaAboveBetaInBothPhases, isTrue);
    expect(beta.thetaAboveBetaInBothPhases, isFalse);
  });

  test('rejeita contato ruim, perdas e saltos de sequência', () {
    final poorContact = analyzer.analyze(
      eyesOpen: _sineBatches(10, poorSignal: 100),
      eyesClosed: _sineBatches(10),
      minimumEpochsPerPhase: 1,
    );
    final dropped = analyzer.analyze(
      eyesOpen: _sineBatches(10, droppedAt: 2),
      eyesClosed: _sineBatches(10),
      minimumEpochsPerPhase: 1,
    );
    final gapBatches = _sineBatches(10).toList();
    gapBatches[2] = RawBatch(
      seq: 8,
      t0: gapBatches[2].t0,
      poorSignal: 0,
      dropped: 0,
      samples: gapBatches[2].samples,
    );
    final gap = analyzer.analyze(
      eyesOpen: gapBatches,
      eyesClosed: _sineBatches(10),
      minimumEpochsPerPhase: 1,
    );

    expect(poorContact.isUsable, isFalse);
    expect(poorContact.thetaAboveBetaInBothPhases, isNull);
    expect(poorContact.eyesOpen.acceptedEpochs, 0);
    expect(dropped.eyesOpen.rejectedEpochs, greaterThan(0));
    expect(gap.eyesOpen.rejectedEpochs, greaterThan(0));
  });

  test('rejeita sinal plano e amplitude compatível com artefato', () {
    final flat = List<RawBatch>.generate(
      4,
      (index) => RawBatch(
        seq: index,
        t0: DateTime.fromMillisecondsSinceEpoch(index * 1000),
        poorSignal: 0,
        dropped: 0,
        samples: Int32List(128),
      ),
    );
    final artifact = List<RawBatch>.generate(
      4,
      (index) => RawBatch(
        seq: index,
        t0: DateTime.fromMillisecondsSinceEpoch(index * 1000),
        poorSignal: 0,
        dropped: 0,
        samples: Int32List.fromList(
          List<int>.generate(128, (sample) => sample == 40 ? 1400 : 0),
        ),
      ),
    );

    expect(
      analyzer
          .analyze(
            eyesOpen: flat,
            eyesClosed: flat,
            minimumEpochsPerPhase: 1,
          )
          .isUsable,
      isFalse,
    );
    expect(
      analyzer
          .analyze(
            eyesOpen: artifact,
            eyesClosed: artifact,
            minimumEpochsPerPhase: 1,
          )
          .acceptedEpochs,
      0,
    );
  });

  test('exige quantidade e proporção mínimas de trechos limpos', () {
    final analysis = analyzer.analyze(
      eyesOpen: _sineBatches(10, count: 3),
      eyesClosed: _sineBatches(10, count: 3),
      minimumEpochsPerPhase: 10,
    );

    expect(analysis.isUsable, isFalse);
    expect(analysis.qualityExplanation, contains('olhos abertos'));
  });
}

List<RawBatch> _sineBatches(
  double frequency, {
  int count = 6,
  int poorSignal = 0,
  int? droppedAt,
  double amplitudeMicrovolts = 20,
}) {
  return List<RawBatch>.generate(count, (batchIndex) {
    final samples = Int32List(128);
    for (var index = 0; index < samples.length; index++) {
      final sampleIndex = batchIndex * 128 + index;
      final microvolts = amplitudeMicrovolts *
          math.sin(2 * math.pi * frequency * sampleIndex / 128);
      samples[index] = (microvolts / RawBatch.microvoltsPerUnit).round();
    }
    return RawBatch(
      seq: batchIndex,
      t0: DateTime.fromMillisecondsSinceEpoch(batchIndex * 1000),
      poorSignal: poorSignal,
      dropped: droppedAt == batchIndex ? 1 : 0,
      samples: samples,
    );
  });
}
