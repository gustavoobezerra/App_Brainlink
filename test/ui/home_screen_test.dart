import 'package:brainlink_app/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mantém um único fluxo sem abas, diário ou questionário',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Ver demonstração'), findsOneWidget);
    expect(find.text('Conectar BrainLink'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Diário'), findsNothing);
    expect(find.text('ASRS'), findsNothing);
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

  testWidgets('guia as fases e apresenta velocímetro com resultado',
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
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Agora feche os olhos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Resultado da coleta'), findsOneWidget);
    expect(find.text('Coleta boa'), findsOneWidget);
    expect(find.text('de 100'), findsOneWidget);
    expect(find.text('Exportar resultado'), findsOneWidget);
    expect(
      find.textContaining('nota do velocímetro é da coleta'),
      findsOneWidget,
    );
  });
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
