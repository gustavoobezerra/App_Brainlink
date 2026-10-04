import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/ui/teste/tema/icones.dart';
import 'package:brainlink_app/ui/teste/tema/svg_figura.dart';
import 'package:brainlink_app/ui/teste/tema/tema_teste.dart';
import 'package:brainlink_app/ui/teste/widgets/botao_segurar.dart';
import 'package:brainlink_app/ui/teste/widgets/botao_teste.dart';
import 'package:brainlink_app/ui/teste/widgets/cabecalho_etapa.dart';
import 'package:brainlink_app/ui/teste/widgets/cartao_contato.dart';
import 'package:brainlink_app/ui/teste/widgets/elementos_teste.dart';
import 'package:brainlink_app/ui/teste/widgets/pagina_teste.dart';
import 'package:brainlink_app/ui/teste/widgets/tracado_sinal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'suporte/captura.dart';

Widget _amostra() => TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return PaginaTeste(
            espaco: 20,
            children: [
              CabecalhoEtapa(
                etapa: 2,
                rotulo: 'Calibração',
                acao: BotaoSegurar.pilula(aoConcluir: () {}),
              ),
              Text(
                'Coloque o sensor',
                style: TipografiaTeste.next(28, peso: FontWeight.w700),
              ),
              const CartaoContato(
                estado: EstadoContato.procurando,
                titulo: 'Procurando sinal…',
                subtitulo: 'Ligue o headset e aguarde.',
              ),
              const CartaoContato(
                estado: EstadoContato.bom,
                titulo: 'Contato bom',
                subtitulo: 'Estável por 10 segundos.',
                segmentosEstaveis: 7,
              ),
              QuadroPesquisador(
                child: ColunaTeste(
                  espaco: 8,
                  children: [
                    Text(
                      'PESQUISADOR · SINAL AO VIVO',
                      style: TipografiaTeste.mono(
                        12,
                        cor: cores.textoDiscreto,
                        espacamentoEm: 0.04,
                      ),
                    ),
                    const TracadoSinal(microvolts: null),
                  ],
                ),
              ),
              LinhaTeste(
                espaco: 12,
                children: [
                  const CirculoIcone(figura: IconesTeste.olhosFechados),
                  IconeSvg(IconesTeste.cabecaSensor(cores),
                      largura: 132, altura: 124),
                  const IconeSvg(IconesTeste.barcoPirata, tamanho: 96),
                ],
              ),
              const Spacer(),
              BotaoTeste(texto: 'Continuar', aoTocar: () {}),
              const BotaoTeste(texto: 'Continuar', aoTocar: null),
            ],
          );
        },
      ),
    );

void main() {
  testWidgets('componentes base montam sem estouro de layout', (tester) async {
    await capturarTela(tester, _amostra(), 'base-escuro');
    expect(find.text('Coloque o sensor'), findsOneWidget);
    await capturarTela(tester, _amostra(), 'base-claro',
        brilho: Brightness.light);
    expect(find.text('Segure para encerrar'), findsOneWidget);
  });

  testWidgets('botão de segurar só age depois de 2 segundos', (tester) async {
    var concluido = 0;
    await montarTela(
      tester,
      TemaTeste(
        child: Center(
          child: BotaoSegurar.pilula(aoConcluir: () => concluido++),
        ),
      ),
    );
    final centro = tester.getCenter(find.text('Segure para encerrar'));
    final gesto = await tester.startGesture(centro);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await gesto.up();
    await tester.pump(const Duration(seconds: 1));
    expect(concluido, 0);
    final gesto2 = await tester.startGesture(centro);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await gesto2.up();
    await tester.pump();
    expect(concluido, 1);
  });
}
