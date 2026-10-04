import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cartao_contato.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Erro-contato-perdido": teste pausado porque o sensor perdeu o
/// contato com a testa; retoma quando o contato volta.
class TelaContatoPerdido extends StatelessWidget {
  const TelaContatoPerdido({
    super.key,
    required this.faseRotulo,
    required this.momento,
    required this.contatoRecuperado,
    required this.simulada,
    required this.aoRetomar,
    required this.aoRecomecarFase,
  });

  final String faseRotulo;

  /// Tempo da fase em que o teste foi pausado.
  final Duration momento;
  final bool contatoRecuperado;
  final bool simulada;

  /// Nulo desabilita "Retomar".
  final VoidCallback? aoRetomar;
  final VoidCallback aoRecomecarFase;

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          final estiloPesquisador = TipografiaTeste.mono(
            12,
            cor: cores.textoDiscreto,
            espacamentoEm: 0.03,
          );
          final esquerda = 'PESQUISADOR · pausado em $faseRotulo, '
              '${formatarTempo(momento)}${simulada ? ' · simulado' : ''}';
          const direita = 'alerta + vibração longa';
          return PaginaTeste(
            espaco: 22,
            children: [
              _TestePausado(cores: cores),
              Expanded(
                child: ColunaTeste(
                  espaco: 22,
                  principal: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Reposicione o sensor',
                        style: TipografiaTeste.next(
                          30,
                          peso: FontWeight.w700,
                          altura: 1.2,
                          cor: cores.texto,
                        ),
                      ),
                    ),
                    Text(
                      'Pode abrir os olhos. Encoste o sensor na testa, sem '
                      'cabelo no meio. O teste continua de onde parou.',
                      style: TipografiaTeste.next(
                        19,
                        altura: 1.45,
                        cor: cores.textoSecundario,
                      ),
                    ),
                    contatoRecuperado
                        ? const CartaoContato(
                            estado: EstadoContato.bom,
                            titulo: 'Contato bom',
                            subtitulo: 'Pode retomar o teste.',
                            tamanhoTitulo: 22,
                            tamanhoSubtitulo: 16,
                          )
                        : const CartaoContato(
                            estado: EstadoContato.ajuste,
                            titulo: 'Sem contato',
                            subtitulo: 'Procurando o sinal de novo…',
                            tamanhoTitulo: 22,
                            tamanhoSubtitulo: 16,
                          ),
                    QuadroPesquisador(
                      // `justify-content: space-between` com os dois textos
                      // encolhendo na proporção do tamanho, como no CSS.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: esquerda.length,
                            child: Text(esquerda, style: estiloPesquisador),
                          ),
                          // Folga mínima para os textos não se encostarem.
                          const SizedBox(width: 8),
                          Expanded(
                            flex: direita.length,
                            child: Text(direita, style: estiloPesquisador),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ColunaTeste(
                espaco: 12,
                children: [
                  BotaoTeste(texto: 'Retomar', aoTocar: aoRetomar),
                  BotaoTeste(
                    texto: 'Recomeçar esta fase',
                    aoTocar: aoRecomecarFase,
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
}

/// Linha "Teste pausado" com o ícone de pausa (15 px, texto suave).
class _TestePausado extends StatelessWidget {
  const _TestePausado({required this.cores});

  final CoresTeste cores;

  @override
  Widget build(BuildContext context) => LinhaTeste(
        espaco: 10,
        children: [
          IconeSvg(IconesTeste.pausa, tamanho: 18, cor: cores.textoSuave),
          Flexible(
            child: Text(
              'Teste pausado',
              style: TipografiaTeste.next(15, cor: cores.textoSuave),
            ),
          ),
        ],
      );
}
