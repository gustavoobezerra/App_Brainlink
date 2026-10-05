import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'svg_path.dart';

enum _TipoPintura { herdar, nenhuma, atual, cor }

/// Valor de `fill`/`stroke` de um elemento SVG.
@immutable
class PinturaSvg {
  const PinturaSvg._(this._tipo, [this._cor]);

  /// Usa o valor definido no `<svg>` raiz.
  static const PinturaSvg herdar = PinturaSvg._(_TipoPintura.herdar);

  /// `none`.
  static const PinturaSvg nenhuma = PinturaSvg._(_TipoPintura.nenhuma);

  /// `currentColor`: a cor passada ao [IconeSvg].
  static const PinturaSvg atual = PinturaSvg._(_TipoPintura.atual);

  /// Cor fixa.
  const PinturaSvg.cor(Color cor) : this._(_TipoPintura.cor, cor);

  final _TipoPintura _tipo;
  final Color? _cor;

  bool get herda => _tipo == _TipoPintura.herdar;

  Color? resolver(Color corAtual) => switch (_tipo) {
        _TipoPintura.herdar => null,
        _TipoPintura.nenhuma => null,
        _TipoPintura.atual => corAtual,
        _TipoPintura.cor => _cor,
      };
}

/// Elemento desenhável de uma [FiguraSvg].
@immutable
abstract class ElementoSvg {
  const ElementoSvg({
    this.preenchimento = PinturaSvg.herdar,
    this.traco = PinturaSvg.herdar,
    this.espessura,
    this.tracejado,
  });

  final PinturaSvg preenchimento;
  final PinturaSvg traco;

  /// `stroke-width`; nulo herda da figura.
  final double? espessura;

  /// `stroke-dasharray`, em unidades do `viewBox`.
  final List<double>? tracejado;

  Path caminho();
}

/// `<path d="…">`.
class CaminhoSvg extends ElementoSvg {
  const CaminhoSvg(
    this.d, {
    super.preenchimento,
    super.traco,
    super.espessura,
    super.tracejado,
  });

  final String d;

  static final Map<String, Path> _cache = {};

  @override
  Path caminho() => _cache.putIfAbsent(d, () => caminhoSvg(d));
}

/// `<rect x y width height rx>`.
class RetanguloSvg extends ElementoSvg {
  const RetanguloSvg(
    this.x,
    this.y,
    this.largura,
    this.altura, {
    this.rx = 0,
    super.preenchimento,
    super.traco,
    super.espessura,
  });

  final double x;
  final double y;
  final double largura;
  final double altura;
  final double rx;

  @override
  Path caminho() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, largura, altura),
        Radius.circular(rx),
      ),
    );
}

/// `<circle cx cy r>`.
class CirculoSvg extends ElementoSvg {
  const CirculoSvg(
    this.cx,
    this.cy,
    this.r, {
    super.preenchimento,
    super.traco,
    super.espessura,
  });

  final double cx;
  final double cy;
  final double r;

  @override
  Path caminho() =>
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
}

/// `<polyline points="…">`, com os pontos em pares `x,y`.
class PolilinhaSvg extends ElementoSvg {
  const PolilinhaSvg(
    this.pontos, {
    super.preenchimento,
    super.traco,
    super.espessura,
  });

  final List<double> pontos;

  @override
  Path caminho() {
    final path = Path();
    for (var i = 0; i + 1 < pontos.length; i += 2) {
      if (i == 0) {
        path.moveTo(pontos[i], pontos[i + 1]);
      } else {
        path.lineTo(pontos[i], pontos[i + 1]);
      }
    }
    return path;
  }
}

/// Um `<svg>` com `viewBox`, atributos herdáveis e elementos.
@immutable
class FiguraSvg {
  const FiguraSvg({
    required this.largura,
    required this.altura,
    required this.elementos,
    this.preenchimento = const PinturaSvg.cor(Color(0xFF000000)),
    this.traco = PinturaSvg.nenhuma,
    this.espessura = 1,
    this.pontaRedonda = false,
    this.juncaoRedonda = false,
  });

  /// Ícone de linha do protótipo: `viewBox="0 0 24 24"`, `fill="none"`,
  /// `stroke="currentColor"` e pontas/junções arredondadas.
  const FiguraSvg.linha24({
    required this.elementos,
    this.espessura = 1.75,
    this.juncaoRedonda = true,
  })  : largura = 24,
        altura = 24,
        preenchimento = PinturaSvg.nenhuma,
        traco = PinturaSvg.atual,
        pontaRedonda = true;

  final double largura;
  final double altura;
  final List<ElementoSvg> elementos;
  final PinturaSvg preenchimento;
  final PinturaSvg traco;
  final double espessura;
  final bool pontaRedonda;
  final bool juncaoRedonda;

  /// Cópia com outro `stroke-width` na raiz.
  FiguraSvg comEspessura(double novaEspessura) => FiguraSvg(
        largura: largura,
        altura: altura,
        elementos: elementos,
        preenchimento: preenchimento,
        traco: traco,
        espessura: novaEspessura,
        pontaRedonda: pontaRedonda,
        juncaoRedonda: juncaoRedonda,
      );
}

/// Desenha uma [FiguraSvg] com a semântica do SVG.
class PintorSvg extends CustomPainter {
  PintorSvg(this.figura, this.corAtual, {this.esticar = false});

  final FiguraSvg figura;
  final Color corAtual;

  /// `preserveAspectRatio="none"`; caso contrário, `xMidYMid meet`.
  final bool esticar;

  @override
  void paint(Canvas canvas, Size size) {
    var escalaX = size.width / figura.largura;
    var escalaY = size.height / figura.altura;
    var deslocX = 0.0;
    var deslocY = 0.0;
    if (!esticar) {
      final escala = math.min(escalaX, escalaY);
      deslocX = (size.width - figura.largura * escala) / 2;
      deslocY = (size.height - figura.altura * escala) / 2;
      escalaX = escala;
      escalaY = escala;
    }
    canvas.save();
    canvas.translate(deslocX, deslocY);
    canvas.scale(escalaX, escalaY);
    for (final elemento in figura.elementos) {
      final path = elemento.caminho();
      final corPreenchimento = (elemento.preenchimento.herda
              ? figura.preenchimento
              : elemento.preenchimento)
          .resolver(corAtual);
      if (corPreenchimento != null) {
        canvas.drawPath(
          path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = corPreenchimento,
        );
      }
      final corTraco = (elemento.traco.herda ? figura.traco : elemento.traco)
          .resolver(corAtual);
      final espessura = elemento.espessura ?? figura.espessura;
      if (corTraco != null && espessura > 0) {
        final tracejado = elemento.tracejado;
        canvas.drawPath(
          tracejado == null ? path : tracejar(path, tracejado),
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = espessura
            ..strokeCap = figura.pontaRedonda ? StrokeCap.round : StrokeCap.butt
            ..strokeJoin =
                figura.juncaoRedonda ? StrokeJoin.round : StrokeJoin.miter
            ..color = corTraco,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorSvg oldDelegate) =>
      oldDelegate.figura != figura ||
      oldDelegate.corAtual != corAtual ||
      oldDelegate.esticar != esticar;
}

/// Divide [origem] em traços, como o `stroke-dasharray` do SVG: [padrao]
/// alterna comprimentos de traço e de vão, repetidos ao longo de cada
/// contorno. Um padrão vazio (ou só de zeros) devolve o caminho original.
Path tracejar(Path origem, List<double> padrao) {
  final resultado = Path();
  if (padrao.isEmpty || padrao.every((v) => v <= 0)) return origem;
  for (final metrica in origem.computeMetrics()) {
    var distancia = 0.0;
    var indice = 0;
    var desenhar = true;
    while (distancia < metrica.length) {
      final comprimento = padrao[indice % padrao.length];
      final fim = math.min(distancia + comprimento, metrica.length);
      if (desenhar) {
        resultado.addPath(metrica.extractPath(distancia, fim), Offset.zero);
      }
      distancia += comprimento;
      desenhar = !desenhar;
      indice++;
    }
  }
  return resultado;
}

/// Ícone SVG decorativo (equivalente a `aria-hidden="true"`).
class IconeSvg extends StatelessWidget {
  const IconeSvg(
    this.figura, {
    super.key,
    this.tamanho = 24,
    this.largura,
    this.altura,
    this.cor,
    this.esticar = false,
  });

  final FiguraSvg figura;

  /// Lado do quadrado quando [largura]/[altura] não são informados.
  final double tamanho;
  final double? largura;
  final double? altura;

  /// `currentColor`; por padrão a cor do texto ao redor.
  final Color? cor;
  final bool esticar;

  @override
  Widget build(BuildContext context) {
    final corAtual = cor ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF000000);
    return ExcludeSemantics(
      child: SizedBox(
        width: largura ?? tamanho,
        height: altura ?? tamanho,
        child: CustomPaint(
          painter: PintorSvg(figura, corAtual, esticar: esticar),
        ),
      ),
    );
  }
}
