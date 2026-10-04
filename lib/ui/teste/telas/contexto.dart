import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/cabecalho_etapa.dart';
import '../widgets/pagina_teste.dart';

/// Tela "Contexto" (etapa 7): "Algumas perguntas sobre hoje", com quatro
/// grupos de botões de escolha e "Concluir".
class TelaContexto extends StatelessWidget {
  const TelaContexto({
    super.key,
    required this.respostas,
    required this.aoSono,
    required this.aoCafeina,
    required this.aoMedicacao,
    required this.aoLente,
    required this.aoConcluir,
  });

  final RespostasContexto respostas;
  final ValueChanged<HorasSono> aoSono;
  final ValueChanged<bool> aoCafeina;
  final ValueChanged<MedicacaoAtencao> aoMedicacao;
  final ValueChanged<bool> aoLente;

  /// Nulo desabilita "Concluir".
  final VoidCallback? aoConcluir;

  @override
  Widget build(BuildContext context) {
    return TemaTeste(
      child: Builder(
        builder: (context) {
          final cores = TemaTeste.of(context);
          return PaginaTeste(
            espaco: 26,
            children: [
              const CabecalhoEtapa(
                etapa: 7,
                rotulo: 'Questionário · Sobre hoje',
                tamanhoRotulo: 15,
              ),
              Semantics(
                header: true,
                child: Text(
                  'Algumas perguntas sobre hoje',
                  style: TipografiaTeste.next(
                    26,
                    peso: FontWeight.w700,
                    cor: cores.texto,
                  ),
                ),
              ),
              _Grupo(
                legenda: 'Quantas horas você dormiu na última noite?',
                opcoes: _grade([
                  for (final horas in HorasSono.values)
                    _BotaoEscolha(
                      texto: horas.rotulo,
                      selecionado: respostas.sono == horas,
                      aoTocar: () => aoSono(horas),
                    ),
                ]),
              ),
              _Grupo(
                legenda: 'Tomou café ou energético nas últimas 3 horas?',
                opcoes: _simNao(respostas.cafeina, aoCafeina),
              ),
              _Grupo(
                legenda: 'Toma medicação para atenção? Tomou hoje?',
                opcoes: ColunaTeste(
                  espaco: 8,
                  children: [
                    for (final opcao in MedicacaoAtencao.values)
                      _BotaoEscolha(
                        texto: opcao.rotulo,
                        selecionado: respostas.medicacao == opcao,
                        aoTocar: () => aoMedicacao(opcao),
                        aEsquerda: true,
                      ),
                  ],
                ),
              ),
              _Grupo(
                legenda: 'Usa lente de contato?',
                opcoes: _simNao(respostas.lenteContato, aoLente),
              ),
              const Spacer(),
              BotaoTeste(texto: 'Concluir', aoTocar: aoConcluir),
            ],
          );
        },
      ),
    );
  }

  Widget _simNao(bool? valor, ValueChanged<bool> aoEscolher) => _grade([
        _BotaoEscolha(
          texto: 'Sim',
          selecionado: valor == true,
          aoTocar: () => aoEscolher(true),
        ),
        _BotaoEscolha(
          texto: 'Não',
          selecionado: valor == false,
          aoTocar: () => aoEscolher(false),
        ),
      ]);

  /// `grid-template-columns: repeat(n, 1fr); gap: 8px`.
  Widget _grade(List<Widget> botoes) => IntrinsicHeight(
        child: LinhaTeste(
          espaco: 8,
          alinhamento: CrossAxisAlignment.stretch,
          children: [for (final botao in botoes) Expanded(child: botao)],
        ),
      );
}

/// `fieldset` com a legenda (19, w600, altura 1,35) a 12 px das opções.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.legenda, required this.opcoes});

  final String legenda;
  final Widget opcoes;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Semantics(
      container: true,
      label: legenda,
      explicitChildNodes: true,
      child: ColunaTeste(
        espaco: 12,
        children: [
          ExcludeSemantics(
            child: Text(
              legenda,
              style: TipografiaTeste.next(
                19,
                peso: FontWeight.w600,
                altura: 1.35,
                cor: cores.texto,
              ),
            ),
          ),
          opcoes,
        ],
      ),
    );
  }
}

/// Botão de escolha (`aria-pressed`): 56 px, raio 12, borda 2.
class _BotaoEscolha extends StatelessWidget {
  const _BotaoEscolha({
    required this.texto,
    required this.selecionado,
    required this.aoTocar,
    this.aEsquerda = false,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback aoTocar;

  /// Texto à esquerda com `padding: 0 18px` (opções de medicação).
  final bool aEsquerda;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selecionado ? cores.acento : cores.borda,
        width: 2,
      ),
    );
    return Semantics(
      button: true,
      toggled: selecionado,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: selecionado ? cores.selecionadoFundo : cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: aEsquerda ? 20 : 8,
                vertical: 8,
              ),
              child: Align(
                alignment: aEsquerda ? Alignment.centerLeft : Alignment.center,
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  texto,
                  textAlign: aEsquerda ? TextAlign.left : TextAlign.center,
                  style: TipografiaTeste.next(
                    18,
                    peso: selecionado ? FontWeight.w700 : FontWeight.w400,
                    cor: cores.texto,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
