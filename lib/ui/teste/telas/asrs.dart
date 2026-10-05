import 'package:flutter/material.dart';

import '../../../data/models/asrs_screener_6.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/opcao_radio.dart';
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
                      OpcaoRadioTeste(
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
