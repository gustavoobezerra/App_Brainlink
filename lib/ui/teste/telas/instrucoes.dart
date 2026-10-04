import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Instruções gerais antes da calibração (designs `Instrucoes` e
/// `Claro-Instrucoes`).
class TelaInstrucoes extends StatelessWidget {
  const TelaInstrucoes({super.key, required this.aoEntender});

  final VoidCallback aoEntender;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: _TextoCss(child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            return PaginaTeste(
              espaco: 24,
              children: [
                const CabecalhoEtapa(etapa: 1, rotulo: 'Antes de começar'),
                Semantics(
                  header: true,
                  child: Text(
                    'Como vai ser',
                    style: TipografiaTeste.next(
                      28,
                      peso: FontWeight.w700,
                      altura: 1.2,
                      cor: cores.texto,
                    ),
                  ),
                ),
                const ColunaTeste(
                  espaco: 14,
                  children: [
                    _ItemLista(
                      figura: IconesTeste.pessoaSentada,
                      texto: 'Sente-se confortável e apoie os braços.',
                    ),
                    _ItemLista(
                      figura: IconesTeste.rostoNeutro,
                      texto: 'Durante o teste, evite falar, mexer a cabeça '
                          'ou apertar os dentes.',
                    ),
                  ],
                ),
                Semantics(
                  container: true,
                  label: 'Sinais de som e vibração',
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cores.cartao,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cores.borda),
                    ),
                    child: ColunaTeste(
                      espaco: 14,
                      children: [
                        Text(
                          'Você vai ouvir sinais de sino. O celular também '
                          'vai vibrar.',
                          style: TipografiaTeste.next(
                            18,
                            altura: 1.4,
                            cor: cores.texto,
                          ),
                        ),
                        const IntrinsicHeight(
                          child: LinhaTeste(
                            espaco: 12,
                            alinhamento: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _QuadroBipe(
                                  sinos: 1,
                                  titulo: 'Um bipe',
                                  acao: 'Fechar os olhos',
                                ),
                              ),
                              Expanded(
                                child: _QuadroBipe(
                                  sinos: 2,
                                  titulo: 'Dois bipes',
                                  acao: 'Abrir os olhos',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                BotaoTeste(texto: 'Entendi', aoTocar: aoEntender),
              ],
            );
          },
        )),
      );
}

/// Item da lista com o ícone em círculo de 40 px.
class _ItemLista extends StatelessWidget {
  const _ItemLista({required this.figura, required this.texto});

  final FiguraSvg figura;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return LinhaTeste(
      espaco: 14,
      alinhamento: CrossAxisAlignment.start,
      children: [
        CirculoIcone(figura: figura, diametro: 40, tamanhoIcone: 22),
        Expanded(
          child: Text(
            texto,
            style: TipografiaTeste.next(19, altura: 1.4, cor: cores.texto),
          ),
        ),
      ],
    );
  }
}

/// Quadrinho "Um bipe / Fechar os olhos" e "Dois bipes / Abrir os olhos".
class _QuadroBipe extends StatelessWidget {
  const _QuadroBipe({
    required this.sinos,
    required this.titulo,
    required this.acao,
  });

  final int sinos;
  final String titulo;
  final String acao;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.fundoPesquisador,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ColunaTeste(
        espaco: 10,
        children: [
          LinhaTeste(
            espaco: 6,
            children: [
              for (var i = 0; i < sinos; i++)
                IconeSvg(IconesTeste.sino, cor: cores.acentoIcone),
            ],
          ),
          Text(
            titulo,
            style: TipografiaTeste.next(
              18,
              peso: FontWeight.w700,
              cor: cores.texto,
            ),
          ),
          Text(
            acao,
            style: TipografiaTeste.next(17, cor: cores.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// O `line-height: normal` do navegador vale 1,3 nesta fonte, sem
/// espaçamento extra; o tema do Material herdaria 1,43 e 0,25 do
/// `bodyMedium`. Fixa os valores do CSS, com a entrelinha dividida igualmente.
class _TextoCss extends StatelessWidget {
  const _TextoCss({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const css = TextStyle(
      height: 1.3,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final corpo = (tema.textTheme.bodyMedium ?? const TextStyle()).merge(css);
    return Theme(
      data: tema.copyWith(
        textTheme: tema.textTheme.copyWith(bodyMedium: corpo),
      ),
      child: DefaultTextStyle.merge(style: css, child: child),
    );
  }
}
