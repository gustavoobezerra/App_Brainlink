import 'dart:math' as math;

import '../data/models/raw_batch.dart';

enum EegBand {
  delta('Delta', 1, 4),
  theta('Theta', 4, 8),
  alpha('Alfa', 8, 13),
  beta('Beta', 13, 30);

  const EegBand(this.label, this.startHz, this.endHz);

  final String label;
  final double startHz;
  final double endHz;
}

class EegBandPowers {
  const EegBandPowers({
    required this.delta,
    required this.theta,
    required this.alpha,
    required this.beta,
  });

  const EegBandPowers.empty()
      : delta = 0,
        theta = 0,
        alpha = 0,
        beta = 0;

  final double delta;
  final double theta;
  final double alpha;
  final double beta;

  double valueFor(EegBand band) => switch (band) {
        EegBand.delta => delta,
        EegBand.theta => theta,
        EegBand.alpha => alpha,
        EegBand.beta => beta,
      };
}

class EegSpectrumPoint {
  const EegSpectrumPoint(this.frequencyHz, this.relativePowerDb);

  final double frequencyHz;
  final double relativePowerDb;
}

class EegPhaseSpectrum {
  const EegPhaseSpectrum({
    required this.acceptedEpochs,
    required this.rejectedEpochs,
    required this.bands,
    required this.absoluteBands,
    required this.spectrum,
  });

  final int acceptedEpochs;
  final int rejectedEpochs;
  final EegBandPowers bands;
  final EegBandPowers absoluteBands;
  final List<EegSpectrumPoint> spectrum;

  int get totalEpochs => acceptedEpochs + rejectedEpochs;

  double get acceptedFraction =>
      totalEpochs == 0 ? 0 : acceptedEpochs / totalEpochs;
}

class EegSpectrumAnalysis {
  const EegSpectrumAnalysis({
    required this.eyesOpen,
    required this.eyesClosed,
    required this.minimumEpochsPerPhase,
  });

  static const String pipelineVersion = 'spectrum-v1.0.0';

  final EegPhaseSpectrum eyesOpen;
  final EegPhaseSpectrum eyesClosed;
  final int minimumEpochsPerPhase;

  int get acceptedEpochs => eyesOpen.acceptedEpochs + eyesClosed.acceptedEpochs;

  int get totalEpochs => eyesOpen.totalEpochs + eyesClosed.totalEpochs;

  double get acceptedFraction =>
      totalEpochs == 0 ? 0 : acceptedEpochs / totalEpochs;

  bool get isUsable =>
      eyesOpen.acceptedEpochs >= minimumEpochsPerPhase &&
      eyesClosed.acceptedEpochs >= minimumEpochsPerPhase &&
      eyesOpen.acceptedFraction >= 0.5 &&
      eyesClosed.acceptedFraction >= 0.5;

  String get qualityExplanation {
    if (totalEpochs == 0) {
      return 'O fluxo de EEG bruto não forneceu trechos suficientes.';
    }
    if (eyesOpen.acceptedEpochs < minimumEpochsPerPhase) {
      return 'Poucos trechos aproveitáveis na etapa de olhos abertos.';
    }
    if (eyesClosed.acceptedEpochs < minimumEpochsPerPhase) {
      return 'Poucos trechos aproveitáveis na etapa de olhos fechados.';
    }
    if (eyesOpen.acceptedFraction < 0.5 || eyesClosed.acceptedFraction < 0.5) {
      return 'Mais da metade dos trechos continha contato ruim, perda ou artefato.';
    }
    return 'Trechos suficientes para uma descrição técnica das bandas.';
  }

  double? get alphaChangePercent {
    if (!isUsable || eyesOpen.absoluteBands.alpha <= 0.01) return null;
    return (eyesClosed.absoluteBands.alpha - eyesOpen.absoluteBands.alpha) /
        eyesOpen.absoluteBands.alpha *
        100;
  }
}

/// Análise descritiva de potência espectral do EEG bruto a 128 Hz.
///
/// O pipeline rejeita trechos com contato ruim, perdas, saturação, amplitude
/// excessiva ou sinal plano. Ele não calcula probabilidade ou possibilidade de
/// TDAH: essa finalidade pertence exclusivamente ao rastreio ASRS.
class EegSpectrumAnalyzer {
  const EegSpectrumAnalyzer({
    this.sampleRateHz = 128,
    this.epochSamples = 128,
    this.hopSamples = 64,
    this.maximumPoorSignal = 50,
    this.maximumAbsoluteMicrovolts = 150,
    this.maximumPeakToPeakMicrovolts = 200,
    this.minimumStandardDeviationMicrovolts = 0.5,
  });

  final int sampleRateHz;
  final int epochSamples;
  final int hopSamples;
  final int maximumPoorSignal;
  final double maximumAbsoluteMicrovolts;
  final double maximumPeakToPeakMicrovolts;
  final double minimumStandardDeviationMicrovolts;

  EegSpectrumAnalysis analyze({
    required List<RawBatch> eyesOpen,
    required List<RawBatch> eyesClosed,
    int minimumEpochsPerPhase = 20,
  }) {
    if (!_isPowerOfTwo(epochSamples)) {
      throw StateError('epochSamples precisa ser uma potência de dois.');
    }
    if (hopSamples <= 0 || hopSamples > epochSamples) {
      throw StateError('hopSamples precisa estar entre 1 e epochSamples.');
    }
    return EegSpectrumAnalysis(
      eyesOpen: _analyzePhase(eyesOpen),
      eyesClosed: _analyzePhase(eyesClosed),
      minimumEpochsPerPhase: minimumEpochsPerPhase,
    );
  }

  EegPhaseSpectrum _analyzePhase(List<RawBatch> batches) {
    final flattened = _flatten(batches);
    if (flattened.samples.length < epochSamples) {
      return const EegPhaseSpectrum(
        acceptedEpochs: 0,
        rejectedEpochs: 0,
        bands: EegBandPowers.empty(),
        absoluteBands: EegBandPowers.empty(),
        spectrum: [],
      );
    }

    final spectrumBins = epochSamples ~/ 2 + 1;
    final spectrumSum = List<double>.filled(spectrumBins, 0);
    final bandSums = List<double>.filled(EegBand.values.length, 0);
    final absoluteBandSums = List<double>.filled(EegBand.values.length, 0);
    var accepted = 0;
    var rejected = 0;

    for (var start = 0;
        start + epochSamples <= flattened.samples.length;
        start += hopSamples) {
      if (!_allValid(flattened.valid, start, epochSamples)) {
        rejected++;
        continue;
      }
      final epoch = flattened.samples.sublist(start, start + epochSamples);
      if (_hasArtifact(epoch)) {
        rejected++;
        continue;
      }

      final powers = _powerSpectrum(epoch);
      var total = 0.0;
      for (var bin = 1; bin < powers.length; bin++) {
        final frequency = bin * sampleRateHz / epochSamples;
        if (frequency >= 1 && frequency < 30) total += powers[bin];
      }
      if (!total.isFinite || total <= 0) {
        rejected++;
        continue;
      }

      for (var bin = 1; bin < powers.length; bin++) {
        final frequency = bin * sampleRateHz / epochSamples;
        if (frequency >= 1 && frequency < 30) {
          spectrumSum[bin] += powers[bin] / total;
        }
      }
      for (var index = 0; index < EegBand.values.length; index++) {
        final band = EegBand.values[index];
        var sum = 0.0;
        for (var bin = 1; bin < powers.length; bin++) {
          final frequency = bin * sampleRateHz / epochSamples;
          if (frequency >= band.startHz && frequency < band.endHz) {
            sum += powers[bin];
          }
        }
        bandSums[index] += sum / total * 100;
        absoluteBandSums[index] += sum;
      }
      accepted++;
    }

    if (accepted == 0) {
      return EegPhaseSpectrum(
        acceptedEpochs: 0,
        rejectedEpochs: rejected,
        bands: const EegBandPowers.empty(),
        absoluteBands: const EegBandPowers.empty(),
        spectrum: const [],
      );
    }

    final averagedBands = [for (final value in bandSums) value / accepted];
    final averagedAbsoluteBands = [
      for (final value in absoluteBandSums) value / accepted,
    ];
    final spectrum = <EegSpectrumPoint>[];
    for (var bin = 1; bin < spectrumSum.length; bin++) {
      final frequency = bin * sampleRateHz / epochSamples;
      if (frequency >= 1 && frequency <= 30) {
        final relativePower = spectrumSum[bin] / accepted;
        spectrum.add(
          EegSpectrumPoint(
            frequency,
            10 * math.log(math.max(relativePower, 1e-12)) / math.ln10,
          ),
        );
      }
    }
    return EegPhaseSpectrum(
      acceptedEpochs: accepted,
      rejectedEpochs: rejected,
      bands: EegBandPowers(
        delta: averagedBands[EegBand.delta.index],
        theta: averagedBands[EegBand.theta.index],
        alpha: averagedBands[EegBand.alpha.index],
        beta: averagedBands[EegBand.beta.index],
      ),
      absoluteBands: EegBandPowers(
        delta: averagedAbsoluteBands[EegBand.delta.index],
        theta: averagedAbsoluteBands[EegBand.theta.index],
        alpha: averagedAbsoluteBands[EegBand.alpha.index],
        beta: averagedAbsoluteBands[EegBand.beta.index],
      ),
      spectrum: spectrum,
    );
  }

  _FlattenedSignal _flatten(List<RawBatch> batches) {
    final samples = <double>[];
    final valid = <bool>[];
    int? previousSequence;
    for (final batch in batches) {
      final complete = batch.samples.length == sampleRateHz;
      final continuous =
          previousSequence == null || batch.seq == previousSequence + 1;
      final batchValid = complete &&
          continuous &&
          batch.dropped == 0 &&
          batch.poorSignal <= maximumPoorSignal;
      final converted = batch.toMicrovolts();
      for (var index = 0; index < converted.length; index++) {
        samples.add(converted[index]);
        valid.add(batchValid && !_isSaturated(batch.samples[index]));
      }
      previousSequence = batch.seq;
    }
    return _FlattenedSignal(samples, valid);
  }

  bool _hasArtifact(List<double> epoch) {
    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    var sum = 0.0;
    for (final value in epoch) {
      if (!value.isFinite || value.abs() > maximumAbsoluteMicrovolts) {
        return true;
      }
      minimum = math.min(minimum, value);
      maximum = math.max(maximum, value);
      sum += value;
    }
    if (maximum - minimum > maximumPeakToPeakMicrovolts) return true;
    final mean = sum / epoch.length;
    var variance = 0.0;
    for (final value in epoch) {
      final difference = value - mean;
      variance += difference * difference;
    }
    final standardDeviation = math.sqrt(variance / epoch.length);
    return standardDeviation < minimumStandardDeviationMicrovolts;
  }

  List<double> _powerSpectrum(List<double> source) {
    final length = source.length;
    final real = List<double>.filled(length, 0);
    final imaginary = List<double>.filled(length, 0);
    final mean = source.reduce((a, b) => a + b) / length;

    var sumX = 0.0;
    var sumXX = 0.0;
    var sumXY = 0.0;
    final center = (length - 1) / 2;
    for (var index = 0; index < length; index++) {
      final x = index - center;
      final y = source[index] - mean;
      sumX += x;
      sumXX += x * x;
      sumXY += x * y;
    }
    final slope = sumXX == 0 ? 0.0 : sumXY / sumXX;
    final interceptCorrection = sumX == 0 ? 0.0 : slope * sumX / length;
    for (var index = 0; index < length; index++) {
      final x = index - center;
      final detrended = source[index] - mean - slope * x + interceptCorrection;
      final window = 0.5 - 0.5 * math.cos(2 * math.pi * index / (length - 1));
      real[index] = detrended * window;
    }

    _fft(real, imaginary);
    final powers = List<double>.filled(length ~/ 2 + 1, 0);
    for (var bin = 0; bin < powers.length; bin++) {
      powers[bin] = real[bin] * real[bin] + imaginary[bin] * imaginary[bin];
    }
    return powers;
  }

  static void _fft(List<double> real, List<double> imaginary) {
    final length = real.length;
    var swapIndex = 0;
    for (var index = 1; index < length; index++) {
      var bit = length >> 1;
      while ((swapIndex & bit) != 0) {
        swapIndex ^= bit;
        bit >>= 1;
      }
      swapIndex ^= bit;
      if (index < swapIndex) {
        final tempReal = real[index];
        real[index] = real[swapIndex];
        real[swapIndex] = tempReal;
        final tempImaginary = imaginary[index];
        imaginary[index] = imaginary[swapIndex];
        imaginary[swapIndex] = tempImaginary;
      }
    }

    for (var size = 2; size <= length; size <<= 1) {
      final angle = -2 * math.pi / size;
      final stepReal = math.cos(angle);
      final stepImaginary = math.sin(angle);
      for (var start = 0; start < length; start += size) {
        var twiddleReal = 1.0;
        var twiddleImaginary = 0.0;
        final half = size >> 1;
        for (var offset = 0; offset < half; offset++) {
          final even = start + offset;
          final odd = even + half;
          final oddReal =
              real[odd] * twiddleReal - imaginary[odd] * twiddleImaginary;
          final oddImaginary =
              real[odd] * twiddleImaginary + imaginary[odd] * twiddleReal;
          real[odd] = real[even] - oddReal;
          imaginary[odd] = imaginary[even] - oddImaginary;
          real[even] += oddReal;
          imaginary[even] += oddImaginary;

          final nextReal =
              twiddleReal * stepReal - twiddleImaginary * stepImaginary;
          twiddleImaginary =
              twiddleReal * stepImaginary + twiddleImaginary * stepReal;
          twiddleReal = nextReal;
        }
      }
    }
  }

  static bool _allValid(List<bool> values, int start, int length) {
    for (var index = start; index < start + length; index++) {
      if (!values[index]) return false;
    }
    return true;
  }

  static bool _isSaturated(int value) {
    final signed = value > RawBatch.signedMax ? value - 65536 : value;
    return signed.abs() >= 32760;
  }

  static bool _isPowerOfTwo(int value) =>
      value > 0 && (value & (value - 1)) == 0;
}

class _FlattenedSignal {
  const _FlattenedSignal(this.samples, this.valid);

  final List<double> samples;
  final List<bool> valid;
}
