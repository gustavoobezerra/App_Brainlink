import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/pagina_teste.dart';
import 'calibracao_resultado.dart';

/// Poucas piscadas na calibração (design `Erro-calibracao`).
class TelaCalibracaoErro extends StatelessWidget {
  const TelaCalibracaoErro({
    super.key,
    required this.porBipe,
    required this.aoRepetir,
    required this.aoContinuarMesmoAssim,
  });

  /// Para cada bipe, se a piscada apareceu no sinal.
  final List<bool> porBipe;
  final VoidCallback aoRepetir;
  final VoidCallback aoContinuarMesmoAssim;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            return PaginaTeste(
              espaco: 24,
              children: [
                const CabecalhoEtapa(etapa: 2, rotulo: 'Calibração'),
                Expanded(
                  child: ColunaTeste(
                    espaco: 16,
                    principal: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Vamos repetir a calibração?',
                          style: TipografiaTeste.next(
                            28,
                            peso: FontWeight.w700,
                            altura: 1.25,
                            cor: cores.texto,
                          ),
                        ),
                      ),
                      Text(
                        'Algumas piscadas não apareceram no sinal. Isso é '
                        'comum e leva só 20 segundos.',
                        style: TipografiaTeste.next(
                          19,
                          altura: 1.45,
                          cor: cores.textoSecundario,
                        ),
                      ),
                      Text(
                        'Dica: pisque de forma firme, uma vez a cada bipe.',
                        style: TipografiaTeste.next(
                          18,
                          altura: 1.45,
                          cor: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                QuadroPiscadas(
                  porBipe: porBipe,
                  corContagem: cores.ambarTitulo,
                ),
                ColunaTeste(
                  espaco: 12,
                  children: [
                    BotaoTeste(
                      texto: 'Repetir calibração',
                      aoTocar: aoRepetir,
                      icone: IconesTeste.repetir,
                      tamanhoIcone: 20,
                    ),
                    BotaoTeste(
                      texto: 'Continuar mesmo assim',
                      aoTocar: aoContinuarMesmoAssim,
                      estilo: EstiloBotao.contorno,
                      tamanhoTexto: 18,
                      peso: FontWeight.w600,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}
