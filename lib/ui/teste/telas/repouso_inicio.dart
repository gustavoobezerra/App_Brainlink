import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_segurar.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Telas `Repouso-inicio` (etapa 3) e `Repouso-final` (etapa 6) do design:
/// pedem para fechar os olhos até ouvir dois bipes.
class TelaRepousoInicio extends StatelessWidget {
  const TelaRepousoInicio({
    super.key,
    required this.repousoFinal,
    required this.aoComecar,
    required this.aoSegurarEncerrar,
  });

  /// `true` desenha o `Repouso-final` (40 segundos, etapa 6).
  final bool repousoFinal;
  final VoidCallback aoComecar;
  final VoidCallback aoSegurarEncerrar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final titulo = TipografiaTeste.next(
              28,
              peso: FontWeight.w700,
              altura: 1.3,
              cor: cores.texto,
            );
            return PaginaTeste(
              children: [
                CabecalhoEtapa(
                  etapa: repousoFinal ? 6 : 3,
                  rotulo: repousoFinal ? 'Repouso final' : 'Repouso',
                  acao: BotaoSegurar.pilula(aoConcluir: aoSegurarEncerrar),
                ),
                Expanded(
                  child: ColunaTeste(
                    espaco: 28,
                    principal: MainAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CirculoIcone(
                          figura: IconesTeste.olhosFechados,
                          tamanhoIcone: 36,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text.rich(
                          TextSpan(
                            style: titulo,
                            children: [
                              TextSpan(
                                text: repousoFinal
                                    ? 'Último repouso. Feche os olhos até ouvir '
                                    : 'Agora feche os olhos e fique relaxado '
                                        'até ouvir ',
                              ),
                              TextSpan(
                                text: 'dois bipes',
                                style: TextStyle(color: cores.acentoDestaque),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        repousoFinal
                            ? 'Duração: 40 segundos.'
                            : 'Duração: 1 minuto. Você não precisa fazer nada.',
                        style: TipografiaTeste.next(
                          18,
                          altura: 1.45,
                          cor: cores.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                BotaoTeste(texto: 'Começar repouso', aoTocar: aoComecar),
              ],
            );
          },
        ),
      );
}
