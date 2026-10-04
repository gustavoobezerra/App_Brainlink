import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Erro-bluetooth": teste pausado enquanto o app tenta reconectar ao
/// headset.
class TelaReconexao extends StatelessWidget {
  const TelaReconexao({
    super.key,
    required this.tentativa,
    required this.maxTentativas,
    required this.segundosSemDados,
    required this.gravadoAte,
    required this.simulada,
    required this.aoTentarAgora,
    required this.aoEncerrar,
  });

  final int tentativa;
  final int maxTentativas;
  final int segundosSemDados;

  /// Nome da última fase gravada (ex.: "Repouso").
  final String gravadoAte;
  final bool simulada;
  final VoidCallback aoTentarAgora;
  final VoidCallback aoEncerrar;

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return PaginaTeste(
            espaco: 22,
            children: [
              LinhaTeste(
                espaco: 10,
                children: [
                  IconeSvg(
                    IconesTeste.pausa,
                    tamanho: 18,
                    cor: cores.textoSuave,
                  ),
                  Flexible(
                    child: Text(
                      'Teste pausado',
                      style: TipografiaTeste.next(15, cor: cores.textoSuave),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ColunaTeste(
                  espaco: 22,
                  principal: MainAxisAlignment.center,
                  alinhamento: CrossAxisAlignment.start,
                  children: [
                    const CirculoIcone(figura: IconesTeste.bluetooth),
                    Semantics(
                      header: true,
                      child: Text(
                        'Reconectando ao headset…',
                        style: TipografiaTeste.next(
                          30,
                          peso: FontWeight.w700,
                          altura: 1.2,
                          cor: cores.texto,
                        ),
                      ),
                    ),
                    Text(
                      'O que já foi gravado está guardado. Deixe o headset '
                      'ligado e perto do celular.',
                      style: TipografiaTeste.next(
                        19,
                        altura: 1.45,
                        cor: cores.textoSecundario,
                      ),
                    ),
                    _lista(cores),
                    SizedBox(
                      width: double.infinity,
                      child: QuadroPesquisador(
                        child: Text(
                          'PESQUISADOR · último dado há $segundosSemDados s · '
                          'gravado até $gravadoAte'
                          '${simulada ? ' · simulado' : ''}',
                          style: TipografiaTeste.mono(
                            12,
                            cor: cores.textoDiscreto,
                            espacamentoEm: 0.03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ColunaTeste(
                espaco: 12,
                children: [
                  BotaoTeste(
                    texto: 'Tentar agora',
                    aoTocar: aoTentarAgora,
                    estilo: EstiloBotao.secundario,
                    bordaForte: true,
                    tamanhoTexto: 18,
                    peso: FontWeight.w600,
                  ),
                  BotaoTeste(
                    texto: 'Encerrar o teste',
                    aoTocar: aoEncerrar,
                    estilo: EstiloBotao.link,
                    tamanhoTexto: 17,
                    peso: FontWeight.w400,
                    altura: 48,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lista de passos (`ol`): salvo, procurando e o próximo passo.
  Widget _lista(CoresTeste cores) {
    Widget item(Widget marcador, String texto, Color cor) => LinhaTeste(
          espaco: 12,
          children: [
            marcador,
            Expanded(
              child: Text(texto, style: TipografiaTeste.next(17, cor: cor)),
            ),
          ],
        );
    Widget anel(Color cor) => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cor, width: 2),
          ),
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.cartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.borda),
      ),
      child: ColunaTeste(
        espaco: 12,
        children: [
          item(
            IconeSvg(
              IconesTeste.visto.comEspessura(2.25),
              tamanho: 20,
              cor: cores.acentoIcone,
            ),
            'Dados salvos até agora',
            cores.texto,
          ),
          item(
            anel(cores.acento),
            'Procurando o headset (tentativa $tentativa de $maxTentativas)',
            cores.texto,
          ),
          item(
            anel(cores.bordaForte),
            'Checar contato e continuar a fase',
            cores.textoDiscreto,
          ),
        ],
      ),
    );
  }
}
