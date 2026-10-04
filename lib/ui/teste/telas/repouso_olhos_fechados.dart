import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_segurar.dart';
import '../widgets/elementos_teste.dart';

/// Tela `Repouso-olhos-fechados` do design: quase preta, só um ponto central
/// com brilho suave, o canto do pesquisador e o botão de segurar. Nada anima.
class TelaRepousoOlhosFechados extends StatelessWidget {
  const TelaRepousoOlhosFechados({
    super.key,
    required this.restante,
    required this.qualidade,
    required this.simulada,
    required this.aoSegurarEncerrar,
  });

  final Duration restante;
  final QualidadeSinal qualidade;
  final bool simulada;
  final VoidCallback aoSegurarEncerrar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        sempreEscuro: true,
        child: Builder(
          builder: (context) {
            final insets = MediaQuery.paddingOf(context);
            return Material(
              color: CoresFase.repousoFundo,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: ExcludeSemantics(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: CoresFase.repousoPonto,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CoresFase.repousoBrilho,
                              blurRadius: 18,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20 + insets.left,
                    bottom: 24 + insets.bottom,
                    child: CantoPesquisador(
                      restante: restante,
                      qualidade: qualidade,
                      cor: CoresFase.repousoTexto,
                      simulada: simulada,
                    ),
                  ),
                  Positioned(
                    right: 16 + insets.right,
                    bottom: 12 + insets.bottom,
                    child: BotaoSegurar.canto(
                      aoConcluir: aoSegurarEncerrar,
                      corBorda: CoresFase.repousoSegurarBorda,
                      corIcone: CoresFase.repousoSegurarIcone,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
