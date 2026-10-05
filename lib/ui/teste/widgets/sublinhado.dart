import 'package:flutter/material.dart';

/// Texto sublinhado com afastamento da linha de base, como o
/// `text-underline-offset` do CSS (o Flutter não tem esse ajuste).
class TextoSublinhado extends StatelessWidget {
  const TextoSublinhado(
    this.texto, {
    super.key,
    required this.estilo,
    required this.deslocamento,
  });

  final String texto;
  final TextStyle estilo;

  /// Distância, em pixels lógicos, entre a linha de base e o sublinhado.
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
    // A linha de base é medida com a entrelinha proporcional (o padrão do
    // Flutter): os deslocamentos das telas foram ajustados ao design com
    // essa medida.
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: estilo.copyWith(
          leadingDistribution: TextLeadingDistribution.proportional,
        ),
      ),
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
