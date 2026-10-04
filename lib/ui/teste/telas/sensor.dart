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
                CartaoTeste(
                  padding: const EdgeInsets.all(16),
                  child: LinhaTeste(
                    espaco: 16,
                    children: [
                      IconeSvg(
                        IconesTeste.cabecaSensor(cores),
                        largura: 132,
                        altura: 124,
                      ),
                      Expanded(
                        child: ColunaTeste(
                          espaco: 12,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Sensor na testa',
                                    style: TipografiaTeste.next(
                                      16,
                                      peso: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ', sem cabelo entre o sensor e a '
                                        'pele.',
                                  ),
                                ],
                              ),
                              style: TipografiaTeste.next(
                                16,
                                altura: 1.35,
                                cor: cores.texto,
                              ),
                            ),
                            Text(
                              'Clipe na orelha, se o seu headset tiver.',
                              style: TipografiaTeste.next(
                                16,
                                altura: 1.35,
                                cor: cores.textoSuave,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                cartao,
                QuadroPesquisador(
                  child: ColunaTeste(
                    espaco: 8,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PESQUISADOR · SINAL AO VIVO',
                              style: estiloMono,
                            ),
                          ),
                          if (simulada) ...[
                            const SeloSimulado(compacto: true),
                            const SizedBox(width: 8),
                          ],
                          Text(rotuloSinal, style: estiloMono),
                        ],
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
