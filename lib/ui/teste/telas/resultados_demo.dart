import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/elementos_teste.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Resultados-demo": o que o sensor registrou na demonstração, em
/// quatro cartões, com o rodapé "Demonstração de pesquisa. Não é
/// diagnóstico." fixo embaixo.
class TelaResultadosDemo extends StatelessWidget {
  const TelaResultadosDemo({
    super.key,
    required this.resumo,
    required this.simulada,
    required this.aoNovaDemonstracao,
  });

  final ResumoDemonstracao resumo;
  final bool simulada;
  final VoidCallback aoNovaDemonstracao;

  /// "+4 dB", "−3 dB" (sinal U+2212) ou "0 dB".
  static String formatarDb(int db) {
    if (db > 0) return '+$db dB';
    if (db < 0) return '−${db.abs()} dB';
    return '0 dB';
  }

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          final inferior = MediaQuery.paddingOf(context).bottom;
          return Material(
            color: cores.fundo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: PaginaTeste(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 18),
                      espaco: 18,
                      children: [
                        _cabecalho(cores),
                        _cartaoAlfa(cores),
                        _cartaoFases(cores),
                        _cartaoPiscadas(cores),
                        _cartaoTarefa(cores),
                        BotaoTeste(
                          texto: 'Nova demonstração',
                          aoTocar: aoNovaDemonstracao,
                          estilo: EstiloBotao.secundario,
                          tamanhoTexto: 18,
                          peso: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, 28 + inferior),
                  decoration: BoxDecoration(
                    color: cores.fundoPesquisador,
                    border: Border(top: BorderSide(color: cores.borda)),
                  ),
                  child: Text(
                    'Demonstração de pesquisa. Não é diagnóstico.',
                    textAlign: TextAlign.center,
                    style: TipografiaTeste.next(
                      16,
                      peso: FontWeight.w600,
                      cor: cores.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecalho(CoresTeste cores) => ColunaTeste(
        espaco: 12,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cores.selecionadoFundo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Modo demonstração',
                  style: TipografiaTeste.next(
                    14,
                    peso: FontWeight.w600,
                    cor: cores.acentoDestaque,
                  ),
                ),
              ),
              if (simulada) const SeloSimulado(),
            ],
          ),
          Semantics(
            header: true,
            child: Text(
              'O que o sensor registrou',
              style: TipografiaTeste.next(
                28,
                peso: FontWeight.w700,
                altura: 1.2,
                cor: cores.texto,
              ),
            ),
          ),
          Text(
            'Estes números descrevem só esta sessão. Não há comparação com '
            'outras pessoas.',
            style:
                TipografiaTeste.next(17, altura: 1.45, cor: cores.textoSuave),
          ),
        ],
      );

  Widget _cartaoAlfa(CoresTeste cores) {
    final db = resumo.alfaDb;
    final paragrafo = TipografiaTeste.next(
      17,
      altura: 1.45,
      cor: cores.textoSecundario,
    );
    return _Cartao(
      numero: '1',
      titulo: 'O sensor captou seu cérebro',
      espaco: 12,
      children: [
        if (db != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatarDb(db),
                style: TipografiaTeste.mono(
                  44,
                  peso: FontWeight.w500,
                  cor: cores.acentoDestaque,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'no ritmo alfa',
                  style: TipografiaTeste.next(16, cor: cores.textoSuave),
                ),
              ),
            ],
          ),
          Text(
            db > 0
                ? 'O ritmo alfa subiu quando você fechou os olhos. É esse o '
                    'sinal que mostra que o sensor está lendo a atividade do '
                    'cérebro.'
                : 'O ritmo alfa não subiu quando você fechou os olhos.',
            style: paragrafo,
          ),
        ] else
          Text(
            resumo.motivoAlfaDb ?? '',
            style: TipografiaTeste.next(17, cor: cores.textoSecundario),
          ),
      ],
    );
  }

  Widget _cartaoFases(CoresTeste cores) {
    final valores = resumo.alfaPorFase;
    const rotulos = ['Repouso', 'Tarefa', 'Repouso final'];
    return _Cartao(
      numero: '2',
      titulo: 'Seu cérebro trocou de estado',
      espaco: 14,
      children: [
        if (valores != null && valores.length >= 3) ...[
          ColunaTeste(
            espaco: 10,
            children: [
              Semantics(
                label: 'Ritmo alfa por fase: '
                    '${[
                  for (var i = 0; i < 3; i++)
                    '${rotulos[i].toLowerCase()} '
                        '${(valores[i].clamp(0.0, 1.0) * 100).round()}%',
                ].join(', ')}',
                child: ExcludeSemantics(
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cores.bordaForte),
                      ),
                    ),
                    child: LinhaTeste(
                      espaco: 18,
                      alinhamento: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: Container(
                              height: math.max(
                                4,
                                140 * valores[i].clamp(0.0, 1.0),
                              ),
                              decoration: BoxDecoration(
                                color: cores.acento,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LinhaTeste(
                    espaco: 18,
                    alinhamento: CrossAxisAlignment.start,
                    children: [
                      for (final rotulo in rotulos)
                        Expanded(
                          child: Text(
                            rotulo,
                            textAlign: TextAlign.center,
                            style: TipografiaTeste.next(
                              15,
                              cor: cores.textoSecundario,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Ritmo alfa em cada fase. Quando o cérebro se concentra em uma '
            'tarefa, o alfa costuma diminuir.',
            style: TipografiaTeste.next(
              17,
              altura: 1.45,
              cor: cores.textoSecundario,
            ),
          ),
        ] else
          Text(
            resumo.motivoAlfaPorFase ?? '',
            style: TipografiaTeste.next(17, cor: cores.textoSecundario),
          ),
      ],
    );
  }

  Widget _cartaoPiscadas(CoresTeste cores) => _Cartao(
        numero: '3',
        titulo: 'Piscadas',
        espaco: 10,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Detectamos '),
                TextSpan(
                  text: '${resumo.piscadasDetectadas} de '
                      '${resumo.piscadasTotal}',
                  style: TipografiaTeste.next(
                    18,
                    peso: FontWeight.w700,
                    altura: 1.45,
                    cor: cores.texto,
                  ),
                ),
                const TextSpan(text: ' na calibração.'),
              ],
            ),
            style: TipografiaTeste.next(
              18,
              altura: 1.45,
              cor: cores.textoSecundario,
            ),
          ),
        ],
      );

  Widget _cartaoTarefa(CoresTeste cores) {
    final auditiva = resumo.versao == VersaoTeste.auditiva;
    final tempo = resumo.tempoMedioMs;
    final motivo = tempo == null ? resumo.motivoTempoMedio : null;
    return _Cartao(
      numero: '4',
      titulo: 'Sua tarefa',
      espaco: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinhaDl(
              termo:
                  auditiva ? 'Acertos no som grave' : 'Acertos na figura comum',
              valor: '${resumo.acertos} de ${resumo.comuns}',
              comBorda: true,
            ),
            _LinhaDl(
              termo: auditiva ? 'Toques no som agudo' : 'Toques na figura rara',
              valor: '${resumo.toquesRaros} de ${resumo.raros}',
              comBorda: true,
            ),
            _LinhaDl(
              termo: 'Tempo médio de resposta',
              valor: tempo == null ? '—' : '$tempo ms',
              comBorda: false,
              complemento: motivo,
            ),
          ],
        ),
      ],
    );
  }
}

/// Cartão numerado (`article`): número mono 13 e título 21 w700.
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.numero,
    required this.titulo,
    required this.espaco,
    required this.children,
  });

  final String numero;
  final String titulo;
  final double espaco;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Semantics(
      container: true,
      child: CartaoTeste(
        child: ColunaTeste(
          espaco: espaco,
          children: [
            ExcludeSemantics(
              child: Text(
                numero,
                style: TipografiaTeste.mono(13, cor: cores.textoDiscreto),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                titulo,
                style: TipografiaTeste.next(
                  21,
                  peso: FontWeight.w700,
                  cor: cores.texto,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Linha da lista de descrição: termo à esquerda e valor mono à direita.
class _LinhaDl extends StatelessWidget {
  const _LinhaDl({
    required this.termo,
    required this.valor,
    required this.comBorda,
    this.complemento,
  });

  final String termo;
  final String valor;
  final bool comBorda;

  /// Motivo de não haver número, logo abaixo da linha.
  final String? complemento;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            termo,
            style: TipografiaTeste.next(17, cor: cores.textoSecundario),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valor,
          style: TipografiaTeste.mono(18, cor: cores.texto),
        ),
      ],
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border:
              comBorda ? Border(bottom: BorderSide(color: cores.borda)) : null,
        ),
        child: complemento == null
            ? linha
            : ColunaTeste(
                espaco: 4,
                children: [
                  linha,
                  Text(
                    complemento!,
                    style: TipografiaTeste.next(15, cor: cores.textoSuave),
                  ),
                ],
              ),
      ),
    );
  }
}
