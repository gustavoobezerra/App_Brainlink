import '../../data/models/raw_batch.dart';
import 'detector_piscadas.dart';

// ESQUELETO (WP2): implementação a ser substituída pelo agente de DSP.

/// Resultado de uma tentativa de calibração.
class ResultadoCalibracao {
  const ResultadoCalibracao({required this.porBipe, required this.extras});

  /// Se houve piscada atribuída a cada bipe.
  final List<bool> porBipe;

  /// Piscadas fora das janelas dos bipes.
  final int extras;

  int get detectadas => porBipe.where((v) => v).length;
}

/// Detecta as piscadas do EEG entre [inicioNanos] e [fimNanos] e atribui a
/// cada bipe a primeira piscada ainda livre em
/// `[bipe + inicioJanela, bipe + fimJanela]`.
///
/// O instante de cada amostra vem de `RawBatch.t0MonoNanos`; lotes sem esse
/// campo são ignorados.
ResultadoCalibracao avaliarCalibracao({
  required List<RawBatch> lotes,
  required List<int> bipesNanos,
  required int inicioNanos,
  required int fimNanos,
  DetectorPiscadas detector = const DetectorPiscadas(),
  Duration inicioJanela = const Duration(milliseconds: 150),
  Duration fimJanela = const Duration(milliseconds: 1500),
}) {
  throw UnimplementedError('avaliarCalibracao');
}

/// Piscadas detectadas desde [inicioNanos] (contagem ao vivo do pesquisador).
int contarPiscadas({
  required List<RawBatch> lotes,
  required int inicioNanos,
  int? fimNanos,
  DetectorPiscadas detector = const DetectorPiscadas(),
}) {
  throw UnimplementedError('contarPiscadas');
}
