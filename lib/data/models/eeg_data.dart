/// Amostra consolidada de eletroencefalografia recebida do BrainLink Lite.
///
/// As potências das bandas são valores relativos fornecidos pelo dispositivo.
/// Atenção, meditação e qualidade do sinal seguem as escalas definidas
/// pelo SDK do fabricante.
class EEGData {
  const EEGData({
    required this.attention,
    required this.meditation,
    required this.signalQuality,
    required this.delta,
    required this.theta,
    required this.lowAlpha,
    required this.highAlpha,
    required this.lowBeta,
    required this.highBeta,
    required this.lowGamma,
    required this.midGamma,
    required this.timestamp,
  });

  /// Índice de atenção na escala de 0 a 100.
  final int attention;

  /// Índice de meditação na escala de 0 a 100.
  final int meditation;

  /// Qualidade do sinal na escala de 0 a 200; valores menores são melhores.
  final int signalQuality;

  /// Potência relativa da banda delta.
  final int delta;

  /// Potência relativa da banda theta.
  final int theta;

  /// Potência relativa da faixa inferior da banda alfa.
  final int lowAlpha;

  /// Potência relativa da faixa superior da banda alfa.
  final int highAlpha;

  /// Potência relativa da faixa inferior da banda beta.
  final int lowBeta;

  /// Potência relativa da faixa superior da banda beta.
  final int highBeta;

  /// Potência relativa da faixa inferior da banda gama.
  final int lowGamma;

  /// Potência relativa da faixa intermediária da banda gama.
  final int midGamma;

  /// Instante de aquisição da amostra.
  final DateTime timestamp;

  /// Converte o mapa recebido pelo canal nativo em uma amostra tipada.
  factory EEGData.fromMap(Map<String, dynamic> map) {
    return EEGData(
      attention: map['attention'] as int? ?? 0,
      meditation: map['meditation'] as int? ?? 0,
      signalQuality: map['signalQuality'] as int? ?? 200,
      delta: map['delta'] as int? ?? 0,
      theta: map['theta'] as int? ?? 0,
      lowAlpha: map['lowAlpha'] as int? ?? 0,
      highAlpha: map['highAlpha'] as int? ?? 0,
      lowBeta: map['lowBeta'] as int? ?? 0,
      highBeta: map['highBeta'] as int? ?? 0,
      lowGamma: map['lowGamma'] as int? ?? 0,
      midGamma: map['midGamma'] as int? ?? 0,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  /// Cria uma amostra inicial que representa ausência de sinal.
  factory EEGData.empty() {
    return EEGData(
      attention: 0,
      meditation: 0,
      signalQuality: 200,
      delta: 0,
      theta: 0,
      lowAlpha: 0,
      highAlpha: 0,
      lowBeta: 0,
      highBeta: 0,
      lowGamma: 0,
      midGamma: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Indica se a amostra possui qualidade de sinal adequada.
  bool get hasGoodSignal => signalQuality <= 50;

  /// Indica se o sensor registra contato com a pele.
  bool get hasContact => signalQuality < 200;

  int get totalAlpha => lowAlpha + highAlpha;

  int get totalBeta => lowBeta + highBeta;

  int get totalGamma => lowGamma + midGamma;

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
  String toString() {
    return 'EEGData(attention: $attention, meditation: $meditation, '
        'signalQuality: $signalQuality, delta: $delta, theta: $theta, '
        'alpha: $totalAlpha, beta: $totalBeta, gamma: $totalGamma, '
        'timestamp: $timestamp)';
  }
}
