import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Telas `Treino-auditivo` e `Treino-visual` do design: instruções da tarefa
/// antes do treino (etapa 4).
class TelaInstrucoesTarefa extends StatelessWidget {
  const TelaInstrucoesTarefa({
    super.key,
    required this.versao,
    required this.aoOuvirExemplo,
    required this.aoFazerTreino,
  });

  final VersaoTeste versao;

  /// "Som grave" → [TipoEstimulo.comum]; "Som agudo" → [TipoEstimulo.raro].
  final ValueChanged<TipoEstimulo> aoOuvirExemplo;
  final VoidCallback aoFazerTreino;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final auditiva = versao == VersaoTeste.auditiva;
            final titulo = TipografiaTeste.next(
              24,
              peso: FontWeight.w600,
              altura: 1.3,
              cor: cores.texto,
            );
            const forte = TextStyle(fontWeight: FontWeight.w700);
            final paragrafo = TipografiaTeste.next(
              18,
              altura: 1.45,
              cor: cores.textoSecundario,
            );
            return PaginaTeste(
              espaco: 20,
              children: [
                const CabecalhoEtapa(etapa: 4, rotulo: 'Instruções da tarefa'),
                Semantics(
                  header: true,
                  child: auditiva
                      ? Text.rich(
                          TextSpan(
                            style: titulo,
                            children: const [
                              TextSpan(text: 'Você vai ouvir dois sons: um '),
                              TextSpan(text: 'grave', style: forte),
                              TextSpan(text: ' e um '),
                              TextSpan(text: 'agudo', style: forte),
                              TextSpan(text: '.'),
                            ],
                          ),
                        )
                      : Text(
                          'Vão aparecer figuras no centro da tela, uma de '
                          'cada vez.',
                          style: titulo,
                        ),
                ),
                if (auditiva) ...[
                  LinhaTeste(
                    espaco: 12,
                    children: [
                      Expanded(
                        child: _BotaoExemplo(
                          texto: 'Som grave',
                          aoTocar: () => aoOuvirExemplo(TipoEstimulo.comum),
                        ),
                      ),
                      Expanded(
                        child: _BotaoExemplo(
                          texto: 'Som agudo',
                          aoTocar: () => aoOuvirExemplo(TipoEstimulo.raro),
                        ),
                      ),
                    ],
                  ),
                  const _CartaoRegra(),
                  Text.rich(
                    TextSpan(
                      style: paragrafo,
                      children: [
                        const TextSpan(
                          text: 'Responda o mais rápido que puder, sem errar. '
                              'Você vai fazer de ',
                        ),
                        TextSpan(
                          text: 'olhos fechados',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cores.texto,
                          ),
                        ),
                        const TextSpan(text: ', segurando o celular.'),
                      ],
                    ),
                  ),
                ] else ...[
                  const IntrinsicHeight(
                    child: LinhaTeste(
                      espaco: 12,
                      alinhamento: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CartaoFigura(
                            figura: IconesTeste.barcoComum,
                            rotulo: 'Figura comum',
                            tocar: true,
                          ),
                        ),
                        Expanded(
                          child: _CartaoFigura(
                            figura: IconesTeste.barcoPirata,
                            rotulo: 'Figura rara',
                            tocar: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cores.fundoPesquisador,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: LinhaTeste(
                      espaco: 14,
                      children: [
                        IconeSvg(
                          IconesTeste.mais,
                          tamanho: 26,
                          cor: cores.acentoIcone,
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TipografiaTeste.next(
                                19,
                                altura: 1.35,
                                cor: cores.texto,
                              ),
                              children: const [
                                TextSpan(text: 'Olhe sempre para o '),
                                TextSpan(text: 'centro da tela', style: forte),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Responda o mais rápido que puder, sem errar.',
                    style: paragrafo,
                  ),
                ],
                const Spacer(),
                BotaoTeste(
                  texto: auditiva
                      ? 'Fazer o treino (10 sons)'
                      : 'Fazer o treino (10 figuras)',
                  aoTocar: aoFazerTreino,
                ),
              ],
            );
          },
        ),
      );
}

/// Botão "Som grave"/"Som agudo": fundo de cartão, borda forte, ícone de tocar.
class _BotaoExemplo extends StatelessWidget {
  const _BotaoExemplo({required this.texto, required this.aoTocar});

  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: cores.bordaForte),
    );
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconeSvg(
                    IconesTeste.tocar,
                    tamanho: 18,
                    cor: cores.acentoIcone,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: TipografiaTeste.next(
                        18,
                        peso: FontWeight.w600,
                        cor: cores.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão "Regra da tarefa": som grave → toque; som agudo → não toque.
class _CartaoRegra extends StatelessWidget {
  const _CartaoRegra();

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    Widget linha(Widget circulo, String rotulo, Widget acao) => Padding(
          padding: const EdgeInsets.all(18),
          child: LinhaTeste(
            espaco: 16,
            children: [
              circulo,
              Expanded(
                child: ColunaTeste(
                  espaco: 2,
                  children: [
                    Text(
                      rotulo,
                      style: TipografiaTeste.next(16, cor: cores.textoSuave),
                    ),
                    acao,
                  ],
                ),
              ),
            ],
          ),
        );
    final estiloAcao = TipografiaTeste.next(
      22,
      peso: FontWeight.w700,
      cor: cores.texto,
    );
    return Semantics(
      container: true,
      label: 'Regra da tarefa',
      child: Container(
        decoration: BoxDecoration(
          color: cores.cartao,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cores.borda),
        ),
        child: ColunaTeste(
          children: [
            linha(
              const CirculoIcone(
                figura: IconesTeste.mao,
                diametro: 52,
                tamanhoIcone: 26,
              ),
              'Som grave',
              Text('Toque na tela', style: estiloAcao),
            ),
            Container(height: 1, color: cores.borda),
            linha(
              CirculoIcone(
                figura: IconesTeste.maoRiscada,
                diametro: 52,
                tamanhoIcone: 26,
                fundo: cores.fundoPesquisador,
                borda: cores.bordaForte,
                cor: cores.textoSecundario,
              ),
              'Som agudo',
              _textoNaoToque(context, estiloAcao),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de figura do `Treino-visual`: caixa escura de 120 com a figura de 96.
class _CartaoFigura extends StatelessWidget {
  const _CartaoFigura({
    required this.figura,
    required this.rotulo,
    required this.tocar,
  });

  final FiguraSvg figura;
  final String rotulo;
  final bool tocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final estiloAcao = TipografiaTeste.next(
      20,
      peso: FontWeight.w700,
      cor: cores.texto,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        color: cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.borda),
      ),
      child: ColunaTeste(
        espaco: 12,
        alinhamento: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CoresFase.visualFundo,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: IconeSvg(figura, tamanho: 96),
          ),
          ColunaTeste(
            espaco: 4,
            alinhamento: CrossAxisAlignment.center,
            children: [
              Text(
                rotulo,
                textAlign: TextAlign.center,
                style: TipografiaTeste.next(16, cor: cores.textoSuave),
              ),
              if (tocar)
                Text('Toque', textAlign: TextAlign.center, style: estiloAcao)
              else
                _textoNaoToque(context, estiloAcao),
            ],
          ),
        ],
      ),
    );
  }
}

/// "NÃO toque", com "NÃO" sublinhado (`text-underline-offset: 4px`).
Widget _textoNaoToque(BuildContext context, TextStyle estilo) => Text.rich(
      TextSpan(
        style: estilo,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _Sublinhado('NÃO', estilo: estilo, deslocamento: 4),
          ),
          const TextSpan(text: ' toque'),
        ],
      ),
      textAlign: TextAlign.center,
    );

/// Texto sublinhado com afastamento da linha de base, como o
/// `text-underline-offset` do CSS (o Flutter não tem esse ajuste).
class _Sublinhado extends StatelessWidget {
  const _Sublinhado(
    this.texto, {
    required this.estilo,
    required this.deslocamento,
  });

  final String texto;
  final TextStyle estilo;
  final double deslocamento;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context);
    return CustomPaint(
      foregroundPainter: _PintorSublinhado(
        texto: texto,
        estilo: estilo,
        deslocamento: deslocamento,
        escala: escala,
      ),
      child: Text(texto, style: estilo),
    );
  }
}

class _PintorSublinhado extends CustomPainter {
  _PintorSublinhado({
    required this.texto,
    required this.estilo,
    required this.deslocamento,
    required this.escala,
  });

  final String texto;
  final TextStyle estilo;
  final double deslocamento;
  final TextScaler escala;

  @override
  void paint(Canvas canvas, Size size) {
    final pintor = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala,
    )..layout();
    final base = pintor.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    pintor.dispose();
    final tamanho = escala.scale(estilo.fontSize ?? 14);
    final espessura = tamanho / 14;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        base + escala.scale(deslocamento),
        size.width,
        espessura,
      ),
      Paint()..color = estilo.color ?? const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_PintorSublinhado oldDelegate) =>
      oldDelegate.texto != texto ||
      oldDelegate.estilo != estilo ||
      oldDelegate.deslocamento != deslocamento ||
      oldDelegate.escala != escala;
}
