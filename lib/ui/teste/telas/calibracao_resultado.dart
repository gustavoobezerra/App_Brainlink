import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Calibração concluída (design `Calibracao-resultado`).
class TelaCalibracaoResultado extends StatelessWidget {
  const TelaCalibracaoResultado({
    super.key,
    required this.porBipe,
    required this.aoRepetir,
    required this.aoContinuar,
  });

  /// Para cada bipe, se a piscada apareceu no sinal.
  final List<bool> porBipe;
  final VoidCallback aoRepetir;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            return PaginaTeste(
              espaco: 24,
              children: [
                const CabecalhoEtapa(etapa: 2, rotulo: 'Calibração'),
                Expanded(
                  child: ColunaTeste(
                    espaco: 14,
                    principal: MainAxisAlignment.center,
                    alinhamento: CrossAxisAlignment.center,
                    children: [
                      const CirculoIcone(figura: IconesTeste.visto),
                      Semantics(
                        header: true,
                        child: Text(
                          'Calibração concluída',
                          textAlign: TextAlign.center,
                          style: TipografiaTeste.next(
                            28,
                            peso: FontWeight.w700,
                            cor: cores.texto,
                          ),
                        ),
                      ),
                      Text(
                        'Pode piscar normalmente agora.',
                        textAlign: TextAlign.center,
                        style: TipografiaTeste.next(
                          19,
                          altura: 1.4,
                          cor: cores.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                QuadroPiscadas(
                  porBipe: porBipe,
                  rodape: BotaoTeste(
                    texto: 'Repetir calibração',
                    aoTocar: aoRepetir,
                    estilo: EstiloBotao.link,
                    tamanhoTexto: 16,
                    peso: FontWeight.w400,
                    altura: 44,
                    icone: IconesTeste.repetir,
                    tamanhoIcone: 18,
                    espacoIcone: 8,
                    preenchimentoHorizontal: 4,
                    alinhamento: MainAxisAlignment.start,
                  ),
                ),
                BotaoTeste(texto: 'Continuar', aoTocar: aoContinuar),
              ],
            );
          },
        ),
      );
}

/// Quadro do pesquisador com "Piscadas detectadas", "X de N" e a barra por
/// bipe (telas `Calibracao-resultado` e `Erro-calibracao`).
class QuadroPiscadas extends StatelessWidget {
  const QuadroPiscadas({
    super.key,
    required this.porBipe,
    this.corContagem,
    this.rodape,
  });

  final List<bool> porBipe;

  /// Cor do "X de N"; padrão: a cor do texto.
  final Color? corContagem;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final detectadas = porBipe.where((p) => p).length;
    final total = porBipe.length;
    return QuadroPesquisador(
      padding: const EdgeInsets.all(16),
      raio: 14,
      comBorda: true,
      child: ColunaTeste(
        espaco: 14,
        children: [
          Text(
            'PESQUISADOR',
            style: TipografiaTeste.mono(
              12,
              cor: cores.textoDiscreto,
              espacamentoEm: 0.04,
            ),
          ),
          LinhaTeste(
            espaco: 12,
            children: [
              Expanded(
                child: Text(
                  'Piscadas detectadas',
                  style: TipografiaTeste.next(18, cor: cores.texto),
                ),
              ),
              Text(
                '$detectadas de $total',
                style: TipografiaTeste.mono(
                  20,
                  peso: FontWeight.w500,
                  cor: corContagem ?? cores.texto,
                ),
              ),
            ],
          ),
          Semantics(
            container: true,
            label: '$detectadas de $total piscadas detectadas',
            child: ExcludeSemantics(
              child: LinhaTeste(
                espaco: 6,
                children: [
                  for (final detectada in porBipe)
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color:
                              detectada ? cores.acento : cores.progressoInativo,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (rodape != null) rodape!,
        ],
      ),
    );
  }
}
