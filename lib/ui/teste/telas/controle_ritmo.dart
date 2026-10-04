import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela `Controle-ritmo` do design (etapa 5, "Tarefa · parte 2"): toque em
/// todos os estímulos.
class TelaControleRitmo extends StatelessWidget {
  const TelaControleRitmo({
    super.key,
    required this.versao,
    required this.aoComecar,
  });

  final VersaoTeste versao;
  final VoidCallback aoComecar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final auditiva = versao == VersaoTeste.auditiva;
            final titulo = TipografiaTeste.next(
              30,
              peso: FontWeight.w700,
              altura: 1.25,
              cor: cores.texto,
            );
            return PaginaTeste(
              children: [
                const CabecalhoEtapa(etapa: 5, rotulo: 'Tarefa · parte 2'),
                Expanded(
                  child: ColunaTeste(
                    espaco: 24,
                    principal: MainAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CirculoIcone(figura: IconesTeste.mao),
                      ),
                      Semantics(
                        header: true,
                        child: Text.rich(
                          TextSpan(
                            style: titulo,
                            children: [
                              const TextSpan(text: 'Agora toque em '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: _Sublinhado(
                                  auditiva ? 'todos' : 'todas',
                                  estilo: titulo,
                                  deslocamento: 5,
                                ),
                              ),
                              TextSpan(
                                text: auditiva ? ' os sons.' : ' as figuras.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        auditiva
                            ? 'Todos os sons serão iguais. Toque uma vez a '
                                'cada som, de olhos fechados.'
                            : 'Todas as figuras serão iguais. Toque uma vez a '
                                'cada figura.',
                        style: TipografiaTeste.next(
                          19,
                          altura: 1.45,
                          cor: cores.textoSecundario,
                        ),
                      ),
                      Text(
                        'Duração: 1 minuto.',
                        style: TipografiaTeste.next(
                          18,
                          altura: 1.45,
                          cor: cores.textoSuave,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cores.fundoPesquisador,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: TipografiaTeste.next(
                              16,
                              altura: 1.4,
                              cor: cores.textoSuave,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Na versão visual: “Agora toque em ',
                              ),
                              TextSpan(
                                text: 'todas',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cores.texto,
                                ),
                              ),
                              const TextSpan(text: ' as figuras.”'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                BotaoTeste(texto: 'Começar', aoTocar: aoComecar),
              ],
            );
          },
        ),
      );
}

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
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        base + escala.scale(deslocamento),
        size.width,
        tamanho / 14,
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
