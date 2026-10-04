import 'package:flutter/material.dart';

import '../tema/tema_teste.dart';
import 'pagina_teste.dart';

/// Barra discreta de etapas: segmentos de 4 px, `gap` 6, raio 2.
///
/// Mostra as etapas, não o tempo, para não gerar ansiedade.
class BarraEtapas extends StatelessWidget {
  const BarraEtapas({
    super.key,
    required this.atual,
    this.total = 7,
    this.rotuloSemantico,
  });

  /// Quantidade de segmentos preenchidos (1 a [total]).
  final int atual;
  final int total;

  /// Padrão: "Etapa N de 7".
  final String? rotuloSemantico;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Semantics(
      label: rotuloSemantico ?? 'Etapa $atual de $total',
      child: ExcludeSemantics(
        child: LinhaTeste(
          espaco: 6,
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < atual ? cores.acento : cores.progressoInativo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho das telas com etapa: barra + rótulo e, opcionalmente, uma ação
/// à direita (ex.: "Segure para encerrar").
class CabecalhoEtapa extends StatelessWidget {
  const CabecalhoEtapa({
    super.key,
    required this.etapa,
    required this.rotulo,
    this.total = 7,
    this.tamanhoRotulo = 14,
    this.acao,
    this.rotuloDireita,
    this.rotuloSemantico,
  });

  final int etapa;
  final String rotulo;
  final int total;
  final double tamanhoRotulo;

  /// Widget à direita do rótulo (alinhado ao centro).
  final Widget? acao;

  /// Texto à direita do rótulo, no mesmo estilo (ex.: "Som 4 de 10").
  final String? rotuloDireita;
  final String? rotuloSemantico;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final estilo = TipografiaTeste.next(tamanhoRotulo, cor: cores.textoSuave);
    final Widget linha;
    if (acao != null) {
      linha = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          acao!,
        ],
      );
    } else if (rotuloDireita != null) {
      linha = Row(
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          Text(rotuloDireita!, style: estilo),
        ],
      );
    } else {
      linha = Text(rotulo, style: estilo);
    }
    return ColunaTeste(
      espaco: 10,
      children: [
        BarraEtapas(
          atual: etapa,
          total: total,
          rotuloSemantico: rotuloSemantico,
        ),
        linha,
      ],
    );
  }
}
