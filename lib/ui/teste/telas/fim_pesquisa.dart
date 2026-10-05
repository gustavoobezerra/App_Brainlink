import 'package:flutter/material.dart';

import '../tema/icones.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Fim-pesquisa": agradecimento e aviso de que o teste não é
/// diagnóstico (sem o botão "Ver serviços de atendimento", a pedido).
class TelaFimPesquisa extends StatelessWidget {
  const TelaFimPesquisa({super.key, required this.aoConcluir});

  final VoidCallback aoConcluir;

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return PaginaTeste(
            children: [
              Expanded(
                child: ColunaTeste(
                  espaco: 18,
                  principal: MainAxisAlignment.center,
                  alinhamento: CrossAxisAlignment.start,
                  children: [
                    const CirculoIcone(figura: IconesTeste.visto),
                    Semantics(
                      header: true,
                      child: Text(
                        'Obrigado!',
                        style: TipografiaTeste.next(
                          34,
                          peso: FontWeight.w700,
                          cor: cores.texto,
                        ),
                      ),
                    ),
                    Text(
                      'Sua participação foi registrada. Já pode tirar o '
                      'sensor.',
                      style: TipografiaTeste.next(
                        20,
                        altura: 1.4,
                        cor: cores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              CartaoTeste(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Este teste '),
                      TextSpan(
                        text: 'não é diagnóstico',
                        style: TipografiaTeste.next(
                          18,
                          peso: FontWeight.w700,
                          altura: 1.45,
                          cor: cores.texto,
                        ),
                      ),
                      const TextSpan(
                        text: '. Se quiser conversar sobre atenção, procure '
                            'um profissional.',
                      ),
                    ],
                  ),
                  style: TipografiaTeste.next(
                    18,
                    altura: 1.45,
                    cor: cores.texto,
                  ),
                ),
              ),
              BotaoTeste(texto: 'Concluir', aoTocar: aoConcluir),
            ],
          );
        },
      ),
    );
  }
}
