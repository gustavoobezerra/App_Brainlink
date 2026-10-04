import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/services/teste/estimulos.dart';
import 'package:brainlink_app/services/teste/fonte_sinal.dart';
import 'package:brainlink_app/ui/teste/telas/calibracao.dart';
import 'package:brainlink_app/ui/teste/telas/calibracao_erro.dart';
import 'package:brainlink_app/ui/teste/telas/calibracao_resultado.dart';
import 'package:brainlink_app/ui/teste/telas/folha_dispositivos.dart';
import 'package:brainlink_app/ui/teste/telas/inicio.dart';
import 'package:brainlink_app/ui/teste/telas/instrucoes.dart';
import 'package:brainlink_app/ui/teste/telas/sensor.dart';
import 'package:brainlink_app/ui/teste/telas/volume_baixo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/captura.dart';

const _pequena = Size(320, 568);

final _tracadoBom = [
  for (var i = 0; i < 300; i++) (i % 7 - 3) * 4.0,
];

/// Registra as chamadas dos callbacks.
class _Registro {
  final chamadas = <String>[];
  VoidCallback cb(String nome) => () => chamadas.add(nome);
}

Widget _inicio(
  _Registro r, {
  VersaoTeste versao = VersaoTeste.auditiva,
  bool demo = false,
  TextEditingController? controller,
}) =>
    TelaInicio(
      versao: versao,
      demonstracao: demo,
      codigoController: controller ?? TextEditingController(),
      aoEscolherVersao: (v) => r.chamadas.add('versao:${v.name}'),
      aoAlternarDemonstracao: r.cb('demo'),
      aoComecar: r.cb('comecar'),
      aoAbrirColetaAnterior: r.cb('anterior'),
    );

Widget _sensor(
  _Registro r,
  EstadoContato estado, {
  int segundos = 0,
  bool simulada = false,
  bool habilitado = false,
}) =>
    TelaSensor(
      estado: estado,
      segundosEstaveis: segundos,
      tracado: estado == EstadoContato.procurando ? null : _tracadoBom,
      simulada: simulada,
      aoContinuar: habilitado ? r.cb('continuar') : null,
      aoAbrirDispositivos: r.cb('dispositivos'),
    );

Widget _folha(
  _Registro r, {
  List<DispositivoSinal> dispositivos = const [],
  bool buscando = false,
  String? erro,
  String? conectandoId,
}) =>
    Stack(
      children: [
        _sensor(r, EstadoContato.procurando),
        FolhaDispositivos(
          dispositivos: dispositivos,
          buscando: buscando,
          erro: erro,
          conectandoId: conectandoId,
          aoEscolher: (d) => r.chamadas.add('escolher:${d.id}'),
          aoProcurarDeNovo: r.cb('procurar'),
          aoUsarSimulados: (c) => r.chamadas.add('simulados:${c.name}'),
          aoFechar: r.cb('fechar'),
        ),
      ],
    );

Widget _calibracao(
  _Registro r, {
  int bipes = 3,
  QualidadeSinal qualidade = QualidadeSinal.boa,
  bool simulada = false,
}) =>
    TelaCalibracao(
      bipesTocados: bipes,
      totalBipes: 5,
      piscadasDetectadas: 3,
      qualidade: qualidade,
      simulada: simulada,
      aoSegurarEncerrar: r.cb('encerrar'),
    );

const _aparelhos = [
  DispositivoSinal(id: 'AA:01', nome: 'BrainLink_Pro', pareado: true),
  DispositivoSinal(id: 'AA:02', nome: 'BrainLink_Lite', pareado: false),
];

void main() {
  group('TelaInicio', () {
    testWidgets('escuro, auditivo, demo desligado', (tester) async {
      final r = _Registro();
      await capturarTela(tester, _inicio(r), 'inicio-escuro');
      expect(find.text('Teste de atenção\ncom sons'), findsOneWidget);
      expect(find.text('PROJETO BRAINLINK · PESQUISA'), findsOneWidget);
      expect(find.text('Ex.: P017'), findsOneWidget);
      expect(find.text('Duração: cerca de 5 minutos.'), findsOneWidget);
      await tester.tap(find.text('Visual'));
      await tester.tap(find.text('Auditivo'));
      await tester.tap(find.text('Modo demonstração'));
      await tester.tap(find.text('Começar'));
      await tester.tap(find.text('Abrir coleta anterior'));
      expect(r.chamadas, ['versao:visual', 'demo', 'comecar', 'anterior']);
      final altura = tester.getSize(find.ancestor(
        of: find.text('Abrir coleta anterior'),
        matching: find.byType(InkWell),
      ));
      expect(altura.height, greaterThanOrEqualTo(44));
    });

    testWidgets('visual com demonstração ligada', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        _inicio(r, versao: VersaoTeste.visual, demo: true),
        'inicio-visual-demo',
      );
      expect(find.text('Teste de atenção\ncom imagens'), findsOneWidget);
      await tester.tap(find.text('Auditivo'));
      expect(r.chamadas, ['versao:auditiva']);
    });

    testWidgets('claro e campo de código', (tester) async {
      final r = _Registro();
      final controller = TextEditingController();
      await capturarTela(
          tester, _inicio(r, controller: controller), 'inicio-claro',
          brilho: Brightness.light);
      await tester.enterText(find.byType(TextField), 'p017');
      expect(controller.text, 'p017');
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.textCapitalization, TextCapitalization.characters);
      expect(campo.autocorrect, isFalse);
    });

    testWidgets('rola em tela pequena', (tester) async {
      await capturarTela(tester, _inicio(_Registro()), 'inicio-pequena',
          tamanho: _pequena);
      await tester.scrollUntilVisible(find.text('Abrir coleta anterior'), 100);
    });
  });

  group('TelaVolumeBaixo', () {
    testWidgets('volume baixo', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        TelaVolumeBaixo(
          volume: const VolumeMidia(4, 15),
          aoTocarSomDeTeste: r.cb('som'),
          aoContinuar: r.cb('continuar'),
        ),
        'volume-baixo',
      );
      expect(find.text('Aumente o volume'), findsOneWidget);
      expect(find.text('Baixo'), findsOneWidget);
      expect(find.bySemanticsLabel('Volume em 3 de 10'), findsOneWidget);
      await tester.tap(find.text('Tocar som de teste'));
      await tester.tap(find.text('Já aumentei, continuar'));
      expect(r.chamadas, ['som', 'continuar']);
    });

    testWidgets('volume adequado e nulo', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        TelaVolumeBaixo(
          volume: const VolumeMidia(12, 15),
          aoTocarSomDeTeste: r.cb('som'),
          aoContinuar: r.cb('continuar'),
        ),
        'volume-adequado',
        brilho: Brightness.light,
      );
      expect(find.text('Adequado'), findsOneWidget);
      expect(find.bySemanticsLabel('Volume em 8 de 10'), findsOneWidget);
      await capturarTela(
        tester,
        TelaVolumeBaixo(
          volume: null,
          aoTocarSomDeTeste: r.cb('som'),
          aoContinuar: r.cb('continuar'),
        ),
        'volume-nulo',
        tamanho: _pequena,
      );
      expect(find.text('Baixo'), findsOneWidget);
      expect(find.bySemanticsLabel('Volume em 0 de 10'), findsOneWidget);
    });
  });

  group('TelaSensor', () {
    testWidgets('procurando', (tester) async {
      final r = _Registro();
      await capturarTela(
          tester, _sensor(r, EstadoContato.procurando), 'sensor-procurando');
      expect(find.text('Procurando sinal…'), findsOneWidget);
      expect(find.text('sem dados'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.tap(find.text('Procurando sinal…'));
      expect(r.chamadas, ['dispositivos']);
    });

    testWidgets('ajuste', (tester) async {
      await capturarTela(
          tester, _sensor(_Registro(), EstadoContato.ajuste), 'sensor-ajuste');
      expect(find.text('Ajuste o sensor'), findsOneWidget);
      expect(find.text('contato instável'), findsOneWidget);
    });

    testWidgets('contato bom, simulado', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        _sensor(r, EstadoContato.bom,
            segundos: 10, simulada: true, habilitado: true),
        'sensor-bom',
      );
      expect(find.text('Estável por 10 segundos.'), findsOneWidget);
      expect(find.text('estável'), findsOneWidget);
      expect(find.text('SIMULADO'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      expect(r.chamadas, ['continuar']);
    });

    testWidgets('claro e tela pequena', (tester) async {
      await capturarTela(
        tester,
        _sensor(_Registro(), EstadoContato.bom, segundos: 4),
        'sensor-bom-claro',
        brilho: Brightness.light,
      );
      expect(find.text('Estável por 4 segundos.'), findsOneWidget);
      await capturarTela(
        tester,
        _sensor(_Registro(), EstadoContato.ajuste, simulada: true),
        'sensor-pequena',
        tamanho: _pequena,
      );
    });
  });

  group('FolhaDispositivos', () {
    testWidgets('com aparelhos', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        _folha(r, dispositivos: _aparelhos, conectandoId: 'AA:01'),
        'folha-aparelhos',
      );
      expect(find.text('Escolha o headset'), findsOneWidget);
      expect(find.text('Pareado'), findsOneWidget);
      expect(find.text('Conectando…'), findsOneWidget);
      await tester.tap(find.text('BrainLink_Lite'));
      await tester.tap(find.text('Procurar de novo'));
      await tester.tapAt(const Offset(195, 10));
      expect(r.chamadas, ['escolher:AA:02', 'procurar', 'fechar']);
    });

    testWidgets('vazia, simulados e fechar', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        _folha(r, erro: 'Bluetooth desligado.'),
        'folha-vazia',
        brilho: Brightness.light,
      );
      expect(find.text('Nenhum aparelho encontrado.'), findsOneWidget);
      expect(find.text('Bluetooth desligado.'), findsOneWidget);
      for (final c in CenarioSimulado.values) {
        expect(find.text(c.rotulo), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('Fechar'), 100);
      await tester.tap(find.text('Perda de contato'));
      await tester.pump();
      await tester.tap(find.text('Usar dados simulados'));
      await tester.tap(find.text('Fechar'));
      expect(r.chamadas, ['simulados:perdaContato', 'fechar']);
    });

    testWidgets('buscando, tela pequena', (tester) async {
      final r = _Registro();
      await capturarTela(tester, _folha(r, buscando: true), 'folha-buscando',
          tamanho: _pequena);
      expect(find.text('Procurando…'), findsOneWidget);
      expect(find.text('Nenhum aparelho encontrado.'), findsNothing);
      await tester.scrollUntilVisible(find.text('Usar dados simulados'), 100);
      await tester.tap(find.text('Usar dados simulados'));
      expect(r.chamadas, ['simulados:tudoCerto']);
    });
  });

  group('TelaInstrucoes', () {
    testWidgets('escuro e claro', (tester) async {
      final r = _Registro();
      await capturarTela(
          tester, TelaInstrucoes(aoEntender: r.cb('ok')), 'instrucoes');
      expect(find.text('Como vai ser'), findsOneWidget);
      expect(find.text('Dois bipes'), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      expect(r.chamadas, ['ok']);
      await capturarTela(
          tester, TelaInstrucoes(aoEntender: r.cb('ok')), 'instrucoes-claro',
          brilho: Brightness.light);
      await capturarTela(
          tester, TelaInstrucoes(aoEntender: r.cb('ok')), 'instrucoes-pequena',
          tamanho: _pequena);
    });
  });

  group('TelaCalibracao', () {
    testWidgets('3 de 5 e crescimento do círculo', (tester) async {
      final r = _Registro();
      await capturarTela(tester, _calibracao(r), 'calibracao');
      expect(find.text('3 de 5'), findsOneWidget);
      expect(find.text('PESQUISADOR · piscadas: 3'), findsOneWidget);
      expect(find.text('sinal bom'), findsOneWidget);
      const chave = ValueKey('cal');
      await montarTela(tester, _calibracao(r), chave: chave);
      final circulo = find.byType(AnimatedContainer);
      expect(tester.getSize(circulo).width, closeTo(128.8, 0.01));
      await montarTela(tester, _calibracao(r, bipes: 5), chave: chave);
      await tester.pump(const Duration(milliseconds: 300));
      final meio = tester.getSize(circulo).width;
      expect(meio, inExclusiveRange(128.8, 148));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(circulo).width, closeTo(148, 0.01));
    });

    testWidgets('segurar encerra', (tester) async {
      final r = _Registro();
      await capturarTela(
        tester,
        _calibracao(r,
            bipes: 0, qualidade: QualidadeSinal.ajuste, simulada: true),
        'calibracao-simulada',
        brilho: Brightness.light,
      );
      expect(find.text('PESQUISADOR · piscadas: 3 · simulado'), findsOneWidget);
      expect(find.text('sinal instável'), findsOneWidget);
      final gesto = await tester
          .startGesture(tester.getCenter(find.text('Segure para encerrar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesto.up();
      expect(r.chamadas, ['encerrar']);
    });

    testWidgets('tela pequena', (tester) async {
      await capturarTela(
        tester,
        _calibracao(_Registro(), qualidade: QualidadeSinal.semDados),
        'calibracao-pequena',
        tamanho: _pequena,
      );
      expect(find.text('sem sinal'), findsOneWidget);
    });
  });

  group('TelaCalibracaoResultado', () {
    testWidgets('5 de 5', (tester) async {
      final r = _Registro();
      Widget tela() => TelaCalibracaoResultado(
            porBipe: const [true, true, true, true, true],
            aoRepetir: r.cb('repetir'),
            aoContinuar: r.cb('continuar'),
          );
      await capturarTela(tester, tela(), 'calibracao-resultado');
      expect(find.text('Calibração concluída'), findsOneWidget);
      expect(find.text('5 de 5'), findsOneWidget);
      await tester.tap(find.text('Repetir calibração'));
      await tester.tap(find.text('Continuar'));
      expect(r.chamadas, ['repetir', 'continuar']);
      await capturarTela(tester, tela(), 'calibracao-resultado-claro',
          brilho: Brightness.light);
      await capturarTela(tester, tela(), 'calibracao-resultado-pequena',
          tamanho: _pequena);
    });
  });

  group('TelaCalibracaoErro', () {
    testWidgets('4 de 5', (tester) async {
      final r = _Registro();
      Widget tela() => TelaCalibracaoErro(
            porBipe: const [true, true, false, true, true],
            aoRepetir: r.cb('repetir'),
            aoContinuarMesmoAssim: r.cb('mesmo-assim'),
          );
      await capturarTela(tester, tela(), 'calibracao-erro');
      expect(find.text('Vamos repetir a calibração?'), findsOneWidget);
      expect(find.text('4 de 5'), findsOneWidget);
      expect(
          find.bySemanticsLabel('4 de 5 piscadas detectadas'), findsOneWidget);
      await tester.tap(find.text('Repetir calibração'));
      await tester.tap(find.text('Continuar mesmo assim'));
      expect(r.chamadas, ['repetir', 'mesmo-assim']);
      await capturarTela(tester, tela(), 'calibracao-erro-claro',
          brilho: Brightness.light);
      await capturarTela(tester, tela(), 'calibracao-erro-pequena',
          tamanho: _pequena);
    });
  });
}
