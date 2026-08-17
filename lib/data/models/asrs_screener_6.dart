/// Respostas oficiais do ASRS v1.1 Screener, na ordem apresentada no
/// instrumento em português do Brasil.
enum AsrsResponse {
  never('Nunca'),
  rarely('Raramente'),
  sometimes('Algumas vezes'),
  often('Frequentemente'),
  veryOften('Muito frequentemente');

  const AsrsResponse(this.label);

  final String label;

  static AsrsResponse fromJson(Object? value) {
    return AsrsResponse.values.firstWhere(
      (response) => response.name == value,
      orElse: () => throw FormatException('Resposta ASRS inválida: $value'),
    );
  }
}

/// Um item imutável do instrumento oficial.
class AsrsScreenerItem {
  const AsrsScreenerItem({
    required this.number,
    required this.text,
    required this.positiveFrom,
  });

  final int number;
  final String text;
  final AsrsResponse positiveFrom;

  bool isPositive(AsrsResponse response) =>
      response.index >= positiveFrom.index;
}

/// Classifica somente o resultado do rastreio, sem inferência clínica.
enum AsrsScreeningClassification {
  belowScreeningThreshold,
  meritsAttention,
}

/// Definição canônica do ASRS v1.1 Screener de seis perguntas.
///
/// O instrumento é autoaplicado e destinado a adultos (18+). Seu algoritmo
/// conta quantas respostas caem nas faixas sombreadas do formulário oficial;
/// não é uma soma ordinal das alternativas.
abstract final class AsrsScreener6 {
  static const String instrumentId = 'asrs-v1.1-screener-6q-pt-br';
  static const String instrumentName = 'ASRS v1.1 Screener — 6 perguntas';
  static const int minimumAge = 18;
  static const int attentionThreshold = 4;

  static const String attribution =
      'Adult ADHD Self-Report Scale (ASRS-v1.1) Screener © 2003 '
      'World Health Organization. Desenvolvida em conjunto com Lenard Adler, '
      'Ronald Kessler, Thomas Spencer e o grupo de trabalho da OMS.';

  static const String officialSource =
      'https://www.hcp.med.harvard.edu/ncs/asrs.php';
  static const String licensingSource =
      'https://license.tov.med.nyu.edu/product/asrs-v1-1-screener';

  static const String attentionMessage =
      'Sua pontuação merece atenção. Converse com um profissional de saúde.';

  static const String belowThresholdMessage =
      'Pontuação de rastreio registrada. Se houver preocupação, converse '
      'com um profissional de saúde.';

  static const String scopeNotice =
      'Instrumento de rastreio autoaplicado para adultos. O resultado não '
      'substitui uma avaliação profissional.';

  /// Texto da versão brasileira distribuída para uso do screener.
  ///
  /// Os itens e as alternativas não devem ser resumidos ou adaptados na UI.
  static const List<AsrsScreenerItem> items = <AsrsScreenerItem>[
    AsrsScreenerItem(
      number: 1,
      text: 'Com que frequência você tem dificuldade para acabar os detalhes '
          'finais de um projeto, depois de já ter feito as partes mais difíceis?',
      positiveFrom: AsrsResponse.sometimes,
    ),
    AsrsScreenerItem(
      number: 2,
      text: 'Com que frequência você tem dificuldade para colocar as coisas '
          'em ordem quando você tem que fazer uma tarefa que exige organização?',
      positiveFrom: AsrsResponse.sometimes,
    ),
    AsrsScreenerItem(
      number: 3,
      text: 'Com que frequência você tem problemas para lembrar de '
          'compromissos ou obrigações?',
      positiveFrom: AsrsResponse.sometimes,
    ),
    AsrsScreenerItem(
      number: 4,
      text: 'Quando você precisa fazer algo que exige muita concentração, '
          'com que frequência você evita ou adia o início?',
      positiveFrom: AsrsResponse.often,
    ),
    AsrsScreenerItem(
      number: 5,
      text: 'Com que frequência você fica se mexendo na cadeira ou balançando '
          'as mãos ou os pés quando precisa ficar sentado(a) por muito tempo?',
      positiveFrom: AsrsResponse.often,
    ),
    AsrsScreenerItem(
      number: 6,
      text: 'Com que frequência você se sente ativo(a) demais e necessitando '
          'fazer coisas, como se estivesse "com um motor ligado"?',
      positiveFrom: AsrsResponse.often,
    ),
  ];

  static int score(Iterable<AsrsResponse> responses) {
    final values = List<AsrsResponse>.unmodifiable(responses);
    if (values.length != items.length) {
      throw ArgumentError.value(
        values.length,
        'responses.length',
        'O screener requer exatamente 6 respostas.',
      );
    }

    var result = 0;
    for (var index = 0; index < values.length; index++) {
      if (items[index].isPositive(values[index])) result++;
    }
    return result;
  }

  static AsrsScreeningClassification classify(
    Iterable<AsrsResponse> responses,
  ) {
    return score(responses) >= attentionThreshold
        ? AsrsScreeningClassification.meritsAttention
        : AsrsScreeningClassification.belowScreeningThreshold;
  }
}

/// Uma aplicação concluída e auditável do screener.
class AsrsScreenerResult {
  AsrsScreenerResult({
    required this.id,
    required this.completedAt,
    required Iterable<AsrsResponse> responses,
  }) : responses = List<AsrsResponse>.unmodifiable(responses) {
    // Valida o tamanho no momento da criação, não apenas ao exibir.
    AsrsScreener6.score(this.responses);
  }

  final String id;
  final DateTime completedAt;
  final List<AsrsResponse> responses;

  int get score => AsrsScreener6.score(responses);

  AsrsScreeningClassification get classification =>
      AsrsScreener6.classify(responses);

  bool get meritsAttention =>
      classification == AsrsScreeningClassification.meritsAttention;

  String get guidance => meritsAttention
      ? AsrsScreener6.attentionMessage
      : AsrsScreener6.belowThresholdMessage;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'id': id,
        'instrument': AsrsScreener6.instrumentId,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'responses': responses.map((response) => response.name).toList(),
        'screeningScore': score,
        'classification': classification.name,
        'attribution': AsrsScreener6.attribution,
      };

  factory AsrsScreenerResult.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1 ||
        json['instrument'] != AsrsScreener6.instrumentId) {
      throw const FormatException('Versão de questionário não suportada.');
    }
    final rawResponses = json['responses'];
    if (rawResponses is! List) {
      throw const FormatException('Respostas ASRS ausentes ou inválidas.');
    }
    return AsrsScreenerResult(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      responses: rawResponses.map(AsrsResponse.fromJson),
    );
  }
}
