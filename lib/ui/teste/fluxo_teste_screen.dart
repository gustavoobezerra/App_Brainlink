import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/teste/controlador_teste.dart';
import '../../services/teste/estimulos_nativos.dart';
import '../../services/teste/fonte_headset.dart';
import '../../services/teste/fonte_simulada.dart';
import '../../services/teste/relogio.dart';
import '../screens/home_screen.dart';
import 'telas/asrs.dart';
import 'telas/calibracao.dart';
import 'telas/calibracao_erro.dart';
import 'telas/calibracao_resultado.dart';
import 'telas/contato_perdido.dart';
import 'telas/contexto.dart';
import 'telas/controle_ritmo.dart';
import 'telas/fim_pesquisa.dart';
import 'telas/folha_dispositivos.dart';
import 'telas/inicio.dart';
import 'telas/instrucoes.dart';
import 'telas/instrucoes_tarefa.dart';
import 'telas/reconexao.dart';
import 'telas/repouso_fim.dart';
import 'telas/repouso_inicio.dart';
import 'telas/repouso_olhos_fechados.dart';
import 'telas/resultados_demo.dart';
import 'telas/saida_antecipada.dart';
import 'telas/sensor.dart';
import 'telas/tarefa.dart';
import 'telas/treino.dart';
import 'telas/volume_baixo.dart';

/// Tela inicial do app: o fluxo do teste de atenção (auditivo ou visual).
///
/// Liga o [ControladorTeste] às telas do protótipo, trata o botão voltar do
/// Android (confirmação de saída), o app indo para segundo plano e o acesso
/// à coleta guiada anterior.
class FluxoTesteScreen extends StatefulWidget {
  const FluxoTesteScreen({
    super.key,
    this.controlador,
    this.relogio,
    this.coletaAnterior,
  });

  /// Controlador injetado (testes); por padrão, o de produção.
  final ControladorTeste? controlador;

  /// Relógio usado para o instante dos toques; deve ser o do controlador.
  final Relogio? relogio;

  /// Tela aberta pelo link "Abrir coleta anterior".
  final WidgetBuilder? coletaAnterior;

  @override
  State<FluxoTesteScreen> createState() => _FluxoTesteScreenState();
}

class _FluxoTesteScreenState extends State<FluxoTesteScreen>
    with WidgetsBindingObserver {
  late final Relogio _relogio;
  late final ControladorTeste _controlador;
  final TextEditingController _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final injetado = widget.controlador;
    if (injetado != null) {
      _relogio = widget.relogio ?? RelogioMonotonico();
      _controlador = injetado;
      return;
    }
    final relogio = RelogioMonotonico();
    final estimulos = EstimulosNativos();
    unawaited(relogio.sincronizar(estimulos.agoraNanos));
    _relogio = relogio;
    _controlador = ControladorTeste(
      estimulos: estimulos,
      relogio: relogio,
      criarFonteHeadset: FonteHeadset.new,
      criarFonteSimulada: (cenario, duracoes) => FonteSimulada(
        cenario: cenario,
        relogio: relogio,
        duracoes: duracoes,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _controlador.aoMudarCicloDeVida(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _abrirColetaAnterior() async {
    // O EEG bruto tem um único ouvinte nativo: a fonte deste fluxo precisa
    // soltar o canal antes de a coleta anterior assiná-lo.
    await _controlador.encerrarParaColetaAnterior();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: widget.coletaAnterior ?? (_) => const HomeScreen(),
      ),
    );
  }

  void _tocar(PointerDownEvent evento) =>
      _controlador.registrarToque(_relogio.nanosDoToque(evento));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          final c = _controlador;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (c.aoVoltar()) unawaited(SystemNavigator.pop());
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: KeyedSubtree(
                    key: ValueKey(c.pausa ?? c.etapa),
                    child: _tela(c),
                  ),
                ),
                if (c.listaDispositivosVisivel && c.etapa == EtapaTeste.sensor)
                  Positioned.fill(
                    child: FolhaDispositivos(
                      dispositivos: c.dispositivos,
                      buscando: c.buscandoDispositivos,
                      erro: c.erroConexao,
                      conectandoId: c.conectandoId,
                      aoEscolher: c.escolherDispositivo,
                      aoProcurarDeNovo: c.procurarDispositivos,
                      aoUsarSimulados: c.usarDadosSimulados,
                      aoFechar: c.fecharDispositivos,
                    ),
                  ),
                if (c.saidaAberta)
                  Positioned.fill(
                    child: SobreposicaoSaida(
                      aoContinuar: c.continuarTeste,
                      aoEncerrar: () {
                        c.confirmarSaida();
                        _codigo.clear();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _tela(ControladorTeste c) {
    switch (c.pausa) {
      case MotivoPausa.contato:
        return TelaContatoPerdido(
          faseRotulo: c.rotuloFasePausada,
          momento: c.momentoPausa,
          contatoRecuperado: c.contatoRecuperado,
          simulada: c.simulada,
          aoRetomar: c.contatoRecuperado ? c.retomar : null,
          aoRecomecarFase: c.recomecarFase,
        );
      case MotivoPausa.bluetooth:
        return TelaReconexao(
          tentativa: c.tentativaReconexao,
          maxTentativas: c.maxTentativasReconexao,
          segundosSemDados: c.segundosSemDados,
          gravadoAte: c.gravadoAte,
          simulada: c.simulada,
          aoTentarAgora: c.tentarReconectarAgora,
          aoEncerrar: c.abrirSaida,
        );
      case null:
        break;
    }
    switch (c.etapa) {
      case EtapaTeste.inicio:
        return TelaInicio(
          versao: c.versao,
          demonstracao: c.demonstracao,
          codigoController: _codigo,
          aoEscolherVersao: c.escolherVersao,
          aoAlternarDemonstracao: c.alternarDemonstracao,
          aoComecar: () => unawaited(c.comecar(_codigo.text)),
          aoAbrirColetaAnterior: () => unawaited(_abrirColetaAnterior()),
        );
      case EtapaTeste.volumeBaixo:
        return TelaVolumeBaixo(
          volume: c.volume,
          aoTocarSomDeTeste: () => unawaited(c.tocarSomDeTeste()),
          aoContinuar: () => unawaited(c.continuarAposVolume()),
        );
      case EtapaTeste.sensor:
        return TelaSensor(
          estado: c.estadoContato,
          segundosEstaveis: c.segundosEstaveis,
          tracado: c.tracado,
          simulada: c.simulada,
          aoContinuar: c.contatoLiberado ? c.continuarAposSensor : null,
          aoAbrirDispositivos: c.abrirDispositivos,
        );
      case EtapaTeste.instrucoes:
        return TelaInstrucoes(aoEntender: c.entendiInstrucoes);
      case EtapaTeste.calibracao:
        return TelaCalibracao(
          bipesTocados: c.bipesTocados,
          totalBipes: c.duracoes.bipesCalibracao,
          piscadasDetectadas: c.piscadasAoVivo,
          qualidade: c.qualidade,
          simulada: c.simulada,
          aoSegurarEncerrar: c.abrirSaida,
        );
      case EtapaTeste.calibracaoResultado:
        return TelaCalibracaoResultado(
          porBipe: c.porBipeCalibracao,
          aoRepetir: c.repetirCalibracao,
          aoContinuar: c.continuarAposCalibracao,
        );
      case EtapaTeste.calibracaoErro:
        return TelaCalibracaoErro(
          porBipe: c.porBipeCalibracao,
          aoRepetir: c.repetirCalibracao,
          aoContinuarMesmoAssim: c.continuarAposCalibracao,
        );
      case EtapaTeste.repousoInicio || EtapaTeste.repousoFinalInicio:
        return TelaRepousoInicio(
          repousoFinal: c.etapa == EtapaTeste.repousoFinalInicio,
          aoComecar: c.comecarRepouso,
          aoSegurarEncerrar: c.abrirSaida,
        );
      case EtapaTeste.repouso || EtapaTeste.repousoFinal:
        return TelaRepousoOlhosFechados(
          restante: c.restanteFase,
          qualidade: c.qualidade,
          simulada: c.simulada,
          aoSegurarEncerrar: c.abrirSaida,
        );
      case EtapaTeste.repousoFim || EtapaTeste.repousoFinalFim:
        return TelaRepousoFim(aoContinuar: c.continuarAposRepouso);
      case EtapaTeste.instrucoesTarefa:
        return TelaInstrucoesTarefa(
          versao: c.versao,
          aoOuvirExemplo: c.ouvirExemplo,
          aoFazerTreino: c.iniciarTreino,
        );
      case EtapaTeste.treino:
        return TelaTreino(
          versao: c.versao,
          indice: c.treinoIndice,
          total: c.treinoTotal,
          feedback: c.feedbackTreino,
          estimuloVisual: c.estimuloVisual,
          concluido: c.treinoConcluido,
          aoTocar: _tocar,
          aoComecarTeste: c.comecarTarefa,
        );
      case EtapaTeste.tarefa || EtapaTeste.ritmo:
        return TelaTarefa(
          versao: c.versao,
          ritmo: c.etapa == EtapaTeste.ritmo,
          restante: c.restanteFase,
          qualidade: c.qualidade,
          toques: c.toquesNaFase,
          estimuloVisual: c.estimuloVisual,
          simulada: c.simulada,
          aoTocar: _tocar,
          aoSegurarEncerrar: c.abrirSaida,
        );
      case EtapaTeste.ritmoInstrucoes:
        return TelaControleRitmo(versao: c.versao, aoComecar: c.iniciarRitmo);
      case EtapaTeste.asrs:
        return TelaAsrs(
          indice: c.asrsIndice,
          resposta: c.respostaAsrsAtual,
          aoResponder: c.responderAsrs,
          aoVoltar: c.asrsIndice > 0 ? c.asrsVoltar : null,
          aoProxima: c.podeAvancarAsrs ? c.asrsProxima : null,
        );
      case EtapaTeste.contexto:
        return TelaContexto(
          respostas: c.contexto,
          aoSono: c.definirSono,
          aoCafeina: c.definirCafeina,
          aoMedicacao: c.definirMedicacao,
          aoLente: c.definirLente,
          aoConcluir: c.contexto.completas ? c.concluirQuestionarios : null,
        );
      case EtapaTeste.fimPesquisa:
        return TelaFimPesquisa(
          aoConcluir: () {
            c.voltarAoInicio();
            _codigo.clear();
          },
        );
      case EtapaTeste.resultadosDemo:
        final resumo = c.resumo;
        if (resumo == null) return const SizedBox.shrink();
        return TelaResultadosDemo(
          resumo: resumo,
          simulada: c.simulada,
          aoNovaDemonstracao: () {
            c.voltarAoInicio();
            _codigo.clear();
          },
        );
    }
  }
}
