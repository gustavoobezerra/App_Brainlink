import 'dart:async';

import 'package:flutter/services.dart';

import '../core/logger.dart';
import '../data/models/eeg_data.dart';

/// Interface entre a camada Flutter e o SDK Android do BrainLink.
///
/// A instância única concentra o canal de métodos e distribui os eventos
/// nativos por streams de dados, conexão, status e erro.
class BrainLinkBridge {
  factory BrainLinkBridge() => _instance;

  BrainLinkBridge._internal() {
    _configureNativeCallback();
  }

  static final BrainLinkBridge _instance = BrainLinkBridge._internal();
  static const MethodChannel _channel = MethodChannel('com.brainlink.app/sdk');

  final Logger _logger = const Logger('BrainLinkBridge');
  final StreamController<EEGData> _eegDataController =
      StreamController<EEGData>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isConnected = false;

  Stream<EEGData> get eegDataStream => _eegDataController.stream;

  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;

  void _configureNativeCallback() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onEEGData':
          final data = Map<String, dynamic>.from(call.arguments as Map);
          _eegDataController.add(EEGData.fromMap(data));
        case 'onStatusUpdate':
          _connectionStatusController.add(call.arguments as String);
        case 'onConnectionStateChanged':
          _isConnected = call.arguments as bool;
          _connectionStateController.add(_isConnected);
        case 'onError':
          final message = call.arguments as String;
          _logger.error('Erro informado pelo SDK nativo: $message');
          _errorController.add(message);
        default:
          _logger.warning('Callback nativo desconhecido: ${call.method}');
      }
    });
  }

  /// Solicita ao SDK a conexão com o endereço Bluetooth informado.
  Future<bool> connect(String deviceAddress) async {
    try {
      _logger.info('Iniciando conexão com $deviceAddress');
      final result = await _channel.invokeMethod<bool>(
        'connect',
        {'deviceAddress': deviceAddress},
      );
      return result ?? false;
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível iniciar a conexão: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return false;
    }
  }

  /// Encerra a conexão ativa com o dispositivo.
  Future<bool> disconnect() async {
    try {
      final result = await _channel.invokeMethod<bool>('disconnect');
      _isConnected = false;
      _connectionStateController.add(false);
      return result ?? false;
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível encerrar a conexão: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return false;
    }
  }

  /// Encaminha bytes recebidos externamente para a camada nativa.
  Future<void> parseRawData(List<int> rawData) async {
    try {
      await _channel.invokeMethod<void>('parseData', {'rawData': rawData});
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível processar os dados: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
    }
  }

  /// Solicita o início da descoberta de dispositivos.
  Future<bool> startScan() async {
    try {
      final result = await _channel.invokeMethod<bool>('startScan');
      return result ?? false;
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível iniciar a busca: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return false;
    }
  }

  /// Solicita a interrupção da descoberta de dispositivos.
  Future<void> stopScan() async {
    try {
      await _channel.invokeMethod<void>('stopScan');
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível interromper a busca: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
    }
  }

  /// Encerra os streams mantidos pela ponte.
  Future<void> dispose() async {
    await Future.wait([
      _eegDataController.close(),
      _connectionStateController.close(),
      _connectionStatusController.close(),
      _errorController.close(),
    ]);
  }
}
