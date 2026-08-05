// =============================================================================
// BRAINLINK_BRIDGE.DART - Ponte de Comunicação Dart ↔ Java
// =============================================================================
// Este arquivo é o CORAÇÃO da integração com o SDK nativo.
// Ele gerencia toda a comunicação entre o código Dart (Flutter) e o código
// Java (Android) usando MethodChannels.
//
// FLUXO DE DADOS:
// BrainLink Lite → Bluetooth → Java SDK → MethodChannel → Dart → UI
// =============================================================================
// Feito por GUSTAVO DE OLIVEIRA BEZERRA - 01/01/2026
import 'dart:async';
import 'package:flutter/services.dart';
import '../data/models/eeg_data.dart';
import '../core/logger.dart';

/// Classe responsável pela comunicação com o SDK nativo do BrainLink.
/// MADE BY GUSTAVO BEZERRA
/// Esta classe implementa o padrão Singleton para garantir que apenas
/// uma instância exista durante toda a execução do app.
class BrainLinkBridge {

  /// Isso aqui tá enviando o status pro dart dando mais assitência que PAULO HENRIQUE GANSO NO AUGE NO FLUZÃO.

  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  /// Stream público para monitorar atualizações de status da conexão.
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  
  /// Instância única da classe (Singleton).
  static final BrainLinkBridge _instance = BrainLinkBridge._internal();

  /// Factory constructor que retorna sempre a mesma instância.
  factory BrainLinkBridge() => _instance;

  /// Construtor privado - só pode ser chamado internamente.
  BrainLinkBridge._internal() {
    _setupMethodCallHandler();
  }

  // ---------------------------------------------------------------------------
  // METHOD CHANNEL - O "Túnel" de Comunicação
  // ---------------------------------------------------------------------------
  // O MethodChannel é como um walkie-talkie entre Dart e Java.
  // Ambos os lados precisam usar o MESMO nome do canal.

  /// Logger para este serviço.
  final Logger _logger = Logger('BrainLinkBridge');

  /// Canal de comunicação com o código nativo.
  /// O nome 'com.brainlink.app/sdk' deve ser IDÊNTICO no lado Java.
  static const MethodChannel _channel = MethodChannel('com.brainlink.app/sdk');

  // ---------------------------------------------------------------------------
  // STREAM CONTROLLER - Fluxo de Dados em Tempo Real
  // ---------------------------------------------------------------------------
  // O StreamController é como uma "esteira de produção" que entrega
  // os dados de EEG para quem estiver "ouvindo" (a interface gráfica).
  
  /// Controller do stream de dados EEG.
  /// broadcast = permite múltiplos listeners (várias telas podem ouvir).
  /// A UI usa este stream para atualizar os gráficos em tempo real.
  final StreamController<EEGData> _eegDataController =
      StreamController<EEGData>.broadcast();

  /// Stream público para a UI se inscrever e receber dados.
  /// A UI usa este stream para atualizar os gráficos em tempo real.
  Stream<EEGData> get eegDataStream => _eegDataController.stream;

  // ---------------------------------------------------------------------------
  // ESTADO DA CONEXÃO
  // ---------------------------------------------------------------------------
  
  /// Controller do stream de estado de conexão.
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Stream público para monitorar o estado da conexão.
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Flag interna para rastrear se estamos conectados.
  bool _isConnected = false;

  /// Getter público para verificar o estado atual.
  bool get isConnected => _isConnected;

  /// Controller para emitir mensagens de erro.
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Stream público para receber mensagens de erro.
  Stream<String> get errorStream => _errorController.stream;

  // ---------------------------------------------------------------------------
  // SETUP DO HANDLER - Receber Mensagens do Java
  // ---------------------------------------------------------------------------
  
  /// Configura o handler para receber chamadas vindas do código Java.
  ///
  /// Quando o Java chama `channel.invokeMethod("onEEGData", data)`,
  /// este handler é acionado e processa os dados recebidos.
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((MethodCall call) async {
      // Identifica qual método o Java está chamando
      switch (call.method) {

        // Caso 1: Recebemos novos dados de EEG
        //Ganso tocou e gol do Fluzão
        case 'onEEGData':
          // Converte o Map recebido em um objeto EEGData tipado
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(call.arguments as Map);
          final eegData = EEGData.fromMap(data);

          // Envia os dados para todos os listeners (a UI)
          // E o Criolo Beiçudo Do Monte Mario vai Usar isso aqui
          _eegDataController.add(eegData);
          break;
          //A bola tá chegando pro cano fazer o gol
        // Caso 2: Atualização de status da conexão
        case 'onStatusUpdate':
          final String status = call.arguments as String;
          _connectionStatusController.add(status);
          break;

        // Caso 3: O estado da conexão mudou
        //??? Quando não sabemos o estado real do bagui.
        case 'onConnectionStateChanged':
          final bool connected = call.arguments as bool;
          _isConnected = connected;
          _connectionStateController.add(connected);
          break;

        // Caso 4: Ocorreu um erro no lado nativo
        // A Bola chegou na área mas era o Everaldo e ele perdeu o gol.
        case 'onError':
          final String errorMessage = call.arguments as String;
          _logger.error('Erro do SDK nativo: $errorMessage');
          _errorController.add(errorMessage);
          break;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS PÚBLICOS - Comandos para o SDK Nativo
  // ---------------------------------------------------------------------------

  /// Inicia a conexão com o dispositivo BrainLink.
  /// 
  /// [deviceAddress] é o endereço MAC do dispositivo Bluetooth.
  /// Retorna `true` se a conexão foi iniciada com sucesso.
  /// 
  /// Exemplo:
  /// ```dart
  /// final success = await bridge.connect('AA:BB:CC:DD:EE:FF');
  /// ```
  /// Ali em cima configurei pra entender oq o Java Fala e aqui embaixo é pro Java entender.
  /// É boolean pq ou está conectado ou não.
  Future<bool> connect(String deviceAddress) async {
    try {
      _logger.info('Iniciando conexão com $deviceAddress');
      // Chama o método 'connect' no lado Java, passando o endereço
      final bool result = await _channel.invokeMethod('connect', {
        'deviceAddress': deviceAddress,
      });
      ///Esses _logger.info é só boa prática para sabermos no console que porra que está acontecendo.
      _logger.info('Conexão iniciada com sucesso');
      return result;
    } on PlatformException catch (e) {
      final errorMsg = 'Erro ao conectar: ${e.message}';
      _logger.error(errorMsg, e);
      _errorController.add(errorMsg);
      return false;
    } catch (e) {
      final errorMsg = 'Erro inesperado ao conectar: $e';
      _logger.error(errorMsg, e);
      _errorController.add(errorMsg);
      return false;
    }
  }

  /// Encerra a conexão com o dispositivo BrainLink.
  ///
  /// Retorna `true` se a desconexão foi bem-sucedida.
  Future<bool> disconnect() async {
    try {
      final bool result = await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectionStateController.add(false);
      return result;
    } on PlatformException catch (e) {
      _logger.error('Erro ao desconectar: ${e.message}', e);
      return false;
    }
  }

  /// Envia dados brutos do Bluetooth para o SDK processar.
  ///
  /// Este método é chamado quando recebemos bytes do BLE e precisamos
  /// que o SDK nativo os decodifique em dados de EEG.
  ///
  /// [rawData] é a lista de bytes recebidos do Bluetooth.
  /// Recebemos aqui pelo Bluetooth um monte de código binário Regurgitado sem pé nem cabeça e mandaas para o SDK em JAVA processar e ele retorna uma papinha de neném gostosa e comestível.
  Future<void> parseRawData(List<int> rawData) async {
    try {
      await _channel.invokeMethod('parseData', {
        'rawData': rawData,
      });
    } on PlatformException catch (e) {
      _logger.error('Erro ao processar dados: ${e.message}', e);
    }
  }


  /// Inicia o escaneamento de dispositivos BrainLink próximos.
  ///
  /// Retorna `true` se o scan foi iniciado com sucesso.
  Future<bool> startScan() async {
    try {
      final bool result = await _channel.invokeMethod('startScan');
      return result;
    } on PlatformException catch (e) {
      _logger.error('Erro ao iniciar scan: ${e.message}', e);
      return false;
    }
  }

  /// Para o escaneamento de dispositivos.
  Future<void> stopScan() async {
    try {
      await _channel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      _logger.error('Erro ao parar scan: ${e.message}', e);
    }
  }

  // ---------------------------------------------------------------------------
  // CLEANUP - Liberar Recursos
  // ---------------------------------------------------------------------------
  
  /// Libera os recursos quando o app é fechado.
  ///
  /// IMPORTANTE: Sempre chame este método no dispose() da tela principal
  /// para evitar memory leaks.
  void dispose() {
    _eegDataController.close();
    _connectionStateController.close();
    _connectionStatusController.close();
    _errorController.close();
  }
}
