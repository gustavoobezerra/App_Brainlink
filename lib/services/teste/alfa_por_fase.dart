import 'dart:math' as math;

import '../../data/models/raw_batch.dart';
import '../eeg_spectrum_analyzer.dart';
import 'detector_piscadas.dart';

/// Potência alfa de uma fase, ou o motivo de não haver número.
class MedidaAlfa {
  const MedidaAlfa({
    required this.potencia,
    required this.segundosLimpos,
    this.motivo,
  });

  /// Potência absoluta média de 8–13 Hz nas épocas aceitas (unidade do
  /// analisador); nula quando não há sinal limpo suficiente.
  final double? potencia;

  /// Segundos de sinal aceito.
  final double segundosLimpos;
  final String? motivo;

  bool get disponivel => potencia != null;
}

/// Motivo usado quando a fase não tem sinal limpo bastante.
const String motivoSinalInsuficiente = 'Sinal limpo insuficiente';

/// Mede o alfa do EEG contido nas [janelas] `(início, fim)` em nanossegundos.
///
/// Remove as piscadas (máscara do [detector]) quando [removerPiscadas], usa as
/// regras de rejeição do [analisador] e exige [minimoSegundosLimpos].
///
/// Cada sequência de lotes vizinhos que toca alguma janela é analisada à
/// parte (assim o salto de seq entre janelas não invalida lotes); amostras
/// fora das janelas são excluídas. A potência é a média das épocas aceitas
/// de todos os trechos. `segundosLimpos` soma, por trecho,
/// `(aceitas − 1) · salto + época` em segundos — com os padrões (1 s, salto
/// 0,5 s) dá `(aceitas + 1) / 2`, exato quando as épocas aceitas são
/// contíguas e um teto quando há buracos entre elas.
MedidaAlfa medirAlfa({
  required List<RawBatch> lotes,
  required List<(int, int)> janelas,
  required double minimoSegundosLimpos,
  bool removerPiscadas = true,
  DetectorPiscadas detector = const DetectorPiscadas(),
  EegSpectrumAnalyzer analisador = const EegSpectrumAnalyzer(),
}) {
  bool dentro(int t) {
    for (final (de, ate) in janelas) {
      if (t >= de && t <= ate) return true;
    }
    return false;
  }

  bool tocaJanela(RawBatch lote) {
    final n = lote.samples.length;
    if (lote.t0MonoNanos == null || n == 0) return false;
    final primeiro = instanteAmostraNanos(lote, 0);
    final ultimo = instanteAmostraNanos(lote, n - 1);
    for (final (de, ate) in janelas) {
      if (ultimo >= de && primeiro <= ate) return true;
    }
    return false;
  }

  // Agrupa lotes vizinhos (na lista original) que tocam alguma janela.
  final grupos = <List<RawBatch>>[];
  List<RawBatch>? atual;
  for (final lote in lotes) {
    if (tocaJanela(lote)) {
      (atual ??= (grupos..add(<RawBatch>[])).last).add(lote);
    } else {
      atual = null;
    }
  }

  final fs = analisador.sampleRateHz.toDouble();
  var somaAlfa = 0.0;
  var aceitas = 0;
  var segundos = 0.0;
  for (final grupo in grupos) {
    final excluidas = <bool>[];
    for (final lote in grupo) {
      for (var i = 0; i < lote.samples.length; i++) {
        excluidas.add(!dentro(instanteAmostraNanos(lote, i)));
      }
    }
    if (removerPiscadas) {
      _marcarPiscadas(grupo, excluidas, detector);
    }
    final fase = analisador.analyzeSegment(grupo, excludedSamples: excluidas);
    if (fase.acceptedEpochs == 0) continue;
    aceitas += fase.acceptedEpochs;
    somaAlfa += fase.absoluteBands.alpha * fase.acceptedEpochs;
    segundos += ((fase.acceptedEpochs - 1) * analisador.hopSamples +
            analisador.epochSamples) /
        fs;
  }

  if (aceitas == 0 || segundos < minimoSegundosLimpos) {
    return MedidaAlfa(
      potencia: null,
      segundosLimpos: segundos,
      motivo: motivoSinalInsuficiente,
    );
  }
  return MedidaAlfa(potencia: somaAlfa / aceitas, segundosLimpos: segundos);
}

/// Marca em [excluidas] as amostras de piscada, detectando por trecho
/// contínuo do [grupo] (a ordem das amostras é a do analisador).
void _marcarPiscadas(
  List<RawBatch> grupo,
  List<bool> excluidas,
  DetectorPiscadas detector,
) {
  final deslocamentos = <int>[0];
  for (final lote in grupo) {
    deslocamentos.add(deslocamentos.last + lote.samples.length);
  }
  for (final (de, ate) in trechosContinuos(grupo)) {
    final sinal = <double>[
      for (var l = de; l < ate; l++) ...grupo[l].toMicrovolts(),
    ];
    final picos = detector.detectar(sinal);
    if (picos.isEmpty) continue;
    final mascara = detector.mascara(sinal.length, picos);
    final base = deslocamentos[de];
    for (var i = 0; i < mascara.length; i++) {
      if (mascara[i]) excluidas[base + i] = true;
    }
  }
}

/// `10 · log10(fechados / abertos)`, arredondado; nulo se faltar medida.
int? reatividadeAlfaDb({
  required MedidaAlfa olhosAbertos,
  required MedidaAlfa olhosFechados,
}) {
  final abertos = olhosAbertos.potencia;
  final fechados = olhosFechados.potencia;
  if (abertos == null || fechados == null || abertos <= 0 || fechados <= 0) {
    return null;
  }
  return (10 * math.log(fechados / abertos) / math.ln10).round();
}
