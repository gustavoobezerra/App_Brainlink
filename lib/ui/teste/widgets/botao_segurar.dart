import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';

/// Botão que só age depois de ser segurado por 2 s.
///
/// Soltar antes do fim desfaz o progresso. Usa eventos crus de ponteiro, então
/// também funciona em cima de uma área de toque de tela inteira. Leitores de
/// tela acionam pela ação de toque longo.
class BotaoSegurar extends StatefulWidget {
  const BotaoSegurar({
    super.key,
    required this.aoConcluir,
    required this.construtor,
    this.semantica = 'Encerrar o teste: segure por 2 segundos',
  });

  final VoidCallback aoConcluir;

  /// Desenha o botão a partir do progresso (0 a 1).
  final Widget Function(BuildContext context, double progresso) construtor;
  final String semantica;

  /// Pílula "Segure para encerrar" (Calibração, Repouso, Repouso final).
  static Widget pilula({Key? key, required VoidCallback aoConcluir}) =>
      BotaoSegurar(
        key: key,
        aoConcluir: aoConcluir,
        construtor: (context, progresso) {
          final cores = TemaTeste.of(context);
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: cores.borda),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: ColoredBox(color: cores.borda),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconeSvg(
                          IconesTeste.parar,
                          tamanho: 16,
                          cor: cores.textoDiscreto,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Segure para encerrar',
                          style: TipografiaTeste.next(
                            14,
                            cor: cores.textoDiscreto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  /// Botão redondo de 48 dp no canto das telas escuras.
  static Widget canto({
    Key? key,
    required VoidCallback aoConcluir,
    required Color corBorda,
    required Color corIcone,
    Color fundo = Colors.transparent,
  }) =>
      BotaoSegurar(
        key: key,
        aoConcluir: aoConcluir,
        construtor: (context, progresso) => SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _AnelProgresso(
              progresso: progresso,
              cor: corIcone,
              largura: 1.5,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: fundo,
                shape: BoxShape.circle,
                border: Border.all(color: corBorda),
              ),
              alignment: Alignment.center,
              child: IconeSvg(IconesTeste.parar, tamanho: 16, cor: corIcone),
            ),
          ),
        ),
      );

  /// Botão "Segure 2 s para encerrar" da confirmação de saída (E3).
  static Widget confirmacao({Key? key, required VoidCallback aoConcluir}) =>
      BotaoSegurar(
        key: key,
        aoConcluir: aoConcluir,
        semantica: 'Encerrar: segure por 2 segundos',
        construtor: (context, progresso) {
          final cores = TemaTeste.of(context);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                border: Border.all(color: CoresFase.saidaSegurarBorda),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: const ColoredBox(
                        color: CoresFase.saidaSegurarPreenchimento,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CustomPaint(
                            painter: _AnelProgresso(
                              progresso: progresso,
                              cor: cores.texto,
                              corFundo: CoresFase.saidaAnel,
                              largura: 2 * 22 / 24,
                              raioFracao: 9 / 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Segure 2 s para encerrar',
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
                ],
              ),
            ),
          );
        },
      );

  @override
  State<BotaoSegurar> createState() => _BotaoSegurarState();
}

class _BotaoSegurarState extends State<BotaoSegurar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progresso = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..addStatusListener(_aoMudarStatus);

  int? _ponteiro;

  void _aoMudarStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _ponteiro = null;
      _progresso.value = 0;
      widget.aoConcluir();
    }
  }

  void _comecar(PointerDownEvent evento) {
    if (_ponteiro != null) return;
    _ponteiro = evento.pointer;
    _progresso.forward(from: 0);
  }

  void _soltar(PointerEvent evento) {
    if (evento.pointer != _ponteiro) return;
    _ponteiro = null;
    if (_progresso.isAnimating) {
      _progresso.stop();
      _progresso.value = 0;
    }
  }

  @override
  void dispose() {
    _progresso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.semantica,
        onLongPress: widget.aoConcluir,
        excludeSemantics: true,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _comecar,
          onPointerUp: _soltar,
          onPointerCancel: _soltar,
          child: AnimatedBuilder(
            animation: _progresso,
            builder: (context, _) =>
                widget.construtor(context, _progresso.value),
          ),
        ),
      );
}

/// Anel com o arco de progresso começando no topo, no sentido horário.
class _AnelProgresso extends CustomPainter {
  _AnelProgresso({
    required this.progresso,
    required this.cor,
    this.corFundo,
    this.largura = 2,
    this.raioFracao,
  });

  final double progresso;
  final Color cor;
  final Color? corFundo;
  final double largura;

  /// Raio como fração do lado; padrão: encostado na borda.
  final double? raioFracao;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = raioFracao != null
        ? size.shortestSide * raioFracao!
        : size.shortestSide / 2 - largura / 2;
    final retangulo = Rect.fromCircle(center: centro, radius: raio);
    if (corFundo != null) {
      canvas.drawCircle(
        centro,
        raio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = largura
          ..color = corFundo!,
      );
    }
    if (progresso <= 0) return;
    canvas.drawArc(
      retangulo,
      -math.pi / 2,
      2 * math.pi * progresso,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = largura
        ..strokeCap = StrokeCap.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(_AnelProgresso oldDelegate) =>
      oldDelegate.progresso != progresso || oldDelegate.cor != cor;
}
