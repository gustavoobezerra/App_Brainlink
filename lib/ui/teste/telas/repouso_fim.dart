import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela `Repouso-fim` do design: "Pode abrir os olhos." (sempre escura).
class TelaRepousoFim extends StatelessWidget {
  const TelaRepousoFim({super.key, required this.aoContinuar});

  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) => TemaTeste(
        sempreEscuro: true,
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            return PaginaTeste(
              fundo: CoresFase.repousoFimFundo,
              children: [
                Expanded(
                  child: ColunaTeste(
                    espaco: 18,
                    principal: MainAxisAlignment.center,
                    alinhamento: CrossAxisAlignment.center,
                    children: [
                      const CirculoIcone(
                        figura: IconesTeste.olho,
                        diametro: 64,
                        tamanhoIcone: 32,
                        fundo: CoresFase.repousoFimCirculo,
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          'Pode abrir os olhos.',
                          textAlign: TextAlign.center,
                          style: TipografiaTeste.next(
                            30,
                            peso: FontWeight.w700,
                            cor: cores.texto,
                          ),
                        ),
                      ),
                      Text(
                        'Respire normalmente. Sem pressa.',
                        textAlign: TextAlign.center,
                        style: TipografiaTeste.next(18, cor: cores.textoSuave),
                      ),
                    ],
                  ),
                ),
                BotaoTeste(
                  texto: 'Continuar',
                  aoTocar: aoContinuar,
                  estilo: EstiloBotao.secundario,
                ),
              ],
            );
          },
        ),
      );
}
