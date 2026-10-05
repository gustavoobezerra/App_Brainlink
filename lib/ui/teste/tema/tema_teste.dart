import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Famílias tipográficas das telas do teste, empacotadas em `assets/fonts`.
abstract final class FontesTeste {
  static const String next = 'Atkinson Hyperlegible Next';
  static const String mono = 'Atkinson Hyperlegible Mono';
}

/// Atalhos de estilo de texto com os valores do design.
///
/// Os tamanhos são os pixels do protótipo de 390 × 844, que correspondem aos
/// pixels lógicos do Flutter. O peso padrão é `w400`. A sobra da entrelinha
/// é dividida igualmente acima e abaixo do texto, como no CSS.
abstract final class TipografiaTeste {
  static TextStyle next(
    double tamanho, {
    FontWeight peso = FontWeight.w400,
    Color? cor,
    double? altura,
    double? espacamento,
    TextDecoration? decoracao,
  }) =>
      TextStyle(
        fontFamily: FontesTeste.next,
        fontSize: tamanho,
        fontWeight: peso,
        color: cor,
        height: altura,
        letterSpacing: espacamento,
        decoration: decoracao,
        decorationColor: cor,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// Texto monoespaçado; [espacamentoEm] segue o `letter-spacing` em `em`.
  static TextStyle mono(
    double tamanho, {
    FontWeight peso = FontWeight.w400,
    Color? cor,
    double? altura,
    double espacamentoEm = 0,
  }) =>
      TextStyle(
        fontFamily: FontesTeste.mono,
        fontSize: tamanho,
        fontWeight: peso,
        color: cor,
        height: altura,
        letterSpacing: espacamentoEm * tamanho,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

/// Paleta semântica das telas do teste.
///
/// Os valores escuros e claros vêm das telas do zip
/// (`docs/design/brainlink-telas-testes.zip`). Onde o tema claro não foi
/// desenhado, o valor é o equivalente do mapeamento das telas claras.
@immutable
class CoresTeste {
  const CoresTeste({
    required this.brilho,
    required this.fundo,
    required this.texto,
    required this.textoSecundario,
    required this.textoSuave,
    required this.textoDiscreto,
    required this.textoApagado,
    required this.cartao,
    required this.borda,
    required this.bordaForte,
    required this.fundoPesquisador,
    required this.bordaPesquisador,
    required this.fundoNeutro,
    required this.fundoSecundario,
    required this.bordaSecundario,
    required this.primario,
    required this.textoPrimario,
    required this.desabilitadoFundo,
    required this.desabilitadoTexto,
    required this.acento,
    required this.acentoIcone,
    required this.acentoDestaque,
    required this.selecionadoFundo,
    required this.selecionadoTextoSub,
    required this.iconeInativo,
    required this.progressoInativo,
    required this.radioAnel,
    required this.interruptorDesligadoFundo,
    required this.interruptorDesligadoBorda,
    required this.interruptorDesligadoBotao,
    required this.interruptorLigado,
    required this.ambarBorda,
    required this.ambarFundo,
    required this.ambarIcone,
    required this.ambarTitulo,
    required this.ambarTexto,
    required this.verde,
    required this.verdeFundo,
    required this.verdeTitulo,
    required this.verdeTexto,
    required this.verdeIcone,
    required this.neutroIndicador,
    required this.tracado,
    required this.tracadoVazio,
    required this.circuloCalibracaoExterno,
    required this.circuloCalibracaoBorda,
    required this.feedbackNeutroFundo,
    required this.link,
  });

  final Brightness brilho;

  /// Fundo da página (`#08111F` / `#F5F7FA`).
  final Color fundo;

  /// Texto principal (`#EEF2F8` / `#0E1A2B`).
  final Color texto;

  /// Corpo de texto secundário (`#C9D3E2` / `#3A4860`).
  final Color textoSecundario;

  /// Rótulos e legendas (`#A9B6CA` / `#4A5870`).
  final Color textoSuave;

  /// Sobrescritos e textos do pesquisador (`#8DA0BC` / `#4A5870`).
  final Color textoDiscreto;

  /// Linha discreta do pesquisador na calibração (`#6F819C` / `#5A6880`).
  final Color textoApagado;

  /// Fundo de cartões (`#111C2E` / `#FFFFFF`).
  final Color cartao;

  /// Borda de cartões e trilhos (`#25334A` / `#D3DBE7`).
  final Color borda;

  /// Borda de campos e botões de contorno (`#33445F` / `#B7C3D4`).
  final Color bordaForte;

  /// Fundo dos quadros "Para o pesquisador" (`#0B1424` / `#EEF2F7`).
  final Color fundoPesquisador;

  /// Borda dos quadros do pesquisador (`#1E2C44` / `#D3DBE7`).
  final Color bordaPesquisador;

  /// Fundo do indicador de contato neutro (`#0D1728` / `#FFFFFF`).
  final Color fundoNeutro;

  /// Fundo de botões secundários (`#18243A` / `#FFFFFF`).
  final Color fundoSecundario;

  /// Borda de botões secundários (`#25334A` / `#B7C3D4`).
  final Color bordaSecundario;

  /// Botão principal (`#2F6FD0` / `#2560C4`).
  final Color primario;
  final Color textoPrimario;

  /// Botão desabilitado (`#18243A` + `#8392AA` / `#E4E9F0` + `#8A97AB`).
  final Color desabilitadoFundo;
  final Color desabilitadoTexto;

  /// Bordas selecionadas, barras e pontos ativos (`#4F8FEA` / `#2F6FD0`).
  final Color acento;

  /// Ícones em círculos e links (`#8DB7F5` / `#2560C4`).
  final Color acentoIcone;

  /// Destaque de texto e números grandes (`#B5D0FA` / `#1A4A9C`).
  final Color acentoDestaque;

  /// Fundo selecionado e círculos de ícone (`#15284A` / `#E6EEFC`).
  final Color selecionadoFundo;

  /// Subtítulo de cartão selecionado (`#B9C6D8` / `#3A4860`).
  final Color selecionadoTextoSub;

  /// Ícone de cartão não selecionado (`#A9B6CA` / `#4A5870`).
  final Color iconeInativo;

  /// Segmento inativo da barra de etapas (`#25334A` / `#D3DBE7`).
  final Color progressoInativo;

  /// Anel de opção não marcada (`#6F819C` / `#8A97AB`).
  final Color radioAnel;

  final Color interruptorDesligadoFundo;
  final Color interruptorDesligadoBorda;
  final Color interruptorDesligadoBotao;
  final Color interruptorLigado;

  final Color ambarBorda;
  final Color ambarFundo;
  final Color ambarIcone;
  final Color ambarTitulo;
  final Color ambarTexto;

  final Color verde;
  final Color verdeFundo;
  final Color verdeTitulo;
  final Color verdeTexto;

  /// Ícone sobre o círculo verde (`#06140D` / `#FFFFFF`).
  final Color verdeIcone;

  /// Círculo tracejado de "Procurando sinal…" (`#6F819C` / `#5A6880`).
  final Color neutroIndicador;

  /// Linha do sinal ao vivo (`#6F819C` / `#5A6880`).
  final Color tracado;

  /// Linha tracejada sem dados (`#3A4A63` / `#B7C3D4`).
  final Color tracadoVazio;

  final Color circuloCalibracaoExterno;
  final Color circuloCalibracaoBorda;

  /// Círculo do feedback "Era para não tocar" (`#1A2232`).
  final Color feedbackNeutroFundo;

  /// Cor de links (`#8DB7F5` / `#2560C4`).
  final Color link;

  bool get escuro => brilho == Brightness.dark;

  static const CoresTeste escuroPadrao = CoresTeste(
    brilho: Brightness.dark,
    fundo: Color(0xFF08111F),
    texto: Color(0xFFEEF2F8),
    textoSecundario: Color(0xFFC9D3E2),
    textoSuave: Color(0xFFA9B6CA),
    textoDiscreto: Color(0xFF8DA0BC),
    textoApagado: Color(0xFF6F819C),
    cartao: Color(0xFF111C2E),
    borda: Color(0xFF25334A),
    bordaForte: Color(0xFF33445F),
    fundoPesquisador: Color(0xFF0B1424),
    bordaPesquisador: Color(0xFF1E2C44),
    fundoNeutro: Color(0xFF0D1728),
    fundoSecundario: Color(0xFF18243A),
    bordaSecundario: Color(0xFF25334A),
    primario: Color(0xFF2F6FD0),
    textoPrimario: Color(0xFFFFFFFF),
    desabilitadoFundo: Color(0xFF18243A),
    desabilitadoTexto: Color(0xFF8392AA),
    acento: Color(0xFF4F8FEA),
    acentoIcone: Color(0xFF8DB7F5),
    acentoDestaque: Color(0xFFB5D0FA),
    selecionadoFundo: Color(0xFF15284A),
    selecionadoTextoSub: Color(0xFFB9C6D8),
    iconeInativo: Color(0xFFA9B6CA),
    progressoInativo: Color(0xFF25334A),
    radioAnel: Color(0xFF6F819C),
    interruptorDesligadoFundo: Color(0xFF18243A),
    interruptorDesligadoBorda: Color(0xFF44567A),
    interruptorDesligadoBotao: Color(0xFF8DA0BC),
    interruptorLigado: Color(0xFF2F6FD0),
    ambarBorda: Color(0xFFE8A23A),
    ambarFundo: Color(0xFF221A0C),
    ambarIcone: Color(0xFFF2B85C),
    ambarTitulo: Color(0xFFF6C77A),
    ambarTexto: Color(0xFFE9DCC4),
    verde: Color(0xFF3FB97A),
    verdeFundo: Color(0xFF0C2119),
    verdeTitulo: Color(0xFF8FE0B5),
    verdeTexto: Color(0xFFCFE7DA),
    verdeIcone: Color(0xFF06140D),
    neutroIndicador: Color(0xFF6F819C),
    tracado: Color(0xFF6F819C),
    tracadoVazio: Color(0xFF3A4A63),
    circuloCalibracaoExterno: Color(0xFF1E2C44),
    circuloCalibracaoBorda: Color(0xFF2D4C7E),
    feedbackNeutroFundo: Color(0xFF1A2232),
    link: Color(0xFF8DB7F5),
  );

  static const CoresTeste claroPadrao = CoresTeste(
    brilho: Brightness.light,
    fundo: Color(0xFFF5F7FA),
    texto: Color(0xFF0E1A2B),
    textoSecundario: Color(0xFF3A4860),
    textoSuave: Color(0xFF4A5870),
    textoDiscreto: Color(0xFF4A5870),
    textoApagado: Color(0xFF5A6880),
    cartao: Color(0xFFFFFFFF),
    borda: Color(0xFFD3DBE7),
    bordaForte: Color(0xFFB7C3D4),
    fundoPesquisador: Color(0xFFEEF2F7),
    bordaPesquisador: Color(0xFFD3DBE7),
    fundoNeutro: Color(0xFFFFFFFF),
    fundoSecundario: Color(0xFFFFFFFF),
    bordaSecundario: Color(0xFFB7C3D4),
    primario: Color(0xFF2560C4),
    textoPrimario: Color(0xFFFFFFFF),
    desabilitadoFundo: Color(0xFFE4E9F0),
    desabilitadoTexto: Color(0xFF8A97AB),
    acento: Color(0xFF2F6FD0),
    acentoIcone: Color(0xFF2560C4),
    acentoDestaque: Color(0xFF1A4A9C),
    selecionadoFundo: Color(0xFFE6EEFC),
    selecionadoTextoSub: Color(0xFF3A4860),
    iconeInativo: Color(0xFF4A5870),
    progressoInativo: Color(0xFFD3DBE7),
    radioAnel: Color(0xFF8A97AB),
    interruptorDesligadoFundo: Color(0xFFE4E9F0),
    interruptorDesligadoBorda: Color(0xFF8A97AB),
    interruptorDesligadoBotao: Color(0xFF5A6880),
    interruptorLigado: Color(0xFF2560C4),
    ambarBorda: Color(0xFFE8A23A),
    ambarFundo: Color(0xFFFFF4E0),
    ambarIcone: Color(0xFF9A5B00),
    ambarTitulo: Color(0xFF9A5B00),
    ambarTexto: Color(0xFF5C4520),
    verde: Color(0xFF1E7A4C),
    verdeFundo: Color(0xFFE8F6EE),
    verdeTitulo: Color(0xFF1E7A4C),
    verdeTexto: Color(0xFF2C4A3A),
    verdeIcone: Color(0xFFFFFFFF),
    neutroIndicador: Color(0xFF5A6880),
    tracado: Color(0xFF5A6880),
    tracadoVazio: Color(0xFFB7C3D4),
    circuloCalibracaoExterno: Color(0xFFD3DBE7),
    circuloCalibracaoBorda: Color(0xFF9DB8E8),
    feedbackNeutroFundo: Color(0xFFEEF2F7),
    link: Color(0xFF2560C4),
  );
}

/// Cores das telas que ficam sempre escuras: olhos fechados, tarefa, treino,
/// fim do repouso e a confirmação de saída.
abstract final class CoresFase {
  // 5b · Repouso de olhos fechados.
  static const Color repousoFundo = Color(0xFF020408);
  static const Color repousoPonto = Color(0xFF24324A);
  static const Color repousoBrilho = Color(0xFF0B1424);
  static const Color repousoTexto = Color(0xFF4B5A70);
  static const Color repousoSegurarBorda = Color(0xFF141C28);
  static const Color repousoSegurarIcone = Color(0xFF36425A);

  // 5c · Repouso — fim.
  static const Color repousoFimFundo = Color(0xFF050A13);
  static const Color repousoFimCirculo = Color(0xFF101B2E);

  // 7A · Tarefa auditiva.
  static const Color auditivaFundo = Color(0xFF000000);
  static const Color auditivaRotulo = Color(0xFF232C3A);
  static const Color auditivaTexto = Color(0xFF3E4A5E);
  static const Color auditivaSegurarBorda = Color(0xFF10161F);
  static const Color auditivaSegurarIcone = Color(0xFF2E3848);

  // 7B · Tarefa visual.
  static const Color visualFundo = Color(0xFF121417);
  static const Color visualTexto = Color(0xFF4A525E);
  static const Color visualSegurarBorda = Color(0xFF1E2228);
  static const Color visualSegurarIcone = Color(0xFF3C434E);
  static const Color visualCruz = Color(0xFF8A93A0);
  static const Color figura = Color(0xFFE6ECF5);

  // E3 · Saída antecipada.
  static const Color saidaVeu = Color(0xFF02050B);
  static const double saidaVeuOpacidade = 0.85;
  static const Color saidaSegurarBorda = Color(0xFF44567A);
  static const Color saidaSegurarPreenchimento = Color(0xFF1E2A40);
  static const Color saidaAnel = Color(0xFF33445F);

  // Ponto de qualidade do sinal sobre fundos quase pretos.
  static const Color qualidadeBoaDiscreta = Color(0xFF2C7A55);
  static const Color qualidadeAjusteDiscreta = Color(0xFF8C6224);
  static const Color qualidadeRuimDiscreta = Color(0xFF7E3A35);

  // Ponto de qualidade do sinal sobre o fundo padrão.
  static const Color qualidadeBoa = Color(0xFF3FB97A);
  static const Color qualidadeAjuste = Color(0xFFE8A23A);
  static const Color qualidadeRuim = Color(0xFFE05A4F);
}

/// Disponibiliza a paleta às telas do teste.
///
/// Por padrão a paleta acompanha o tema claro/escuro do sistema;
/// [sempreEscuro] fixa a paleta escura nas telas desenhadas apenas no escuro.
class TemaTeste extends StatelessWidget {
  const TemaTeste({
    super.key,
    required this.child,
    this.sempreEscuro = false,
  });

  final Widget child;
  final bool sempreEscuro;

  /// `line-height: normal` desta fonte no navegador (o design usa esse
  /// valor sempre que não define outro).
  static const double alturaNormal = 1.3;

  /// Os estilos do Material (altura 1,43 e espaçamento 0,25 no `bodyMedium`)
  /// vazam para todo `Text` sem estilo próprio dentro de um `Material`;
  /// trocamos pela métrica do navegador.
  static ThemeData _comTextoCss(ThemeData base, CoresTeste cores) {
    TextStyle? ajustar(TextStyle? estilo) => estilo?.copyWith(
          fontFamily: FontesTeste.next,
          height: alturaNormal,
          letterSpacing: 0,
          leadingDistribution: TextLeadingDistribution.even,
          color: cores.texto,
        );
    final t = base.textTheme;
    return base.copyWith(
      textTheme: t.copyWith(
        displayLarge: ajustar(t.displayLarge),
        displayMedium: ajustar(t.displayMedium),
        displaySmall: ajustar(t.displaySmall),
        headlineLarge: ajustar(t.headlineLarge),
        headlineMedium: ajustar(t.headlineMedium),
        headlineSmall: ajustar(t.headlineSmall),
        titleLarge: ajustar(t.titleLarge),
        titleMedium: ajustar(t.titleMedium),
        titleSmall: ajustar(t.titleSmall),
        bodyLarge: ajustar(t.bodyLarge),
        bodyMedium: ajustar(t.bodyMedium),
        bodySmall: ajustar(t.bodySmall),
        labelLarge: ajustar(t.labelLarge),
        labelMedium: ajustar(t.labelMedium),
        labelSmall: ajustar(t.labelSmall),
      ),
    );
  }

  static CoresTeste of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EscopoCores>()?.cores ??
      CoresTeste.escuroPadrao;

  @override
  Widget build(BuildContext context) {
    final brilho = sempreEscuro
        ? Brightness.dark
        : context.dependOnInheritedWidgetOfExactType<BrilhoTeste>()?.brilho ??
            MediaQuery.platformBrightnessOf(context);
    final cores = brilho == Brightness.dark
        ? CoresTeste.escuroPadrao
        : CoresTeste.claroPadrao;
    final barras = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          cores.escuro ? Brightness.light : Brightness.dark,
      statusBarBrightness: cores.escuro ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: cores.fundo,
      systemNavigationBarIconBrightness:
          cores.escuro ? Brightness.light : Brightness.dark,
    );
    return _EscopoCores(
      cores: cores,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: barras,
        child: Theme(
          data: _comTextoCss(
              ThemeData(
                useMaterial3: true,
                brightness: brilho,
                fontFamily: FontesTeste.next,
                scaffoldBackgroundColor: cores.fundo,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: cores.acento,
                  brightness: brilho,
                  surface: cores.cartao,
                  primary: cores.primario,
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: cores.acento,
                  selectionColor: cores.acento.withValues(alpha: 0.35),
                  selectionHandleColor: cores.acento,
                ),
              ),
              cores),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: FontesTeste.next,
              color: cores.texto,
              height: alturaNormal,
              letterSpacing: 0,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fixa o brilho usado pelos [TemaTeste] descendentes (testes e capturas).
class BrilhoTeste extends InheritedWidget {
  const BrilhoTeste({super.key, required this.brilho, required super.child});

  final Brightness brilho;

  @override
  bool updateShouldNotify(BrilhoTeste oldWidget) => brilho != oldWidget.brilho;
}

class _EscopoCores extends InheritedWidget {
  const _EscopoCores({required this.cores, required super.child});

  final CoresTeste cores;

  @override
  bool updateShouldNotify(_EscopoCores oldWidget) => cores != oldWidget.cores;
}
