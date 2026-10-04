import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/ui/teste/telas/controle_ritmo.dart';
import 'package:brainlink_app/ui/teste/telas/instrucoes_tarefa.dart';
import 'package:brainlink_app/ui/teste/telas/repouso_fim.dart';
import 'package:brainlink_app/ui/teste/telas/repouso_inicio.dart';
import 'package:brainlink_app/ui/teste/telas/repouso_olhos_fechados.dart';
import 'package:brainlink_app/ui/teste/telas/tarefa.dart';
import 'package:brainlink_app/ui/teste/telas/treino.dart';
import 'package:brainlink_app/ui/teste/widgets/botao_segurar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/captura.dart';

const _pequena = Size(320, 568);

Widget _treino({
  VersaoTeste versao = VersaoTeste.auditiva,
  int indice = 4,
  FeedbackTreino? feedback,
  EstimuloVisual estimulo = EstimuloVisual.nenhum,
  bool concluido = false,
  ValueChanged<PointerDownEvent>? aoTocar,
  VoidCallback? aoComecarTeste,
}) =>
    TelaTreino(
      versao: versao,
      indice: indice,
      total: 10,
      feedback: feedback,
      estimuloVisual: estimulo,
      concluido: concluido,
      aoTocar: aoTocar ?? (_) {},
      aoComecarTeste: aoComecarTeste ?? () {},
    );

Widget _tarefa({
  VersaoTeste versao = VersaoTeste.auditiva,
  bool ritmo = false,
  EstimuloVisual estimulo = EstimuloVisual.fixacao,
  bool simulada = false,
  ValueChanged<PointerDownEvent>? aoTocar,
  VoidCallback? aoSegurar,
}) =>
    TelaTarefa(
      versao: versao,
      ritmo: ritmo,
      restante: const Duration(minutes: 2, seconds: 13),
      qualidade: QualidadeSinal.boa,
      toques: versao == VersaoTeste.auditiva ? 41 : 63,
      estimuloVisual: estimulo,
      simulada: simulada,
      aoTocar: aoTocar ?? (_) {},
      aoSegurarEncerrar: aoSegurar ?? () {},
    );

Future<void> _pequenaSemEstouro(WidgetTester tester, Widget tela) async {
  await montarTela(tester, tela, tamanho: _pequena);
  expect(tester.takeException(), isNull);
}

void main() {
  group('Repouso', () {
    testWidgets('início (etapa 3)', (tester) async {
      var comecou = 0;
      var encerrou = 0;
      final tela = TelaRepousoInicio(
        repousoFinal: false,
        aoComecar: () => comecou++,
        aoSegurarEncerrar: () => encerrou++,
      );
      await capturarTela(tester, tela, 'Repouso-inicio');
      expect(find.text('Repouso'), findsOneWidget);
      expect(
        find.text(
          'Agora feche os olhos e fique relaxado até ouvir dois bipes.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Duração: 1 minuto. Você não precisa fazer nada.'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 3 de 7'), findsOneWidget);
      await tester.tap(find.text('Começar repouso'));
      expect(comecou, 1);
      final gesto = await tester
          .startGesture(tester.getCenter(find.byType(BotaoSegurar)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesto.up();
      expect(encerrou, 1);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('início claro', (tester) async {
      await capturarTela(
        tester,
        TelaRepousoInicio(
          repousoFinal: false,
          aoComecar: () {},
          aoSegurarEncerrar: () {},
        ),
        'Repouso-inicio-claro',
        brilho: Brightness.light,
      );
    });

    testWidgets('final (etapa 6)', (tester) async {
      var comecou = 0;
      final tela = TelaRepousoInicio(
        repousoFinal: true,
        aoComecar: () => comecou++,
        aoSegurarEncerrar: () {},
      );
      await capturarTela(tester, tela, 'Repouso-final');
      expect(find.text('Repouso final'), findsOneWidget);
      expect(
        find.text('Último repouso. Feche os olhos até ouvir dois bipes.',
            findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Duração: 40 segundos.'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 7'), findsOneWidget);
      await tester.tap(find.text('Começar repouso'));
      expect(comecou, 1);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('olhos fechados', (tester) async {
      var encerrou = 0;
      final tela = TelaRepousoOlhosFechados(
        restante: const Duration(seconds: 42),
        qualidade: QualidadeSinal.boa,
        simulada: false,
        aoSegurarEncerrar: () => encerrou++,
      );
      // Com sombras reais, para a captura mostrar o brilho do ponto.
      debugDisableShadows = false;
      await capturarTela(tester, tela, 'Repouso-olhos-fechados');
      debugDisableShadows = true;
      expect(find.text('0:42'), findsOneWidget);
      expect(find.text('SIMULADO'), findsNothing);
      final gesto = await tester
          .startGesture(tester.getCenter(find.byType(BotaoSegurar)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesto.up();
      expect(encerrou, 1);
      expect(tester.hasRunningAnimations, isFalse);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('olhos fechados simulado', (tester) async {
      await capturarTela(
        tester,
        TelaRepousoOlhosFechados(
          restante: const Duration(seconds: 42),
          qualidade: QualidadeSinal.ajuste,
          simulada: true,
          aoSegurarEncerrar: () {},
        ),
        'Repouso-olhos-fechados-simulado',
      );
      expect(find.text('SIMULADO'), findsOneWidget);
    });

    testWidgets('fim', (tester) async {
      var continuou = 0;
      final tela = TelaRepousoFim(aoContinuar: () => continuou++);
      await capturarTela(tester, tela, 'Repouso-fim', brilho: Brightness.light);
      expect(find.text('Pode abrir os olhos.'), findsOneWidget);
      expect(find.text('Respire normalmente. Sem pressa.'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      expect(continuou, 1);
      await _pequenaSemEstouro(tester, tela);
    });
  });

  group('Instruções da tarefa', () {
    testWidgets('auditiva', (tester) async {
      final exemplos = <TipoEstimulo>[];
      var treino = 0;
      final tela = TelaInstrucoesTarefa(
        versao: VersaoTeste.auditiva,
        aoOuvirExemplo: exemplos.add,
        aoFazerTreino: () => treino++,
      );
      await capturarTela(tester, tela, 'Treino-auditivo');
      expect(find.text('Instruções da tarefa'), findsOneWidget);
      expect(
        find.text('Você vai ouvir dois sons: um grave e um agudo.',
            findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Toque na tela'), findsOneWidget);
      expect(find.text('NÃO'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Regra da tarefa')), findsOneWidget);
      await tester.tap(find.text('Som grave').first);
      await tester.tap(find.text('Som agudo').first);
      expect(exemplos, [TipoEstimulo.comum, TipoEstimulo.raro]);
      await tester.tap(find.text('Fazer o treino (10 sons)'));
      expect(treino, 1);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('auditiva clara', (tester) async {
      await capturarTela(
        tester,
        TelaInstrucoesTarefa(
          versao: VersaoTeste.auditiva,
          aoOuvirExemplo: (_) {},
          aoFazerTreino: () {},
        ),
        'Treino-auditivo-claro',
        brilho: Brightness.light,
      );
    });

    testWidgets('visual', (tester) async {
      var treino = 0;
      final tela = TelaInstrucoesTarefa(
        versao: VersaoTeste.visual,
        aoOuvirExemplo: (_) {},
        aoFazerTreino: () => treino++,
      );
      await capturarTela(tester, tela, 'Treino-visual');
      expect(
        find.text('Vão aparecer figuras no centro da tela, uma de cada vez.'),
        findsOneWidget,
      );
      expect(find.text('Figura comum'), findsOneWidget);
      expect(find.text('Figura rara'), findsOneWidget);
      expect(find.text('Toque'), findsOneWidget);
      expect(
        find.text('Olhe sempre para o centro da tela.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Som grave'), findsNothing);
      await tester.tap(find.text('Fazer o treino (10 figuras)'));
      expect(treino, 1);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('visual clara', (tester) async {
      await capturarTela(
        tester,
        TelaInstrucoesTarefa(
          versao: VersaoTeste.visual,
          aoOuvirExemplo: (_) {},
          aoFazerTreino: () {},
        ),
        'Treino-visual-claro',
        brilho: Brightness.light,
      );
    });
  });

  group('Treino', () {
    testWidgets('certo (auditiva)', (tester) async {
      final toques = <PointerDownEvent>[];
      final tela = _treino(feedback: FeedbackTreino.certo, aoTocar: toques.add);
      await capturarTela(tester, tela, 'Treino-auditivo-feedback-certo');
      expect(find.text('Treino'), findsOneWidget);
      expect(find.text('Som 4 de 10'), findsOneWidget);
      expect(find.text('Certo'), findsOneWidget);
      expect(find.text('1 vibração curta e firme'), findsOneWidget);
      expect(find.text('Toque em qualquer lugar'), findsOneWidget);
      // Cantos e centro da área tracejada.
      await tester.tapAt(const Offset(30, 100));
      await tester.tapAt(const Offset(360, 810));
      await tester.tapAt(const Offset(195, 450));
      expect(toques, hasLength(3));
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('não tocar (auditiva)', (tester) async {
      final tela = _treino(indice: 5, feedback: FeedbackTreino.naoTocar);
      await capturarTela(tester, tela, 'Treino-auditivo-feedback-naoTocar');
      expect(find.text('Som 5 de 10'), findsOneWidget);
      expect(find.text('Era para não tocar'), findsOneWidget);
      expect(find.text('Esse foi o som agudo.'), findsOneWidget);
      expect(find.text('1 vibração curta e fraca'), findsOneWidget);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('não tocou (auditiva e visual)', (tester) async {
      await capturarTela(
        tester,
        _treino(indice: 6, feedback: FeedbackTreino.naoTocou),
        'Treino-auditivo-feedback-naoTocou',
      );
      expect(find.text('Era para tocar'), findsOneWidget);
      expect(find.text('Esse foi o som grave.'), findsOneWidget);
      expect(find.text('1 vibração curta e fraca'), findsOneWidget);
      await capturarTela(
        tester,
        _treino(
          versao: VersaoTeste.visual,
          indice: 6,
          feedback: FeedbackTreino.naoTocou,
        ),
        'Treino-visual-feedback-naoTocou',
      );
      expect(find.text('Figura 6 de 10'), findsOneWidget);
      expect(find.text('Essa foi a figura comum.'), findsOneWidget);
    });

    testWidgets('visual: não tocar e certo', (tester) async {
      await capturarTela(
        tester,
        _treino(versao: VersaoTeste.visual, feedback: FeedbackTreino.naoTocar),
        'Treino-visual-feedback-naoTocar',
      );
      expect(find.text('Essa foi a figura rara.'), findsOneWidget);
      await capturarTela(
        tester,
        _treino(versao: VersaoTeste.visual, feedback: FeedbackTreino.certo),
        'Treino-visual-feedback-certo',
      );
      expect(find.text('Certo'), findsOneWidget);
    });

    testWidgets('sem feedback (auditiva)', (tester) async {
      final tela = _treino(indice: 1);
      await capturarTela(tester, tela, 'Treino-auditivo-espera');
      expect(find.text('Som 1 de 10'), findsOneWidget);
      expect(find.text('Toque em qualquer lugar'), findsOneWidget);
      expect(find.text('Certo'), findsNothing);
      await _pequenaSemEstouro(tester, tela);
    });

    for (final estimulo in EstimuloVisual.values) {
      testWidgets('sem feedback (visual, ${estimulo.name})', (tester) async {
        final toques = <PointerDownEvent>[];
        final tela = _treino(
          versao: VersaoTeste.visual,
          indice: 2,
          estimulo: estimulo,
          aoTocar: toques.add,
        );
        await capturarTela(tester, tela, 'Treino-visual-${estimulo.name}');
        expect(find.text('Figura 2 de 10'), findsOneWidget);
        // A dica visível (a outra cópia, invisível, centraliza a figura).
        expect(find.text('Toque em qualquer lugar'), findsNWidgets(2));
        await tester.tapAt(const Offset(195, 450));
        await tester.tapAt(const Offset(40, 800));
        expect(toques, hasLength(2));
        await _pequenaSemEstouro(tester, tela);
      });
    }

    for (final versao in VersaoTeste.values) {
      testWidgets('concluído (${versao.name})', (tester) async {
        var comecou = 0;
        final toques = <PointerDownEvent>[];
        final tela = _treino(
          versao: versao,
          indice: 10,
          concluido: true,
          aoTocar: toques.add,
          aoComecarTeste: () => comecou++,
        );
        await capturarTela(
          tester,
          tela,
          'Treino-${versao.name}-feedback-fim',
        );
        expect(find.text('10 de 10'), findsOneWidget);
        expect(find.text('Treino concluído'), findsOneWidget);
        expect(
          find.text(
            'No teste não vai aparecer “certo” nem “errado”. Tudo bem não '
            'saber como foi.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            versao == VersaoTeste.auditiva
                ? 'Ao ouvir um bipe, feche os olhos. O teste dura 3 minutos.'
                : 'Ao ouvir um bipe, olhe para o centro da tela. O teste dura '
                    '3 minutos.',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.text('Toque em qualquer lugar'), findsNothing);
        await tester.tap(find.text('Começar o teste'));
        expect(comecou, 1);
        expect(toques, isEmpty);
        await _pequenaSemEstouro(tester, tela);
      });
    }
  });

  group('Tarefa', () {
    testWidgets('auditiva: tela inteira responde, botão incluso',
        (tester) async {
      final toques = <PointerDownEvent>[];
      var encerrou = 0;
      final tela = _tarefa(aoTocar: toques.add, aoSegurar: () => encerrou++);
      await capturarTela(tester, tela, 'Tarefa-auditiva');
      expect(find.text('OLHOS FECHADOS · TOQUE NO SOM GRAVE'), findsOneWidget);
      expect(find.text('2:13'), findsOneWidget);
      expect(find.text('41 toques'), findsOneWidget);
      expect(find.text('SIMULADO'), findsNothing);
      expect(
        find.bySemanticsLabel(
            'Área de resposta: toque em qualquer lugar da tela'),
        findsOneWidget,
      );
      for (final ponto in const [
        Offset(1, 1),
        Offset(389, 1),
        Offset(195, 422),
        Offset(1, 843),
        Offset(30, 810), // canto do pesquisador
      ]) {
        await tester.tapAt(ponto);
      }
      expect(toques, hasLength(5));
      // Segurar o botão também conta como toque e encerra após 2 s.
      final gesto = await tester
          .startGesture(tester.getCenter(find.byType(BotaoSegurar)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesto.up();
      expect(toques, hasLength(6));
      expect(encerrou, 1);
      expect(tester.hasRunningAnimations, isFalse);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('auditiva: ritmo e simulada', (tester) async {
      await capturarTela(
        tester,
        _tarefa(ritmo: true, simulada: true),
        'Tarefa-auditiva-ritmo',
      );
      expect(
        find.text('OLHOS FECHADOS · TOQUE EM TODOS OS SONS'),
        findsOneWidget,
      );
      expect(find.text('SIMULADO'), findsOneWidget);
    });

    for (final (estimulo, nome) in const [
      (EstimuloVisual.fixacao, 'Tarefa-visual-fixacao'),
      (EstimuloVisual.comum, 'Tarefa-visual-comum'),
      (EstimuloVisual.raro, 'Tarefa-visual-rara'),
      (EstimuloVisual.nenhum, 'Tarefa-visual-nenhum'),
    ]) {
      testWidgets('visual ${estimulo.name}', (tester) async {
        final toques = <PointerDownEvent>[];
        final tela = _tarefa(
          versao: VersaoTeste.visual,
          estimulo: estimulo,
          aoTocar: toques.add,
        );
        await capturarTela(tester, tela, nome);
        expect(find.textContaining('OLHOS FECHADOS'), findsNothing);
        expect(find.text('63 toques'), findsOneWidget);
        await tester.tapAt(const Offset(195, 422));
        await tester.tapAt(const Offset(5, 5));
        await tester.tapAt(tester.getCenter(find.byType(BotaoSegurar)));
        expect(toques, hasLength(3));
        await _pequenaSemEstouro(tester, tela);
      });
    }

    testWidgets('visual simulada', (tester) async {
      await capturarTela(
        tester,
        _tarefa(versao: VersaoTeste.visual, simulada: true),
        'Tarefa-visual-simulada',
      );
      expect(find.text('SIMULADO'), findsOneWidget);
    });
  });

  group('Controle de ritmo', () {
    testWidgets('auditiva', (tester) async {
      var comecou = 0;
      final tela = TelaControleRitmo(
        versao: VersaoTeste.auditiva,
        aoComecar: () => comecou++,
      );
      await capturarTela(tester, tela, 'Controle-ritmo');
      expect(find.text('Tarefa · parte 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 5 de 7'), findsOneWidget);
      expect(find.text('todos'), findsOneWidget);
      expect(
        find.text(
          'Todos os sons serão iguais. Toque uma vez a cada som, de olhos '
          'fechados.',
        ),
        findsOneWidget,
      );
      expect(find.text('Duração: 1 minuto.'), findsOneWidget);
      expect(
        find.text('Na versão visual: “Agora toque em todas as figuras.”',
            findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Começar'));
      expect(comecou, 1);
      await _pequenaSemEstouro(tester, tela);
    });

    testWidgets('visual e claro', (tester) async {
      var comecou = 0;
      final tela = TelaControleRitmo(
        versao: VersaoTeste.visual,
        aoComecar: () => comecou++,
      );
      await capturarTela(tester, tela, 'Controle-ritmo-visual-claro',
          brilho: Brightness.light);
      expect(find.text('todas'), findsOneWidget);
      expect(
        find.text(
            'Todas as figuras serão iguais. Toque uma vez a cada figura.'),
        findsOneWidget,
      );
      expect(
        find.text('Na versão visual: “Agora toque em todas as figuras.”',
            findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Começar'));
      expect(comecou, 1);
      await _pequenaSemEstouro(tester, tela);
    });
  });
}
