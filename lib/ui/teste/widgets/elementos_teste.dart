import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../data/models/sessao_teste.dart';
import '../tema/svg_figura.dart';
import '../tema/tema_teste.dart';
import 'pagina_teste.dart';

/// Ícone dentro de um círculo (ex.: 72 × 72, fundo `#15284A`, ícone `#8DB7F5`).
class CirculoIcone extends StatelessWidget {
  const CirculoIcone({
    super.key,
    required this.figura,
    this.diametro = 72,
    this.tamanhoIcone = 34,
    this.fundo,
    this.cor,
    this.borda,
    this.espessuraBorda = 2,
    this.espessuraIcone,
  });

  final FiguraSvg figura;
  final double diametro;
  final double tamanhoIcone;

  /// Padrão: `CoresTeste.selecionadoFundo`.
  final Color? fundo;

  /// Padrão: `CoresTeste.acentoIcone`.
  final Color? cor;
  final Color? borda;
  final double espessuraBorda;

  /// Substitui o `stroke-width` do ícone.
  final double? espessuraIcone;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        color: fundo ?? cores.selecionadoFundo,
        shape: BoxShape.circle,
        border: borda == null
            ? null
            : Border.all(color: borda!, width: espessuraBorda),
      ),
      alignment: Alignment.center,
      child: IconeSvg(
        espessuraIcone == null ? figura : figura.comEspessura(espessuraIcone!),
        tamanho: tamanhoIcone,
        cor: cor ?? cores.acentoIcone,
      ),
    );
  }
}

/// Cartão do protótipo: fundo `#111C2E`, borda `#25334A`, raio 16.
class CartaoTeste extends StatelessWidget {
  const CartaoTeste({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.raio = 16,
    this.fundo,
    this.borda,
    this.larguraBorda = 1,
  });

  final Widget child;
  final EdgeInsets padding;
  final double raio;
  final Color? fundo;
  final Color? borda;
  final double larguraBorda;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fundo ?? cores.cartao,
        borderRadius: BorderRadius.circular(raio),
        border: Border.all(color: borda ?? cores.borda, width: larguraBorda),
      ),
      child: child,
    );
  }
}

/// Quadro "Para o pesquisador": fundo `#0B1424`, texto discreto.
class QuadroPesquisador extends StatelessWidget {
  const QuadroPesquisador({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.raio = 12,
    this.comBorda = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double raio;

  /// Borda `#1E2C44` (quadros da calibração).
  final bool comBorda;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    return Semantics(
      container: true,
      label: 'Para o pesquisador',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cores.fundoPesquisador,
          borderRadius: BorderRadius.circular(raio),
          border: comBorda ? Border.all(color: cores.bordaPesquisador) : null,
        ),
        child: child,
      ),
    );
  }
}

/// Selo que identifica dados simulados (exigência do Vault: a simulação
/// sempre se identifica).
class SeloSimulado extends StatelessWidget {
  const SeloSimulado({super.key, this.compacto = false, this.cor});

  /// Versão em texto monoespaçado para os cantos do pesquisador.
  final bool compacto;

  /// Cor do texto compacto; padrão: âmbar.
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    if (compacto) {
      return Text(
        'SIMULADO',
        style: TipografiaTeste.mono(
          12,
          cor: cor ?? cores.ambarTitulo,
          espacamentoEm: 0.04,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cores.ambarFundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Dados simulados',
        style: TipografiaTeste.next(
          14,
          peso: FontWeight.w600,
          cor: cores.ambarTitulo,
        ),
      ),
    );
  }
}

/// Pontinho de 8 × 8 com a qualidade do sinal (verde/âmbar/vermelho).
class PontoQualidade extends StatelessWidget {
  const PontoQualidade({
    super.key,
    required this.qualidade,
    this.discreto = false,
  });

  final QualidadeSinal qualidade;

  /// Tons apagados para as telas quase pretas.
  final bool discreto;

  static String rotulo(QualidadeSinal qualidade) => switch (qualidade) {
        QualidadeSinal.boa => 'Sinal bom',
        QualidadeSinal.ajuste => 'Sinal instável',
        QualidadeSinal.ruim => 'Sem contato',
        QualidadeSinal.semDados => 'Sem sinal',
      };

  @override
  Widget build(BuildContext context) {
    final cor = switch (qualidade) {
      QualidadeSinal.boa =>
        discreto ? CoresFase.qualidadeBoaDiscreta : CoresFase.qualidadeBoa,
      QualidadeSinal.ajuste => discreto
          ? CoresFase.qualidadeAjusteDiscreta
          : CoresFase.qualidadeAjuste,
      QualidadeSinal.ruim ||
      QualidadeSinal.semDados =>
        discreto ? CoresFase.qualidadeRuimDiscreta : CoresFase.qualidadeRuim,
    };
    return Semantics(
      label: rotulo(qualidade),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
    );
  }
}

/// Canto inferior esquerdo das telas escuras: tempo restante, qualidade do
/// sinal e, na tarefa, a contagem de toques.
class CantoPesquisador extends StatelessWidget {
  const CantoPesquisador({
    super.key,
    required this.restante,
    required this.qualidade,
    required this.cor,
    this.toques,
    this.simulada = false,
    this.espaco = 10,
  });

  final Duration restante;
  final QualidadeSinal qualidade;

  /// Cor do texto (cada tela escura tem a sua).
  final Color cor;
  final int? toques;
  final bool simulada;
  final double espaco;

  @override
  Widget build(BuildContext context) {
    final estilo = TipografiaTeste.mono(13, cor: cor);
    return Semantics(
      container: true,
      label: 'Para o pesquisador',
      child: LinhaTeste(
        espaco: espaco,
        children: [
          Text(formatarTempo(restante), style: estilo),
          PontoQualidade(qualidade: qualidade, discreto: true),
          if (toques != null) Text('$toques toques', style: estilo),
          if (simulada) SeloSimulado(compacto: true, cor: cor),
        ],
      ),
    );
  }
}

/// `m:ss`, arredondando para cima (o relógio mostra 0:01 até o último
/// instante e 0:00 só no fim).
String formatarTempo(Duration duracao) {
  final totalMs = duracao.inMilliseconds;
  final segundos = totalMs <= 0 ? 0 : (totalMs + 999) ~/ 1000;
  final minutos = segundos ~/ 60;
  final resto = segundos % 60;
  return '$minutos:${resto.toString().padLeft(2, '0')}';
}

/// Área de resposta: a tela inteira é o botão.
///
/// Usa o evento cru de toque (sem esperar o gesto terminar), que traz o
/// instante do toque no relógio monotônico do Android.
class AreaToque extends StatelessWidget {
  const AreaToque({
    super.key,
    required this.aoTocar,
    required this.child,
    this.semantica = 'Área de resposta: toque em qualquer lugar da tela',
  });

  final ValueChanged<PointerDownEvent> aoTocar;
  final Widget child;
  final String semantica;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantica,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: aoTocar,
          child: child,
        ),
      );
}

/// Atalho para o `kPrimaryButton`, para filtrar toques de mouse secundário.
bool toquePrimario(PointerDownEvent evento) =>
    evento.kind != PointerDeviceKind.mouse || evento.buttons == kPrimaryButton;
