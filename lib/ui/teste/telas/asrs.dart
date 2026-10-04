import 'package:flutter/material.dart';

import '../../../data/models/asrs_screener_6.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/pagina_teste.dart';

/// Tela "ASRS" / "Claro-ASRS": uma pergunta do ASRS-6 por vez, com as cinco
/// respostas oficiais e os botões "Voltar" e "Próxima".
class TelaAsrs extends StatelessWidget {
  const TelaAsrs({
    super.key,
    required this.indice,
    required this.resposta,
    required this.aoResponder,
    required this.aoVoltar,
    required this.aoProxima,
  });

  /// Pergunta atual, de 0 a 5.
  final int indice;
  final AsrsResponse? resposta;
  final ValueChanged<AsrsResponse> aoResponder;

  /// Nulo desabilita "Voltar".
  final VoidCallback? aoVoltar;

  /// Nulo desabilita "Próxima".
  final VoidCallback? aoProxima;

  @override
  Widget build(BuildContext context) {
    final numero = indice + 1;
    final total = AsrsScreener6.questions.length;
    final pergunta = AsrsScreener6.questions[indice];
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return PaginaTeste(
            espaco: 22,
            children: [
              CabecalhoEtapa(
                etapa: numero,
                total: total,
                rotulo: 'Questionário · Pergunta $numero de $total',
                tamanhoRotulo: 15,
                rotuloSemantico: 'Pergunta $numero de $total',
              ),
              Semantics(
                header: true,
                child: Text(
                  pergunta,
                  style: TipografiaTeste.next(
                    22,
                    peso: FontWeight.w600,
                    altura: 1.4,
                    cor: cores.texto,
                  ),
                ),
              ),
              Semantics(
                container: true,
                label: pergunta,
                explicitChildNodes: true,
                child: ColunaTeste(
                  espaco: 10,
                  children: [
                    for (final opcao in AsrsResponse.values)
                      _OpcaoRadio(
                        texto: opcao.label,
                        selecionada: resposta == opcao,
                        aoTocar: () => aoResponder(opcao),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              IntrinsicHeight(
                child: LinhaTeste(
                  espaco: 12,
                  alinhamento: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: BotaoTeste(
                        texto: 'Voltar',
                        aoTocar: aoVoltar,
                        estilo: EstiloBotao.secundario,
                        tamanhoTexto: 18,
                        peso: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: BotaoTeste(
                        texto: 'Próxima',
                        aoTocar: aoProxima,
                        tamanhoTexto: 18,
                      ),
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
}

/// Opção de resposta (`role="radio"`): 60 px, raio 14, borda 2 e anel de 24.
class _OpcaoRadio extends StatelessWidget {
  const _OpcaoRadio({
    required this.texto,
    required this.selecionada,
    required this.aoTocar,
  });

  final String texto;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selecionada ? cores.acento : cores.borda,
        width: 2,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selecionada,
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: selecionada ? cores.selecionadoFundo : cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinhaTeste(
                espaco: 14,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selecionada ? cores.acentoIcone : cores.radioAnel,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selecionada
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cores.acentoIcone,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      texto,
                      style: TipografiaTeste.next(
                        19,
                        peso: selecionada ? FontWeight.w600 : FontWeight.w400,
                        cor: cores.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
