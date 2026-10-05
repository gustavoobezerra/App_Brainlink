import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tema_teste.dart';

/// Página no formato do protótipo de 390 × 844.
///
/// Reproduz o `display: flex; flex-direction: column; gap` do design: os
/// filhos são separados por [espaco] e um [Spacer] equivale ao
/// `<div style="flex: 1">`. Quando o conteúdo não cabe (tela pequena ou texto
/// ampliado), a página rola em vez de cortar.
///
/// O [padding] é o do design; o recuo de cima e de baixo nunca fica menor que
/// a área ocupada pelas barras do sistema.
class PaginaTeste extends StatelessWidget {
  const PaginaTeste({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 40, 24, 32),
    this.espaco = 24,
    this.fundo,
    this.alinhamento = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double espaco;

  /// Cor de fundo; por padrão, `CoresTeste.fundo`.
  final Color? fundo;
  final CrossAxisAlignment alinhamento;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final insets = MediaQuery.paddingOf(context);
    final recuo = EdgeInsets.fromLTRB(
      padding.left + insets.left,
      math.max(padding.top, insets.top + 12),
      padding.right + insets.right,
      math.max(padding.bottom, insets.bottom + 12),
    );
    return Material(
      color: fundo ?? cores.fundo,
      child: LayoutBuilder(
        builder: (context, limites) => SingleChildScrollView(
          padding: recuo,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, limites.maxHeight - recuo.vertical),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: alinhamento,
                children: comEspacos(children, espaco),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Intercala `SizedBox` de [espaco] entre os widgets, como o `gap` do CSS.
List<Widget> comEspacos(List<Widget> filhos, double espaco,
    {Axis eixo = Axis.vertical}) {
  final resultado = <Widget>[];
  for (var i = 0; i < filhos.length; i++) {
    if (i > 0) {
      resultado.add(
        eixo == Axis.vertical
            ? SizedBox(height: espaco)
            : SizedBox(width: espaco),
      );
    }
    resultado.add(filhos[i]);
  }
  return resultado;
}

/// Coluna com `gap`, para blocos internos das telas.
class ColunaTeste extends StatelessWidget {
  const ColunaTeste({
    super.key,
    required this.children,
    this.espaco = 0,
    this.alinhamento = CrossAxisAlignment.stretch,
    this.principal = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final double espaco;
  final CrossAxisAlignment alinhamento;
  final MainAxisAlignment principal;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: principal,
        crossAxisAlignment: alinhamento,
        children: comEspacos(children, espaco),
      );
}

/// Linha com `gap`, para blocos internos das telas.
class LinhaTeste extends StatelessWidget {
  const LinhaTeste({
    super.key,
    required this.children,
    this.espaco = 0,
    this.alinhamento = CrossAxisAlignment.center,
    this.principal = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final double espaco;
  final CrossAxisAlignment alinhamento;
  final MainAxisAlignment principal;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: principal,
        crossAxisAlignment: alinhamento,
        children: comEspacos(children, espaco, eixo: Axis.horizontal),
      );
}
