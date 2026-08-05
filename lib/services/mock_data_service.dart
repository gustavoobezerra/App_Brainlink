// =============================================================================
// MOCK_DATA_SERVICE.DART - Serviço de Dados Simulados
// =============================================================================
// Este arquivo fornece dados simulados de EEG para testes sem o dispositivo
// físico BrainLink. Gera dados realistas que mudam ao longo do tempo.
// =============================================================================

import 'dart:async';
import 'dart:math';
import '../data/models/eeg_data.dart';

/// Serviço que gera dados simulados de EEG para testes.
///
/// Este serviço simula o comportamento do BrainLink gerando dados
/// aleatórios mas realistas de ondas cerebrais.
class MockDataService {
  // ---------------------------------------------------------------------------
  // SINGLETON PATTERN
  // ---------------------------------------------------------------------------

  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // ---------------------------------------------------------------------------
  // STREAM CONTROLLERS
  // ---------------------------------------------------------------------------

  /// Controller para emitir dados de EEG simulados.
  final StreamController<EEGData> _dataController =
      StreamController<EEGData>.broadcast();

  /// Stream público de dados simulados.
  Stream<EEGData> get dataStream => _dataController.stream;

  /// Controller para estado de conexão simulado.
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream público de estado de conexão.
  Stream<bool> get connectionStream => _connectionController.stream;

  // ---------------------------------------------------------------------------
  // ESTADO INTERNO
  // ---------------------------------------------------------------------------

  /// Timer para gerar dados periodicamente.
  Timer? _dataTimer;

  /// Flag indicando se está "conectado" (gerando dados).
  bool _isConnected = false;

  /// Gerador de números aleatórios.
  final Random _random = Random();

  /// Contador para variar os dados ao longo do tempo.
  int _counter = 0;

  // ---------------------------------------------------------------------------
  // PARÂMETROS DE SIMULAÇÃO
  // ---------------------------------------------------------------------------

  /// Intervalo entre atualizações de dados (em milissegundos).
  static const int updateInterval = 1000; // 1 segundo

  /// Valores base para cada onda cerebral (para gerar variações realistas).
  static const Map<String, int> baseValues = {
    'delta': 50000,
    'theta': 80000,
    'lowAlpha': 120000,
    'highAlpha': 100000,
    'lowBeta': 90000,
    'highBeta': 70000,
    'lowGamma': 40000,
    'midGamma': 30000,
  };

  // ---------------------------------------------------------------------------
  // MÉTODOS PÚBLICOS
  // ---------------------------------------------------------------------------

  /// Inicia a simulação de conexão e geração de dados.
  ///
  /// Retorna `true` sempre (simulação sempre funciona).
  Future<bool> startMockData() async {
    if (_isConnected) {
      return true;
    }

    _isConnected = true;
    _connectionController.add(true);

    // Aguarda um pouco para simular o tempo de conexão
    await Future.delayed(const Duration(seconds: 1));

    // Inicia o timer para gerar dados periodicamente
    _dataTimer = Timer.periodic(
      const Duration(milliseconds: updateInterval),
      (_) => _generateMockData(),
    );

    return true;
  }

  /// Para a simulação de dados.
  Future<void> stopMockData() async {
    _dataTimer?.cancel();
    _dataTimer = null;
    _isConnected = false;
    _connectionController.add(false);
    _counter = 0;
  }

  /// Retorna se está atualmente gerando dados.
  bool get isConnected => _isConnected;

  // ---------------------------------------------------------------------------
  // GERAÇÃO DE DADOS MOCK
  // ---------------------------------------------------------------------------

  /// Gera um pacote de dados de EEG simulado.
  void _generateMockData() {
    _counter++;

    // Simula diferentes estados mentais ao longo do tempo
    final mentalState = _getMentalStateForCounter();

    // Gera dados baseados no estado mental
    final data = EEGData(
      attention: _generateAttention(mentalState),
      meditation: _generateMeditation(mentalState),
      signalQuality: _generateSignalQuality(),
      delta: _generateWaveValue('delta', mentalState),
      theta: _generateWaveValue('theta', mentalState),
      lowAlpha: _generateWaveValue('lowAlpha', mentalState),
      highAlpha: _generateWaveValue('highAlpha', mentalState),
      lowBeta: _generateWaveValue('lowBeta', mentalState),
      highBeta: _generateWaveValue('highBeta', mentalState),
      lowGamma: _generateWaveValue('lowGamma', mentalState),
      midGamma: _generateWaveValue('midGamma', mentalState),
      timestamp: DateTime.now(),
    );

    // Emite os dados
    _dataController.add(data);
  }

  /// Determina o estado mental simulado baseado no contador.
  ///
  /// Cicla entre diferentes estados para variar os dados:
  /// - Relaxado (0-10s)
  /// - Focado (10-20s)
  /// - Meditando (20-30s)
  /// - Normal (30-40s)
  _MentalState _getMentalStateForCounter() {
    final cycle = (_counter ~/ 10) % 4;
    switch (cycle) {
      case 0:
        return _MentalState.relaxed;
      case 1:
        return _MentalState.focused;
      case 2:
        return _MentalState.meditating;
      default:
        return _MentalState.normal;
    }
  }

  /// Gera valor de atenção baseado no estado mental.
  int _generateAttention(_MentalState state) {
    int base;
    switch (state) {
      case _MentalState.relaxed:
        base = 40;
        break;
      case _MentalState.focused:
        base = 85;
        break;
      case _MentalState.meditating:
        base = 50;
        break;
      case _MentalState.normal:
        base = 60;
        break;
    }

    // Adiciona variação aleatória de ±15
    return (base + _random.nextInt(30) - 15).clamp(0, 100);
  }

  /// Gera valor de meditação baseado no estado mental.
  int _generateMeditation(_MentalState state) {
    int base;
    switch (state) {
      case _MentalState.relaxed:
        base = 70;
        break;
      case _MentalState.focused:
        base = 45;
        break;
      case _MentalState.meditating:
        base = 90;
        break;
      case _MentalState.normal:
        base = 55;
        break;
    }

    // Adiciona variação aleatória de ±15
    return (base + _random.nextInt(30) - 15).clamp(0, 100);
  }

  /// Gera qualidade do sinal (simula ocasionalmente sinal ruim).
  int _generateSignalQuality() {
    // 90% das vezes, sinal bom (0-50)
    // 10% das vezes, sinal ruim (50-150)
    if (_random.nextDouble() < 0.9) {
      return _random.nextInt(50);
    } else {
      return 50 + _random.nextInt(100);
    }
  }

  /// Gera valor de uma onda cerebral específica.
  int _generateWaveValue(String waveType, _MentalState state) {
    final base = baseValues[waveType] ?? 50000;

    // Multiplica baseado no estado mental
    double multiplier;
    switch (state) {
      case _MentalState.relaxed:
        // Alpha e Theta altos
        multiplier = (waveType.contains('alpha') || waveType == 'theta')
            ? 1.5 : 0.8;
        break;
      case _MentalState.focused:
        // Beta alto
        multiplier = waveType.contains('beta') ? 1.6 : 0.7;
        break;
      case _MentalState.meditating:
        // Theta e Alpha muito altos
        multiplier = (waveType == 'theta' || waveType.contains('alpha'))
            ? 2.0 : 0.5;
        break;
      case _MentalState.normal:
        multiplier = 1.0;
        break;
    }

    // Adiciona variação aleatória de ±30%
    final variation = 0.7 + (_random.nextDouble() * 0.6); // 0.7 a 1.3

    return ((base * multiplier * variation).toInt()).clamp(0, 999999);
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  /// Libera recursos.
  void dispose() {
    _dataTimer?.cancel();
    _dataController.close();
    _connectionController.close();
  }
}

// =============================================================================
// ENUM - Estados Mentais Simulados
// =============================================================================

/// Estados mentais que podem ser simulados.
enum _MentalState {
  /// Estado relaxado (Alpha alto).
  relaxed,

  /// Estado focado (Beta alto).
  focused,

  /// Estado meditando (Theta e Alpha muito altos).
  meditating,

  /// Estado normal (balanceado).
  normal,
}
