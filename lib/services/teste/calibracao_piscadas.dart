import '../../data/models/raw_batch.dart';
import 'detector_piscadas.dart';

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
/// campo são ignorados. Trechos quebrados (salto de seq, perda, lote
/// incompleto) são analisados separadamente.
ResultadoCalibracao avaliarCalibracao({
  required List<RawBatch> lotes,
  required List<int> bipesNanos,
  required int inicioNanos,
  required int fimNanos,
  DetectorPiscadas detector = const DetectorPiscadas(),
  Duration inicioJanela = const Duration(milliseconds: 150),
  Duration fimJanela = const Duration(milliseconds: 1500),
}) {
  final piscadas = _instantesPiscadas(
    lotes: lotes,
    inicioNanos: inicioNanos,
    fimNanos: fimNanos,
    detector: detector,
  );
  final usadas = List<bool>.filled(piscadas.length, false);
  final porBipe = <bool>[];
  for (final bipe in bipesNanos) {
    final de = bipe + inicioJanela.inMicroseconds * 1000;
    final ate = bipe + fimJanela.inMicroseconds * 1000;
    var achou = false;
    for (var i = 0; i < piscadas.length; i++) {
      final t = piscadas[i];
      if (usadas[i] || t < de) continue;
      if (t > ate) break;
      usadas[i] = true;
      achou = true;
      break;
    }
    porBipe.add(achou);
  }
  final extras = usadas.where((u) => !u).length;
  return ResultadoCalibracao(porBipe: porBipe, extras: extras);
}

/// Piscadas detectadas desde [inicioNanos] (contagem ao vivo do pesquisador).
///
/// Sem [fimNanos], conta até a última amostra disponível.
int contarPiscadas({
  required List<RawBatch> lotes,
  required int inicioNanos,
  int? fimNanos,
  DetectorPiscadas detector = const DetectorPiscadas(),
}) {
  return _instantesPiscadas(
    lotes: lotes,
    inicioNanos: inicioNanos,
    fimNanos: fimNanos,
    detector: detector,
  ).length;
}

/// Instantes (ns, em ordem) dos picos de piscada em `[início, fim]`.
List<int> _instantesPiscadas({
  required List<RawBatch> lotes,
  required int inicioNanos,
  required int? fimNanos,
  required DetectorPiscadas detector,
}) {
  final instantes = <int>[];
  for (final (de, ate) in trechosContinuos(lotes)) {
    final sinal = <double>[];
    final tempos = <int>[];
    for (var l = de; l < ate; l++) {
      final lote = lotes[l];
      final n = lote.samples.length;
      if (n == 0) continue;
      // Descarta o lote inteiro fora do intervalo sem converter amostras.
      if (instanteAmostraNanos(lote, n - 1) < inicioNanos) continue;
      if (fimNanos != null && instanteAmostraNanos(lote, 0) > fimNanos) {
        continue;
      }
      final uv = lote.toMicrovolts();
      for (var i = 0; i < n; i++) {
        final t = instanteAmostraNanos(lote, i);
        if (t < inicioNanos || (fimNanos != null && t > fimNanos)) continue;
        sinal.add(uv[i]);
        tempos.add(t);
      }
    }
    for (final pico in detector.detectar(sinal)) {
      instantes.add(tempos[pico]);
    }
  }
  instantes.sort();
  return instantes;
}
