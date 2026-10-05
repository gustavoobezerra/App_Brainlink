import 'package:flutter/material.dart';

import '../tema/tema_teste.dart';
import 'pagina_teste.dart';

/// Opção de escolha única (`role="radio"`): 60 px, raio 14, borda 2 e anel
/// de 24. Usada nas respostas do ASRS e nos cenários simulados.
class OpcaoRadioTeste extends StatelessWidget {
  const OpcaoRadioTeste({
    super.key,
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
