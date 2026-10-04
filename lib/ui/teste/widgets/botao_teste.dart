import 'package:flutter/material.dart';

import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';

/// Variações de botão do protótipo.
enum EstiloBotao {
  /// Fundo azul (`#2F6FD0` / `#2560C4`) e texto branco.
  primario,

  /// Fundo `#18243A` com borda (`#25334A`, ou `#33445F` com [BotaoTeste.bordaForte]).
  secundario,

  /// Sem fundo, borda `#33445F` ("Recomeçar esta fase").
  contorno,

  /// Só texto na cor de link ("Encerrar o teste", "Repetir calibração").
  link,
}

/// Botão do teste: 56 dp de altura mínima, raio 12, texto centralizado.
///
/// Com [aoTocar] nulo o botão fica desabilitado; no estilo principal ele usa
/// as cores de desabilitado do design (`#18243A` / `#8392AA`).
class BotaoTeste extends StatelessWidget {
  const BotaoTeste({
    super.key,
    required this.texto,
    required this.aoTocar,
    this.estilo = EstiloBotao.primario,
    this.tamanhoTexto = 19,
    this.peso = FontWeight.w700,
    this.altura = 56,
    this.icone,
    this.tamanhoIcone = 18,
    this.corIcone,
    this.iconeDepois = false,
    this.bordaForte = false,
    this.espacoIcone = 10,
    this.alinhamento = MainAxisAlignment.center,
    this.preenchimentoHorizontal = 16,
    this.semantica,
  });

  final String texto;
  final VoidCallback? aoTocar;
  final EstiloBotao estilo;
  final double tamanhoTexto;
  final FontWeight peso;
  final double altura;

  /// Ícone opcional, antes do texto (ou depois, com [iconeDepois]).
  final FiguraSvg? icone;
  final double tamanhoIcone;

  /// Cor do ícone; padrão: a cor do texto.
  final Color? corIcone;
  final bool iconeDepois;

  /// Secundário com borda `#33445F` em vez de `#25334A`.
  final bool bordaForte;
  final double espacoIcone;
  final MainAxisAlignment alinhamento;
  final double preenchimentoHorizontal;

  /// Rótulo de acessibilidade; padrão: [texto].
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final habilitado = aoTocar != null;
    late final Color fundo;
    late final Color corTexto;
    BorderSide borda = BorderSide.none;
    switch (estilo) {
      case EstiloBotao.primario:
        fundo = habilitado ? cores.primario : cores.desabilitadoFundo;
        corTexto = habilitado ? cores.textoPrimario : cores.desabilitadoTexto;
      case EstiloBotao.secundario:
        fundo = cores.fundoSecundario;
        corTexto = habilitado ? cores.texto : cores.desabilitadoTexto;
        borda = BorderSide(
          color: bordaForte ? cores.bordaForte : cores.bordaSecundario,
        );
      case EstiloBotao.contorno:
        fundo = Colors.transparent;
        corTexto = habilitado ? cores.texto : cores.desabilitadoTexto;
        borda = BorderSide(color: cores.bordaForte);
      case EstiloBotao.link:
        fundo = Colors.transparent;
        corTexto = habilitado ? cores.link : cores.desabilitadoTexto;
    }
    final rotulo = Text(
      texto,
      textAlign: TextAlign.center,
      style: TipografiaTeste.next(tamanhoTexto, peso: peso, cor: corTexto),
    );
    final iconeWidget = icone == null
        ? null
        : IconeSvg(icone!, tamanho: tamanhoIcone, cor: corIcone ?? corTexto);
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alinhamento,
      children: [
        if (iconeWidget != null && !iconeDepois) ...[
          iconeWidget,
          SizedBox(width: espacoIcone),
        ],
        Flexible(child: rotulo),
        if (iconeWidget != null && iconeDepois) ...[
          SizedBox(width: espacoIcone),
          iconeWidget,
        ],
      ],
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: borda,
    );
    return Semantics(
      button: true,
      enabled: habilitado,
      label: semantica ?? texto,
      excludeSemantics: true,
      child: Material(
        color: fundo,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: altura),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: preenchimentoHorizontal,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: alinhamento,
                children: [Flexible(child: conteudo)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
