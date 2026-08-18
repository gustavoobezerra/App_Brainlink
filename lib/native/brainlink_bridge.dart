import 'dart:async';

import 'package:flutter/services.dart';

import '../core/logger.dart';
import '../data/models/bluetooth_device_info.dart';
import '../data/models/eeg_data.dart';
import '../data/models/raw_batch.dart';

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
  static const EventChannel _rawChannel = EventChannel('com.brainlink.app/raw');

  final Logger _logger = const Logger('BrainLinkBridge');
  final StreamController<EEGData> _eegDataController =
      StreamController<EEGData>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<BluetoothDeviceInfo> _deviceController =
      StreamController<BluetoothDeviceInfo>.broadcast();
  final StreamController<bool> _scanStateController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  Stream<EEGData> get eegDataStream => _eegDataController.stream;

  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  Stream<String> get errorStream => _errorController.stream;

  Stream<BluetoothDeviceInfo> get deviceStream => _deviceController.stream;

  Stream<bool> get scanStateStream => _scanStateController.stream;

  /// EEG bruto a 128 Hz, agrupado em lotes de um segundo pela camada Android.
  Stream<RawBatch> get rawDataStream => _rawChannel
      .receiveBroadcastStream()
      .map((event) => RawBatch.fromMap(event as Map<Object?, Object?>));

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
        case 'onDeviceFound':
          final map = call.arguments as Map<Object?, Object?>;
          _deviceController.add(BluetoothDeviceInfo.fromMap(map));
        case 'onScanStateChanged':
          _scanStateController.add(call.arguments as bool);
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
  Future<bool> stopScan() async {
    try {
      return await _channel.invokeMethod<bool>('stopScan') ?? false;
    } on PlatformException catch (error, stackTrace) {
      final message = 'Não foi possível interromper a busca: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return false;
    }
  }

  /// Estado do Android de que a conexão depende, para diagnóstico em campo.
  Future<Map<String, Object?>> getDiagnostics() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, Object?>('getDiagnostics');
      return result ?? const {};
    } on PlatformException catch (error, stackTrace) {
      _logger.error('Diagnóstico indisponível', error, stackTrace);
      return const {};
    }
  }

  /// Diretório privado do aplicativo, usado pela persistência local.
  Future<String?> getStorageRoot() async {
    try {
      return await _channel.invokeMethod<String>('getStorageRoot');
    } on PlatformException catch (error, stackTrace) {
      final message =
          'Não foi possível acessar o armazenamento: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return null;
    }
  }

  /// Abre o compartilhamento do Android para um arquivo privado do app.
  Future<bool> shareFile(
    String path, {
    String mimeType = 'text/html',
  }) async {
    try {
      return await _channel.invokeMethod<bool>('shareFile', {
            'path': path,
            'mimeType': mimeType,
          }) ??
          false;
    } on PlatformException catch (error, stackTrace) {
      final message =
          'Não foi possível compartilhar o relatório: ${error.message}';
      _logger.error(message, error, stackTrace);
      _errorController.add(message);
      return false;
    }
  }

  /// Encerra os streams mantidos pela ponte.
  Future<void> dispose() async {
    await Future.wait([
      _eegDataController.close(),
      _connectionStateController.close(),
      _connectionStatusController.close(),
      _errorController.close(),
      _deviceController.close(),
      _scanStateController.close(),
    ]);
  }
}
