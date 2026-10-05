import 'package:flutter/material.dart';

import '../../../services/teste/estimulos.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/pagina_teste.dart';

/// Aviso de volume baixo antes do teste auditivo (design `Erro-volume-baixo`).
class TelaVolumeBaixo extends StatelessWidget {
  const TelaVolumeBaixo({
    super.key,
    required this.volume,
    required this.aoTocarSomDeTeste,
    required this.aoContinuar,
  });

  /// Volume de mídia atual; nulo quando não foi possível ler.
  final VolumeMidia? volume;
  final VoidCallback aoTocarSomDeTeste;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final fracao = volume?.fracao ?? 0;
            final preenchidos = (fracao * 10).round().clamp(0, 10);
            final adequado = volume != null && fracao >= 0.6;
            final corSegmento = adequado ? cores.verde : cores.ambarBorda;
            return PaginaTeste(
              espaco: 22,
              children: [
                Expanded(
                  child: ColunaTeste(
                    espaco: 22,
                    principal: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: cores.ambarBorda, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: IconeSvg(
                            IconesTeste.volume,
                            tamanho: 34,
                            cor: cores.ambarIcone,
                          ),
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          'Aumente o volume',
                          style: TipografiaTeste.next(
                            30,
                            peso: FontWeight.w700,
                            altura: 1.2,
                            cor: cores.texto,
                          ),
                        ),
                      ),
                      Text(
                        'Este teste usa sons. Deixe o volume do celular perto '
                        'do máximo e confira se você ouve bem o som de teste.',
                        style: TipografiaTeste.next(
                          19,
                          altura: 1.45,
                          cor: cores.textoSecundario,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cores.cartao,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cores.borda),
                        ),
                        child: ColunaTeste(
                          espaco: 10,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Volume atual',
                                    style: TipografiaTeste.next(
                                      16,
                                      cor: cores.texto,
                                    ),
                                  ),
                                ),
                                Text(
                                  adequado ? 'Adequado' : 'Baixo',
                                  style: TipografiaTeste.next(
                                    16,
                                    peso: FontWeight.w600,
                                    cor: adequado
                                        ? cores.verdeTitulo
                                        : cores.ambarTitulo,
                                  ),
                                ),
                              ],
                            ),
                            Semantics(
                              label: 'Volume em $preenchidos de 10',
                              child: ExcludeSemantics(
                                child: LinhaTeste(
                                  espaco: 4,
                                  children: [
                                    for (var i = 0; i < 10; i++)
                                      Expanded(
                                        child: Container(
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: i < preenchidos
                                                ? corSegmento
                                                : cores.progressoInativo,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      BotaoTeste(
                        texto: 'Tocar som de teste',
                        aoTocar: aoTocarSomDeTeste,
                        estilo: EstiloBotao.secundario,
                        bordaForte: true,
                        tamanhoTexto: 18,
                        peso: FontWeight.w600,
                        icone: IconesTeste.tocar,
                        tamanhoIcone: 18,
                        corIcone: cores.acentoIcone,
                      ),
                    ],
                  ),
                ),
                BotaoTeste(
                    texto: 'Já aumentei, continuar', aoTocar: aoContinuar),
              ],
            );
          },
        ),
      );
}
