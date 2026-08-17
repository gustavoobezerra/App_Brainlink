import 'package:brainlink_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('oferece os modos e identifica o público adulto', (tester) async {
    await tester.pumpWidget(const BrainLinkApp());

    expect(find.text('Demonstração'), findsOneWidget);
    expect(find.text('Hardware'), findsOneWidget);
    expect(find.textContaining('adultos (18+)'), findsWidgets);
  });

  testWidgets('exemplo do screener mostra a orientação de atenção',
      (tester) async {
    await tester.pumpWidget(const BrainLinkApp());
    await tester.tap(find.text('ASRS'));
    await tester.pumpAndSettle();

    final exampleButton = find.text('Usar exemplo');
    await tester.scrollUntilVisible(
      exampleButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(exampleButton);
    await tester.pumpAndSettle();

    expect(find.text('5/6 respostas de rastreio'), findsOneWidget);
    expect(
      find.text(
        'Sua pontuação merece atenção. Converse com um profissional de saúde.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sessão simulada alimenta gráfico e prévia do relatório',
      (tester) async {
    await tester.pumpWidget(const BrainLinkApp());
    await tester.tap(find.text('Sessão'));
    await tester.pumpAndSettle();

    final startButton = find.text('Iniciar sessão');
    await tester.scrollUntilVisible(
      startButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startButton);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Finalizar e registrar'), findsOneWidget);
    expect(find.text('Sem dados nesta sessão'), findsNothing);

    await tester.tap(find.text('Finalizar e registrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relatório'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 sessão'), findsOneWidget);
    expect(find.text('Exportar relatório HTML'), findsOneWidget);
    expect(find.textContaining('RELATÓRIO DE OBSERVAÇÃO BRAINLINK'),
        findsOneWidget);
  });
}
