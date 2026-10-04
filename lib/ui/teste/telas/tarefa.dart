import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_segurar.dart';
import '../widgets/elementos_teste.dart';

/// Telas `Tarefa-auditiva` e `Tarefa-visual` (estados `-fixacao`, `-comum`,
/// `-rara`) do design. Sempre escuras; a tela inteira é a área de resposta.
///
/// A área usa `Listener` por fora de tudo: um toque no botão de segurar
/// também chega a [aoTocar] e conta como resposta.
class TelaTarefa extends StatelessWidget {
  const TelaTarefa({
    super.key,
    required this.versao,
    required this.ritmo,
    required this.restante,
    required this.qualidade,
    required this.toques,
    required this.estimuloVisual,
    required this.simulada,
    required this.aoTocar,
    required this.aoSegurarEncerrar,
  });

  final VersaoTeste versao;

  /// Parte 2 (controle de ritmo): toque em todos os estímulos.
  final bool ritmo;
  final Duration restante;
  final QualidadeSinal qualidade;
  final int toques;
  final EstimuloVisual estimuloVisual;
  final bool simulada;
  final ValueChanged<PointerDownEvent> aoTocar;
  final VoidCallback aoSegurarEncerrar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        sempreEscuro: true,
        child: Builder(
          builder: (context) {
            final auditiva = versao == VersaoTeste.auditiva;
            final insets = MediaQuery.paddingOf(context);
            final fundo =
                auditiva ? CoresFase.auditivaFundo : CoresFase.visualFundo;
            final corTexto =
                auditiva ? CoresFase.auditivaTexto : CoresFase.visualTexto;
            return Material(
              color: fundo,
              child: AreaToque(
                aoTocar: aoTocar,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auditiva)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 48 + insets.top,
                        child: ExcludeSemantics(
                          child: Text(
                            ritmo
                                ? 'OLHOS FECHADOS · TOQUE EM TODOS OS SONS'
                                : 'OLHOS FECHADOS · TOQUE NO SOM GRAVE',
                            textAlign: TextAlign.center,
                            style: TipografiaTeste.next(
                              13,
                              cor: CoresFase.auditivaRotulo,
                              espacamento: 13 * 0.06,
                            ),
                          ),
                        ),
                      )
                    else
                      Center(child: _estimulo()),
                    Positioned(
                      left: 20 + insets.left,
                      bottom: 24 + insets.bottom,
                      child: CantoPesquisador(
                        restante: restante,
                        qualidade: qualidade,
                        cor: corTexto,
                        toques: toques,
                        simulada: simulada,
                        espaco: 12,
                      ),
                    ),
                    Positioned(
                      right: 16 + insets.right,
                      bottom: 12 + insets.bottom,
                      child: Semantics(
                        container: true,
                        child: BotaoSegurar.canto(
                          aoConcluir: aoSegurarEncerrar,
                          corBorda: auditiva
                              ? CoresFase.auditivaSegurarBorda
                              : CoresFase.visualSegurarBorda,
                          corIcone: auditiva
                              ? CoresFase.auditivaSegurarIcone
                              : CoresFase.visualSegurarIcone,
                          fundo: fundo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  /// Caixa central de 140 com a cruz de fixação (20) ou a figura (120).
  Widget _estimulo() {
    final FiguraSvg? figura = switch (estimuloVisual) {
      EstimuloVisual.nenhum => null,
      EstimuloVisual.fixacao => IconesTeste.cruzFixacao,
      EstimuloVisual.comum => IconesTeste.barcoComum,
      EstimuloVisual.raro => IconesTeste.barcoPirata,
    };
    return ExcludeSemantics(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: figura == null
              ? null
              : IconeSvg(
                  figura,
                  tamanho: estimuloVisual == EstimuloVisual.fixacao ? 20 : 120,
                ),
        ),
      ),
    );
  }
}
