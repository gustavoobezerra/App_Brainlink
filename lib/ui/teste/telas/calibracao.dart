import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_segurar.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Calibração das piscadas (design `Calibracao`).
///
/// O círculo interno cresce suavemente a cada bipe (100 → 148 px).
class TelaCalibracao extends StatelessWidget {
  const TelaCalibracao({
    super.key,
    required this.bipesTocados,
    required this.totalBipes,
    required this.piscadasDetectadas,
    required this.qualidade,
    required this.simulada,
    required this.aoSegurarEncerrar,
  });

  final int bipesTocados;
  final int totalBipes;
  final int piscadasDetectadas;
  final QualidadeSinal qualidade;
  final bool simulada;
  final VoidCallback aoSegurarEncerrar;

  static String rotuloQualidade(QualidadeSinal qualidade) =>
      switch (qualidade) {
        QualidadeSinal.boa => 'sinal bom',
        QualidadeSinal.ajuste => 'sinal instável',
        QualidadeSinal.ruim || QualidadeSinal.semDados => 'sem sinal',
      };

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final total = totalBipes < 1 ? 1 : totalBipes;
            final tocados = bipesTocados.clamp(0, total);
            // 100 px antes do primeiro bipe e +16 px por bipe: 148 px em 3 de 5,
            // como no design.
            final diametro = 100 + 80 * (tocados / total);
            final estiloMono = TipografiaTeste.mono(
              12,
              cor: cores.textoApagado,
              espacamentoEm: 0.04,
            );
            return PaginaTeste(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              espaco: 24,
              children: [
                CabecalhoEtapa(
                  etapa: 2,
                  rotulo: 'Calibração',
                  acao: BotaoSegurar.pilula(aoConcluir: aoSegurarEncerrar),
                ),
                Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Pisque '),
                        TextSpan(
                          text: 'uma vez',
                          style: TipografiaTeste.next(
                            26,
                            peso: FontWeight.w700,
                            cor: cores.acentoDestaque,
                          ),
                        ),
                        const TextSpan(text: ' cada\nvez que ouvir o bipe.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TipografiaTeste.next(
                      26,
                      peso: FontWeight.w600,
                      altura: 1.3,
                      cor: cores.texto,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ExcludeSemantics(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cores.circuloCalibracaoExterno,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                          width: diametro,
                          height: diametro,
                          decoration: BoxDecoration(
                            color: cores.selecionadoFundo,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cores.circuloCalibracaoBorda,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: cores.acento,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ColunaTeste(
                  espaco: 10,
                  alinhamento: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Bipe $tocados de $total',
                      child: ExcludeSemantics(
                        child: LinhaTeste(
                          espaco: 10,
                          principal: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < total; i++)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: i < tocados
                                      ? cores.acento
                                      : cores.progressoInativo,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        '$tocados de $total',
                        style: TipografiaTeste.next(18, cor: cores.textoSuave),
                      ),
                    ),
                  ],
                ),
                Semantics(
                  container: true,
                  label: 'Para o pesquisador',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PESQUISADOR · piscadas: $piscadasDetectadas'
                          '${simulada ? ' · simulado' : ''}',
                          style: estiloMono,
                        ),
                      ),
                      LinhaTeste(
                        espaco: 6,
                        children: [
                          PontoQualidade(qualidade: qualidade),
                          Text(rotuloQualidade(qualidade), style: estiloMono),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}
