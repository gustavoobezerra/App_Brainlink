import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Borda do círculo neutro de "Era para não tocar" (`#44567A`).
const Color _bordaCirculoNeutro = Color(0xFF44567A);

/// Tela `Treino-auditivo-feedback` do design (estados `-certo`, `-naoTocar`
/// e `-fim`), também usada no treino visual. Sempre escura.
class TelaTreino extends StatelessWidget {
  const TelaTreino({
    super.key,
    required this.versao,
    required this.indice,
    required this.total,
    required this.feedback,
    required this.estimuloVisual,
    required this.concluido,
    required this.aoTocar,
    required this.aoComecarTeste,
  });

  final VersaoTeste versao;

  /// Número do estímulo atual (1 a [total]).
  final int indice;
  final int total;

  /// Feedback do último estímulo; nulo mostra só a dica (ou a figura).
  final FeedbackTreino? feedback;

  /// O que aparece no centro da área na versão visual, sem feedback.
  final EstimuloVisual estimuloVisual;
  final bool concluido;
  final ValueChanged<PointerDownEvent> aoTocar;
  final VoidCallback aoComecarTeste;

  bool get _auditiva => versao == VersaoTeste.auditiva;

  @override
  Widget build(BuildContext context) => TemaTeste(
        sempreEscuro: true,
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            return PaginaTeste(
              espaco: 20,
              children: [
                CabecalhoEtapa(
                  etapa: 4,
                  rotulo: 'Treino',
                  rotuloDireita: concluido
                      ? '$total de $total'
                      : '${_auditiva ? 'Som' : 'Figura'} $indice de $total',
                ),
                if (concluido) ...[
                  Expanded(child: _fim(cores)),
                  BotaoTeste(texto: 'Começar o teste', aoTocar: aoComecarTeste),
                ] else
                  Expanded(child: _area(cores)),
              ],
            );
          },
        ),
      );

  Widget _fim(CoresTeste cores) {
    final paragrafo = TipografiaTeste.next(
      19,
      altura: 1.45,
      cor: cores.textoSecundario,
    );
    return ColunaTeste(
      espaco: 18,
      principal: MainAxisAlignment.center,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Treino concluído',
            style: TipografiaTeste.next(
              28,
              peso: FontWeight.w700,
              cor: cores.texto,
            ),
          ),
        ),
        Text(
          'No teste não vai aparecer “certo” nem “errado”. Tudo bem não '
          'saber como foi.',
          style: paragrafo,
        ),
        Text.rich(
          TextSpan(
            style: paragrafo,
            children: [
              const TextSpan(text: 'Ao ouvir '),
              TextSpan(
                text: 'um bipe',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cores.texto,
                ),
              ),
              TextSpan(
                text: _auditiva
                    ? ', feche os olhos. O teste dura 3 minutos.'
                    : ', olhe para o centro da tela. O teste dura 3 minutos.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _area(CoresTeste cores) {
    final dica = Text(
      'Toque em qualquer lugar',
      textAlign: TextAlign.center,
      style: TipografiaTeste.next(16, cor: cores.textoDiscreto),
    );
    final conteudo = _conteudo(cores);
    final List<Widget> filhos;
    if (feedback == null && !_auditiva) {
      // Uma cópia invisível da dica em cima mantém a figura no centro exato.
      filhos = [
        ExcludeSemantics(child: Opacity(opacity: 0, child: dica)),
        FiguraEstimulo(estimuloVisual, caixa: 120),
        dica,
      ];
    } else {
      filhos = [if (conteudo != null) conteudo, dica];
    }
    return AreaToque(
      aoTocar: aoTocar,
      semantica: 'Área de resposta: toque em qualquer lugar',
      child: CustomPaint(
        painter: _BordaTracejada(cores.borda),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ColunaTeste(
              espaco: 28,
              alinhamento: CrossAxisAlignment.center,
              children: filhos,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _conteudo(CoresTeste cores) {
    final legenda = TipografiaTeste.next(15, cor: cores.textoDiscreto);
    switch (feedback) {
      case null:
        return null;
      case FeedbackTreino.certo:
        return Semantics(
          liveRegion: true,
          container: true,
          child: ColunaTeste(
            espaco: 16,
            alinhamento: CrossAxisAlignment.center,
            children: [
              const CirculoIcone(
                figura: IconesTeste.visto,
                diametro: 88,
                tamanhoIcone: 40,
              ),
              Text(
                'Certo',
                style: TipografiaTeste.next(
                  30,
                  peso: FontWeight.w700,
                  cor: cores.texto,
                ),
              ),
              Text('1 vibração curta e firme', style: legenda),
            ],
          ),
        );
      case FeedbackTreino.naoTocar:
      case FeedbackTreino.naoTocou:
        final naoTocar = feedback == FeedbackTreino.naoTocar;
        final explicacao = naoTocar
            ? (_auditiva ? 'Esse foi o som agudo.' : 'Essa foi a figura rara.')
            : (_auditiva
                ? 'Esse foi o som grave.'
                : 'Essa foi a figura comum.');
        return Semantics(
          liveRegion: true,
          container: true,
          child: ColunaTeste(
            espaco: 16,
            alinhamento: CrossAxisAlignment.center,
            children: [
              CirculoIcone(
                figura: IconesTeste.menos,
                diametro: 88,
                tamanhoIcone: 36,
                fundo: cores.feedbackNeutroFundo,
                borda: _bordaCirculoNeutro,
                cor: cores.textoSecundario,
              ),
              Text(
                naoTocar ? 'Era para não tocar' : 'Era para tocar',
                textAlign: TextAlign.center,
                style: TipografiaTeste.next(
                  26,
                  peso: FontWeight.w700,
                  cor: cores.texto,
                ),
              ),
              Text(
                explicacao,
                textAlign: TextAlign.center,
                style: TipografiaTeste.next(17, cor: cores.textoSecundario),
              ),
              Text('1 vibração curta e fraca', style: legenda),
            ],
          ),
        );
    }
  }
}

/// Borda tracejada de 1 px com raio 20 (`border: 1px dashed`).
class _BordaTracejada extends CustomPainter {
  _BordaTracejada(this.cor);

  final Color cor;

  static const double _traco = 3;
  static const double _vao = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final retangulo = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(19.5),
    );
    final pincel = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(
      tracejar(Path()..addRRect(retangulo), const [_traco, _vao]),
      pincel,
    );
  }

  @override
  bool shouldRepaint(_BordaTracejada oldDelegate) => oldDelegate.cor != cor;
}
