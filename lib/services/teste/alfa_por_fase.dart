import '../../data/models/raw_batch.dart';
import '../eeg_spectrum_analyzer.dart';
import 'detector_piscadas.dart';

// ESQUELETO (WP2): implementação a ser substituída pelo agente de DSP.

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

/// Mede o alfa do EEG contido nas [janelas] `(início, fim)` em nanossegundos.
///
/// Remove as piscadas (máscara do [detector]) quando [removerPiscadas], usa as
/// regras de rejeição do [analisador] e exige [minimoSegundosLimpos].
MedidaAlfa medirAlfa({
  required List<RawBatch> lotes,
  required List<(int, int)> janelas,
  required double minimoSegundosLimpos,
  bool removerPiscadas = true,
  DetectorPiscadas detector = const DetectorPiscadas(),
  EegSpectrumAnalyzer analisador = const EegSpectrumAnalyzer(),
}) {
  throw UnimplementedError('medirAlfa');
}

/// `10 · log10(fechados / abertos)`, arredondado; nulo se faltar medida.
int? reatividadeAlfaDb({
  required MedidaAlfa olhosAbertos,
  required MedidaAlfa olhosFechados,
}) {
  throw UnimplementedError('reatividadeAlfaDb');
}
