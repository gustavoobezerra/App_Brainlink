import 'package:flutter/widgets.dart';

import 'svg_figura.dart';
import 'tema_teste.dart';

/// Ícones e figuras copiados literalmente das telas do zip.
///
/// Os ícones de linha usam `currentColor`: a cor vem do [IconeSvg]. A
/// espessura padrão é a do design; use [FiguraSvg.comEspessura] quando uma
/// tela desenha o mesmo ícone com outro `stroke-width`.
abstract final class IconesTeste {
  /// Fone de ouvido (versão auditiva).
  static const FiguraSvg fone = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M4 15v-3a8 8 0 0 1 16 0v3'),
      RetanguloSvg(3, 14, 4, 7, rx: 1.5),
      RetanguloSvg(17, 14, 4, 7, rx: 1.5),
    ],
  );

  /// Olho aberto (versão visual; "Pode abrir os olhos.").
  static const FiguraSvg olho = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z'),
      CirculoSvg(12, 12, 3),
    ],
  );

  /// Olhos fechados (telas de repouso).
  static const FiguraSvg olhosFechados = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M3 10c2.5 3.5 5.5 5 9 5s6.5-1.5 9-5'),
      CaminhoSvg('M6.5 13.5L5 16'),
      CaminhoSvg('M12 15v2.8'),
      CaminhoSvg('M17.5 13.5L19 16'),
    ],
  );

  /// Pessoa sentada ("Sente-se confortável…").
  static const FiguraSvg pessoaSentada = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M6 20v-5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v5'),
      CaminhoSvg('M4 20h16'),
      CirculoSvg(12, 6.5, 3),
    ],
  );

  /// Rosto neutro ("evite falar…").
  static const FiguraSvg rostoNeutro = FiguraSvg.linha24(
    elementos: [
      CirculoSvg(12, 12, 8.5),
      CaminhoSvg('M9 15h6'),
      CaminhoSvg('M9 10h.01M15 10h.01'),
    ],
  );

  /// Sino dos sinais de fase.
  static const FiguraSvg sino = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z'),
      CaminhoSvg('M10 20.5a2 2 0 0 0 4 0'),
    ],
  );

  /// Mão tocando ("Toque na tela").
  static const FiguraSvg mao = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M9 11V5.5a1.5 1.5 0 0 1 3 0V11'),
      CaminhoSvg('M12 10.5a1.5 1.5 0 0 1 3 0V12'),
      CaminhoSvg(
        'M15 11.5a1.5 1.5 0 0 1 3 0V15a6 6 0 0 1-6 6h-1a6 6 0 0 1-5-2.7'
        'L3.6 15a1.5 1.5 0 0 1 2.4-1.8L9 15.5',
      ),
    ],
  );

  /// Mão riscada ("NÃO toque").
  static const FiguraSvg maoRiscada = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M9 11V5.5a1.5 1.5 0 0 1 3 0V11'),
      CaminhoSvg('M12 10.5a1.5 1.5 0 0 1 3 0V12'),
      CaminhoSvg(
        'M15 11.5a1.5 1.5 0 0 1 3 0V15a6 6 0 0 1-6 6h-1a6 6 0 0 1-5-2.7'
        'L3.6 15a1.5 1.5 0 0 1 2.4-1.8L9 15.5',
      ),
      CaminhoSvg('M3 3l18 18', espessura: 2.25),
    ],
  );

  /// Visto (`stroke-width` 2; algumas telas usam 2,25).
  static const FiguraSvg visto = FiguraSvg.linha24(
    espessura: 2,
    elementos: [CaminhoSvg('M5 12.5l4.5 4.5L19 7.5')],
  );

  /// Seta circular ("Repetir calibração").
  static const FiguraSvg repetir = FiguraSvg.linha24(
    espessura: 2,
    elementos: [
      CaminhoSvg('M20 11a8 8 0 1 0-2.3 5.7'),
      CaminhoSvg('M20 4v7h-7'),
    ],
  );

  /// Quadrado de parar ("Segure para encerrar").
  static const FiguraSvg parar = FiguraSvg.linha24(
    espessura: 2,
    elementos: [RetanguloSvg(6, 6, 12, 12, rx: 2)],
  );

  /// Pausa ("Teste pausado").
  static const FiguraSvg pausa = FiguraSvg.linha24(
    espessura: 2,
    juncaoRedonda: false,
    elementos: [CaminhoSvg('M9 6v12M15 6v12')],
  );

  /// Bluetooth ("Reconectando ao headset…").
  static const FiguraSvg bluetooth = FiguraSvg.linha24(
    elementos: [CaminhoSvg('M7 7l10 10-5 4V3l5 4L7 17')],
  );

  /// Exclamação ("Ajuste o sensor", "Sem contato").
  static const FiguraSvg exclamacao = FiguraSvg.linha24(
    espessura: 2,
    elementos: [CaminhoSvg('M12 7v6'), CaminhoSvg('M12 16.5v.5')],
  );

  /// Alto-falante ("Aumente o volume").
  static const FiguraSvg volume = FiguraSvg.linha24(
    elementos: [
      CaminhoSvg('M4 9.5h3.5L12 5.5v13l-4.5-4H4z'),
      CaminhoSvg('M15.5 9.5a3.5 3.5 0 0 1 0 5'),
    ],
  );

  /// Triângulo de tocar, preenchido.
  static const FiguraSvg tocar = FiguraSvg(
    largura: 24,
    altura: 24,
    preenchimento: PinturaSvg.atual,
    elementos: [CaminhoSvg('M7 4.5v15l12.5-7.5z')],
  );

  /// Traço horizontal ("Era para não tocar").
  static const FiguraSvg menos = FiguraSvg.linha24(
    espessura: 2,
    elementos: [CaminhoSvg('M6 12h12')],
  );

  /// Cruz arredondada ("Olhe sempre para o centro da tela").
  static const FiguraSvg mais = FiguraSvg.linha24(
    espessura: 2,
    juncaoRedonda: false,
    elementos: [CaminhoSvg('M12 6v12M6 12h12')],
  );

  /// Cruz de fixação da tarefa visual (`viewBox="0 0 20 20"`).
  static const FiguraSvg cruzFixacao = FiguraSvg(
    largura: 20,
    altura: 20,
    preenchimento: PinturaSvg.nenhuma,
    traco: PinturaSvg.cor(CoresFase.visualCruz),
    espessura: 2,
    elementos: [CaminhoSvg('M10 2v16M2 10h16')],
  );

  /// Barco comum: estímulo que pede toque (`viewBox="0 0 120 120"`).
  static const FiguraSvg barcoComum = FiguraSvg(
    largura: 120,
    altura: 120,
    preenchimento: PinturaSvg.cor(CoresFase.figura),
    elementos: [
      CaminhoSvg('M16 82h88l-13 18H29z'),
      RetanguloSvg(58, 22, 4, 60),
      CaminhoSvg('M64 28l30 48H64z'),
      CaminhoSvg('M56 34L30 76h26z'),
      CaminhoSvg('M62 10h20l-7 7 7 7H62z'),
    ],
  );

  /// Barco pirata: estímulo raro, que pede para não tocar.
  static const FiguraSvg barcoPirata = FiguraSvg(
    largura: 120,
    altura: 120,
    preenchimento: PinturaSvg.cor(CoresFase.figura),
    elementos: [
      CaminhoSvg('M16 82h88l-13 18H29z'),
      RetanguloSvg(58, 22, 4, 60),
      CaminhoSvg('M64 28l30 48H64z'),
      CaminhoSvg('M56 34L30 76h26z'),
      RetanguloSvg(
        62,
        8,
        24,
        17,
        preenchimento: PinturaSvg.cor(CoresFase.visualFundo),
        traco: PinturaSvg.cor(CoresFase.figura),
        espessura: 2,
      ),
      CirculoSvg(74, 14, 3),
      CaminhoSvg(
        'M68 20l12-2M68 18l12 2',
        preenchimento: PinturaSvg.nenhuma,
        traco: PinturaSvg.cor(CoresFase.figura),
        espessura: 2,
      ),
    ],
  );

  /// Anel completo do botão "Segure 2 s para encerrar".
  static const FiguraSvg anel = FiguraSvg(
    largura: 24,
    altura: 24,
    preenchimento: PinturaSvg.nenhuma,
    traco: PinturaSvg.atual,
    espessura: 2,
    pontaRedonda: true,
    elementos: [CirculoSvg(12, 12, 9)],
  );

  /// Cabeça com o sensor na testa e o clipe na orelha (`viewBox 200 × 170`).
  static FiguraSvg cabecaSensor(CoresTeste cores) => FiguraSvg(
        largura: 200,
        altura: 170,
        preenchimento: PinturaSvg.nenhuma,
        traco: PinturaSvg.cor(cores.textoDiscreto),
        espessura: 2.5,
        pontaRedonda: true,
        juncaoRedonda: true,
        elementos: [
          const CaminhoSvg(
            'M100 18c-36 0-58 26-58 62 0 30 14 52 30 64 9 7 18 10 28 10'
            's19-3 28-10c16-12 30-34 30-64 0-36-22-62-58-62z',
          ),
          const CaminhoSvg('M42 84c-8 0-12 6-11 14s6 13 12 12'),
          const CaminhoSvg('M158 84c8 0 12 6 11 14s-6 13-12 12'),
          const CaminhoSvg('M78 98h10M112 98h10'),
          const CaminhoSvg('M92 128c5 3 11 3 16 0'),
          CaminhoSvg(
            'M45 66c16-8 35-12 55-12s39 4 55 12',
            traco: PinturaSvg.cor(cores.acento),
            espessura: 7,
          ),
          CirculoSvg(
            100,
            55,
            10,
            preenchimento: PinturaSvg.cor(cores.acento),
            traco: PinturaSvg.cor(cores.cartao),
            espessura: 3,
          ),
          CaminhoSvg(
            'M44 70C36 80 32 92 31 104',
            traco: PinturaSvg.cor(cores.acento),
            espessura: 2,
            tracejado: const [3, 5],
          ),
          RetanguloSvg(
            25,
            104,
            12,
            14,
            rx: 4,
            preenchimento: PinturaSvg.cor(cores.acento),
            traco: PinturaSvg.nenhuma,
          ),
        ],
      );
}

/// Atalho para ícones de linha com cor e tamanho do design.
Widget iconeTeste(
  FiguraSvg figura, {
  required double tamanho,
  Color? cor,
  double? espessura,
}) =>
    IconeSvg(
      espessura == null ? figura : figura.comEspessura(espessura),
      tamanho: tamanho,
      cor: cor,
    );
