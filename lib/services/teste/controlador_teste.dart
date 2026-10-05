import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../../data/models/asrs_screener_6.dart';
import '../../data/models/raw_batch.dart';
import '../../data/models/sessao_teste.dart';
import 'calibracao_piscadas.dart';
import 'cronograma_ensaios.dart';
import 'duracoes_teste.dart';
import 'estimulos.dart';
import 'fonte_sinal.dart';
import 'relogio.dart';
import 'resumo_demonstracao.dart';

/// Telas do teste, na ordem do fluxo (brief de 04/10/2026).
enum EtapaTeste {
  inicio,
  volumeBaixo,
  sensor,
  instrucoes,
  calibracao,
  calibracaoResultado,
  calibracaoErro,
  repousoInicio,
  repouso,
  repousoFim,
  instrucoesTarefa,
  treino,
  tarefa,
  ritmoInstrucoes,
  ritmo,
  repousoFinalInicio,
  repousoFinal,
  repousoFinalFim,
  asrs,
  contexto,
  fimPesquisa,
  resultadosDemo,
}

/// Motivo de o teste estar pausado.
enum MotivoPausa {
  /// O sensor perdeu contato (tela E1).
  contato,

  /// O Bluetooth caiu (tela E2).
  bluetooth,
}

/// Máquina de estados do teste de atenção.
///
/// Dono único do estado do fluxo: etapas, temporização das fases, sons e
/// vibrações, gravação dos lotes de EEG na sessão, pausas por contato ou
/// Bluetooth e a confirmação de saída. As telas só leem este estado e chamam
/// os métodos públicos.
class ControladorTeste extends ChangeNotifier {
  ControladorTeste({
    required EstimulosTeste estimulos,
    required Relogio relogio,
    required FonteSinal Function() criarFonteHeadset,
    required FonteSinal Function(
            CenarioSimulado cenario, DuracoesTeste duracoes)
        criarFonteSimulada,
    DuracoesTeste duracoesHeadset = DuracoesTeste.padrao,
    DuracoesTeste duracoesSimuladas = DuracoesTeste.simulada,
    int Function()? semente,
  })  : _estimulos = estimulos,
        _relogio = relogio,
        _criarFonteHeadset = criarFonteHeadset,
        _criarFonteSimulada = criarFonteSimulada,
        _duracoesHeadset = duracoesHeadset,
        _duracoesSimuladas = duracoesSimuladas,
        _semente = semente ?? (() => DateTime.now().microsecondsSinceEpoch),
        _duracoes = duracoesHeadset;

  final EstimulosTeste _estimulos;
  final Relogio _relogio;
  final FonteSinal Function() _criarFonteHeadset;
  final FonteSinal Function(CenarioSimulado, DuracoesTeste) _criarFonteSimulada;
  final DuracoesTeste _duracoesHeadset;
  final DuracoesTeste _duracoesSimuladas;
  final int Function() _semente;

  static const int _nanosPorMs = 1000000;
  static const int _nanosPorSegundo = 1000000000;

  // ---------------------------------------------------------------------------
  // Estado público.

  EtapaTeste _etapa = EtapaTeste.inicio;
  EtapaTeste get etapa => _etapa;

  VersaoTeste _versao = VersaoTeste.auditiva;
  VersaoTeste get versao => _versao;

  bool _demonstracao = false;
  bool get demonstracao => _demonstracao;

  DuracoesTeste _duracoes;
  DuracoesTeste get duracoes => _duracoes;

  SessaoTeste? _sessao;
  SessaoTeste? get sessao => _sessao;

  FonteSinal? _fonte;
  bool get simulada => _fonte?.simulada ?? false;

  /// Volume de mídia (tela "Aumente o volume").
  VolumeMidia? _volume;
  VolumeMidia? get volume => _volume;

  // Sensor e lista de aparelhos.
  EstadoContato _estadoContato = EstadoContato.procurando;
  EstadoContato get estadoContato => _estadoContato;

  int _segundosEstaveis = 0;

  /// Segmentos preenchidos (0 a 10) da barra de estabilidade do contato.
  int get segundosEstaveis => _segundosEstaveis;

  bool get contatoLiberado => _segundosEstaveis >= 10;

  List<double>? _tracado;

  /// Últimos ~2 s do EEG em µV, para o traçado do pesquisador.
  List<double>? get tracado => _tracado;

  bool _listaVisivel = false;
  bool get listaDispositivosVisivel => _listaVisivel;

  List<DispositivoSinal> _dispositivos = const [];
  List<DispositivoSinal> get dispositivos => _dispositivos;

  bool _buscando = false;
  bool get buscandoDispositivos => _buscando;

  String? _erroConexao;
  String? get erroConexao => _erroConexao;

  String? _conectandoId;
  String? get conectandoId => _conectandoId;

  // Calibração.
  int _bipesTocados = 0;
  int get bipesTocados => _bipesTocados;

  int _piscadasAoVivo = 0;
  int get piscadasAoVivo => _piscadasAoVivo;

  /// Resultado por bipe da última tentativa concluída.
  List<bool> get porBipeCalibracao =>
      _sessao?.ultimaCalibracao?.porBipe ?? const [];

  // Treino.
  int _treinoIndice = 0;
  int get treinoIndice => _treinoIndice;
  int get treinoTotal => _duracoes.treinoComuns + _duracoes.treinoRaros;

  FeedbackTreino? _feedback;
  FeedbackTreino? get feedbackTreino => _feedback;

  bool _treinoConcluido = false;
  bool get treinoConcluido => _treinoConcluido;

  EstimuloVisual _estimuloVisual = EstimuloVisual.nenhum;
  EstimuloVisual get estimuloVisual => _estimuloVisual;

  // Tarefa e ritmo.
  int _toquesNaFase = 0;
  int get toquesNaFase => _toquesNaFase;

  // Questionários.
  int _asrsIndice = 0;
  int get asrsIndice => _asrsIndice;

  AsrsResponse? get respostaAsrsAtual => _sessao?.asrs[_asrsIndice];

  RespostasContexto get contexto => _sessao?.contexto ?? RespostasContexto();

  ResumoDemonstracao? _resumo;
  ResumoDemonstracao? get resumo => _resumo;

  // Pausas.
  MotivoPausa? _pausa;
  MotivoPausa? get pausa => _pausa;

  FaseTeste? _fasePausada;
  FaseTeste? get fasePausada => _fasePausada;

  EtapaTeste? _etapaRetorno;

  Duration _momentoPausa = Duration.zero;

  /// Tempo restante da fase no instante da pausa ("pausado em Tarefa, 1:47").
  Duration get momentoPausa => _momentoPausa;

  bool _contatoRecuperado = false;
  bool get contatoRecuperado => _contatoRecuperado;

  int _tentativaReconexao = 0;
  int get tentativaReconexao => _tentativaReconexao;
  int get maxTentativasReconexao => _duracoes.tentativasReconexao;

  bool _reconectando = false;

  // Saída antecipada.
  bool _saidaAberta = false;
  bool get saidaAberta => _saidaAberta;

  /// Etapa 1 a 7 da barra de progresso (o brief agrupa as telas em 7 etapas).
  String get rotuloFasePausada =>
      (_fasePausada ?? _ultimaFaseGravada)?.rotulo ??
      FaseTeste.calibracao.rotulo;

  /// Última fase com dados gravados ("gravado até Repouso").
  String get gravadoAte => _ultimaFaseGravada?.rotulo ?? 'o início';

  FaseTeste? get _ultimaFaseGravada {
    FaseTeste? ultima;
    final sessao = _sessao;
    if (sessao == null) return null;
    for (final fase in FaseTeste.values) {
      if ((sessao.fases[fase]?.trechos.isNotEmpty ?? false) ||
          (fase == FaseTeste.calibracao && sessao.calibracoes.isNotEmpty)) {
        ultima = fase;
      }
    }
    return ultima;
  }

  int get segundosSemDados {
    final ultimo = _ultimoLoteNanos;
    if (ultimo == null) return 0;
    return ((_relogio.agoraNanos() - ultimo) / _nanosPorSegundo)
        .floor()
        .clamp(0, 9999);
  }

  /// Qualidade do sinal para o pontinho do pesquisador.
  QualidadeSinal get qualidade {
    final q = _qualidadeAtual;
    final instante = _qualidadeNanos;
    if (q == null ||
        instante == null ||
        _relogio.agoraNanos() - instante > 3 * _nanosPorSegundo ||
        _fonte?.estadoConexao != EstadoConexao.conectado) {
      return QualidadeSinal.semDados;
    }
    if (q <= 50) return QualidadeSinal.boa;
    if (q < 200) return QualidadeSinal.ajuste;
    return QualidadeSinal.ruim;
  }

  /// Tempo que falta na fase em andamento (ou na pausada).
  Duration get restanteFase {
    final execucao = _execucao;
    if (execucao == null) return Duration.zero;
    final restanteMs = execucao.duracaoMs - _decorridoMs(execucao);
    return Duration(milliseconds: math.max(0, restanteMs));
  }

  // ---------------------------------------------------------------------------
  // Estado interno.

  bool _descartado = false;
  final List<StreamSubscription<Object?>> _assinaturas = [];
  Timer? _pulso;
  Timer? _timerVolume;
  Timer? _timerReconexao;
  Timer? _timerTreino;
  Timer? _timerFigura;
  Timer? _aguardaDados;
  void Function()? _aposDados;
  int? _aguardaDadosNanos;

  int? _qualidadeAtual;
  int? _qualidadeNanos;
  int? _inicioEstavelNanos;
  int? _inicioRuimNanos;
  int? _inicioBomNaPausaNanos;
  int? _ultimoLoteNanos;

  _Execucao? _execucao;
  TentativaCalibracao? _tentativa;
  math.Random _aleatorio = math.Random(1);

  List<Ensaio> _ensaiosTreino = const [];
  bool _janelaTreinoAberta = false;
  Ensaio? _ensaioTreinoAtual;
  bool _treinoCongelado = false;

  ControleSimulacao? get _controle {
    final fonte = _fonte;
    return fonte is ControleSimulacao ? fonte as ControleSimulacao : null;
  }

  // ---------------------------------------------------------------------------
  // Início.

  void escolherVersao(VersaoTeste versao) {
    if (_etapa != EtapaTeste.inicio || _versao == versao) return;
    _versao = versao;
    notifyListeners();
  }

  void alternarDemonstracao() {
    if (_etapa != EtapaTeste.inicio) return;
    _demonstracao = !_demonstracao;
    notifyListeners();
  }

  String _codigo = '';
  bool _comecando = false;

  /// "Começar": prepara os sons, liga a tela acesa e confere o volume.
  Future<void> comecar(String codigoParticipante) async {
    if (_etapa != EtapaTeste.inicio || _comecando) return;
    _comecando = true;
    try {
      await _comecar(codigoParticipante);
    } finally {
      _comecando = false;
    }
  }

  Future<void> _comecar(String codigoParticipante) async {
    _codigo = codigoParticipante.trim();
    unawaited(_estimulos.preparar());
    unawaited(_estimulos.manterTelaAcesa(true));
    _iniciarPulso();
    if (_versao == VersaoTeste.auditiva) {
      final volume = await _estimulos.volumeMidia();
      if (_descartado) return;
      _volume = volume;
      if (volume != null && volume.fracao < _duracoes.limiteVolumeBaixo) {
        _irPara(EtapaTeste.volumeBaixo);
        _timerVolume = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _atualizarVolume(),
        );
        return;
      }
    }
    await _entrarSensor();
  }

  Future<void> _atualizarVolume() async {
    final volume = await _estimulos.volumeMidia();
    if (_descartado || _etapa != EtapaTeste.volumeBaixo) return;
    if (volume?.atual != _volume?.atual || volume?.maximo != _volume?.maximo) {
      _volume = volume;
      notifyListeners();
    }
  }

  /// "Tocar som de teste": o tom grave e, em seguida, o agudo.
  Future<void> tocarSomDeTeste() async {
    await _estimulos.tocar(SomTeste.grave);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_descartado) return;
    await _estimulos.tocar(SomTeste.agudo);
  }

  Future<void> continuarAposVolume() async {
    if (_etapa != EtapaTeste.volumeBaixo) return;
    _timerVolume?.cancel();
    await _entrarSensor();
  }

  // ---------------------------------------------------------------------------
  // Sensor e conexão.

  Future<void> _entrarSensor() async {
    _irPara(EtapaTeste.sensor);
    _inicioEstavelNanos = null;
    _atualizarContato();
    var fonte = _fonte;
    if (fonte == null) {
      fonte = _criarFonteHeadset();
      _usarFonte(fonte, _duracoesHeadset);
    }
    if (fonte.estadoConexao == EstadoConexao.conectado) return;
    await _autoConectar();
  }

  Future<void> _autoConectar() async {
    final fonte = _fonte;
    if (fonte == null) return;
    final resultado = await fonte.autoConectar();
    if (_descartado || !identical(fonte, _fonte)) return;
    switch (resultado) {
      case AutoConectado():
        _listaVisivel = false;
        _erroConexao = null;
      case AutoEscolher(:final dispositivos):
        _dispositivos = dispositivos;
        _listaVisivel = true;
      case AutoFalhou(:final motivo):
        _erroConexao = motivo;
        _listaVisivel = true;
    }
    notifyListeners();
  }

  void _usarFonte(FonteSinal fonte, DuracoesTeste duracoes) {
    for (final assinatura in _assinaturas) {
      unawaited(assinatura.cancel());
    }
    _assinaturas.clear();
    _fonte = fonte;
    _duracoes = duracoes;
    _qualidadeAtual = null;
    _qualidadeNanos = null;
    _ultimoLoteNanos = null;
    _tracado = null;
    _assinaturas
      ..add(fonte.lotes.listen(_aoLote))
      ..add(fonte.qualidade.listen(_aoQualidade))
      ..add(fonte.conexao.listen(_aoConexao));
  }

  void abrirDispositivos() {
    if (_etapa != EtapaTeste.sensor) return;
    _listaVisivel = true;
    notifyListeners();
    if (_dispositivos.isEmpty && !(_fonte?.simulada ?? false)) {
      unawaited(procurarDispositivos());
    }
  }

  void fecharDispositivos() {
    if (!_listaVisivel) return;
    _listaVisivel = false;
    notifyListeners();
  }

  Future<void> procurarDispositivos() async {
    if (_buscando) return;
    var fonte = _fonte;
    if (fonte == null || fonte.simulada) {
      await fonte?.dispose();
      fonte = _criarFonteHeadset();
      _usarFonte(fonte, _duracoesHeadset);
    }
    _buscando = true;
    _erroConexao = null;
    notifyListeners();
    try {
      final encontrados = await fonte.buscar();
      if (_descartado) return;
      _dispositivos = encontrados;
    } catch (erro) {
      if (_descartado) return;
      _erroConexao = _mensagem(erro);
    } finally {
      if (!_descartado) {
        _buscando = false;
        notifyListeners();
      }
    }
  }

  Future<void> escolherDispositivo(DispositivoSinal dispositivo) async {
    var fonte = _fonte;
    if (fonte == null || fonte.simulada) {
      await fonte?.dispose();
      fonte = _criarFonteHeadset();
      _usarFonte(fonte, _duracoesHeadset);
    }
    _conectandoId = dispositivo.id;
    _erroConexao = null;
    notifyListeners();
    try {
      await fonte.conectar(dispositivo);
      if (_descartado) return;
      _listaVisivel = false;
    } catch (erro) {
      if (_descartado) return;
      _erroConexao = _mensagem(erro);
    } finally {
      if (!_descartado) {
        _conectandoId = null;
        notifyListeners();
      }
    }
  }

  /// Troca o headset pela simulação (tempos encurtados).
  Future<void> usarDadosSimulados(CenarioSimulado cenario) async {
    final anterior = _fonte;
    _fonte = null;
    await anterior?.dispose();
    if (_descartado) return;
    _usarFonte(
        _criarFonteSimulada(cenario, _duracoesSimuladas), _duracoesSimuladas);
    _listaVisivel = false;
    _erroConexao = null;
    _inicioEstavelNanos = null;
    _atualizarContato();
    notifyListeners();
    await _autoConectar();
  }

  /// "Continuar" do sensor: abre a sessão e segue para as instruções.
  void continuarAposSensor() {
    if (_etapa != EtapaTeste.sensor || !contatoLiberado) return;
    _sessao = SessaoTeste(
      codigoParticipante: _demonstracao ? '' : _codigo,
      versao: _versao,
      demonstracao: _demonstracao,
      simulada: simulada,
      semente: _semente(),
    );
    _aleatorio = math.Random(_sessao!.semente);
    _irPara(EtapaTeste.instrucoes);
  }

  void entendiInstrucoes() {
    if (_etapa != EtapaTeste.instrucoes) return;
    _iniciarCalibracao();
  }

  // ---------------------------------------------------------------------------
  // Calibração de piscadas.

  void _iniciarCalibracao() {
    final sessao = _sessao;
    if (sessao == null) return;
    final agora = _relogio.agoraNanos();
    final tentativa = TentativaCalibracao(agora);
    sessao.calibracoes.add(tentativa);
    _tentativa = tentativa;
    _bipesTocados = 0;
    _piscadasAoVivo = 0;
    _controle?.definirEstado(EstadoSimulado.olhosAbertos);
    final eventos = <_Evento>[];
    for (var k = 0; k < _duracoes.bipesCalibracao; k++) {
      final variacao = _duracoes.variacaoBipe.inMilliseconds;
      final base = _duracoes.primeiroBipe.inMilliseconds +
          k * _duracoes.intervaloBipes.inMilliseconds;
      final deslocamento =
          variacao == 0 ? 0 : _aleatorio.nextInt(2 * variacao + 1) - variacao;
      eventos.add(_Evento(base + deslocamento, _tocarBipeCalibracao));
    }
    _irPara(EtapaTeste.calibracao);
    _iniciarExecucao(
      _Execucao(
        fase: FaseTeste.calibracao,
        duracaoMs: _duracoes.calibracao.inMilliseconds,
        eventos: eventos,
        aoTerminar: _terminarCalibracao,
        monitorarContato: true,
      ),
    );
  }

  Future<void> _tocarBipeCalibracao() async {
    final tentativa = _tentativa;
    if (tentativa == null) return;
    final pedido = _relogio.agoraNanos();
    final inicio = await _estimulos.tocar(SomTeste.bipeCalibracao) ?? pedido;
    if (_descartado || !identical(tentativa, _tentativa)) return;
    tentativa.bipesNanos.add(inicio);
    _bipesTocados = tentativa.bipesNanos.length;
    _controle?.aoBipeCalibracao(inicio);
    notifyListeners();
  }

  void _terminarCalibracao() {
    final tentativa = _tentativa;
    final sessao = _sessao;
    if (tentativa == null || sessao == null) return;
    tentativa.fimNanos = _relogio.agoraNanos();
    _aguardarDadosAte(tentativa.fimNanos!, () {
      if (!identical(tentativa, _tentativa)) return;
      final resultado = _avaliarCalibracao(sessao, tentativa);
      tentativa
        ..porBipe = resultado.porBipe
        ..extras = resultado.extras;
      _tentativa = null;
      _irPara(
        resultado.detectadas >= _duracoes.bipesCalibracao
            ? EtapaTeste.calibracaoResultado
            : EtapaTeste.calibracaoErro,
      );
    });
  }

  ResultadoCalibracao _avaliarCalibracao(
    SessaoTeste sessao,
    TentativaCalibracao tentativa,
  ) {
    try {
      return avaliarCalibracao(
        lotes: sessao.lotes,
        bipesNanos: tentativa.bipesNanos,
        inicioNanos: tentativa.inicioNanos,
        fimNanos: tentativa.fimNanos!,
        inicioJanela: _duracoes.janelaPiscadaInicio,
        fimJanela: _duracoes.janelaPiscadaFim,
      );
    } catch (_) {
      return ResultadoCalibracao(
        porBipe: List<bool>.filled(tentativa.bipesNanos.length, false),
        extras: 0,
      );
    }
  }

  void repetirCalibracao() {
    if (_etapa != EtapaTeste.calibracaoResultado &&
        _etapa != EtapaTeste.calibracaoErro) {
      return;
    }
    _iniciarCalibracao();
  }

  void continuarAposCalibracao() {
    if (_etapa != EtapaTeste.calibracaoResultado &&
        _etapa != EtapaTeste.calibracaoErro) {
      return;
    }
    _irPara(EtapaTeste.repousoInicio);
  }

  // ---------------------------------------------------------------------------
  // Repousos de olhos fechados.

  void comecarRepouso() {
    final final_ = _etapa == EtapaTeste.repousoFinalInicio;
    if (_etapa != EtapaTeste.repousoInicio && !final_) return;
    final fase = final_ ? FaseTeste.repousoFinal : FaseTeste.repouso;
    _irPara(final_ ? EtapaTeste.repousoFinal : EtapaTeste.repouso);
    _controle?.definirEstado(EstadoSimulado.olhosFechados);
    _sinalComeco();
    _iniciarExecucao(
      _Execucao(
        fase: fase,
        duracaoMs: (final_ ? _duracoes.repousoFinal : _duracoes.repouso)
            .inMilliseconds,
        eventos: const [],
        aoTerminar: () {
          _sinalFim();
          _controle?.definirEstado(EstadoSimulado.olhosAbertos);
          _irPara(final_ ? EtapaTeste.repousoFinalFim : EtapaTeste.repousoFim);
        },
        monitorarContato: true,
      ),
    );
  }

  void continuarAposRepouso() {
    if (_etapa == EtapaTeste.repousoFim) {
      _irPara(EtapaTeste.instrucoesTarefa);
    } else if (_etapa == EtapaTeste.repousoFinalFim) {
      _asrsIndice = 0;
      _irPara(EtapaTeste.asrs);
    }
  }

  // ---------------------------------------------------------------------------
  // Instruções da tarefa e treino.

  /// Exemplos "▶ Som grave" e "▶ Som agudo".
  void ouvirExemplo(TipoEstimulo tipo) {
    unawaited(_estimulos
        .tocar(tipo == TipoEstimulo.comum ? SomTeste.grave : SomTeste.agudo));
  }

  void iniciarTreino() {
    if (_etapa != EtapaTeste.instrucoesTarefa) return;
    final sessao = _sessao;
    if (sessao == null) return;
    _ensaiosTreino = gerarCronograma(
      comuns: _duracoes.treinoComuns,
      raros: _duracoes.treinoRaros,
      aleatorio: _aleatorio,
      primeirosComuns: 1,
      intervaloMinimo: _duracoes.intervaloMinimo,
      intervaloMaximo: _duracoes.intervaloMaximo,
    );
    sessao.treino
      ..clear()
      ..addAll(_ensaiosTreino);
    _treinoIndice = 0;
    _feedback = null;
    _treinoConcluido = false;
    _estimuloVisual = _versao == VersaoTeste.visual
        ? EstimuloVisual.fixacao
        : EstimuloVisual.nenhum;
    _irPara(EtapaTeste.treino);
    _agendarTreino(const Duration(seconds: 1));
  }

  void _agendarTreino(Duration atraso) {
    _timerTreino?.cancel();
    _timerTreino = Timer(atraso, _proximoEnsaioTreino);
  }

  Future<void> _proximoEnsaioTreino() async {
    if (_etapa != EtapaTeste.treino || _treinoCongelado) return;
    if (_treinoIndice >= _ensaiosTreino.length) {
      _treinoConcluido = true;
      _estimuloVisual = EstimuloVisual.nenhum;
      notifyListeners();
      return;
    }
    final ensaio = _ensaiosTreino[_treinoIndice];
    _treinoIndice++;
    _feedback = null;
    _ensaioTreinoAtual = ensaio;
    ensaio.inicioNanos = await _apresentar(ensaio.tipo);
    if (_descartado || _etapa != EtapaTeste.treino) return;
    if (_treinoCongelado) {
      // Pausa ou saída chegou durante a apresentação: repete este ensaio.
      ensaio.interrompido = true;
      if (_treinoIndice > 0) _treinoIndice--;
      return;
    }
    _janelaTreinoAberta = true;
    notifyListeners();
    _timerTreino = Timer(_duracoes.janelaTreino, () {
      if (!_janelaTreinoAberta) return;
      _janelaTreinoAberta = false;
      _mostrarFeedback(
        ensaio.tipo == TipoEstimulo.comum
            ? FeedbackTreino.naoTocou
            : FeedbackTreino.certo,
      );
    });
  }

  void _mostrarFeedback(FeedbackTreino feedback) {
    _feedback = feedback;
    _timerFigura?.cancel();
    if (_versao == VersaoTeste.visual) _estimuloVisual = EstimuloVisual.fixacao;
    unawaited(_estimulos.vibrar(
      feedback == FeedbackTreino.certo
          ? VibracaoTeste.firme
          : VibracaoTeste.fraca,
    ));
    notifyListeners();
    _timerTreino?.cancel();
    _timerTreino = Timer(_duracoes.feedbackTreino, () {
      if (_etapa != EtapaTeste.treino) return;
      _feedback = null;
      notifyListeners();
      _agendarTreino(_duracoes.pausaEntreEnsaiosTreino);
    });
  }

  void comecarTarefa() {
    if (_etapa != EtapaTeste.treino || !_treinoConcluido) return;
    _iniciarTarefa();
  }

  // ---------------------------------------------------------------------------
  // Tarefa e bloco de ritmo.

  void _iniciarTarefa() {
    final sessao = _sessao;
    if (sessao == null) return;
    final ensaios = gerarCronograma(
      comuns: _duracoes.tarefaComuns,
      raros: _duracoes.tarefaRaros,
      aleatorio: _aleatorio,
      intervaloMinimo: _duracoes.intervaloMinimo,
      intervaloMaximo: _duracoes.intervaloMaximo,
    );
    sessao.tarefa
      ..clear()
      ..addAll(ensaios);
    sessao.toques.removeWhere((t) => t.fase == FaseTeste.tarefa);
    _iniciarBlocoEstimulos(
      etapa: EtapaTeste.tarefa,
      fase: FaseTeste.tarefa,
      ensaios: ensaios,
      aoTerminar: () => _irPara(EtapaTeste.ritmoInstrucoes),
    );
  }

  void iniciarRitmo() {
    if (_etapa != EtapaTeste.ritmoInstrucoes) return;
    final sessao = _sessao;
    if (sessao == null) return;
    final ensaios = gerarRitmo(
      quantidade: _duracoes.ritmoEnsaios,
      aleatorio: _aleatorio,
      intervaloMinimo: _duracoes.intervaloMinimo,
      intervaloMaximo: _duracoes.intervaloMaximo,
    );
    sessao.ritmo
      ..clear()
      ..addAll(ensaios);
    sessao.toques.removeWhere((t) => t.fase == FaseTeste.ritmo);
    _iniciarBlocoEstimulos(
      etapa: EtapaTeste.ritmo,
      fase: FaseTeste.ritmo,
      ensaios: ensaios,
      aoTerminar: () => _irPara(EtapaTeste.repousoFinalInicio),
    );
  }

  void _iniciarBlocoEstimulos({
    required EtapaTeste etapa,
    required FaseTeste fase,
    required List<Ensaio> ensaios,
    required void Function() aoTerminar,
  }) {
    _toquesNaFase = 0;
    _estimuloVisual = _versao == VersaoTeste.visual
        ? EstimuloVisual.fixacao
        : EstimuloVisual.nenhum;
    _controle?.definirEstado(
      _versao == VersaoTeste.auditiva
          ? EstadoSimulado.tarefaOlhosFechados
          : EstadoSimulado.tarefaOlhosAbertos,
    );
    _irPara(etapa);
    _sinalComeco();
    final eventos = <_Evento>[];
    var deslocamento = _duracoes.preparacaoTarefa.inMilliseconds;
    for (final ensaio in ensaios) {
      eventos.add(_Evento(deslocamento, () => _apresentarEnsaio(ensaio)));
      deslocamento += ensaio.intervaloMs;
    }
    _iniciarExecucao(
      _Execucao(
        fase: fase,
        duracaoMs: deslocamento,
        eventos: eventos,
        ensaios: ensaios,
        aoTerminar: () {
          _timerFigura?.cancel();
          _estimuloVisual = EstimuloVisual.nenhum;
          _sinalFim();
          _controle?.definirEstado(EstadoSimulado.olhosAbertos);
          aoTerminar();
        },
        monitorarContato: true,
      ),
    );
  }

  Future<void> _apresentarEnsaio(Ensaio ensaio) async {
    final execucao = _execucao;
    if (execucao == null) return;
    execucao.ensaioAberto = ensaio;
    ensaio.inicioNanos = await _apresentar(ensaio.tipo);
    notifyListeners();
  }

  /// Toca o tom ou mostra a figura por 250 ms; devolve o início.
  Future<int> _apresentar(TipoEstimulo tipo) async {
    final pedido = _relogio.agoraNanos();
    if (_versao == VersaoTeste.auditiva) {
      final som = tipo == TipoEstimulo.comum ? SomTeste.grave : SomTeste.agudo;
      return await _estimulos.tocar(som) ?? pedido;
    }
    _estimuloVisual =
        tipo == TipoEstimulo.comum ? EstimuloVisual.comum : EstimuloVisual.raro;
    notifyListeners();
    _timerFigura?.cancel();
    _timerFigura = Timer(_duracoes.exibicaoFigura, () {
      if (_estimuloVisual == EstimuloVisual.comum ||
          _estimuloVisual == EstimuloVisual.raro) {
        _estimuloVisual = EstimuloVisual.fixacao;
        notifyListeners();
      }
    });
    return pedido;
  }

  /// Toque na área de resposta (treino, tarefa ou ritmo).
  void registrarToque(int nanos) {
    final sessao = _sessao;
    if (sessao == null || _saidaAberta || _pausa != null) return;
    switch (_etapa) {
      case EtapaTeste.treino:
        if (_treinoConcluido) return;
        sessao.toques.add(ToqueRegistrado(nanos, FaseTeste.treino));
        final ensaio = _ensaioTreinoAtual;
        if (!_janelaTreinoAberta || ensaio == null) return;
        final inicio = ensaio.inicioNanos;
        if (inicio != null &&
            nanos - inicio <
                _duracoes.respostaMinima.inMilliseconds * _nanosPorMs) {
          return;
        }
        _janelaTreinoAberta = false;
        ensaio.toqueNanos = nanos;
        _mostrarFeedback(
          ensaio.tipo == TipoEstimulo.comum
              ? FeedbackTreino.certo
              : FeedbackTreino.naoTocar,
        );
      case EtapaTeste.tarefa || EtapaTeste.ritmo:
        if (_execucao == null) return;
        sessao.toques.add(ToqueRegistrado(
          nanos,
          _etapa == EtapaTeste.tarefa ? FaseTeste.tarefa : FaseTeste.ritmo,
        ));
        _toquesNaFase++;
        notifyListeners();
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Questionários.

  void responderAsrs(AsrsResponse resposta) {
    final sessao = _sessao;
    if (_etapa != EtapaTeste.asrs || sessao == null) return;
    sessao.asrs[_asrsIndice] = resposta;
    notifyListeners();
  }

  bool get podeAvancarAsrs => respostaAsrsAtual != null;

  void asrsProxima() {
    if (_etapa != EtapaTeste.asrs || !podeAvancarAsrs) return;
    if (_asrsIndice < AsrsScreener6.itemCount - 1) {
      _asrsIndice++;
      notifyListeners();
    } else {
      _irPara(EtapaTeste.contexto);
    }
  }

  void asrsVoltar() {
    if (_etapa != EtapaTeste.asrs || _asrsIndice == 0) return;
    _asrsIndice--;
    notifyListeners();
  }

  void definirSono(HorasSono valor) => _alterarContexto((c) => c.sono = valor);

  void definirCafeina(bool valor) => _alterarContexto((c) => c.cafeina = valor);

  void definirMedicacao(MedicacaoAtencao valor) =>
      _alterarContexto((c) => c.medicacao = valor);

  void definirLente(bool valor) =>
      _alterarContexto((c) => c.lenteContato = valor);

  void _alterarContexto(void Function(RespostasContexto) alterar) {
    final sessao = _sessao;
    if (_etapa != EtapaTeste.contexto || sessao == null) return;
    alterar(sessao.contexto);
    notifyListeners();
  }

  /// "Concluir" dos questionários: fim (pesquisa) ou resultados (demonstração).
  void concluirQuestionarios() {
    final sessao = _sessao;
    if (_etapa != EtapaTeste.contexto ||
        sessao == null ||
        !sessao.contexto.completas) {
      return;
    }
    sessao.encerramento = EncerramentoSessao.completo;
    unawaited(_estimulos.manterTelaAcesa(false));
    if (sessao.demonstracao) {
      _resumo = montarResumoDemonstracao(sessao, _duracoes);
      _irPara(EtapaTeste.resultadosDemo);
    } else {
      _irPara(EtapaTeste.fimPesquisa);
    }
  }

  /// "Concluir" (10A) e "Nova demonstração" (10B): volta ao início.
  void voltarAoInicio() {
    if (_etapa != EtapaTeste.fimPesquisa &&
        _etapa != EtapaTeste.resultadosDemo) {
      return;
    }
    _reiniciar();
  }

  // ---------------------------------------------------------------------------
  // Pausa por contato (E1) e por Bluetooth (E2).

  void _pausar(MotivoPausa motivo) {
    final execucao = _execucao;
    if (_pausa == null) {
      _etapaRetorno = _etapa;
      _fasePausada = execucao?.fase;
      if (execucao != null) {
        _momentoPausa = restanteFase;
        _congelar(execucao);
      }
      if (_etapa == EtapaTeste.treino) _congelarTreino();
    }
    _pausa = motivo;
    _contatoRecuperado = false;
    _inicioBomNaPausaNanos = null;
    if (motivo == MotivoPausa.contato) {
      unawaited(_estimulos.tocar(SomTeste.alerta));
      unawaited(_estimulos.vibrar(VibracaoTeste.longa));
    } else {
      _tentativaReconexao = 0;
      unawaited(_tentarReconectar());
    }
    notifyListeners();
  }

  /// "Retomar" (E1): continua a fase de onde parou (a calibração recomeça).
  void retomar() {
    if (_pausa != MotivoPausa.contato || !_contatoRecuperado) return;
    final execucao = _execucao;
    final retorno = _etapaRetorno;
    _limparPausa();
    if (execucao != null && execucao.congelada) {
      if (execucao.fase == FaseTeste.calibracao) {
        _descartarExecucao();
        _iniciarCalibracao();
        return;
      }
      _etapa = retorno ?? _etapa;
      if (execucao.fase.olhosFechados(_versao)) {
        _sinalComeco();
        if (execucao.fase == FaseTeste.repouso ||
            execucao.fase == FaseTeste.repousoFinal) {
          _controle?.definirEstado(EstadoSimulado.olhosFechados);
        }
      }
      _retomarExecucao(execucao, preparacaoMs: _preparacaoRetomadaMs(execucao));
      notifyListeners();
      return;
    }
    if (retorno == EtapaTeste.treino) {
      _etapa = retorno!;
      _descongelarTreino();
      notifyListeners();
      return;
    }
    if (retorno != null) _irPara(retorno);
  }

  /// "Recomeçar esta fase" (E1): descarta a fase e volta à sua tela inicial.
  void recomecarFase() {
    if (_pausa == null) return;
    final execucao = _execucao;
    final retorno = _etapaRetorno;
    _limparPausa();
    if (execucao == null) {
      if (retorno == EtapaTeste.treino) {
        _etapa = EtapaTeste.instrucoesTarefa;
        _treinoCongelado = false;
        iniciarTreino();
        return;
      }
      if (retorno != null) _irPara(retorno);
      return;
    }
    final fase = execucao.fase;
    _descartarFase(execucao);
    switch (fase) {
      case FaseTeste.calibracao:
        _iniciarCalibracao();
      case FaseTeste.repouso:
        _irPara(EtapaTeste.repousoInicio);
      case FaseTeste.tarefa:
        _treinoConcluido = true;
        _feedback = null;
        _irPara(EtapaTeste.treino);
      case FaseTeste.ritmo:
        _irPara(EtapaTeste.ritmoInstrucoes);
      case FaseTeste.repousoFinal:
        _irPara(EtapaTeste.repousoFinalInicio);
      case FaseTeste.treino:
        _irPara(EtapaTeste.instrucoesTarefa);
    }
  }

  /// "Tentar agora" (E2).
  void tentarReconectarAgora() {
    if (_pausa != MotivoPausa.bluetooth || _reconectando) return;
    _timerReconexao?.cancel();
    if (_tentativaReconexao >= _duracoes.tentativasReconexao) {
      _tentativaReconexao = 0;
    }
    unawaited(_tentarReconectar());
  }

  Future<void> _tentarReconectar() async {
    final fonte = _fonte;
    if (fonte == null || _reconectando) return;
    _reconectando = true;
    _tentativaReconexao++;
    notifyListeners();
    final conectou = await fonte.reconectar();
    _reconectando = false;
    if (_descartado || _pausa != MotivoPausa.bluetooth) return;
    if (conectou) {
      _pausa = MotivoPausa.contato;
      _contatoRecuperado = false;
      _inicioBomNaPausaNanos = null;
      _ultimoLoteNanos = _relogio.agoraNanos();
      notifyListeners();
      return;
    }
    if (_tentativaReconexao < _duracoes.tentativasReconexao) {
      _timerReconexao = Timer(_duracoes.intervaloReconexao, () {
        if (_pausa == MotivoPausa.bluetooth) unawaited(_tentarReconectar());
      });
    }
    notifyListeners();
  }

  void _limparPausa() {
    _pausa = null;
    _etapaRetorno = null;
    _fasePausada = null;
    _contatoRecuperado = false;
    _inicioBomNaPausaNanos = null;
    _inicioRuimNanos = null;
    _timerReconexao?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Saída antecipada (E3) e botão voltar.

  /// Abre a confirmação de saída (segurar 2 s ou "voltar" do Android).
  void abrirSaida() {
    if (_saidaAberta || _etapa == EtapaTeste.inicio) return;
    _saidaAberta = true;
    final execucao = _execucao;
    if (_pausa == null) {
      if (execucao != null && !execucao.congelada) _congelar(execucao);
      if (_etapa == EtapaTeste.treino) _congelarTreino();
    }
    notifyListeners();
  }

  /// "Continuar o teste".
  void continuarTeste() {
    if (!_saidaAberta) return;
    _saidaAberta = false;
    if (_pausa == null) {
      final execucao = _execucao;
      if (execucao != null && execucao.congelada) {
        if (execucao.fase == FaseTeste.calibracao) {
          _descartarExecucao();
          _iniciarCalibracao();
          return;
        }
        _retomarExecucao(execucao,
            preparacaoMs: _preparacaoRetomadaMs(execucao));
      } else if (_etapa == EtapaTeste.treino) {
        _descongelarTreino();
      }
    }
    notifyListeners();
  }

  /// "Segure 2 s para encerrar": descarta a sessão e volta ao início.
  void confirmarSaida() {
    if (!_saidaAberta) return;
    _sessao?.encerramento = EncerramentoSessao.abortado;
    _reiniciar();
  }

  /// Botão "voltar" do Android. Devolve `true` se o app pode sair.
  bool aoVoltar() {
    if (_listaVisivel) {
      fecharDispositivos();
      return false;
    }
    if (_saidaAberta) {
      continuarTeste();
      return false;
    }
    switch (_etapa) {
      case EtapaTeste.inicio:
        return true;
      case EtapaTeste.fimPesquisa || EtapaTeste.resultadosDemo:
        voltarAoInicio();
        return false;
      default:
        abrirSaida();
        return false;
    }
  }

  /// O app foi para segundo plano no meio de uma fase: congela e pergunta.
  void aoMudarCicloDeVida(AppLifecycleState estado) {
    if (estado != AppLifecycleState.paused &&
        estado != AppLifecycleState.hidden) {
      return;
    }
    final emFase = (_execucao != null && !_execucao!.congelada) ||
        (_etapa == EtapaTeste.treino && !_treinoConcluido);
    if (emFase && _pausa == null) abrirSaida();
  }

  /// Libera o canal de EEG antes de abrir a coleta anterior.
  Future<void> encerrarParaColetaAnterior() async {
    _pararTudo();
    unawaited(_estimulos.manterTelaAcesa(false));
    unawaited(_estimulos.liberar());
    final fonte = _fonte;
    _fonte = null;
    for (final assinatura in _assinaturas) {
      await assinatura.cancel();
    }
    _assinaturas.clear();
    await fonte?.dispose();
  }

  // ---------------------------------------------------------------------------
  // Execução de fases com pausa e retomada.

  void _iniciarExecucao(_Execucao execucao) {
    _descartarExecucao();
    _execucao = execucao;
    final registro = _sessao?.registro(execucao.fase);
    registro?.concluida = false;
    _retomarExecucao(execucao);
  }

  int _decorridoMs(_Execucao execucao) {
    final inicio = execucao.inicioTrechoNanos;
    if (inicio == null) return execucao.decorridoMs;
    return execucao.decorridoMs +
        (_relogio.agoraNanos() - inicio) ~/ _nanosPorMs;
  }

  void _retomarExecucao(_Execucao execucao, {int preparacaoMs = 0}) {
    final agora = _relogio.agoraNanos();
    execucao
      ..congelada = false
      ..decorridoMs -= preparacaoMs
      ..inicioTrechoNanos = agora;
    _sessao?.registro(execucao.fase).trechos.add(TrechoRegistro(agora));
    _inicioRuimNanos = null;
    _agendar(execucao);
  }

  void _agendar(_Execucao execucao) {
    execucao.timer?.cancel();
    if (!identical(execucao, _execucao) || execucao.congelada) return;
    final decorrido = _decorridoMs(execucao);
    if (execucao.proximo < execucao.eventos.length) {
      final evento = execucao.eventos[execucao.proximo];
      execucao.timer = Timer(
        Duration(milliseconds: math.max(0, evento.deslocamentoMs - decorrido)),
        () {
          if (!identical(execucao, _execucao) || execucao.congelada) return;
          execucao.proximo++;
          unawaited(Future<void>.sync(evento.acao));
          _agendar(execucao);
        },
      );
      return;
    }
    execucao.timer = Timer(
      Duration(milliseconds: math.max(0, execucao.duracaoMs - decorrido)),
      () {
        if (!identical(execucao, _execucao) || execucao.congelada) return;
        _fecharTrecho(execucao);
        _sessao?.registro(execucao.fase).concluida = true;
        _execucao = null;
        execucao.aoTerminar();
      },
    );
  }

  void _congelar(_Execucao execucao) {
    execucao.timer?.cancel();
    execucao.decorridoMs = _decorridoMs(execucao);
    _fecharTrecho(execucao);
    execucao.congelada = true;
    final aberto = execucao.ensaioAberto;
    if (aberto != null && execucao.ensaios != null) {
      // O estímulo em curso perde a janela de resposta: sai da conta.
      aberto.interrompido = true;
      execucao.ensaioAberto = null;
    }
    _timerFigura?.cancel();
    if (_estimuloVisual == EstimuloVisual.comum ||
        _estimuloVisual == EstimuloVisual.raro) {
      _estimuloVisual = EstimuloVisual.fixacao;
    }
  }

  void _fecharTrecho(_Execucao execucao) {
    if (execucao.inicioTrechoNanos == null) return;
    final trechos = _sessao?.registro(execucao.fase).trechos;
    if (trechos != null &&
        trechos.isNotEmpty &&
        trechos.last.fimNanos == null) {
      trechos.last.fimNanos = _relogio.agoraNanos();
    }
    execucao.inicioTrechoNanos = null;
  }

  int _preparacaoRetomadaMs(_Execucao execucao) =>
      execucao.ensaios == null ? 0 : _duracoes.preparacaoTarefa.inMilliseconds;

  void _descartarExecucao() {
    final execucao = _execucao;
    if (execucao == null) return;
    execucao.timer?.cancel();
    _fecharTrecho(execucao);
    if (execucao.fase == FaseTeste.calibracao) {
      _tentativa?.interrompida = true;
      _tentativa = null;
    }
    _execucao = null;
  }

  void _descartarFase(_Execucao execucao) {
    _descartarExecucao();
    final sessao = _sessao;
    if (sessao == null) return;
    sessao.registro(execucao.fase).trechos.clear();
    sessao.toques.removeWhere((t) => t.fase == execucao.fase);
    sessao.eventos.add(
        EventoSessao(_relogio.agoraNanos(), 'recomeco', execucao.fase.name));
  }

  void _congelarTreino() {
    _treinoCongelado = true;
    _timerTreino?.cancel();
    _timerFigura?.cancel();
    if (_janelaTreinoAberta) {
      _janelaTreinoAberta = false;
      _ensaioTreinoAtual?.interrompido = true;
      // O ensaio será repetido ao continuar.
      if (_treinoIndice > 0) _treinoIndice--;
    }
    _feedback = null;
    if (_versao == VersaoTeste.visual) _estimuloVisual = EstimuloVisual.fixacao;
  }

  void _descongelarTreino() {
    _treinoCongelado = false;
    if (!_treinoConcluido) _agendarTreino(const Duration(seconds: 1));
  }

  // ---------------------------------------------------------------------------
  // Sinal e monitoramento.

  void _aoLote(RawBatch lote) {
    final agora = _relogio.agoraNanos();
    _ultimoLoteNanos = agora;
    _sessao?.lotes.add(lote);
    final microvolts = lote.toMicrovolts();
    final anterior = _tracado ?? const <double>[];
    final juntos = [...anterior, ...microvolts];
    _tracado =
        juntos.length > 1024 ? juntos.sublist(juntos.length - 1024) : juntos;
    final tentativa = _tentativa;
    if (_etapa == EtapaTeste.calibracao && tentativa != null) {
      try {
        _piscadasAoVivo = contarPiscadas(
          lotes: _sessao!.lotes,
          inicioNanos: tentativa.inicioNanos,
        );
      } catch (_) {
        // Contagem ao vivo é só informativa para o pesquisador.
      }
    }
    final aguardado = _aguardaDadosNanos;
    if (aguardado != null && (lote.t0MonoNanos ?? agora) >= aguardado) {
      _executarAposDados();
    }
    if (_etapa == EtapaTeste.sensor || _etapa == EtapaTeste.calibracao) {
      notifyListeners();
    }
  }

  void _aoQualidade(int valor) {
    _qualidadeAtual = valor;
    _qualidadeNanos = _relogio.agoraNanos();
    _monitorar();
  }

  void _aoConexao(EstadoConexao estado) {
    if (estado == EstadoConexao.desconectado && _gravando && _pausa == null) {
      _pausar(MotivoPausa.bluetooth);
      return;
    }
    _monitorar();
  }

  /// Etapas em que o EEG precisa continuar chegando.
  bool get _gravando => switch (_etapa) {
        EtapaTeste.instrucoes ||
        EtapaTeste.calibracao ||
        EtapaTeste.calibracaoResultado ||
        EtapaTeste.calibracaoErro ||
        EtapaTeste.repousoInicio ||
        EtapaTeste.repouso ||
        EtapaTeste.repousoFim ||
        EtapaTeste.instrucoesTarefa ||
        EtapaTeste.treino ||
        EtapaTeste.tarefa ||
        EtapaTeste.ritmoInstrucoes ||
        EtapaTeste.ritmo ||
        EtapaTeste.repousoFinalInicio ||
        EtapaTeste.repousoFinal =>
          true,
        _ => false,
      };

  void _iniciarPulso() {
    _pulso?.cancel();
    _pulso = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _monitorar(notificar: true),
    );
  }

  void _monitorar({bool notificar = false}) {
    if (_descartado) return;
    final agora = _relogio.agoraNanos();
    final q = qualidade;
    final boa = q == QualidadeSinal.boa;

    if (_etapa == EtapaTeste.sensor) _atualizarContato();

    // E2: sem dados durante a gravação.
    final ultimoLote = _ultimoLoteNanos;
    if (_pausa == null &&
        _gravando &&
        !_saidaAberta &&
        (_fonte?.estadoConexao != EstadoConexao.conectado ||
            (ultimoLote != null &&
                agora - ultimoLote >
                    _duracoes.semDadosParaBluetooth.inMicroseconds * 1000))) {
      _pausar(MotivoPausa.bluetooth);
      return;
    }

    // E1: contato ruim contínuo durante uma fase monitorada.
    final execucao = _execucao;
    if (_pausa == null &&
        !_saidaAberta &&
        execucao != null &&
        !execucao.congelada &&
        execucao.monitorarContato) {
      final ruim = q == QualidadeSinal.ajuste || q == QualidadeSinal.ruim;
      if (ruim) {
        _inicioRuimNanos ??= agora;
        if (agora - _inicioRuimNanos! >=
            _duracoes.contatoParaPausar.inMicroseconds * 1000) {
          _pausar(MotivoPausa.contato);
          return;
        }
      } else {
        _inicioRuimNanos = null;
      }
    }

    // E1: contato de volta, libera "Retomar".
    if (_pausa == MotivoPausa.contato) {
      if (boa) {
        _inicioBomNaPausaNanos ??= agora;
        final recuperado = agora - _inicioBomNaPausaNanos! >=
            _duracoes.contatoParaRetomar.inMicroseconds * 1000;
        if (recuperado != _contatoRecuperado) {
          _contatoRecuperado = recuperado;
          notifyListeners();
        }
      } else {
        _inicioBomNaPausaNanos = null;
        if (_contatoRecuperado) {
          _contatoRecuperado = false;
          notifyListeners();
        }
      }
    }

    final animado = (execucao != null && !execucao.congelada) ||
        _pausa == MotivoPausa.bluetooth;
    if (notificar && animado) notifyListeners();
  }

  void _atualizarContato() {
    final agora = _relogio.agoraNanos();
    final conectado = _fonte?.estadoConexao == EstadoConexao.conectado;
    final q = _qualidadeAtual;
    final instante = _qualidadeNanos;
    final semLeitura = q == null ||
        instante == null ||
        agora - instante > 3 * _nanosPorSegundo;
    final EstadoContato novo;
    if (!conectado || semLeitura) {
      novo = EstadoContato.procurando;
    } else if (q <= 50) {
      novo = EstadoContato.bom;
    } else {
      novo = EstadoContato.ajuste;
    }
    if (novo == EstadoContato.bom) {
      _inicioEstavelNanos ??= agora;
    } else {
      _inicioEstavelNanos = null;
    }
    final inicioEstavel = _inicioEstavelNanos;
    final necessarioNanos = _duracoes.contatoEstavel.inMicroseconds * 1000;
    final segmentos = inicioEstavel == null
        ? 0
        : (((agora - inicioEstavel) / necessarioNanos) * 10)
            .floor()
            .clamp(0, 10);
    if (novo != _estadoContato || segmentos != _segundosEstaveis) {
      _estadoContato = novo;
      _segundosEstaveis = segmentos;
      notifyListeners();
    }
  }

  void _aguardarDadosAte(int nanos, void Function() acao) {
    _aguardaDados?.cancel();
    _aguardaDadosNanos = nanos;
    _aposDados = acao;
    final ultimo = _sessao?.lotes.isNotEmpty ?? false
        ? _sessao!.lotes.last.t0MonoNanos
        : null;
    if (ultimo != null && ultimo >= nanos) {
      _executarAposDados();
      return;
    }
    _aguardaDados =
        Timer(const Duration(milliseconds: 2500), _executarAposDados);
  }

  void _executarAposDados() {
    _aguardaDados?.cancel();
    final acao = _aposDados;
    _aposDados = null;
    _aguardaDadosNanos = null;
    if (acao != null && !_descartado) acao();
  }

  // ---------------------------------------------------------------------------
  // Utilidades.

  void _sinalComeco() {
    unawaited(_estimulos.tocar(SomTeste.sino));
    unawaited(_estimulos.vibrar(VibracaoTeste.curta));
  }

  void _sinalFim() {
    unawaited(_estimulos.tocar(SomTeste.sinoDuplo));
    unawaited(_estimulos.vibrar(VibracaoTeste.dupla));
  }

  void _irPara(EtapaTeste etapa) {
    _etapa = etapa;
    // Uma transição durante a pausa (ex.: fim da espera pelos dados da
    // calibração) também é para onde "Retomar" deve voltar.
    if (_pausa != null) _etapaRetorno = etapa;
    if (etapa != EtapaTeste.volumeBaixo) _timerVolume?.cancel();
    notifyListeners();
  }

  void _pararTudo() {
    _descartarExecucao();
    _pulso?.cancel();
    _timerVolume?.cancel();
    _timerReconexao?.cancel();
    _timerTreino?.cancel();
    _timerFigura?.cancel();
    _aguardaDados?.cancel();
    _aposDados = null;
    _aguardaDadosNanos = null;
  }

  void _reiniciar() {
    _pararTudo();
    unawaited(_estimulos.manterTelaAcesa(false));
    _limparPausa();
    _saidaAberta = false;
    _sessao = null;
    _resumo = null;
    _tentativa = null;
    _bipesTocados = 0;
    _piscadasAoVivo = 0;
    _treinoIndice = 0;
    _treinoConcluido = false;
    _treinoCongelado = false;
    _feedback = null;
    _janelaTreinoAberta = false;
    _estimuloVisual = EstimuloVisual.nenhum;
    _toquesNaFase = 0;
    _asrsIndice = 0;
    _listaVisivel = false;
    _erroConexao = null;
    _inicioEstavelNanos = null;
    _segundosEstaveis = 0;
    _codigo = '';
    _irPara(EtapaTeste.inicio);
  }

  static String _mensagem(Object erro) {
    final texto = erro.toString();
    const prefixos = ['Bad state: ', 'Exception: '];
    for (final prefixo in prefixos) {
      if (texto.startsWith(prefixo)) return texto.substring(prefixo.length);
    }
    return texto;
  }

  @override
  void dispose() {
    _descartado = true;
    _pararTudo();
    for (final assinatura in _assinaturas) {
      unawaited(assinatura.cancel());
    }
    _assinaturas.clear();
    unawaited(_estimulos.manterTelaAcesa(false));
    unawaited(_estimulos.liberar());
    unawaited(_fonte?.dispose());
    super.dispose();
  }
}

class _Evento {
  const _Evento(this.deslocamentoMs, this.acao);

  /// Instante no relógio da fase (que para nas pausas), em ms.
  final int deslocamentoMs;
  final FutureOr<void> Function() acao;
}

/// Fase em andamento: eventos agendados no relógio da fase.
class _Execucao {
  _Execucao({
    required this.fase,
    required this.duracaoMs,
    required this.eventos,
    required this.aoTerminar,
    this.ensaios,
    this.monitorarContato = false,
  });

  final FaseTeste fase;
  final int duracaoMs;
  final List<_Evento> eventos;
  final void Function() aoTerminar;
  final List<Ensaio>? ensaios;
  final bool monitorarContato;

  int decorridoMs = 0;
  int? inicioTrechoNanos;
  int proximo = 0;
  bool congelada = false;
  Timer? timer;
  Ensaio? ensaioAberto;
}
