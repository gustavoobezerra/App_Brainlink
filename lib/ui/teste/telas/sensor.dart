import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/cartao_contato.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';
import '../widgets/tracado_sinal.dart';

/// "Coloque o sensor" (designs `Sensor-procurando`, `Sensor-ajuste` e
/// `Sensor-contato-bom`).
///
/// Tocar no cartão de contato abre a lista de aparelhos.
class TelaSensor extends StatelessWidget {
  const TelaSensor({
    super.key,
    required this.estado,
    required this.segundosEstaveis,
    required this.tracado,
    required this.simulada,
    required this.aoContinuar,
    required this.aoAbrirDispositivos,
  });

  final EstadoContato estado;

  /// Segundos seguidos de contato bom (0 a 10).
  final int segundosEstaveis;

  /// Amostras recentes em µV; nulo sem sinal.
  final List<double>? tracado;
  final bool simulada;

  /// Nulo deixa "Continuar" desabilitado.
  final VoidCallback? aoContinuar;
  final VoidCallback aoAbrirDispositivos;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final segundos = segundosEstaveis.clamp(0, 10);
            final cartao = switch (estado) {
              EstadoContato.procurando => CartaoContato(
                  estado: estado,
                  titulo: 'Procurando sinal…',
                  subtitulo: 'Ligue o headset e aguarde.',
                  aoTocar: aoAbrirDispositivos,
                ),
              EstadoContato.ajuste => CartaoContato(
                  estado: estado,
                  titulo: 'Ajuste o sensor',
                  subtitulo: 'Encoste bem na testa, sem cabelo no meio.',
                  aoTocar: aoAbrirDispositivos,
                ),
              EstadoContato.bom => CartaoContato(
                  estado: estado,
                  titulo: 'Contato bom',
                  subtitulo: 'Estável por $segundos '
                      '${segundos == 1 ? 'segundo' : 'segundos'}.',
                  segmentosEstaveis: segundos,
                  aoTocar: aoAbrirDispositivos,
                ),
            };
            final rotuloSinal = switch (estado) {
              EstadoContato.procurando => 'sem dados',
              EstadoContato.ajuste => 'contato instável',
              EstadoContato.bom => 'estável',
            };
            final estiloMono = TipografiaTeste.mono(
              12,
              cor: cores.textoDiscreto,
              espacamentoEm: 0.04,
            );
            return PaginaTeste(
              espaco: 20,
              children: [
                const CabecalhoEtapa(etapa: 1, rotulo: 'Preparação do sensor'),
                Semantics(
                  header: true,
                  child: Text(
                    'Coloque o sensor',
                    style: TipografiaTeste.next(
                      28,
                      peso: FontWeight.w700,
                      altura: 1.2,
                      cor: cores.texto,
                    ),
                  ),
                ),
                const _FiguraSensor(),
                cartao,
                QuadroPesquisador(
                  child: ColunaTeste(
                    espaco: 8,
                    children: [
                      _LinhaPesquisador(
                        estilo: estiloMono,
                        rotulo: rotuloSinal,
                        simulada: simulada,
                      ),
                      TracadoSinal(microvolts: tracado),
                    ],
                  ),
                ),
                const Spacer(),
                BotaoTeste(texto: 'Continuar', aoTocar: aoContinuar),
              ],
            );
          },
        ),
      );
}

/// Figura "Sensor na testa" com a legenda ao lado.
///
/// No design a figura de 132 px encolhe junto com a legenda (`flex-shrink`
/// do CSS, proporcional à largura natural de cada uma); aqui os fatores de
/// [Flexible] reproduzem essa divisão.
class _FiguraSensor extends StatelessWidget {
  const _FiguraSensor();

  static const double _larguraFigura = 132;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final base = TipografiaTeste.next(16, altura: 1.35, cor: cores.texto);
    final legenda1 = TextSpan(
      style: base,
      children: [
        TextSpan(
          text: 'Sensor na testa',
          style: TipografiaTeste.next(16, peso: FontWeight.w700),
        ),
        const TextSpan(text: ', sem cabelo entre o sensor e a pele.'),
      ],
    );
    final legenda2 = TextSpan(
      text: 'Clipe na orelha, se o seu headset tiver.',
      style: base.copyWith(color: cores.textoSuave),
    );
    final escala = MediaQuery.textScalerOf(context);
    double natural(InlineSpan texto) => _larguraNatural(texto, escala);

    final larguraLegenda =
        [natural(legenda1), natural(legenda2)].reduce((a, b) => a > b ? a : b);
    return CartaoTeste(
      padding: const EdgeInsets.all(16),
      child: LinhaTeste(
        espaco: 16,
        children: [
          Flexible(
            flex: (_larguraFigura * 10).round(),
            child: IconeSvg(
              IconesTeste.cabecaSensor(cores),
              largura: _larguraFigura,
              altura: 124,
            ),
          ),
          Flexible(
            flex: (larguraLegenda * 10).round().clamp(1, 1 << 30),
            child: ColunaTeste(
              espaco: 12,
              children: [Text.rich(legenda1), Text.rich(legenda2)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha "PESQUISADOR · SINAL AO VIVO" + estado, como o `display: flex;
/// justify-content: space-between` do design: quando não cabem, os dois
/// lados encolhem na proporção da largura natural e quebram linha.
class _LinhaPesquisador extends StatelessWidget {
  const _LinhaPesquisador({
    required this.estilo,
    required this.rotulo,
    required this.simulada,
  });

  static const String _titulo = 'PESQUISADOR · SINAL AO VIVO';
  static const double _espacoSelo = 8;

  final TextStyle estilo;
  final String rotulo;
  final bool simulada;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context);
    double natural(String texto, TextStyle estilo) =>
        _larguraNatural(TextSpan(text: texto, style: estilo), escala);

    final larguraSelo = simulada
        ? natural(
              'SIMULADO',
              TipografiaTeste.mono(
                12,
                cor: TemaTeste.of(context).ambarTitulo,
                espacamentoEm: 0.04,
              ),
            ) +
            _espacoSelo
        : 0.0;
    int fator(double largura) => (largura * 10).round().clamp(1, 1 << 30);
    final direita = Text(rotulo, style: estilo);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: fator(natural(_titulo, estilo)),
          child: Text(_titulo, style: estilo),
        ),
        Flexible(
          flex: fator(natural(rotulo, estilo) + larguraSelo),
          child: simulada
              // Quebra entre o selo e o rótulo, nunca no meio da palavra.
              ? Wrap(
                  alignment: WrapAlignment.end,
                  spacing: _espacoSelo,
                  children: [const SeloSimulado(compacto: true), direita],
                )
              : direita,
        ),
      ],
    );
  }
}

/// Largura de [texto] numa linha só, sem limite (a largura "natural" do CSS).
double _larguraNatural(InlineSpan texto, TextScaler escala) {
  final pintor = TextPainter(
    text: texto,
    textDirection: TextDirection.ltr,
    textScaler: escala,
  )..layout();
  final largura = pintor.width;
  pintor.dispose();
  return largura;
}
