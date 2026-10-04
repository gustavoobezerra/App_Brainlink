import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tema_teste.dart';

/// Traçado pequeno e calmo do sinal ao vivo, para o pesquisador.
///
/// Sem dados, desenha a linha tracejada do design (`#3A4A63`, traço 4 6).
/// Com dados, uma linha fina (`#6F819C`, 1,25) dos últimos segundos, com
/// escala simétrica entre 20 e 150 µV para não "saltar" a cada lote.
class TracadoSinal extends StatelessWidget {
  const TracadoSinal({super.key, required this.microvolts, this.altura = 40});

  /// Amostras recentes, em µV; nulo ou vazio quando não há sinal.
  final List<double>? microvolts;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: CustomPaint(
          painter: _PintorTracado(
            amostras: microvolts,
            cor: cores.tracado,
            corVazio: cores.tracadoVazio,
          ),
        ),
      ),
    );
  }
}

class _PintorTracado extends CustomPainter {
  _PintorTracado({
    required this.amostras,
    required this.cor,
    required this.corVazio,
  });

  final List<double>? amostras;
  final Color cor;
  final Color corVazio;

  static const int _pontosMaximos = 160;

  @override
  void paint(Canvas canvas, Size size) {
    final dados = amostras;
    // A escala vertical segue o viewBox de 40 de altura do design.
    final escalaY = size.height / 40;
    if (dados == null || dados.isEmpty) {
      final pincel = Paint()
        ..color = corVazio
        ..strokeWidth = 1.25 * escalaY
        ..style = PaintingStyle.stroke;
      final meio = size.height / 2;
      final passo = size.width / 300;
      for (var x = 0.0; x < 300; x += 10) {
        canvas.drawLine(
          Offset(x * passo, meio),
          Offset(math.min(x + 4, 300) * passo, meio),
          pincel,
        );
      }
      return;
    }
    var maximo = 0.0;
    for (final valor in dados) {
      if (valor.isFinite) maximo = math.max(maximo, valor.abs());
    }
    final amplitude = maximo.clamp(20.0, 150.0);
    final passo = math.max(1, (dados.length / _pontosMaximos).ceil());
    final caminho = Path();
    var primeiro = true;
    final quantidade = (dados.length / passo).ceil();
    for (var i = 0; i < quantidade; i++) {
      final valor = dados[math.min(i * passo, dados.length - 1)];
      final normalizado =
          valor.isFinite ? (valor / amplitude).clamp(-1.0, 1.0) : 0.0;
      final x = quantidade <= 1 ? 0.0 : size.width * i / (quantidade - 1);
      // Mantém a margem do design (pontos entre y = 4 e y = 36).
      final y = size.height / 2 - normalizado * 16 * escalaY;
      if (primeiro) {
        caminho.moveTo(x, y);
        primeiro = false;
      } else {
        caminho.lineTo(x, y);
      }
    }
    canvas.drawPath(
      caminho,
      Paint()
        ..color = cor
        ..strokeWidth = 1.25
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_PintorTracado oldDelegate) =>
      !identical(oldDelegate.amostras, amostras) ||
      oldDelegate.cor != cor ||
      oldDelegate.corVazio != corVazio;
}
