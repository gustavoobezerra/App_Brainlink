import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import 'pagina_teste.dart';

/// Indicador grande de contato do sensor (telas 2a, 2b, 2c e E1).
///
/// - procurando: borda `#33445F`, círculo tracejado;
/// - ajuste: âmbar, com exclamação;
/// - bom: verde, com visto e a barra de estabilidade de 10 segmentos.
class CartaoContato extends StatelessWidget {
  const CartaoContato({
    super.key,
    required this.estado,
    required this.titulo,
    required this.subtitulo,
    this.segmentosEstaveis,
    this.totalSegmentos = 10,
    this.tamanhoTitulo = 24,
    this.tamanhoSubtitulo,
    this.aoTocar,
  });

  final EstadoContato estado;
  final String titulo;
  final String subtitulo;

  /// Segmentos preenchidos da barra de estabilidade (só no estado bom).
  final int? segmentosEstaveis;
  final int totalSegmentos;
  final double tamanhoTitulo;

  /// Padrão: 16 (procurando) e 17 (ajuste e bom).
  final double? tamanhoSubtitulo;

  /// Toque opcional (abre a lista de aparelhos na tela do sensor).
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final (borda, fundo, corTitulo, corSubtitulo) = switch (estado) {
      EstadoContato.procurando => (
          cores.bordaForte,
          cores.fundoNeutro,
          cores.texto,
          cores.textoSuave,
        ),
      EstadoContato.ajuste => (
          cores.ambarBorda,
          cores.ambarFundo,
          cores.ambarTitulo,
          cores.ambarTexto,
        ),
      EstadoContato.bom => (
          cores.verde,
          cores.verdeFundo,
          cores.verdeTitulo,
          cores.verdeTexto,
        ),
    };
    final tamanhoSub =
        tamanhoSubtitulo ?? (estado == EstadoContato.procurando ? 16.0 : 17.0);
    final linha = LinhaTeste(
      espaco: 18,
      children: [
        _circulo(cores),
        Expanded(
          child: ColunaTeste(
            espaco: 6,
            children: [
              Text(
                titulo,
                style: TipografiaTeste.next(
                  tamanhoTitulo,
                  peso: FontWeight.w700,
                  cor: corTitulo,
                ),
              ),
              Text(
                subtitulo,
                style: TipografiaTeste.next(
                  tamanhoSub,
                  cor: corSubtitulo,
                  altura: estado == EstadoContato.ajuste ? 1.35 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final segmentos = segmentosEstaveis;
    final conteudo = estado == EstadoContato.bom && segmentos != null
        ? ColunaTeste(
            espaco: 14,
            children: [
              linha,
              Semantics(
                label: 'Estabilidade: $segmentos de $totalSegmentos segundos',
                child: ExcludeSemantics(
                  child: LinhaTeste(
                    espaco: 4,
                    children: [
                      for (var i = 0; i < totalSegmentos; i++)
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: i < segmentos
                                  ? cores.verde
                                  : cores.verde.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : linha;
    final cartao = Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borda, width: 2),
        ),
        child: conteudo,
      ),
    );
    if (aoTocar == null) return cartao;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: cartao,
    );
  }

  Widget _circulo(CoresTeste cores) => switch (estado) {
        EstadoContato.procurando => SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: _CirculoTracejado(cores.neutroIndicador),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cores.neutroIndicador,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        EstadoContato.ajuste => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cores.ambarBorda, width: 3),
            ),
            alignment: Alignment.center,
            child: IconeSvg(
              IconesTeste.exclamacao,
              tamanho: 28,
              cor: cores.ambarIcone,
            ),
          ),
        EstadoContato.bom => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cores.verde,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: IconeSvg(
              IconesTeste.visto.comEspessura(2.25),
              tamanho: 30,
              cor: cores.verdeIcone,
            ),
          ),
      };
}

/// Círculo de 60 px com borda tracejada de 3 px (`border: 3px dashed`).
class _CirculoTracejado extends CustomPainter {
  _CirculoTracejado(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    const largura = 3.0;
    final raio = size.shortestSide / 2 - largura / 2;
    final centro = size.center(Offset.zero);
    final pincel = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura;
    // Traços de ~3 × largura, como o tracejado padrão do navegador.
    final circunferencia = 2 * math.pi * raio;
    final quantidade = (circunferencia / (largura * 3 * 2)).floor();
    final passo = 2 * math.pi / quantidade;
    for (var i = 0; i < quantidade; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio),
        i * passo,
        passo / 2,
        false,
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_CirculoTracejado oldDelegate) => oldDelegate.cor != cor;
}
