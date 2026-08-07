import 'dart:async';
import 'dart:math';

import '../data/models/eeg_data.dart';

/// Produz séries sintéticas para validar o fluxo e a interface sem hardware.
///
/// Os perfis e valores não representam medições fisiológicas nem substituem
/// dados coletados sob um protocolo experimental.
class MockDataService {
  factory MockDataService() => _instance;

  MockDataService._internal();

  static final MockDataService _instance = MockDataService._internal();
  static const int _updateIntervalMilliseconds = 1000;
  static const Map<String, int> _baseValues = {
    'delta': 50000,
    'theta': 80000,
    'lowAlpha': 120000,
    'highAlpha': 100000,
    'lowBeta': 90000,
    'highBeta': 70000,
    'lowGamma': 40000,
    'midGamma': 30000,
  };

  final StreamController<EEGData> _dataController =
      StreamController<EEGData>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final Random _random = Random();

  Timer? _dataTimer;
  bool _isConnected = false;
  int _counter = 0;

  Stream<EEGData> get dataStream => _dataController.stream;

  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Inicia a sessão simulada após uma latência de conexão controlada.
  Future<bool> startMockData() async {
    if (_isConnected) {
      return true;
    }

    _isConnected = true;
    _connectionController.add(true);
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!_isConnected) {
      return false;
    }

    _dataTimer = Timer.periodic(
      const Duration(milliseconds: _updateIntervalMilliseconds),
      (_) => _generateMockData(),
    );
    return true;
  }

  /// Interrompe a sessão simulada e reinicia o ciclo de perfis.
  Future<void> stopMockData() async {
    _dataTimer?.cancel();
    _dataTimer = null;
    _isConnected = false;
    _connectionController.add(false);
    _counter = 0;
  }

  void _generateMockData() {
    _counter++;
    final profile = _profileForCounter();

    _dataController.add(
      EEGData(
        attention: _generateAttention(profile),
        meditation: _generateMeditation(profile),
        signalQuality: _generateSignalQuality(),
        delta: _generateWaveValue('delta', profile),
        theta: _generateWaveValue('theta', profile),
        lowAlpha: _generateWaveValue('lowAlpha', profile),
        highAlpha: _generateWaveValue('highAlpha', profile),
        lowBeta: _generateWaveValue('lowBeta', profile),
        highBeta: _generateWaveValue('highBeta', profile),
        lowGamma: _generateWaveValue('lowGamma', profile),
        midGamma: _generateWaveValue('midGamma', profile),
        timestamp: DateTime.now(),
      ),
    );
  }

  _SimulationProfile _profileForCounter() {
    final cycle = (_counter ~/ 10) % 4;
    switch (cycle) {
      case 0:
        return _SimulationProfile.relaxed;
      case 1:
        return _SimulationProfile.focused;
      case 2:
        return _SimulationProfile.meditative;
      default:
        return _SimulationProfile.baseline;
    }
  }

  int _generateAttention(_SimulationProfile profile) {
    final base = switch (profile) {
      _SimulationProfile.relaxed => 40,
      _SimulationProfile.focused => 85,
      _SimulationProfile.meditative => 50,
      _SimulationProfile.baseline => 60,
    };
    return (base + _random.nextInt(30) - 15).clamp(0, 100);
  }

  int _generateMeditation(_SimulationProfile profile) {
    final base = switch (profile) {
      _SimulationProfile.relaxed => 70,
      _SimulationProfile.focused => 45,
      _SimulationProfile.meditative => 90,
      _SimulationProfile.baseline => 55,
    };
    return (base + _random.nextInt(30) - 15).clamp(0, 100);
  }

  int _generateSignalQuality() {
    if (_random.nextDouble() < 0.9) {
      return _random.nextInt(50);
    }
    return 50 + _random.nextInt(100);
  }

  int _generateWaveValue(String waveType, _SimulationProfile profile) {
    final base = _baseValues[waveType] ?? 50000;
    final multiplier = switch (profile) {
      _SimulationProfile.relaxed =>
        waveType.contains('alpha') || waveType == 'theta' ? 1.5 : 0.8,
      _SimulationProfile.focused => waveType.contains('beta') ? 1.6 : 0.7,
      _SimulationProfile.meditative =>
        waveType == 'theta' || waveType.contains('alpha') ? 2.0 : 0.5,
      _SimulationProfile.baseline => 1.0,
    };
    final variation = 0.7 + (_random.nextDouble() * 0.6);

    return (base * multiplier * variation).toInt().clamp(0, 999999);
  }

  /// Encerra os recursos mantidos pelo serviço.
  Future<void> dispose() async {
    _dataTimer?.cancel();
    await Future.wait([
      _dataController.close(),
      _connectionController.close(),
    ]);
  }
}

/// Perfis numéricos utilizados exclusivamente para variar a demonstração.
enum _SimulationProfile { relaxed, focused, meditative, baseline }
