import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:brainlink_app/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mantém um único fluxo inicial sem abas ou diário',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Ver demonstração'), findsOneWidget);
    expect(find.text('Conectar BrainLink'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Diário'), findsNothing);
    expect(find.textContaining('ASRS'), findsNothing);
    expect(find.textContaining('não avalia saúde'), findsNothing);
  });

  testWidgets('mostra instruções antes de iniciar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Ver demonstração'));
    await tester.pumpAndSettle();

    expect(find.text('Antes de começar'), findsOneWidget);
    expect(find.text('Olhos abertos por 8 segundos'), findsOneWidget);
    expect(find.text('Olhos fechados por 8 segundos'), findsOneWidget);
    expect(find.text('Começar demonstração'), findsOneWidget);
  });

  testWidgets('conecta dispositivo e mostra o protocolo real de dois minutos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(deviceGateway: _FakeGateway())),
    );

    await tester.tap(find.text('Conectar BrainLink'));
    await tester.pumpAndSettle();
    expect(find.text('BrainLink de teste'), findsOneWidget);

    final connectButton = find.text('Conectar');
    await tester.scrollUntilVisible(
      connectButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(find.text('Olhos abertos por 1 minuto'), findsOneWidget);
    expect(find.text('Olhos fechados por 1 minuto'), findsOneWidget);
    expect(find.text('Começar teste de 2 minutos'), findsOneWidget);
  });

  testWidgets('oferece o diagnóstico de conexão no painel do hardware',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(deviceGateway: _FakeGateway())),
    );

    await tester.tap(find.text('Conectar BrainLink'));
    await tester.pumpAndSettle();

    // Quem testa em campo precisa alcançar o relatório sem instrução extra.
    final botao = find.text('Compartilhar diagnóstico');
    await tester.scrollUntilVisible(
      botao,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(botao, findsOneWidget);
  });

  testWidgets('guia as fases e apresenta indicador visual com resultado',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          demonstrationPhaseDuration: Duration(seconds: 1),
        ),
      ),
    );
    await tester.tap(find.text('Ver demonstração'));
    await tester.pumpAndSettle();
    final startButton = find.text('Começar demonstração');
    await tester.scrollUntilVisible(
      startButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startButton);
    await tester.pump();

    expect(find.text('Mantenha os olhos abertos'), findsOneWidget);
    expect(find.text('EEG bruto ao vivo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Agora feche os olhos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Resultado da coleta'), findsOneWidget);
    expect(find.text('Coleta boa'), findsOneWidget);
    expect(find.text('de 100'), findsOneWidget);
    expect(
      find.text(
          'Indicador visual de contato e continuidade do sinal recebido.'),
      findsOneWidget,
    );
    expect(find.text('Exportar resultado da coleta'), findsOneWidget);
    expect(find.text('Responder 6 perguntas'), findsOneWidget);
    expect(
      find.textContaining('Para completar a demonstração'),
      findsOneWidget,
    );
    expect(find.text('Ondas observadas nesta coleta'), findsOneWidget);
    expect(find.text('NÃO ENTRA NO RASTREIO DE TDAH'), findsNothing);
    expect(
      find.text('PADRÃO HISTÓRICO PESQUISADO NO TDAH'),
      findsOneWidget,
    );
    expect(
      find.text('THETA MAIOR QUE BETA NAS DUAS ETAPAS'),
      findsOneWidget,
    );
    expect(find.text('Delta'), findsOneWidget);
    expect(find.text('Alfa'), findsOneWidget);
  });

  testWidgets('registra ASRS com EEG sem misturar os cálculos e calcula 0 a 24',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          demonstrationPhaseDuration: Duration(seconds: 1),
        ),
      ),
    );
    await _reachDemonstrationResult(tester);

    final screeningButton = find.text('Responder 6 perguntas');
    await tester.scrollUntilVisible(
      screeningButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(screeningButton);
    await tester.pumpAndSettle();

    expect(find.text('Seis perguntas para adultos'), findsOneWidget);
    expect(
      find.textContaining(
          'respostas e o resumo do EEG ficam registrados juntos'),
      findsOneWidget,
    );
    expect(
      find.textContaining('pontuação ASRS usa somente as respostas'),
      findsOneWidget,
    );
    expect(find.text(AsrsScreener6.questions.first), findsOneWidget);

    for (var index = 0; index < AsrsScreener6.itemCount; index++) {
      final field = find.byKey(ValueKey('asrs_answer_$index'));
      await tester.scrollUntilVisible(
        field,
        450,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AsrsResponse.often.label).last);
      await tester.pumpAndSettle();
    }

    final finishButton = find.text('Concluir e ver os dois resultados');
    await tester.scrollUntilVisible(
      finishButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(find.text('Coleta boa'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('de 24'), findsOneWidget);
    expect(find.text('Faixa superior de rastreio'), findsOneWidget);
    expect(find.text('Possibilidade aumentada no ASRS'), findsOneWidget);
    expect(
      find.text('POSSIBILIDADE DE TDAH · RASTREIO ASRS V1.1'),
      findsOneWidget,
    );
    expect(find.text('NÃO É DIAGNÓSTICO'), findsWidgets);
    expect(
        find.textContaining('possibilidade aumentada de TDAH'), findsOneWidget);
    expect(find.textContaining('não é diagnóstico'), findsWidgets);
    expect(find.text('RESUMO PARA LEVAR AO MÉDICO'), findsOneWidget);
    expect(find.text('18/24 · corte 14 atingido'), findsOneWidget);
    expect(
      find.textContaining('rastreio justifica procurar um médico'),
      findsOneWidget,
    );
    expect(find.text('Exportar os dois resultados'), findsOneWidget);
  });

  testWidgets('abaixo do corte não afirma ausência de TDAH', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          demonstrationPhaseDuration: Duration(seconds: 1),
        ),
      ),
    );
    await _reachDemonstrationResult(tester);

    final screeningButton = find.text('Responder 6 perguntas');
    await tester.scrollUntilVisible(
      screeningButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(screeningButton);
    await tester.pumpAndSettle();

    for (var index = 0; index < AsrsScreener6.itemCount; index++) {
      final field = find.byKey(ValueKey('asrs_answer_$index'));
      await tester.scrollUntilVisible(
        field,
        450,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AsrsResponse.never.label).last);
      await tester.pumpAndSettle();
    }

    final finishButton = find.text('Concluir e ver os dois resultados');
    await tester.scrollUntilVisible(
      finishButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(find.text('Ponto de corte não atingido'), findsOneWidget);
    expect(find.textContaining('Isso não exclui TDAH'), findsOneWidget);
    expect(find.text('NÃO É DIAGNÓSTICO'), findsWidgets);
    expect(find.text('0/24 · corte 14 não atingido'), findsOneWidget);
    expect(
        find.textContaining('possibilidade aumentada de TDAH'), findsNothing);
  });

  testWidgets(
      'consome EEG bruto do hardware e libera bandas com trechos limpos',
      (tester) async {
    final rawController = StreamController<RawBatch>();
    addTearDown(rawController.close);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          deviceGateway: _FakeGateway(),
          rawDataStream: rawController.stream,
          hardwarePhaseDuration: const Duration(seconds: 1),
        ),
      ),
    );

    await tester.tap(find.text('Conectar BrainLink'));
    await tester.pumpAndSettle();
    final connectButton = find.text('Conectar');
    await tester.scrollUntilVisible(
      connectButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    final startButton = find.text('Começar teste de 2 minutos');
    await tester.scrollUntilVisible(
      startButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startButton);
    await tester.pump();

    for (var sequence = 0; sequence < 11; sequence++) {
      rawController.add(
        _sineBatch(sequence, frequency: 10, amplitudeMicrovolts: 5),
      );
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Agora feche os olhos'), findsOneWidget);

    for (var sequence = 11; sequence < 22; sequence++) {
      rawController.add(_sineBatch(sequence, frequency: 10));
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final waves = find.text('Ondas observadas nesta coleta');
    await tester.scrollUntilVisible(
      waves,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(waves, findsOneWidget);
    expect(find.text('Bandas não exibidas'), findsNothing);
    expect(find.textContaining('trechos foram aproveitados'), findsOneWidget);
    expect(find.textContaining('alfa aumentou'), findsOneWidget);
    expect(
      find.textContaining('Para completar o resultado do BrainLink'),
      findsOneWidget,
    );
  });
}

Future<void> _reachDemonstrationResult(WidgetTester tester) async {
  await tester.tap(find.text('Ver demonstração'));
  await tester.pumpAndSettle();
  final startButton = find.text('Começar demonstração');
  await tester.scrollUntilVisible(
    startButton,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(startButton);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

class _FakeGateway implements DeviceDiscoveryGateway {
  @override
  Future<List<ConnectableDevice>> listDevices() async => const [
        ConnectableDevice('00:11:22:33:44:55', 'BrainLink de teste',
            isPaired: true),
      ];

  @override
  Future<void> connect(ConnectableDevice device) async {}
}

RawBatch _sineBatch(
  int sequence, {
  required double frequency,
  double amplitudeMicrovolts = 20,
}) {
  final samples = Int32List(RawBatch.sampleRateHz);
  for (var index = 0; index < samples.length; index++) {
    final absoluteIndex = sequence * samples.length + index;
    final microvolts = amplitudeMicrovolts *
        math.sin(
          2 * math.pi * frequency * absoluteIndex / RawBatch.sampleRateHz,
        );
    samples[index] = (microvolts / RawBatch.microvoltsPerUnit).round();
  }
  return RawBatch(
    seq: sequence,
    t0: DateTime.fromMillisecondsSinceEpoch(sequence * 1000),
    poorSignal: 0,
    dropped: 0,
    samples: samples,
  );
}
