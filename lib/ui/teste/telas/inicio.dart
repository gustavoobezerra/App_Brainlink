import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/icones.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/pagina_teste.dart';

/// Cor padrão do `placeholder` do navegador no protótipo (igual nos dois
/// temas).
const Color _corPlaceholder = Color(0xFF757575);

/// Tela inicial do teste (designs `Main`, `Main-visual-demo` e
/// `Claro-Inicio`).
///
/// Único acréscimo ao design, aprovado: o link "Abrir coleta anterior".
class TelaInicio extends StatelessWidget {
  const TelaInicio({
    super.key,
    required this.versao,
    required this.demonstracao,
    required this.codigoController,
    required this.aoEscolherVersao,
    required this.aoAlternarDemonstracao,
    required this.aoComecar,
    required this.aoAbrirColetaAnterior,
  });

  final VersaoTeste versao;
  final bool demonstracao;
  final TextEditingController codigoController;
  final ValueChanged<VersaoTeste> aoEscolherVersao;
  final VoidCallback aoAlternarDemonstracao;
  final VoidCallback aoComecar;
  final VoidCallback aoAbrirColetaAnterior;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: Builder(
          builder: (context) {
            final cores = TemaTeste.of(context);
            final titulo = versao == VersaoTeste.auditiva
                ? 'Teste de atenção com sons'
                : 'Teste de atenção com imagens';
            return PaginaTeste(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              espaco: 28,
              children: [
                ColunaTeste(
                  espaco: 12,
                  children: [
                    Text(
                      'PROJETO BRAINLINK · PESQUISA',
                      style: TipografiaTeste.mono(
                        13,
                        cor: cores.textoDiscreto,
                        espacamentoEm: 0.08,
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: _TituloEquilibrado(
                        titulo,
                        style: TipografiaTeste.next(
                          32,
                          peso: FontWeight.w700,
                          altura: 1.15,
                          cor: cores.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                ColunaTeste(
                  espaco: 12,
                  children: [
                    Text(
                      'Versão do teste',
                      style: TipografiaTeste.next(16, cor: cores.textoSuave),
                    ),
                    IntrinsicHeight(
                      child: LinhaTeste(
                        espaco: 12,
                        alinhamento: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CartaoVersao(
                              figura: IconesTeste.fone,
                              titulo: 'Auditivo',
                              subtitulo: 'Recomendado · olhos fechados',
                              selecionado: versao == VersaoTeste.auditiva,
                              aoTocar: () =>
                                  aoEscolherVersao(VersaoTeste.auditiva),
                            ),
                          ),
                          Expanded(
                            child: _CartaoVersao(
                              figura: IconesTeste.olho,
                              titulo: 'Visual',
                              subtitulo: 'Alternativa · olhos abertos',
                              selecionado: versao == VersaoTeste.visual,
                              aoTocar: () =>
                                  aoEscolherVersao(VersaoTeste.visual),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ColunaTeste(
                  espaco: 8,
                  children: [
                    Text(
                      'Código do participante',
                      style: TipografiaTeste.next(16, cor: cores.textoSuave),
                    ),
                    _CampoCodigo(controller: codigoController),
                    Text(
                      'Só o código. Não digite o nome.',
                      style: TipografiaTeste.next(14, cor: cores.textoDiscreto),
                    ),
                  ],
                ),
                _CartaoDemonstracao(
                  ligado: demonstracao,
                  aoAlternar: aoAlternarDemonstracao,
                ),
                const Spacer(),
                ColunaTeste(
                  children: [
                    ColunaTeste(
                      espaco: 14,
                      children: [
                        BotaoTeste(texto: 'Começar', aoTocar: aoComecar),
                        Text(
                          'Duração: cerca de 5 minutos.',
                          textAlign: TextAlign.center,
                          style:
                              TipografiaTeste.next(15, cor: cores.textoSuave),
                        ),
                      ],
                    ),
                    // Acréscimo aprovado: logo abaixo da duração; a área de
                    // toque de 44 px já dá o respiro.
                    _LinkColetaAnterior(aoTocar: aoAbrirColetaAnterior),
                  ],
                ),
              ],
            );
          },
        ),
      );
}

/// Título com quebra equilibrada (`text-wrap: balance`): quando o texto
/// ocupa duas linhas, quebra antes da última palavra se isso deixar as linhas
/// mais parecidas.
class _TituloEquilibrado extends StatelessWidget {
  const _TituloEquilibrado(this.texto, {required this.style});

  final String texto;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text(_equilibrar(texto), style: style);

  /// As frases do título são fixas; a quebra fica depois de "atenção", como
  /// no design ("Teste de atenção / com sons").
  static String _equilibrar(String texto) {
    const corte = 'Teste de atenção ';
    if (!texto.startsWith(corte)) return texto;
    return 'Teste de atenção\n${texto.substring(corte.length)}';
  }
}

/// Cartão selecionável de versão (`aria-pressed`).
class _CartaoVersao extends StatelessWidget {
  const _CartaoVersao({
    required this.figura,
    required this.titulo,
    required this.subtitulo,
    required this.selecionado,
    required this.aoTocar,
  });

  final FiguraSvg figura;
  final String titulo;
  final String subtitulo;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selecionado ? cores.acento : cores.borda,
        width: 2,
      ),
    );
    return Semantics(
      button: true,
      toggled: selecionado,
      label: '$titulo. $subtitulo',
      excludeSemantics: true,
      child: Material(
        color: selecionado ? cores.selecionadoFundo : cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selecionado ? null : aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ColunaTeste(
                espaco: 10,
                alinhamento: CrossAxisAlignment.start,
                children: [
                  IconeSvg(
                    figura,
                    tamanho: 28,
                    cor: selecionado ? cores.acentoIcone : cores.iconeInativo,
                  ),
                  Text(
                    titulo,
                    style: TipografiaTeste.next(
                      20,
                      peso: FontWeight.w700,
                      cor: cores.texto,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TipografiaTeste.next(
                      14,
                      cor: selecionado
                          ? cores.selecionadoTextoSub
                          : cores.textoSuave,
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

/// Campo do código do participante (56 px, monoespaçado 20 px).
class _CampoCodigo extends StatelessWidget {
  const _CampoCodigo({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final estilo = TipografiaTeste.mono(
      20,
      cor: cores.texto,
      espacamentoEm: 0.06,
    );
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: TextField(
        controller: controller,
        style: estilo,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        cursorColor: cores.acento,
        decoration: InputDecoration(
          hintText: 'Ex.: P017',
          hintStyle: estilo.copyWith(color: _corPlaceholder),
          semanticCounterText: '',
          filled: true,
          fillColor: cores.cartao,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: borda(cores.bordaForte),
          enabledBorder: borda(cores.bordaForte),
          focusedBorder: borda(cores.acento, 2),
        ),
      ),
    );
  }
}

/// Cartão "Modo demonstração" com o interruptor do design (role switch).
class _CartaoDemonstracao extends StatelessWidget {
  const _CartaoDemonstracao({required this.ligado, required this.aoAlternar});

  final bool ligado;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Semantics(
      toggled: ligado,
      label: 'Modo demonstração',
      hint: 'Para apresentação. Não salva dados identificados.',
      onTap: aoAlternar,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: aoAlternar,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cores.cartao,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cores.borda),
          ),
          child: LinhaTeste(
            espaco: 16,
            children: [
              Expanded(
                child: ColunaTeste(
                  espaco: 4,
                  children: [
                    Text(
                      'Modo demonstração',
                      style: TipografiaTeste.next(
                        18,
                        peso: FontWeight.w600,
                        cor: cores.texto,
                      ),
                    ),
                    Text(
                      'Para apresentação. Não salva dados identificados.',
                      style: TipografiaTeste.next(14, cor: cores.textoSuave),
                    ),
                  ],
                ),
              ),
              _Interruptor(ligado: ligado),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor de 56 × 32 desenhado como no protótipo.
class _Interruptor extends StatelessWidget {
  const _Interruptor({required this.ligado});

  final bool ligado;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 56,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:
            ligado ? cores.interruptorLigado : cores.interruptorDesligadoFundo,
        borderRadius: BorderRadius.circular(16),
        border:
            ligado ? null : Border.all(color: cores.interruptorDesligadoBorda),
      ),
      alignment: ligado ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: ligado ? 26 : 24,
        height: ligado ? 26 : 24,
        decoration: BoxDecoration(
          color: ligado ? cores.textoPrimario : cores.interruptorDesligadoBotao,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Link discreto "Abrir coleta anterior" (14 px, sublinhado, toque ≥ 44 px).
class _LinkColetaAnterior extends StatelessWidget {
  const _LinkColetaAnterior({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Center(
      child: Semantics(
        button: true,
        label: 'Abrir coleta anterior',
        excludeSemantics: true,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'Abrir coleta anterior',
                  textAlign: TextAlign.center,
                  style: TipografiaTeste.next(
                    14,
                    cor: cores.textoSuave,
                    decoracao: TextDecoration.underline,
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
