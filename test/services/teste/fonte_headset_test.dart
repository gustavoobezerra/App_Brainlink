import 'dart:async';
import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/native/brainlink_bridge.dart';
import 'package:brainlink_app/services/teste/fonte_headset.dart';
import 'package:brainlink_app/services/teste/fonte_sinal.dart';
import 'package:brainlink_app/ui/screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gateway falso: registra as conexões e falha quando pedido.
class _GatewayFalso implements DeviceDiscoveryGateway {
  final conexoes = <ConnectableDevice>[];
  List<ConnectableDevice> aparelhos = const [];
  Object? erro;

  @override
  Future<void> connect(ConnectableDevice device) async {
    conexoes.add(device);
    final falha = erro;
    if (falha != null) throw falha;
  }

  @override
  Future<List<ConnectableDevice>> listDevices() async => aparelhos;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('com.brainlink.app/sdk');
  const codec = StandardMethodCodec();
  final mensageiro =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> chamadas;
  late List<Map<String, Object?>> pareados;
  late _GatewayFalso gateway;
  late StreamController<RawBatch> brutos;
  late int inscricoes;
  late int cancelamentos;

  Future<void> doAndroid(String metodo, Object? argumentos) async {
    await mensageiro.handlePlatformMessage(
      canal.name,
      codec.encodeMethodCall(MethodCall(metodo, argumentos)),
      (_) {},
    );
  }

  Map<String, Object?> aparelho(String endereco, String nome) =>
      {'name': nome, 'address': endereco, 'bonded': true};

  RawBatch lote(int seq) => RawBatch(
        seq: seq,
        t0: DateTime(2026),
        poorSignal: 0,
        dropped: 0,
        samples: Int32List(512),
      );

  FonteHeadset criar() => FonteHeadset(
        ponte: BrainLinkBridge(),
        gateway: gateway,
        lotesBrutos: brutos.stream,
      );

  setUp(() async {
    chamadas = [];
    pareados = [];
    gateway = _GatewayFalso();
    inscricoes = 0;
    cancelamentos = 0;
    brutos = StreamController<RawBatch>(
      onListen: () => inscricoes++,
      onCancel: () => cancelamentos++,
    );
    mensageiro.setMockMethodCallHandler(canal, (chamada) async {
      chamadas.add(chamada.method);
      return switch (chamada.method) {
        'getPairedDevices' => pareados,
        'disconnect' => true,
        _ => null,
      };
    });
    // A ponte é única: começa cada teste desconectada.
    await doAndroid('onConnectionStateChanged', false);
  });

  tearDown(() => mensageiro.setMockMethodCallHandler(canal, null));

  group('EEG bruto', () {
    test('assina o canal uma vez só e redistribui para vários ouvintes',
        () async {
      final fonte = criar();
      final a = <int>[];
      final b = <int>[];
      final s1 = fonte.lotes.listen((l) => a.add(l.seq));
      final s2 = fonte.lotes.listen((l) => b.add(l.seq));
      await s1.cancel();
      final s3 = fonte.lotes.listen((l) => a.add(l.seq));

      brutos.add(lote(1));
      brutos.add(lote(2));
      await Future<void>.delayed(Duration.zero);

      expect(inscricoes, 1);
      expect(cancelamentos, 0);
      expect(a, [1, 2]);
      expect(b, [1, 2]);

      await s2.cancel();
      await s3.cancel();
      // Sem ouvintes a assinatura continua: cancelar desligaria o canal.
      expect(cancelamentos, 0);
      await fonte.dispose();
    });

    test('dispose cancela a assinatura sem desconectar o headset', () async {
      final fonte = criar();
      final s = fonte.lotes.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await fonte.dispose();

      expect(inscricoes, 1);
      expect(cancelamentos, 1);
      expect(chamadas, isNot(contains('disconnect')));
      await s.cancel();
    });
  });

  group('autoConectar', () {
    test('sem BrainLink pareado devolve a lista para escolher', () async {
      pareados = [aparelho('11:11:11:11:11:11', 'Fone')];
      final fonte = criar();

      final resultado = await fonte.autoConectar();

      expect(resultado, isA<AutoEscolher>());
      final lista = (resultado as AutoEscolher).dispositivos;
      expect(lista.single.nome, 'Fone');
      expect(gateway.conexoes, isEmpty);
      await fonte.dispose();
    });

    test('com um BrainLink pareado conecta sozinho', () async {
      pareados = [
        aparelho('11:11:11:11:11:11', 'Fone'),
        aparelho('00:11:22:33:44:55', 'BrainLink_Lite'),
      ];
      final fonte = criar();
      final estados = <EstadoConexao>[];
      final s = fonte.conexao.listen(estados.add);

      final resultado = await fonte.autoConectar();
      await Future<void>.delayed(Duration.zero);

      expect(resultado, isA<AutoConectado>());
      expect(gateway.conexoes.single.id, '00:11:22:33:44:55');
      expect(gateway.conexoes.single.isPaired, isTrue);
      expect(estados, [EstadoConexao.conectando, EstadoConexao.conectado]);
      expect(fonte.estadoConexao, EstadoConexao.conectado);
      expect(chamadas, contains('getPairedDevices'));
      await s.cancel();
      await fonte.dispose();
    });

    test('com um BrainLink que recusa devolve o motivo', () async {
      pareados = [aparelho('00:11:22:33:44:55', 'BrainLink Pro')];
      gateway.erro = StateError('O BrainLink recusou a conexão.');
      final fonte = criar();

      final resultado = await fonte.autoConectar();

      expect(resultado, isA<AutoFalhou>());
      expect(
          (resultado as AutoFalhou).motivo, 'O BrainLink recusou a conexão.');
      expect(fonte.estadoConexao, EstadoConexao.desconectado);
      await fonte.dispose();
    });

    test('com dois BrainLinks pede escolha, BrainLinks primeiro', () async {
      pareados = [
        aparelho('11:11:11:11:11:11', 'Fone'),
        aparelho('00:00:00:00:00:01', 'BrainLink_Lite'),
        aparelho('00:00:00:00:00:02', 'brain-link pro'),
      ];
      final fonte = criar();

      final resultado = await fonte.autoConectar();

      expect(resultado, isA<AutoEscolher>());
      final nomes =
          (resultado as AutoEscolher).dispositivos.map((d) => d.nome).toList();
      expect(nomes, ['BrainLink_Lite', 'brain-link pro', 'Fone']);
      expect(gateway.conexoes, isEmpty);
      await fonte.dispose();
    });

    test('já conectado não procura aparelhos', () async {
      await doAndroid('onConnectionStateChanged', true);
      final fonte = criar();

      expect(fonte.estadoConexao, EstadoConexao.conectado);
      expect(await fonte.autoConectar(), isA<AutoConectado>());
      expect(chamadas, isNot(contains('getPairedDevices')));
      await fonte.dispose();
    });
  });

  group('conexão manual', () {
    test('buscar converte os aparelhos do gateway', () async {
      gateway.aparelhos = const [
        ConnectableDevice('00:11:22:33:44:55', 'BrainLink Lite',
            isPaired: true),
        ConnectableDevice('11:11:11:11:11:11', 'Fone', isPaired: false),
      ];
      final fonte = criar();

      final lista = await fonte.buscar();

      expect(lista.map((d) => (d.id, d.nome, d.pareado)), [
        ('00:11:22:33:44:55', 'BrainLink Lite', true),
        ('11:11:11:11:11:11', 'Fone', false),
      ]);
      await fonte.dispose();
    });

    test('conectar converte falhas em StateError com a mensagem', () async {
      gateway.erro = TimeoutException('sem resposta');
      final fonte = criar();

      await expectLater(
        fonte.conectar(const DispositivoSinal(
            id: '00:11:22:33:44:55', nome: 'BrainLink', pareado: true)),
        throwsA(isA<StateError>()),
      );
      expect(fonte.estadoConexao, EstadoConexao.desconectado);
      await fonte.dispose();
    });

    test('reconectar tenta uma vez com o último aparelho', () async {
      final fonte = criar();
      expect(await fonte.reconectar(), isFalse);
      expect(gateway.conexoes, isEmpty);

      const brainLink = DispositivoSinal(
          id: '00:11:22:33:44:55', nome: 'BrainLink', pareado: true);
      await fonte.conectar(brainLink);
      await doAndroid('onConnectionStateChanged', false);
      expect(fonte.estadoConexao, EstadoConexao.desconectado);

      expect(await fonte.reconectar(), isTrue);
      expect(gateway.conexoes.map((d) => d.id), [brainLink.id, brainLink.id]);

      gateway.erro = StateError('fora de alcance');
      expect(await fonte.reconectar(), isFalse);
      expect(gateway.conexoes, hasLength(3));
      await fonte.dispose();
    });

    test('sem último aparelho, reconectar usa o único BrainLink pareado',
        () async {
      pareados = [aparelho('00:11:22:33:44:55', 'BrainLink_Lite')];
      final fonte = criar();
      expect(await fonte.reconectar(), isTrue);
      expect(gateway.conexoes.map((d) => d.id), ['00:11:22:33:44:55']);
      await fonte.dispose();
    });

    test('desconectar chama o Android e atualiza o estado', () async {
      await doAndroid('onConnectionStateChanged', true);
      final fonte = criar();

      await fonte.desconectar();

      expect(chamadas, contains('disconnect'));
      expect(fonte.estadoConexao, EstadoConexao.desconectado);
      expect(fonte.simulada, isFalse);
      await fonte.dispose();
    });

    test('qualidade repassa o poorSignal do SDK', () async {
      final fonte = criar();
      final valores = <int>[];
      final s = fonte.qualidade.listen(valores.add);

      await doAndroid('onSignalQuality', 200);
      await doAndroid('onSignalQuality', 0);
      await Future<void>.delayed(Duration.zero);

      expect(valores, [200, 0]);
      await s.cancel();
      await fonte.dispose();
    });
  });
}
