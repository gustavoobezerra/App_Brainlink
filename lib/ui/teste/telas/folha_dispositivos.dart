import 'package:flutter/material.dart';

import '../../../services/teste/fonte_sinal.dart';
import '../tema/tema_teste.dart';
import '../widgets/botao_teste.dart';
import '../widgets/pagina_teste.dart';

/// Painel "Escolha o headset" sobre um véu escuro (tela nova, no estilo das
/// telas do zip).
///
/// O host a desenha dentro de um `Stack`, por cima da tela do sensor. Tocar
/// no véu fecha o painel.
class FolhaDispositivos extends StatefulWidget {
  const FolhaDispositivos({
    super.key,
    required this.dispositivos,
    required this.buscando,
    required this.erro,
    required this.conectandoId,
    required this.aoEscolher,
    required this.aoProcurarDeNovo,
    required this.aoUsarSimulados,
    required this.aoFechar,
  });

  final List<DispositivoSinal> dispositivos;
  final bool buscando;
  final String? erro;

  /// Id do aparelho em conexão, para mostrar "Conectando…".
  final String? conectandoId;
  final ValueChanged<DispositivoSinal> aoEscolher;
  final VoidCallback aoProcurarDeNovo;
  final ValueChanged<CenarioSimulado> aoUsarSimulados;
  final VoidCallback aoFechar;

  @override
  State<FolhaDispositivos> createState() => _FolhaDispositivosState();
}

class _FolhaDispositivosState extends State<FolhaDispositivos> {
  CenarioSimulado _cenario = CenarioSimulado.values.first;

  @override
  Widget build(BuildContext context) => TemaTeste(
        child: _TextoCss(child: Builder(builder: _construir)),
      );

  Widget _construir(BuildContext context) {
    final cores = TemaTeste.of(context);
    final midia = MediaQuery.of(context);
    final erro = widget.erro;
    final semAparelhos = widget.dispositivos.isEmpty && !widget.buscando;
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Fechar',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.aoFechar,
              child: ColoredBox(
                color: CoresFase.saidaVeu
                    .withValues(alpha: CoresFase.saidaVeuOpacidade),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: midia.size.height - midia.padding.top - 24,
            ),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Escolha o headset',
              child: Material(
                color: cores.cartao,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  side: BorderSide(color: cores.borda),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + midia.padding.bottom,
                  ),
                  child: ColunaTeste(
                    espaco: 16,
                    children: [
                      ColunaTeste(
                        espaco: 8,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Escolha o headset',
                              style: TipografiaTeste.next(
                                22,
                                peso: FontWeight.w700,
                                cor: cores.texto,
                              ),
                            ),
                          ),
                          Text(
                            'Ligue o BrainLink e pareie em Configurações → '
                            'Bluetooth.',
                            style: TipografiaTeste.next(
                              16,
                              altura: 1.4,
                              cor: cores.textoSuave,
                            ),
                          ),
                        ],
                      ),
                      if (widget.dispositivos.isNotEmpty)
                        ColunaTeste(
                          espaco: 10,
                          children: [
                            for (final dispositivo in widget.dispositivos)
                              _LinhaDispositivo(
                                dispositivo: dispositivo,
                                conectando:
                                    widget.conectandoId == dispositivo.id,
                                aoTocar: () => widget.aoEscolher(dispositivo),
                              ),
                          ],
                        ),
                      if (widget.buscando)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            'Procurando…',
                            style: TipografiaTeste.next(
                              16,
                              cor: cores.textoSuave,
                            ),
                          ),
                        ),
                      if (semAparelhos)
                        Text(
                          'Nenhum aparelho encontrado.',
                          style: TipografiaTeste.next(
                            16,
                            cor: cores.textoSuave,
                          ),
                        ),
                      if (erro != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            erro,
                            style: TipografiaTeste.next(
                              16,
                              altura: 1.4,
                              cor: cores.ambarTitulo,
                            ),
                          ),
                        ),
                      BotaoTeste(
                        texto: 'Procurar de novo',
                        aoTocar: widget.aoProcurarDeNovo,
                        estilo: EstiloBotao.secundario,
                        tamanhoTexto: 18,
                        peso: FontWeight.w600,
                      ),
                      Container(height: 1, color: cores.borda),
                      Text(
                        'Sem o headset?',
                        style: TipografiaTeste.next(
                          18,
                          peso: FontWeight.w600,
                          cor: cores.texto,
                        ),
                      ),
                      Semantics(
                        label: 'Cenário simulado',
                        container: true,
                        child: ColunaTeste(
                          espaco: 10,
                          children: [
                            for (final cenario in CenarioSimulado.values)
                              _OpcaoCenario(
                                rotulo: cenario.rotulo,
                                marcada: cenario == _cenario,
                                aoTocar: () =>
                                    setState(() => _cenario = cenario),
                              ),
                          ],
                        ),
                      ),
                      BotaoTeste(
                        texto: 'Usar dados simulados',
                        aoTocar: () => widget.aoUsarSimulados(_cenario),
                      ),
                      BotaoTeste(
                        texto: 'Fechar',
                        aoTocar: widget.aoFechar,
                        estilo: EstiloBotao.link,
                        tamanhoTexto: 16,
                        peso: FontWeight.w400,
                        altura: 44,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha tocável de um aparelho (56+ px).
class _LinhaDispositivo extends StatelessWidget {
  const _LinhaDispositivo({
    required this.dispositivo,
    required this.conectando,
    required this.aoTocar,
  });

  final DispositivoSinal dispositivo;
  final bool conectando;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: conectando ? cores.acento : cores.borda,
        width: 2,
      ),
    );
    final detalhes = [
      if (dispositivo.pareado) 'Pareado',
      if (conectando) 'Conectando…',
    ];
    return Semantics(
      button: true,
      label: [dispositivo.nome, ...detalhes].join('. '),
      excludeSemantics: true,
      child: Material(
        color: conectando ? cores.selecionadoFundo : cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LinhaTeste(
                espaco: 12,
                children: [
                  Expanded(
                    child: ColunaTeste(
                      espaco: 2,
                      children: [
                        Text(
                          dispositivo.nome,
                          style: TipografiaTeste.next(
                            18,
                            peso: FontWeight.w600,
                            cor: cores.texto,
                          ),
                        ),
                        if (dispositivo.pareado)
                          Text(
                            'Pareado',
                            style: TipografiaTeste.next(
                              14,
                              cor: cores.textoSuave,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (conectando)
                    Text(
                      'Conectando…',
                      style: TipografiaTeste.next(14, cor: cores.acentoIcone),
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

/// Opção de cenário no estilo das respostas do ASRS (radio de 24 px).
class _OpcaoCenario extends StatelessWidget {
  const _OpcaoCenario({
    required this.rotulo,
    required this.marcada,
    required this.aoTocar,
  });

  final String rotulo;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = TemaTeste.of(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: marcada ? cores.acento : cores.borda,
        width: 2,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: marcada,
      label: rotulo,
      excludeSemantics: true,
      child: Material(
        color: marcada ? cores.selecionadoFundo : cores.cartao,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          customBorder: forma,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinhaTeste(
                espaco: 14,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: marcada ? cores.acentoIcone : cores.radioAnel,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: marcada
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cores.acentoIcone,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      rotulo,
                      style: TipografiaTeste.next(
                        19,
                        peso: marcada ? FontWeight.w600 : FontWeight.w400,
                        cor: cores.texto,
                      ),
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

/// O `line-height: normal` do navegador vale 1,3 nesta fonte, sem
/// espaçamento extra; o tema do Material herdaria 1,43 e 0,25 do
/// `bodyMedium`. Fixa os valores do CSS, com a entrelinha dividida igualmente.
class _TextoCss extends StatelessWidget {
  const _TextoCss({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const css = TextStyle(
      height: 1.3,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final corpo = (tema.textTheme.bodyMedium ?? const TextStyle()).merge(css);
    return Theme(
      data: tema.copyWith(
        textTheme: tema.textTheme.copyWith(bodyMedium: corpo),
      ),
      child: DefaultTextStyle.merge(style: css, child: child),
    );
  }
}
