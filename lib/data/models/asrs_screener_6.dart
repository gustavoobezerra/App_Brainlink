/// Respostas oficiais do rastreador adulto ASRS v1.1 de seis perguntas.
enum AsrsResponse {
  never(0, 'Nunca'),
  rarely(1, 'Raramente'),
  sometimes(2, 'Algumas vezes'),
  often(3, 'Freqüentemente'),
  veryOften(4, 'Muito freqüentemente');

  const AsrsResponse(this.points, this.label);

  final int points;
  final String label;
}

enum AsrsScoreBand {
  lowNegative,
  highNegative,
  lowPositive,
  highPositive,
}

/// Resultado calculado somente pelas respostas, ainda que seja registrado no
/// mesmo relatório que o resumo do BrainLink.
class AsrsScreenerResult {
  const AsrsScreenerResult({required this.total, required this.band});

  final int total;
  final AsrsScoreBand band;

  bool get reachedScreeningCutoff => total >= AsrsScreener6.cutoff;

  String get possibilityLabel => reachedScreeningCutoff
      ? 'Possibilidade aumentada no ASRS'
      : 'Ponto de corte não atingido';

  String get label => switch (band) {
        AsrsScoreBand.lowNegative => 'Faixa inferior de rastreio',
        AsrsScoreBand.highNegative => 'Próximo ao ponto de corte',
        AsrsScoreBand.lowPositive => 'Faixa de rastreio atingida',
        AsrsScoreBand.highPositive => 'Faixa superior de rastreio',
      };

  String get guidance => reachedScreeningCutoff
      ? 'As respostas atingiram o ponto de corte e apontam possibilidade '
          'aumentada de TDAH neste rastreio. Este resultado não é diagnóstico. '
          'Procure avaliação de um médico ou psicólogo.'
      : 'As respostas ficaram abaixo do ponto de corte. Isso não exclui TDAH '
          'e não é diagnóstico. Se houver dificuldade no dia a dia, converse '
          'com um médico ou psicólogo.';
}

/// ASRS v1.1 Screener (6Q), versão oficial em português do Brasil.
abstract final class AsrsScreener6 {
  static const int itemCount = 6;
  static const int cutoff = 14;
  static const int maximumScore = 24;

  static const String sourceUrl =
      'https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/'
      '6Q_Portuguese%20%28for%20Brazil%29_final.pdf';
  static const String scoringSourceUrl =
      'https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/'
      'ASRS_v1.1_screener%286Q%29_scoring_update.pdf';
  static const String attribution =
      'ASRS v1.1 6-Question Screener © New York University and '
      'Ronald C. Kessler, PhD. All rights reserved. Derived from the WHO CIDI.';

  /// O texto e a ortografia abaixo reproduzem o instrumento PT-BR oficial.
  static const List<String> questions = [
    'Com que freqüência você sente dificuldade para finalizar os últimos '
        'detalhes de uma tarefa, depois de já ter feito as partes mais '
        'complicadas?',
    'Com que freqüência você sente dificuldade para manter as coisas em '
        'ordem quando precisa realizar uma tarefa que exige organização?',
    'Com que freqüência você tem problemas para se lembrar de compromissos '
        'ou obrigações?',
    'Quando precisa realizar uma tarefa que exige muita concentração, com '
        'que freqüência você evita ou atrasa o seu início?',
    'Com que freqüência você fica se mexendo na cadeira ou balançando as '
        'mãos ou os pés quando precisa ficar sentado(a) durante um longo '
        'período de tempo?',
    'Com que freqüência você se sente excessivamente ativo(a) e compelido(a) '
        'a fazer coisas, como se fosse conduzido(a) por um motor?',
  ];

  static AsrsScreenerResult score(Iterable<AsrsResponse> responses) {
    final values = responses.toList(growable: false);
    if (values.length != itemCount) {
      throw ArgumentError.value(
        values.length,
        'responses',
        'O ASRS v1.1 6Q exige exatamente seis respostas.',
      );
    }
    final total = values.fold<int>(0, (sum, value) => sum + value.points);
    final band = switch (total) {
      <= 9 => AsrsScoreBand.lowNegative,
      <= 13 => AsrsScoreBand.highNegative,
      <= 17 => AsrsScoreBand.lowPositive,
      _ => AsrsScoreBand.highPositive,
    };
    return AsrsScreenerResult(total: total, band: band);
  }
}
