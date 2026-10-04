import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/ui/teste/telas/asrs.dart';
import 'package:brainlink_app/ui/teste/telas/contato_perdido.dart';
import 'package:brainlink_app/ui/teste/telas/contexto.dart';
import 'package:brainlink_app/ui/teste/telas/fim_pesquisa.dart';
import 'package:brainlink_app/ui/teste/telas/reconexao.dart';
import 'package:brainlink_app/ui/teste/telas/resultados_demo.dart';
import 'package:brainlink_app/ui/teste/telas/saida_antecipada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/captura.dart';

const _pequena = Size(320, 568);

const _resumoCompleto = ResumoDemonstracao(
  versao: VersaoTeste.auditiva,
  alfaDb: 4,
  motivoAlfaDb: null,
  alfaPorFase: [1, 0.6, 0.94],
  motivoAlfaPorFase: null,
  piscadasDetectadas: 5,
  piscadasTotal: 5,
  acertos: 124,
  comuns: 128,
  toquesRaros: 3,
  raros: 32,
  tempoMedioMs: 412,
  motivoTempoMedio: null,
);

const _resumoSemDados = ResumoDemonstracao(
  versao: VersaoTeste.visual,
  alfaDb: null,
  motivoAlfaDb: 'Sem número: houve pouco sinal limpo no repouso.',
  alfaPorFase: null,
  motivoAlfaPorFase: 'Sem gráfico: a tarefa teve pouco sinal limpo.',
  piscadasDetectadas: 3,
  piscadasTotal: 5,
  acertos: 40,
  comuns: 48,
  toquesRaros: 2,
  raros: 12,
  tempoMedioMs: null,
  motivoTempoMedio: 'Sem toques suficientes para calcular.',
);

const _resumoNegativo = ResumoDemonstracao(
  versao: VersaoTeste.auditiva,
  alfaDb: -2,
  motivoAlfaDb: null,
  alfaPorFase: [0.5, 1, 0],
  motivoAlfaPorFase: null,
  piscadasDetectadas: 5,
  piscadasTotal: 5,
  acertos: 1,
  comuns: 2,
  toquesRaros: 0,
  raros: 1,
  tempoMedioMs: 380,
  motivoTempoMedio: null,
);

/// Fundo preto do design da sobreposição de saída.
Widget _saidaSobrePreto({
  VoidCallback? aoContinuar,
  VoidCallback? aoEncerrar,
}) =>
    ColoredBox(
      color: Colors.black,
      child: SobreposicaoSaida(
        aoContinuar: aoContinuar ?? () {},
        aoEncerrar: aoEncerrar ?? () {},
      ),
    );

void main() {
  group('TelaAsrs', () {
    testWidgets('mostra a pergunta e responde', (tester) async {
      AsrsResponse? escolhida;
      var voltou = 0;
      var proxima = 0;
      await capturarTela(
        tester,
        TelaAsrs(
          indice: 1,
          resposta: AsrsResponse.sometimes,
          aoResponder: (r) => escolhida = r,
          aoVoltar: () => voltou++,
          aoProxima: () => proxima++,
        ),
        'c-asrs-escuro',
      );
      expect(find.text('Questionário · Pergunta 2 de 6'), findsOneWidget);
      expect(find.text(AsrsScreener6.questions[1]), findsOneWidget);
      expect(find.bySemanticsLabel('Pergunta 2 de 6'), findsOneWidget);
      for (final r in AsrsResponse.values) {
        expect(find.text(r.label), findsOneWidget);
      }
      await tester.tap(find.text('Frequentemente'));
      expect(escolhida, AsrsResponse.often);
      await tester.tap(find.text('Voltar'));
      await tester.tap(find.text('Próxima'));
      expect((voltou, proxima), (1, 1));
    });

    testWidgets('claro e botões desabilitados', (tester) async {
      await capturarTela(
        tester,
        TelaAsrs(
          indice: 1,
          resposta: AsrsResponse.sometimes,
          aoResponder: (_) {},
          aoVoltar: () {},
          aoProxima: () {},
        ),
        'c-asrs-claro',
        brilho: Brightness.light,
      );
      await capturarTela(
        tester,
        TelaAsrs(
          indice: 0,
          resposta: null,
          aoResponder: (_) {},
          aoVoltar: null,
          aoProxima: null,
        ),
        'c-asrs-vazia',
      );
      expect(find.text(AsrsScreener6.questions[0]), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await montarTela(
          tester,
          TelaAsrs(
            indice: i,
            resposta: AsrsResponse.veryOften,
            aoResponder: (_) {},
            aoVoltar: () {},
            aoProxima: () {},
          ),
          tamanho: _pequena,
        );
        expect(
            find.text('Questionário · Pergunta ${i + 1} de 6'), findsOneWidget);
      }
    });
  });

  group('TelaContexto', () {
    testWidgets('grupos e callbacks', (tester) async {
      final respostas = RespostasContexto()
        ..sono = HorasSono.de5a7
        ..cafeina = true
        ..medicacao = MedicacaoAtencao.naoToma;
      HorasSono? sono;
      bool? cafeina;
      MedicacaoAtencao? medicacao;
      bool? lente;
      var concluiu = 0;
      Widget tela() => TelaContexto(
            respostas: respostas,
            aoSono: (v) => sono = v,
            aoCafeina: (v) => cafeina = v,
            aoMedicacao: (v) => medicacao = v,
            aoLente: (v) => lente = v,
            aoConcluir: () => concluiu++,
          );
      await capturarTela(tester, tela(), 'c-contexto-escuro',
          tamanho: const Size(390, 1060));
      await capturarTela(tester, tela(), 'c-contexto-claro',
          tamanho: const Size(390, 1060), brilho: Brightness.light);
      expect(find.text('Questionário · Sobre hoje'), findsOneWidget);
      expect(find.text('Algumas perguntas sobre hoje'), findsOneWidget);
      await tester.tap(find.text('> 7'));
      expect(sono, HorasSono.maisDe7);
      await tester.tap(find.text('Não').first);
      expect(cafeina, false);
      await tester.tap(find.text('Prefiro não dizer'));
      expect(medicacao, MedicacaoAtencao.prefiroNaoDizer);
      await tester.tap(find.text('Sim').last);
      expect(lente, true);
      await tester.tap(find.text('Concluir'));
      expect(concluiu, 1);

      await montarTela(tester, tela());
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir'));
      expect(concluiu, 2);

      await montarTela(
        tester,
        TelaContexto(
          respostas: RespostasContexto(),
          aoSono: (_) {},
          aoCafeina: (_) {},
          aoMedicacao: (_) {},
          aoLente: (_) {},
          aoConcluir: null,
        ),
        tamanho: _pequena,
      );
    });
  });

  group('TelaFimPesquisa', () {
    testWidgets('sem o botão de serviços', (tester) async {
      var concluiu = 0;
      await capturarTela(
        tester,
        TelaFimPesquisa(aoConcluir: () => concluiu++),
        'c-fim-escuro',
      );
      await capturarTela(
        tester,
        TelaFimPesquisa(aoConcluir: () => concluiu++),
        'c-fim-claro',
        brilho: Brightness.light,
      );
      expect(find.text('Obrigado!'), findsOneWidget);
      expect(find.textContaining('não é diagnóstico', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('Ver serviços'), findsNothing);
      await tester.tap(find.text('Concluir'));
      expect(concluiu, 1);
      await montarTela(tester, TelaFimPesquisa(aoConcluir: () {}),
          tamanho: _pequena);
    });
  });

  group('TelaResultadosDemo', () {
    testWidgets('completa', (tester) async {
      var nova = 0;
      await capturarTela(
        tester,
        TelaResultadosDemo(
          resumo: _resumoCompleto,
          simulada: false,
          aoNovaDemonstracao: () => nova++,
        ),
        'c-resultados-longa',
        tamanho: const Size(390, 1500),
      );
      await capturarTela(
        tester,
        TelaResultadosDemo(
          resumo: _resumoCompleto,
          simulada: true,
          aoNovaDemonstracao: () => nova++,
        ),
        'c-resultados-escuro',
      );
      expect(find.text('+4 dB'), findsOneWidget);
      expect(find.text('Dados simulados'), findsOneWidget);
      expect(find.text('Demonstração de pesquisa. Não é diagnóstico.'),
          findsOneWidget);
      expect(find.text('Acertos no som grave'), findsOneWidget);
      // O rodapé fica fixo e visível sem rolar.
      final rodape = tester
          .getRect(find.text('Demonstração de pesquisa. Não é diagnóstico.'));
      expect(rodape.bottom, lessThanOrEqualTo(844));
      await tester.scrollUntilVisible(
        find.text('Nova demonstração'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('124 de 128'), findsOneWidget);
      expect(find.text('412 ms'), findsOneWidget);
      await tester.tap(find.text('Nova demonstração'));
      expect(nova, 1);
      expect(
          tester.getRect(
              find.text('Demonstração de pesquisa. Não é diagnóstico.')),
          rodape);
    });

    testWidgets('sem números e alfa negativo', (tester) async {
      await capturarTela(
        tester,
        TelaResultadosDemo(
          resumo: _resumoSemDados,
          simulada: false,
          aoNovaDemonstracao: () {},
        ),
        'c-resultados-sem-dados',
        tamanho: const Size(390, 1300),
        brilho: Brightness.light,
      );
      expect(find.text(_resumoSemDados.motivoAlfaDb!), findsOneWidget);
      expect(find.text(_resumoSemDados.motivoAlfaPorFase!), findsOneWidget);
      expect(find.text(_resumoSemDados.motivoTempoMedio!), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Acertos na figura comum'), findsOneWidget);
      expect(find.text('Toques na figura rara'), findsOneWidget);
      expect(find.textContaining('Ritmo alfa em cada fase'), findsNothing);
      expect(find.textContaining('dB'), findsNothing);

      await capturarTela(
        tester,
        TelaResultadosDemo(
          resumo: _resumoNegativo,
          simulada: false,
          aoNovaDemonstracao: () {},
        ),
        'c-resultados-negativo',
        tamanho: const Size(390, 1500),
      );
      expect(find.text('−2 dB'), findsOneWidget);
      expect(find.text('O ritmo alfa não subiu quando você fechou os olhos.'),
          findsOneWidget);
      expect(TelaResultadosDemo.formatarDb(0), '0 dB');

      await montarTela(
        tester,
        TelaResultadosDemo(
          resumo: _resumoCompleto,
          simulada: true,
          aoNovaDemonstracao: () {},
        ),
        tamanho: _pequena,
      );
    });
  });

  group('TelaContatoPerdido', () {
    testWidgets('sem contato e contato bom', (tester) async {
      var retomou = 0;
      var recomecou = 0;
      await capturarTela(
        tester,
        TelaContatoPerdido(
          faseRotulo: 'Tarefa',
          momento: const Duration(minutes: 1, seconds: 47),
          contatoRecuperado: false,
          simulada: false,
          aoRetomar: null,
          aoRecomecarFase: () => recomecou++,
        ),
        'c-contato-perdido',
      );
      expect(find.text('Sem contato'), findsOneWidget);
      expect(find.text('Procurando o sinal de novo…'), findsOneWidget);
      expect(
          find.text('PESQUISADOR · pausado em Tarefa, 1:47'), findsOneWidget);
      expect(find.text('alerta + vibração longa'), findsOneWidget);
      await tester.tap(find.text('Retomar'));
      expect(retomou, 0);
      await tester.tap(find.text('Recomeçar esta fase'));
      expect(recomecou, 1);

      await capturarTela(
        tester,
        TelaContatoPerdido(
          faseRotulo: 'Tarefa',
          momento: const Duration(minutes: 1, seconds: 47),
          contatoRecuperado: true,
          simulada: true,
          aoRetomar: () => retomou++,
          aoRecomecarFase: () {},
        ),
        'c-contato-recuperado-claro',
        brilho: Brightness.light,
      );
      expect(find.text('Contato bom'), findsOneWidget);
      expect(find.text('Pode retomar o teste.'), findsOneWidget);
      expect(find.text('PESQUISADOR · pausado em Tarefa, 1:47 · simulado'),
          findsOneWidget);
      await tester.tap(find.text('Retomar'));
      expect(retomou, 1);

      await montarTela(
        tester,
        TelaContatoPerdido(
          faseRotulo: 'Repouso final',
          momento: const Duration(minutes: 2, seconds: 5),
          contatoRecuperado: false,
          simulada: true,
          aoRetomar: null,
          aoRecomecarFase: () {},
        ),
        tamanho: _pequena,
      );
    });
  });

  group('TelaReconexao', () {
    testWidgets('lista e botões', (tester) async {
      var tentou = 0;
      var encerrou = 0;
      Widget tela({bool simulada = false}) => TelaReconexao(
            tentativa: 2,
            maxTentativas: 5,
            segundosSemDados: 6,
            gravadoAte: 'Repouso',
            simulada: simulada,
            aoTentarAgora: () => tentou++,
            aoEncerrar: () => encerrou++,
          );
      await capturarTela(tester, tela(), 'c-reconexao');
      expect(find.text('Reconectando ao headset…'), findsOneWidget);
      expect(
          find.text('Procurando o headset (tentativa 2 de 5)'), findsOneWidget);
      expect(
          find.text('PESQUISADOR · último dado há 6 s · gravado até Repouso'),
          findsOneWidget);
      await tester.tap(find.text('Tentar agora'));
      await tester.tap(find.text('Encerrar o teste'));
      expect((tentou, encerrou), (1, 1));
      await capturarTela(tester, tela(simulada: true), 'c-reconexao-claro',
          brilho: Brightness.light);
      expect(
          find.text('PESQUISADOR · último dado há 6 s · gravado até Repouso'
              ' · simulado'),
          findsOneWidget);
      await montarTela(tester, tela(), tamanho: _pequena);
    });
  });

  group('SobreposicaoSaida', () {
    testWidgets('continuar e segurar para encerrar', (tester) async {
      var continuou = 0;
      var encerrou = 0;
      await capturarTela(
        tester,
        _saidaSobrePreto(
          aoContinuar: () => continuou++,
          aoEncerrar: () => encerrou++,
        ),
        'c-saida',
        brilho: Brightness.light,
      );
      expect(find.text('Encerrar o teste?'), findsOneWidget);
      expect(
          find.text('Os dados desta sessão não serão usados.'), findsOneWidget);
      expect(find.text('Também aparece ao apertar “voltar” no celular.'),
          findsOneWidget);
      await tester.tap(find.text('Continuar o teste'));
      expect(continuou, 1);
      final gesto = await tester.startGesture(
          tester.getCenter(find.text('Segure 2 s para encerrar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(encerrou, 0);
      await tester.pump(const Duration(milliseconds: 1100));
      await gesto.up();
      expect(encerrou, 1);
      await montarTela(tester, _saidaSobrePreto(), tamanho: _pequena);
    });
  });
}
