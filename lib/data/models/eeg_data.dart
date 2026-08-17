/// Amostra consolidada de eletroencefalografia recebida do BrainLink Lite.
///
/// As potências das bandas são valores relativos fornecidos pelo dispositivo.
/// Atenção, meditação e qualidade do sinal seguem as escalas definidas
/// pelo SDK do fabricante.
///
/// Todos os campos numéricos são anuláveis por decisão de projeto: `null`
/// significa *não medido*, e é diferente de `0`, que é uma medida real de valor
/// zero. Antes desta distinção existir, uma amostra sem dado chegava à interface
/// como "0" e era lida pelo usuário como leitura válida.
class EEGData {
  const EEGData({
    this.attention,
    this.meditation,
    this.signalQuality,
    this.delta,
    this.theta,
    this.lowAlpha,
    this.highAlpha,
    this.lowBeta,
    this.highBeta,
    this.lowGamma,
    this.midGamma,
    required this.timestamp,
  });

  /// Índice de atenção do fabricante, escala de 0 a 100 (algoritmo proprietário).
  final int? attention;

  /// Índice de meditação do fabricante, escala de 0 a 100.
  final int? meditation;

  /// Qualidade do sinal na escala de 0 a 200; valores menores são melhores.
  final int? signalQuality;

  /// Potência relativa da banda delta.
  final int? delta;

  /// Potência relativa da banda theta.
  final int? theta;

  /// Potência relativa da faixa inferior da banda alfa.
  final int? lowAlpha;

  /// Potência relativa da faixa superior da banda alfa.
  final int? highAlpha;

  /// Potência relativa da faixa inferior da banda beta.
  final int? lowBeta;

  /// Potência relativa da faixa superior da banda beta.
  final int? highBeta;

  /// Potência relativa da faixa inferior da banda gama.
  final int? lowGamma;

  /// Potência relativa da faixa intermediária da banda gama.
  final int? midGamma;

  /// Instante de aquisição da amostra.
  final DateTime timestamp;

  /// Converte o mapa recebido pelo canal nativo em uma amostra tipada.
  ///
  /// Campo ausente vira `null`. Não há valor padrão: inventar um zero aqui é
  /// exatamente o que se quer evitar.
  factory EEGData.fromMap(Map<String, dynamic> map) {
    return EEGData(
      attention: map['attention'] as int?,
      meditation: map['meditation'] as int?,
      signalQuality: map['signalQuality'] as int?,
      delta: map['delta'] as int?,
      theta: map['theta'] as int?,
      lowAlpha: map['lowAlpha'] as int?,
      highAlpha: map['highAlpha'] as int?,
      lowBeta: map['lowBeta'] as int?,
      highBeta: map['highBeta'] as int?,
      lowGamma: map['lowGamma'] as int?,
      midGamma: map['midGamma'] as int?,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  /// Amostra que representa ausência de dado — todos os campos nulos.
  factory EEGData.absent() => EEGData(timestamp: DateTime.now());

  /// Serializa para o mesmo formato que [EEGData.fromMap] consome.
  ///
  /// Campos nulos são omitidos, e não gravados como `null`, para que a ida e
  /// volta por JSON preserve a distinção entre ausente e zero.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
    void put(String key, int? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    put('attention', attention);
    put('meditation', meditation);
    put('signalQuality', signalQuality);
    put('delta', delta);
    put('theta', theta);
    put('lowAlpha', lowAlpha);
    put('highAlpha', highAlpha);
    put('lowBeta', lowBeta);
    put('highBeta', highBeta);
    put('lowGamma', lowGamma);
    put('midGamma', midGamma);
    return map;
  }

  /// Cópia com campos substituídos.
  ///
  /// Com campos anuláveis, passar `null` é indistinguível de não passar nada —
  /// daí os sinalizadores `clearX`, que apagam explicitamente.
  EEGData copyWith({
    int? attention,
    int? meditation,
    int? signalQuality,
    int? delta,
    int? theta,
    int? lowAlpha,
    int? highAlpha,
    int? lowBeta,
    int? highBeta,
    int? lowGamma,
    int? midGamma,
    DateTime? timestamp,
    bool clearAttention = false,
    bool clearMeditation = false,
    bool clearSignalQuality = false,
    bool clearBands = false,
  }) {
    return EEGData(
      attention: clearAttention ? null : (attention ?? this.attention),
      meditation: clearMeditation ? null : (meditation ?? this.meditation),
      signalQuality:
          clearSignalQuality ? null : (signalQuality ?? this.signalQuality),
      delta: clearBands ? null : (delta ?? this.delta),
      theta: clearBands ? null : (theta ?? this.theta),
      lowAlpha: clearBands ? null : (lowAlpha ?? this.lowAlpha),
      highAlpha: clearBands ? null : (highAlpha ?? this.highAlpha),
      lowBeta: clearBands ? null : (lowBeta ?? this.lowBeta),
      highBeta: clearBands ? null : (highBeta ?? this.highBeta),
      lowGamma: clearBands ? null : (lowGamma ?? this.lowGamma),
      midGamma: clearBands ? null : (midGamma ?? this.midGamma),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Indica se a amostra carrega ao menos um valor medido.
  bool get hasAnyData =>
      attention != null ||
      meditation != null ||
      signalQuality != null ||
      delta != null ||
      theta != null ||
      lowAlpha != null ||
      highAlpha != null ||
      lowBeta != null ||
      highBeta != null ||
      lowGamma != null ||
      midGamma != null;

  /// Indica se a amostra possui qualidade de sinal adequada.
  /// `null` quando a qualidade não foi medida.
  bool? get hasGoodSignal =>
      signalQuality == null ? null : signalQuality! <= 50;

  /// Indica se o sensor registra contato com a pele.
  bool? get hasContact => signalQuality == null ? null : signalQuality! < 200;

  /// Soma das duas metades da banda; `null` se qualquer metade faltar.
  int? get totalAlpha => _sum(lowAlpha, highAlpha);

  int? get totalBeta => _sum(lowBeta, highBeta);

  int? get totalGamma => _sum(lowGamma, midGamma);

  static int? _sum(int? a, int? b) => (a == null || b == null) ? null : a + b;

  static DateTime _parseTimestamp(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EEGData &&
        other.attention == attention &&
        other.meditation == meditation &&
        other.signalQuality == signalQuality &&
        other.delta == delta &&
        other.theta == theta &&
        other.lowAlpha == lowAlpha &&
        other.highAlpha == highAlpha &&
        other.lowBeta == lowBeta &&
        other.highBeta == highBeta &&
        other.lowGamma == lowGamma &&
        other.midGamma == midGamma &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        attention,
        meditation,
        signalQuality,
        delta,
        theta,
        lowAlpha,
        highAlpha,
        lowBeta,
        highBeta,
        lowGamma,
        midGamma,
        timestamp,
      );

  @override
  String toString() {
    return 'EEGData(attention: $attention, meditation: $meditation, '
        'signalQuality: $signalQuality, delta: $delta, theta: $theta, '
        'alpha: $totalAlpha, beta: $totalBeta, gamma: $totalGamma, '
        'timestamp: $timestamp)';
  }
}
