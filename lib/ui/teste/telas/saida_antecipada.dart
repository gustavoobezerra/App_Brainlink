import 'package:flutter/material.dart';

import '../tema/tema_teste.dart';
import '../widgets/botao_segurar.dart';
import '../widgets/botao_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Erro-saida-antecipada": confirmação "Encerrar o teste?", sempre
/// escura, desenhada pelo host por cima da tela atual.
///
/// Ocupa a tela inteira: um véu `#02050B` a 85 % e o diálogo embaixo.
class SobreposicaoSaida extends StatelessWidget {
  const SobreposicaoSaida({
    super.key,
    required this.aoContinuar,
    required this.aoEncerrar,
  });

  final VoidCallback aoContinuar;
  final VoidCallback aoEncerrar;

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      sempreEscuro: true,
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return BlockSemantics(
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: CoresFase.saidaVeu.withValues(
                      alpha: CoresFase.saidaVeuOpacidade,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          child: _dialogo(cores),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogo(CoresTeste cores) => Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Encerrar o teste?',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cores.cartao,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cores.borda),
          ),
          child: ColunaTeste(
            espaco: 16,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Encerrar o teste?',
                  style: TipografiaTeste.next(
                    26,
                    peso: FontWeight.w700,
                    cor: cores.texto,
                  ),
                ),
              ),
              Text(
                'Os dados desta sessão não serão usados.',
                style: TipografiaTeste.next(
                  18,
                  altura: 1.45,
                  cor: cores.textoSecundario,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ColunaTeste(
                  espaco: 12,
                  children: [
                    BotaoTeste(
                      texto: 'Continuar o teste',
                      aoTocar: aoContinuar,
                    ),
                    BotaoSegurar.confirmacao(aoConcluir: aoEncerrar),
                  ],
                ),
              ),
              Text(
                'Também aparece ao apertar “voltar” no celular.',
                textAlign: TextAlign.center,
                style: TipografiaTeste.next(14, cor: cores.textoDiscreto),
              ),
            ],
          ),
        ),
      );
}
