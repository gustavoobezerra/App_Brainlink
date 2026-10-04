import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../data/models/raw_batch.dart';
import 'duracoes_teste.dart';
import 'fonte_sinal.dart';
import 'relogio.dart';

/// EEG simulado para percorrer o fluxo sem o headset.
///
/// Usa só [Timer] (funciona com o tempo falso dos testes de widget) e marca
/// os lotes com [Relogio.agoraNanos]. O sinal é ruído rosa (~9 µV RMS) mais
/// um ritmo de 10 Hz cuja amplitude depende do [EstadoSimulado]; cada bipe
/// da calibração gera uma piscada ~350 ms depois. Os [CenarioSimulado]s
/// imitam os problemas que as telas de erro tratam.
class FonteSimulada implements FonteSinal, ControleSimulacao {
  FonteSimulada({
    required this.cenario,
    required this.relogio,
    this.duracoes = DuracoesTeste.simulada,
    this.semente = 7,
  }) : _gerador = _GeradorSinal(math.Random(semente));

  final CenarioSimulado cenario;
  final Relogio relogio;
  final DuracoesTeste duracoes;
  final int semente;

  /// Atraso para "conectar" e para cada tentativa de reconexão.
  static const Duration atrasoConexao = Duration(milliseconds: 300);
  static const Duration atrasoReconexao = Duration(milliseconds: 400);

  /// Contato ainda se ajustando logo após conectar.
  static const Duration ajusteInicial = Duration(milliseconds: 1500);
  static const int qualidadeAjuste = 120;
  static const int qualidadeFora = 200;

  /// Piscada: pico ~350 ms após o bipe.
  static const Duration atrasoPiscada = Duration(milliseconds: 350);

  /// Cenário "Perda de contato": atraso e duração do contato ruim.
  static const Duration atrasoPerdaContato = Duration(seconds: 6);
  static const Duration duracaoPerdaContato = Duration(seconds: 5);

  /// Cenário "Bluetooth cai": tempo de olhos fechados até a queda.
  static const Duration atrasoQuedaBluetooth = Duration(seconds: 4);

  static const int _amostrasPorLote = RawBatch.sampleRateHz;
  static const int _nanosPorAmostra = 1000000000 ~/ RawBatch.sampleRateHz;

  final _GeradorSinal _gerador;

  final StreamController<RawBatch> _lotes =
      StreamController<RawBatch>.broadcast();
  final StreamController<int> _qualidade = StreamController<int>.broadcast();
  final StreamController<EstadoConexao> _conexao =
      StreamController<EstadoConexao>.broadcast();

  EstadoConexao _estadoConexao = EstadoConexao.desconectado;
  EstadoSimulado _estado = EstadoSimulado.olhosAbertos;
  bool _encerrada = false;

  int _seq = 0;
  int _qualidadeBase = qualidadeAjuste;
  bool _contatoPerdido = false;

  Timer? _timerLotes;
  Timer? _timerAjuste;
  Timer? _timerConexao;
  Completer<void>? _conectando;
  Timer? _timerReconexao;
  Completer<bool>? _reconectando;
  final List<Timer> _timersCenario = [];

  int _bipes = 0;
  bool _perdaAgendada = false;
  bool _quedaAgendada = false;
  bool _bluetoothCaiu = false;
  int _tentativasReconexao = 0;

  /// Instantes (relógio monotônico) dos picos das piscadas pendentes.
  final List<int> _piscadasNanos = [];

  @override
  bool get simulada => true;

  @override
  Stream<RawBatch> get lotes => _lotes.stream;

  @override
  Stream<int> get qualidade => _qualidade.stream;

  @override
  Stream<EstadoConexao> get conexao => _conexao.stream;

  @override
  EstadoConexao get estadoConexao => _estadoConexao;

  /// Qualidade vigente (0 bom, 200 fora da cabeça).
  int get _qualidadeAtual => _contatoPerdido ? qualidadeFora : _qualidadeBase;

  @override
  Future<ResultadoAutoConexao> autoConectar() async {
    await _conectarComAtraso();
    return const AutoConectado();
  }

  @override
  Future<List<DispositivoSinal>> buscar() async => const [];

  @override
  Future<void> conectar(DispositivoSinal dispositivo) => _conectarComAtraso();

  @override
  Future<bool> reconectar() {
    if (_encerrada) return Future.value(false);
    if (_estadoConexao == EstadoConexao.conectado) return Future.value(true);
    final pendente = _reconectando;
    if (pendente != null) return pendente.future;

    final completer = Completer<bool>();
    _reconectando = completer;
    _mudarConexao(EstadoConexao.conectando);
    _timerReconexao = Timer(atrasoReconexao, () {
      _timerReconexao = null;
      _reconectando = null;
      _tentativasReconexao++;
      // "Bluetooth cai": a primeira tentativa falha, a segunda conecta.
      final falha = _bluetoothCaiu && _tentativasReconexao == 1;
      if (falha) {
        _mudarConexao(EstadoConexao.desconectado);
      } else {
        _iniciarConexao(qualidadeInicial: 0);
      }
      completer.complete(!falha);
    });
    return completer.future;
  }

  @override
  Future<void> desconectar() async {
    if (_encerrada) return;
    _cancelarConexaoPendente();
    _pararLotes();
    _mudarConexao(EstadoConexao.desconectado);
  }

  @override
  Future<void> dispose() async {
    if (_encerrada) return;
    _cancelarConexaoPendente();
    _pararLotes();
    for (final timer in _timersCenario) {
      timer.cancel();
    }
    _timersCenario.clear();
    _encerrada = true;
    await Future.wait([_lotes.close(), _qualidade.close(), _conexao.close()]);
  }

  @override
  void definirEstado(EstadoSimulado estado) {
    if (_encerrada) return;
    _estado = estado;
    switch (estado) {
      case EstadoSimulado.olhosFechados:
        if (cenario == CenarioSimulado.bluetoothCai && !_quedaAgendada) {
          _quedaAgendada = true;
          _agendar(atrasoQuedaBluetooth, _derrubarBluetooth);
        }
      case EstadoSimulado.tarefaOlhosFechados ||
            EstadoSimulado.tarefaOlhosAbertos:
        if (cenario == CenarioSimulado.perdaContato && !_perdaAgendada) {
          _perdaAgendada = true;
          _agendar(atrasoPerdaContato, () {
            _contatoPerdido = true;
            _agendar(duracaoPerdaContato, () => _contatoPerdido = false);
          });
        }
      case EstadoSimulado.olhosAbertos:
        break;
    }
  }

  @override
  void aoBipeCalibracao(int nanos) {
    if (_encerrada) return;
    _bipes++;
    // "Poucas piscadas": na primeira série, o 3º bipe fica sem piscada.
    if (cenario == CenarioSimulado.poucasPiscadas &&
        _bipes == 3 &&
        _bipes <= duracoes.bipesCalibracao) {
      return;
    }
    _piscadasNanos.add(nanos + atrasoPiscada.inMicroseconds * 1000);
  }

  // --- Conexão --------------------------------------------------------------

  Future<void> _conectarComAtraso() {
    if (_encerrada) return Future.value();
    if (_estadoConexao == EstadoConexao.conectado) return Future.value();
    final pendente = _conectando;
    if (pendente != null) return pendente.future;

    final completer = Completer<void>();
    _conectando = completer;
    _mudarConexao(EstadoConexao.conectando);
    _timerConexao = Timer(atrasoConexao, () {
      _timerConexao = null;
      _conectando = null;
      _iniciarConexao(qualidadeInicial: qualidadeAjuste);
      completer.complete();
    });
    return completer.future;
  }

  /// Conectada: `seq` recomeça em 0 e sai um lote por segundo.
  void _iniciarConexao({required int qualidadeInicial}) {
    _pararLotes();
    _seq = 0;
    _qualidadeBase = qualidadeInicial;
    _mudarConexao(EstadoConexao.conectado);
    if (qualidadeInicial != 0) {
      _timerAjuste = Timer(ajusteInicial, () {
        _timerAjuste = null;
        _qualidadeBase = 0;
      });
    }
    _emitirQualidade();
    _timerLotes = Timer.periodic(const Duration(seconds: 1), (_) => _tique());
  }

  void _derrubarBluetooth() {
    if (_estadoConexao != EstadoConexao.conectado) return;
    _bluetoothCaiu = true;
    _tentativasReconexao = 0;
    _pararLotes();
    _mudarConexao(EstadoConexao.desconectado);
  }

  void _pararLotes() {
    _timerLotes?.cancel();
    _timerLotes = null;
    _timerAjuste?.cancel();
    _timerAjuste = null;
  }

  /// Encerra conexões em andamento; quem aguardava recebe "não conectou".
  void _cancelarConexaoPendente() {
    _timerConexao?.cancel();
    _timerConexao = null;
    final conectando = _conectando;
    _conectando = null;
    if (conectando != null && !conectando.isCompleted) conectando.complete();
    _timerReconexao?.cancel();
    _timerReconexao = null;
    final reconectando = _reconectando;
    _reconectando = null;
    if (reconectando != null && !reconectando.isCompleted) {
      reconectando.complete(false);
    }
  }

  void _mudarConexao(EstadoConexao estado) {
    _estadoConexao = estado;
    if (!_encerrada) _conexao.add(estado);
  }

  void _agendar(Duration atraso, void Function() acao) {
    late final Timer timer;
    timer = Timer(atraso, () {
      _timersCenario.remove(timer);
      if (!_encerrada) acao();
    });
    _timersCenario.add(timer);
  }

  // --- Lotes ----------------------------------------------------------------

  void _emitirQualidade() {
    if (!_encerrada) _qualidade.add(_qualidadeAtual);
  }

  /// Fecha o lote do segundo que termina agora.
  void _tique() {
    if (_encerrada) return;
    final fimNanos = relogio.agoraNanos();
    final amostras = Int32List(_amostrasPorLote);
    final amplitudeAlfa = _amplitudeAlfa(_estado);
    final primeiraNanos = fimNanos - (_amostrasPorLote - 1) * _nanosPorAmostra;
    for (var i = 0; i < _amostrasPorLote; i++) {
      final instante = primeiraNanos + i * _nanosPorAmostra;
      final microvolts =
          _gerador.proxima(amplitudeAlfa) + _piscadasEm(instante);
      amostras[i] = (microvolts / RawBatch.microvoltsPerUnit).round();
    }
    // Piscadas já inteiramente para trás não são mais necessárias.
    _piscadasNanos
        .removeWhere((pico) => pico + _alcancePiscadaNanos < fimNanos);

    _emitirQualidade();
    _lotes.add(
      RawBatch(
        seq: _seq++,
        t0: DateTime.now(),
        poorSignal: _qualidadeAtual,
        dropped: 0,
        samples: amostras,
        observedSampleRateHz: RawBatch.sampleRateHz.toDouble(),
        t0MonoNanos: fimNanos,
      ),
    );
  }

  /// Pico do ritmo de 10 Hz, em µV, conforme o que a pessoa faz.
  static double _amplitudeAlfa(EstadoSimulado estado) => switch (estado) {
        EstadoSimulado.olhosFechados => 14,
        EstadoSimulado.olhosAbertos => 4,
        EstadoSimulado.tarefaOlhosFechados => 8,
        EstadoSimulado.tarefaOlhosAbertos => 4,
      };

  // Forma da piscada: pico positivo e rebote negativo menor, mais tarde.
  static const double _picoPiscada = 150;
  static const double _sigmaPiscadaNanos = 60e6;
  static const double _rebotePiscada = -50;
  static const double _atrasoReboteNanos = 150e6;
  static const double _sigmaReboteNanos = 80e6;
  static const int _alcancePiscadaNanos = 600000000;

  /// Soma das piscadas pendentes no [instante] (µV).
  double _piscadasEm(int instante) {
    var soma = 0.0;
    for (final pico in _piscadasNanos) {
      final dt = (instante - pico).toDouble();
      if (dt.abs() > _alcancePiscadaNanos) continue;
      final dr = dt - _atrasoReboteNanos;
      soma += _picoPiscada *
              math.exp(
                  -dt * dt / (2 * _sigmaPiscadaNanos * _sigmaPiscadaNanos)) +
          _rebotePiscada *
              math.exp(-dr * dr / (2 * _sigmaReboteNanos * _sigmaReboteNanos));
    }
    return soma;
  }
}

/// Ruído rosa (filtro de Paul Kellet) + 10 Hz contínuo entre lotes.
class _GeradorSinal {
  _GeradorSinal(this._aleatorio)
      : _fase = _aleatorio.nextDouble() * 2 * math.pi;

  final math.Random _aleatorio;
  double _b0 = 0, _b1 = 0, _b2 = 0;
  double _fase;

  /// Ganho que leva o filtro (~3 de RMS com ruído branco unitário) a ~9 µV.
  static const double _ganhoRosa = 3.0;

  /// Fora das piscadas o sinal fica dentro de ±[_limite] µV.
  static const double _limite = 95;

  static const double _passoFase = 2 * math.pi * 10 / RawBatch.sampleRateHz;

  double proxima(double amplitudeAlfa) {
    final branco = _gaussiana();
    _b0 = 0.99765 * _b0 + branco * 0.0990460;
    _b1 = 0.96300 * _b1 + branco * 0.2965164;
    _b2 = 0.57000 * _b2 + branco * 1.0526913;
    final rosa = (_b0 + _b1 + _b2 + branco * 0.1848) * _ganhoRosa;
    final alfa = amplitudeAlfa * math.sin(_fase);
    _fase = (_fase + _passoFase) % (2 * math.pi);
    return (rosa + alfa).clamp(-_limite, _limite);
  }

  double _gaussiana() {
    final u1 = 1 - _aleatorio.nextDouble();
    final u2 = _aleatorio.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
