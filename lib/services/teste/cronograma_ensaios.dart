import 'dart:math' as math;

import '../../data/models/sessao_teste.dart';

/// Sorteia a ordem e os intervalos dos estímulos da tarefa ou do treino.
///
/// - exatamente [comuns] estímulos comuns e [raros] raros;
/// - nunca dois raros seguidos; os [primeirosComuns] primeiros são comuns;
/// - cada `intervaloMs` sorteado uniformemente entre [intervaloMinimo] e
///   [intervaloMaximo];
/// - `indice` de 0 a n − 1; mesma semente → mesma sequência.
///
/// Combinação impossível (ex.: raros demais para separá-los) lança
/// [ArgumentError].
List<Ensaio> gerarCronograma({
  required int comuns,
  required int raros,
  required math.Random aleatorio,
  int primeirosComuns = 2,
  Duration intervaloMinimo = const Duration(milliseconds: 900),
  Duration intervaloMaximo = const Duration(milliseconds: 1300),
}) {
  if (comuns < 0) throw ArgumentError.value(comuns, 'comuns');
  if (raros < 0) throw ArgumentError.value(raros, 'raros');
  if (primeirosComuns < 0 || primeirosComuns > comuns) {
    throw ArgumentError.value(
      primeirosComuns,
      'primeirosComuns',
      'precisa estar entre 0 e comuns ($comuns)',
    );
  }
  _validarIntervalos(intervaloMinimo, intervaloMaximo);

  // Depois dos comuns fixos, os comuns restantes formam `livres + 1`
  // vãos (antes, entre e depois deles); cada vão recebe no máximo um raro.
  // Sortear quais vãos recebem raro dá todas as ordens válidas com a mesma
  // chance.
  final livres = comuns - primeirosComuns;
  if (raros > livres + 1) {
    throw ArgumentError(
      'Impossível separar $raros raros com $livres comuns livres '
      '(sem dois raros seguidos).',
    );
  }
  final vaos = List<int>.generate(livres + 1, (i) => i)..shuffle(aleatorio);
  final comRaro = vaos.take(raros).toSet();

  final tipos = <TipoEstimulo>[
    for (var i = 0; i < primeirosComuns; i++) TipoEstimulo.comum,
  ];
  for (var vao = 0; vao <= livres; vao++) {
    if (comRaro.contains(vao)) tipos.add(TipoEstimulo.raro);
    if (vao < livres) tipos.add(TipoEstimulo.comum);
  }

  return [
    for (var i = 0; i < tipos.length; i++)
      Ensaio(
        indice: i,
        tipo: tipos[i],
        intervaloMs: _sortearIntervalo(
          aleatorio,
          intervaloMinimo,
          intervaloMaximo,
        ),
      ),
  ];
}

/// Bloco "toque no ritmo": [quantidade] estímulos, todos comuns.
List<Ensaio> gerarRitmo({
  required int quantidade,
  required math.Random aleatorio,
  Duration intervaloMinimo = const Duration(milliseconds: 900),
  Duration intervaloMaximo = const Duration(milliseconds: 1300),
}) {
  if (quantidade < 0) throw ArgumentError.value(quantidade, 'quantidade');
  _validarIntervalos(intervaloMinimo, intervaloMaximo);
  return [
    for (var i = 0; i < quantidade; i++)
      Ensaio(
        indice: i,
        tipo: TipoEstimulo.comum,
        intervaloMs: _sortearIntervalo(
          aleatorio,
          intervaloMinimo,
          intervaloMaximo,
        ),
      ),
  ];
}

void _validarIntervalos(Duration minimo, Duration maximo) {
  if (minimo.isNegative || maximo < minimo) {
    throw ArgumentError(
      'Intervalo inválido: mínimo ${minimo.inMilliseconds} ms, '
      'máximo ${maximo.inMilliseconds} ms.',
    );
  }
}

/// Inteiro uniforme em `[minimo, maximo]`, em ms.
int _sortearIntervalo(math.Random aleatorio, Duration minimo, Duration maximo) {
  final min = minimo.inMilliseconds;
  return min + aleatorio.nextInt(maximo.inMilliseconds - min + 1);
}
