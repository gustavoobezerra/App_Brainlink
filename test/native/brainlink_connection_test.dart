import 'dart:async';

import 'package:brainlink_app/native/brainlink_bridge.dart';
import 'package:brainlink_app/ui/screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garante por código o caminho de conexão com o BrainLink.
///
/// Os testes exercitam o gateway real sobre o canal de plataforma simulado,
/// e não um duplo de teste, porque as falhas que motivaram este arquivo
/// estavam justamente na conversa entre o Dart e o Android.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.brainlink.app/sdk');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> chamadas;
  late bool buscaIniciada;

  /// Simula uma chamada que o Android faria para o Dart.
  Future<void> doAndroid(String metodo, Object? argumentos) async {
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(metodo, argumentos)),
      (_) {},
    );
  }

  Future<void> anunciarAparelho(
    String endereco,
    String nome, {
    required bool pareado,
  }) =>
      doAndroid('onDeviceFound', <Object?, Object?>{
        'name': nome,
        'address': endereco,
        'bonded': pareado,
      });

  setUp(() {
    chamadas = [];
    buscaIniciada = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      chamadas.add(call.method);
      switch (call.method) {
        case 'startScan':
          return buscaIniciada;
        case 'stopScan':
          return true;
        case 'connect':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('descoberta', () {
    test('mantém o BrainLink pareado quando a varredura ativa não começa',
        () async {
      buscaIniciada = false;
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final busca = gateway.listDevices();
      // O Android emite os pareados antes de tentar a descoberta.
      await anunciarAparelho('00:11:22:33:44:55', 'BrainLink Lite',
          pareado: true);
      final aparelhos = await busca;

      expect(aparelhos, hasLength(1));
      expect(aparelhos.single.name, 'BrainLink Lite');
      expect(aparelhos.single.isPaired, isTrue);
      expect(chamadas, contains('startScan'));
    });

    test('encerra a busca assim que o Android informa que ela terminou',
        () async {
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final busca = gateway.listDevices();
      await doAndroid('onScanStateChanged', true);
      await anunciarAparelho('AA:BB:CC:DD:EE:FF', 'BrainLink Lite',
          pareado: false);
      await doAndroid('onScanStateChanged', false);

      // Sem esperar os treze segundos do limite de segurança.
      final aparelhos = await busca.timeout(const Duration(seconds: 2));
      expect(aparelhos.single.id, 'AA:BB:CC:DD:EE:FF');
    });

    test('ignora o fim de uma busca que nunca começou', () async {
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final busca = gateway.listDevices();
      // Evento remanescente de um cancelDiscovery() anterior.
      await doAndroid('onScanStateChanged', false);
      await anunciarAparelho('00:11:22:33:44:55', 'BrainLink Lite',
          pareado: true);
      await doAndroid('onScanStateChanged', true);
      await doAndroid('onScanStateChanged', false);

      final aparelhos = await busca.timeout(const Duration(seconds: 2));
      expect(aparelhos.single.name, 'BrainLink Lite');
    });

    test('prioriza os pareados e aceita o nome resolvido depois', () async {
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final busca = gateway.listDevices();
      await doAndroid('onScanStateChanged', true);
      await anunciarAparelho('11:11:11:11:11:11', 'Fone qualquer',
          pareado: false);
      await anunciarAparelho('22:22:22:22:22:22', 'Dispositivo Bluetooth',
          pareado: false);
      await anunciarAparelho('22:22:22:22:22:22', 'BrainLink Lite',
          pareado: true);
      await doAndroid('onScanStateChanged', false);

      final aparelhos = await busca.timeout(const Duration(seconds: 2));
      expect(aparelhos.first.name, 'BrainLink Lite');
      expect(aparelhos.first.isPaired, isTrue);
      expect(aparelhos, hasLength(2));
    });

    test('explica a causa do Android quando nada é encontrado', () async {
      buscaIniciada = false;
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final busca = gateway.listDevices();
      await doAndroid('onError', 'Ative a Localização do Android.');

      await expectLater(
        busca,
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'mensagem',
          'Ative a Localização do Android.',
        )),
      );
    });
  });

  group('conexão', () {
    test('leva ao usuário a causa informada pelo Android', () async {
      final erros = <Object>[];
      await runZonedGuarded(() async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'connect') {
            await doAndroid('onError', 'A permissão Bluetooth foi negada.');
            throw PlatformException(
              code: 'BLUETOOTH_PERMISSION_DENIED',
              message: 'A permissão Bluetooth necessária foi negada.',
            );
          }
          return null;
        });
        final gateway = NativeBrainLinkGateway(BrainLinkBridge());

        await expectLater(
          gateway.connect(
            const ConnectableDevice('00:11:22:33:44:55', 'BrainLink Lite',
                isPaired: true),
          ),
          throwsA(isA<StateError>()),
        );
      }, (error, _) => erros.add(error))!;

      // A falha do canal não pode virar exceção assíncrona não tratada.
      expect(erros, isEmpty);
    });

    test('conclui quando o Android confirma o estado conectado', () async {
      final gateway = NativeBrainLinkGateway(BrainLinkBridge());

      final conexao = gateway.connect(
        const ConnectableDevice('00:11:22:33:44:55', 'BrainLink Lite',
            isPaired: true),
      );
      await doAndroid('onConnectionStateChanged', true);

      await expectLater(conexao.timeout(const Duration(seconds: 2)), completes);
      expect(chamadas, contains('connect'));
    });
  });
}
