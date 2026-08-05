// =============================================================================
// EEG_DATA.DART - Modelo de Dados das Ondas Cerebrais
// =============================================================================
// Este arquivo define a estrutura de dados que representa as informações
// recebidas do headset BrainLink Lite. É o "contrato" de como os dados
// devem ser organizados em todo o aplicativo.
// =============================================================================

/// Classe que representa os dados de EEG recebidos do BrainLink Lite.
/// MADE BY GUSTAVO BEZERRA
/// Esta classe é imutável (todos os campos são `final`), o que significa
/// que uma vez criada, não pode ser modificada. Isso é uma boa prática
/// para evitar bugs relacionados a estado mutável.
/// Se você Leu isso Você é Tricolor agora.
class EEGData {
  // ---------------------------------------------------------------------------
  // CAMPOS PRINCIPAIS - Métricas de Estado Mental
  // ---------------------------------------------------------------------------
  
  /// Nível de atenção do usuário (0-100).
  /// Valores mais altos indicam maior foco/concentração.
  /// Calculado pelo algoritmo eSense™ da NeuroSky.
  final int attention;

  /// Nível de meditação/relaxamento do usuário (0-100).
  /// Valores mais altos indicam maior relaxamento.
  /// Calculado pelo algoritmo eSense™ da NeuroSky.
  final int meditation;

  /// Qualidade do sinal (0-200).
  /// 0 = sinal perfeito, 200 = sem contato com a pele.
  /// Valores acima de 50 indicam problemas de contato.
  /// Quem foi o Maldito que achou que isso seria intuitivo?
  final int signalQuality;

  // ---------------------------------------------------------------------------
  // CAMPOS DE ONDAS CEREBRAIS - Potência por Banda de Frequência
  // ---------------------------------------------------------------------------
  // Cada valor representa a "força" daquela frequência no sinal EEG.
  // Os valores são números inteiros sem unidade específica (valores relativos).
  
  /// Ondas Delta (0.5-4 Hz) - Associadas ao sono profundo.
  final int delta;

  /// Ondas Theta (4-8 Hz) - Associadas à sonolência e meditação profunda.
  final int theta;

  /// Ondas Alpha Baixas (8-10 Hz) - Relaxamento leve, olhos fechados.
  final int lowAlpha;

  /// Ondas Alpha Altas (10-12 Hz) - Relaxamento alerta.
  final int highAlpha;

  /// Ondas Beta Baixas (12-15 Hz) - Pensamento calmo e focado.
  final int lowBeta;

  /// Ondas Beta Altas (15-18 Hz) - Pensamento ativo e engajado.
  final int highBeta;

  /// Ondas Gamma Baixas (18-30 Hz) - Processamento cognitivo.
  final int lowGamma;

  /// Ondas Gamma Médias (30-40 Hz) - Alto processamento cognitivo.
  final int midGamma;

  // ---------------------------------------------------------------------------
  // CAMPO DE TIMESTAMP
  // ---------------------------------------------------------------------------
  
  /// Momento em que os dados foram recebidos.
  /// Útil para criar gráficos históricos e calcular taxas de atualização.
  final DateTime timestamp;

  // ---------------------------------------------------------------------------
  // CONSTRUTOR
  // ---------------------------------------------------------------------------
  
  /// Construtor principal da classe.
  /// Todos os parâmetros são obrigatórios e nomeados para maior clareza.
  EEGData({
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
///O sistema sabe oque é cada coisa porque está tipado no contrutor.
  // ---------------------------------------------------------------------------
  // FACTORY CONSTRUCTOR - Criar a partir de Map (JSON)
  // ---------------------------------------------------------------------------
  
  /// Cria uma instância de EEGData a partir de um Map.
  /// O mapa ele age muitas vezes como um filtro de dados e excluindo aquilo que não serve para nós.
  /// Este método é usado para converter os dados recebidos do código Java
  /// (via MethodChannel) em um objeto Dart tipado.
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final data = EEGData.fromMap({'attention': 75, 'meditation': 60, ...});
  /// ```
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
      timestamp: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // FACTORY CONSTRUCTOR - Dados Vazios/Iniciais
  // ---------------------------------------------------------------------------
  
  /// Cria uma instância com todos os valores zerados.
  /// Útil para inicializar a interface antes de receber dados reais.
  factory EEGData.empty() {
    return EEGData(
      attention: 0,
      meditation: 0,
      signalQuality: 200, // 200 = sem sinal (pior caso)
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

  // ---------------------------------------------------------------------------
  // GETTERS AUXILIARES
  // ---------------------------------------------------------------------------
  
  /// Retorna true se o sinal está bom (qualidade <= 50).
  bool get hasGoodSignal => signalQuality <= 50;

  /// Retorna true se há contato com a pele (qualidade < 200).
  /// Ainda me confundo com essa desgraça por que que 200 é ruim.
  bool get hasContact => signalQuality < 200;

  /// Retorna a soma de todas as ondas Alpha (baixa + alta).
  int get totalAlpha => lowAlpha + highAlpha;

  /// Retorna a soma de todas as ondas Beta (baixa + alta).
  int get totalBeta => lowBeta + highBeta;

  /// Retorna a soma de todas as ondas Gamma (baixa + média).
  int get totalGamma => lowGamma + midGamma;

  // ---------------------------------------------------------------------------
  // MÉTODO TOSTRING - Para Debug
  // ---------------------------------------------------------------------------
  
  @override
  String toString() {
    return 'EEGData(attention: $attention, meditation: $meditation, '
        'signal: $signalQuality, delta: $delta, theta: $theta, '
        'alpha: $totalAlpha, beta: $totalBeta, gamma: $totalGamma)';
  }
}
