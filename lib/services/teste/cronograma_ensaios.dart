import 'dart:math' as math;

import '../../data/models/sessao_teste.dart';

// ESQUELETO (WP3): implementação a ser substituída pelo agente do motor.

/// Sorteia a ordem e os intervalos dos estímulos da tarefa ou do treino.
///
/// - exatamente [comuns] estímulos comuns e [raros] raros;
/// - nunca dois raros seguidos; os [primeirosComuns] primeiros são comuns;
/// - cada `intervaloMs` sorteado uniformemente entre [intervaloMinimo] e
///   [intervaloMaximo];
/// - `indice` de 0 a n − 1; mesma semente → mesma sequência.
List<Ensaio> gerarCronograma({
  required int comuns,
  required int raros,
  required math.Random aleatorio,
  int primeirosComuns = 2,
  Duration intervaloMinimo = const Duration(milliseconds: 900),
  Duration intervaloMaximo = const Duration(milliseconds: 1300),
}) {
  throw UnimplementedError('gerarCronograma');
}

/// Bloco "toque no ritmo": [quantidade] estímulos, todos comuns.
List<Ensaio> gerarRitmo({
  required int quantidade,
  required math.Random aleatorio,
  Duration intervaloMinimo = const Duration(milliseconds: 900),
  Duration intervaloMaximo = const Duration(milliseconds: 1300),
}) {
  throw UnimplementedError('gerarRitmo');
}
