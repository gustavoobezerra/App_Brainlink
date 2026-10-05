import 'package:brainlink_app/native/brainlink_bridge.dart';
import 'package:brainlink_app/services/teste/estimulos.dart';
import 'package:brainlink_app/services/teste/estimulos_nativos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrato entre `EstimulosNativos` e os métodos novos de `MainActivity`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('com.brainlink.app/sdk');
  final mensageiro =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> chamadas;
  late Object? Function(MethodCall) resposta;

  setUp(() {
    chamadas = [];
    resposta = (chamada) => switch (chamada.method) {
          'audioPrepare' => true,
          'audioPlay' => 123456789012,
          'audioRelease' => true,
          'vibrate' => true,
          'setKeepScreenOn' => true,
          'getMediaVolume' => <String, Object?>{'current': 7, 'max': 15},
          'monotonicNowNanos' => 987654321098,
          _ => null,
        };
    mensageiro.setMockMethodCallHandler(canal, (chamada) async {
      chamadas.add(chamada);
      return resposta(chamada);
    });
  });

  tearDown(() => mensageiro.setMockMethodCallHandler(canal, null));

  EstimulosNativos criar() => EstimulosNativos(BrainLinkBridge());

  test('toca cada som pelo nome do enum e devolve o instante nativo', () async {
    final estimulos = criar();
    for (final som in SomTeste.values) {
      expect(await estimulos.tocar(som), 123456789012);
    }
    expect(chamadas.map((c) => c.method), everyElement('audioPlay'));
    expect(
      chamadas.map((c) => (c.arguments as Map)['sound']),
      ['grave', 'agudo', 'sino', 'sinoDuplo', 'bipeCalibracao', 'alerta'],
    );
  });

  test('envia os padrões de vibração combinados', () async {
    final estimulos = criar();
    for (final vibracao in VibracaoTeste.values) {
      await estimulos.vibrar(vibracao);
    }
    final argumentos = [
      for (final c in chamadas)
        [(c.arguments as Map)['timings'], (c.arguments as Map)['amplitudes']],
    ];
    expect(chamadas.map((c) => c.method), everyElement('vibrate'));
    expect(argumentos, [
      [
        [0, 60],
        [0, 180],
      ],
      [
        [0, 60, 120, 60],
        [0, 180, 0, 180],
      ],
      [
        [0, 600],
        [0, 200],
      ],
      [
        [0, 40],
        [0, 255],
      ],
      [
        [0, 40],
        [0, 60],
      ],
    ]);
  });

  test('preparar é idempotente depois do sucesso', () async {
    final estimulos = criar();
    await Future.wait([estimulos.preparar(), estimulos.preparar()]);
    await estimulos.preparar();
    expect(chamadas.where((c) => c.method == 'audioPrepare'), hasLength(1));
  });

  test('preparar tenta de novo se a primeira vez falhou', () async {
    final estimulos = criar();
    resposta = (_) => false;
    await estimulos.preparar();
    resposta = (_) => true;
    await estimulos.preparar();
    await estimulos.preparar();
    expect(chamadas.where((c) => c.method == 'audioPrepare'), hasLength(2));
  });

  test('tela acesa, volume, relógio e liberação', () async {
    final estimulos = criar();
    await estimulos.manterTelaAcesa(true);
    await estimulos.manterTelaAcesa(false);
    final volume = await estimulos.volumeMidia();
    final agora = await estimulos.agoraNanos();
    await estimulos.liberar();

    expect(chamadas.map((c) => c.method), [
      'setKeepScreenOn',
      'setKeepScreenOn',
      'getMediaVolume',
      'monotonicNowNanos',
      'audioRelease',
    ]);
    expect((chamadas[0].arguments as Map)['on'], isTrue);
    expect((chamadas[1].arguments as Map)['on'], isFalse);
    expect(volume?.atual, 7);
    expect(volume?.maximo, 15);
    expect(agora, 987654321098);
  });

  test('nunca lança quando o Android falha ou não implementa', () async {
    mensageiro.setMockMethodCallHandler(canal, (chamada) async {
      throw PlatformException(code: 'FALHA', message: 'sem áudio');
    });
    final estimulos = criar();
    await estimulos.preparar();
    expect(await estimulos.tocar(SomTeste.sino), isNull);
    await estimulos.vibrar(VibracaoTeste.longa);
    await estimulos.manterTelaAcesa(true);
    expect(await estimulos.volumeMidia(), isNull);
    expect(await estimulos.agoraNanos(), isNull);
    await estimulos.liberar();

    mensageiro.setMockMethodCallHandler(canal, null);
    expect(await estimulos.tocar(SomTeste.grave), isNull);
    expect(await estimulos.volumeMidia(), isNull);
  });
}
