import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/asrs_screener_6.dart';
import '../../data/models/eeg_data.dart';
import '../../data/models/raw_batch.dart';
import '../../native/brainlink_bridge.dart';
import '../../services/eeg_spectrum_analyzer.dart';
import '../../services/guided_collection_report_exporter.dart';

enum AcquisitionMode { demonstration, hardware }

enum CollectionStep { choice, instructions, running, result, screening }

enum CollectionPhase { eyesOpen, eyesClosed }

class ConnectableDevice {
  const ConnectableDevice(this.id, this.name, {required this.isPaired});

  final String id;
  final String name;
  final bool isPaired;
}

abstract interface class DeviceDiscoveryGateway {
  Future<List<ConnectableDevice>> listDevices();

  Future<void> connect(ConnectableDevice device);
}

class NativeBrainLinkGateway implements DeviceDiscoveryGateway {
  NativeBrainLinkGateway(this.bridge);

  final BrainLinkBridge bridge;

  @override
  Future<List<ConnectableDevice>> listDevices() async {
    final devices = <String, ConnectableDevice>{};
    final finished = Completer<void>();
    var scanStarted = false;
    String? nativeError;
    final errorSubscription =
        bridge.errorStream.listen((message) => nativeError ??= message);
    final deviceSubscription = bridge.deviceStream.listen((device) {
      if (device.address.isEmpty) return;
      devices[device.address] = ConnectableDevice(
        device.address,
        device.name,
        isPaired: device.isBonded,
      );
    });
    final scanSubscription = bridge.scanStateStream.listen((scanning) {
      if (scanning) {
        scanStarted = true;
      } else if (scanStarted && !finished.isCompleted) {
        finished.complete();
      }
    });
    try {
      // A varredura ativa pode falhar (Bluetooth desligado, permissão negada),
      // mas os aparelhos já pareados foram emitidos antes dela: mantemos o
      // resultado em vez de descartá-lo com uma exceção. O limite de tempo
      // cobre o diálogo de permissão que nunca devolve resposta ao canal.
      final started = await bridge
          .startScan()
          .timeout(const Duration(seconds: 60), onTimeout: () => false);
      await Future.any<void>([
        finished.future,
        Future<void>.delayed(
          // A varredura clássica do Android leva cerca de doze segundos.
          started ? const Duration(seconds: 13) : const Duration(seconds: 1),
        ),
      ]);
      final result = devices.values.toList()
        ..sort((a, b) {
          if (a.isPaired != b.isPaired) return a.isPaired ? -1 : 1;
          return a.name.compareTo(b.name);
        });
      if (result.isEmpty && nativeError != null) {
        throw StateError(nativeError!);
      }
      return result;
    } finally {
      await bridge.stopScan();
      await deviceSubscription.cancel();
      await scanSubscription.cancel();
      await errorSubscription.cancel();
    }
  }

  @override
  Future<void> connect(ConnectableDevice device) async {
    final connected = Completer<void>();
    // O erro do canal pode chegar antes do await abaixo; sem este ouvinte ele
    // vira uma exceção assíncrona não tratada e a causa real se perde.
    unawaited(connected.future.catchError((Object _) {}));
    String? nativeError;
    final connectionSubscription = bridge.connectionStateStream.listen((value) {
      if (value && !connected.isCompleted) connected.complete();
    });
    final errorSubscription = bridge.errorStream.listen((message) {
      nativeError ??= message;
      if (!connected.isCompleted) connected.completeError(StateError(message));
    });
    try {
      final started = await bridge.connect(device.id);
      if (!started) {
        throw StateError(
            nativeError ?? 'A conexão Bluetooth não foi iniciada.');
      }
      await connected.future.timeout(const Duration(seconds: 12));
    } finally {
      await connectionSubscription.cancel();
      await errorSubscription.cancel();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.deviceGateway,
    this.rawDataStream,
    this.demonstrationPhaseDuration = const Duration(seconds: 8),
    this.hardwarePhaseDuration = const Duration(minutes: 1),
    this.tickInterval = const Duration(seconds: 1),
  });

  final DeviceDiscoveryGateway? deviceGateway;
  final Stream<RawBatch>? rawDataStream;
  final Duration demonstrationPhaseDuration;
  final Duration hardwarePhaseDuration;
  final Duration tickInterval;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BrainLinkBridge _bridge = BrainLinkBridge();
  final GuidedCollectionReportExporter _exporter =
      const GuidedCollectionReportExporter();
  final EegSpectrumAnalyzer _spectrumAnalyzer = const EegSpectrumAnalyzer();

  late final DeviceDiscoveryGateway _deviceGateway;
  StreamSubscription<EEGData>? _dataSubscription;
  StreamSubscription<RawBatch>? _rawSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<String>? _errorSubscription;
  Timer? _timer;

  CollectionStep _step = CollectionStep.choice;
  AcquisitionMode? _mode;
  CollectionPhase _phase = CollectionPhase.eyesOpen;
  Duration _phaseElapsed = Duration.zero;
  DateTime? _startedAt;
  DateTime? _endedAt;
  final List<_Reading> _readings = [];
  final List<RawBatch> _eyesOpenRaw = [];
  final List<RawBatch> _eyesClosedRaw = [];
  final List<double> _liveRawMicrovolts = [];
  EegSpectrumAnalysis? _spectrumAnalysis;
  int _demonstrationRawSequence = 0;
  int _demonstrationSampleIndex = 0;
  final List<AsrsResponse?> _asrsAnswers =
      List<AsrsResponse?>.filled(AsrsScreener6.itemCount, null);

  bool _showHardware = false;
  bool _scanning = false;
  bool _connecting = false;
  bool _connected = false;
  List<ConnectableDevice> _devices = const [];
  String? _connectionMessage;
  String? _exportMessage;

  @override
  void initState() {
    super.initState();
    _deviceGateway = widget.deviceGateway ?? NativeBrainLinkGateway(_bridge);
    _connected = _bridge.isConnected;
    _dataSubscription = _bridge.eegDataStream.listen(_onHardwareData);
    _rawSubscription = (widget.rawDataStream ?? _bridge.rawDataStream).listen(
      _onHardwareRaw,
      onError: (Object _) {
        if (!mounted ||
            _mode != AcquisitionMode.hardware ||
            _step != CollectionStep.running) {
          return;
        }
        setState(() => _connectionMessage =
            'O fluxo de EEG bruto foi interrompido. Reconecte e repita a coleta.');
      },
    );
    _connectionSubscription = _bridge.connectionStateStream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _connected = connected;
        if (!connected &&
            _mode == AcquisitionMode.hardware &&
            _step == CollectionStep.running) {
          _connectionMessage =
              'A conexão foi interrompida. Encerre a coleta e conecte novamente.';
        }
      });
    });
    _errorSubscription = _bridge.errorStream.listen((message) {
      if (!mounted) return;
      setState(() => _connectionMessage = message);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_dataSubscription?.cancel());
    unawaited(_rawSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    super.dispose();
  }

  Duration get _phaseDuration => _mode == AcquisitionMode.hardware
      ? widget.hardwarePhaseDuration
      : widget.demonstrationPhaseDuration;

  int get _remainingSeconds => math.max(
        0,
        (_phaseDuration - _phaseElapsed).inMilliseconds ~/ 1000,
      );

  double get _totalProgress {
    final duration = math.max(1, _phaseDuration.inMilliseconds);
    final withinPhase = (_phaseElapsed.inMilliseconds / duration).clamp(0, 1);
    return _phase == CollectionPhase.eyesOpen
        ? withinPhase / 2
        : 0.5 + withinPhase / 2;
  }

  int? get _qualityScore {
    final qualities = _readings
        .where((reading) => reading.signalQuality != null)
        .map((reading) => reading.signalQuality!.clamp(0, 200))
        .toList();
    if (qualities.isEmpty) return null;
    final contact =
        qualities.map((quality) => 100 - quality / 2).reduce((a, b) => a + b) /
            qualities.length;
    final expected = math.max(
      1,
      (_phaseDuration.inMilliseconds * 2 / 1000).round(),
    );
    final coverage = math.min(1.0, _readings.length / expected) * 100;
    return (contact * 0.8 + coverage * 0.2).round().clamp(0, 100);
  }

  String get _qualityLabel => switch (_qualityScore) {
        null => 'Sem dados suficientes',
        >= 80 => 'Coleta boa',
        >= 60 => 'Coleta aceitável',
        _ => 'Coleta ruim',
      };

  Color get _qualityColor => switch (_qualityScore) {
        null => const Color(0xFF8493A6),
        >= 80 => const Color(0xFF56D6B3),
        >= 60 => const Color(0xFFFFC45C),
        _ => const Color(0xFFFF6B78),
      };

  double? get _attentionMean => _mean(
        _readings
            .where((reading) => reading.attention != null)
            .map((reading) => reading.attention!),
      );

  double? get _meditationMean => _mean(
        _readings
            .where((reading) => reading.meditation != null)
            .map((reading) => reading.meditation!),
      );

  double? get _displayAttentionMean =>
      (_qualityScore ?? 0) >= 60 ? _attentionMean : null;

  double? get _displayMeditationMean =>
      (_qualityScore ?? 0) >= 60 ? _meditationMean : null;

  AsrsScreenerResult? get _asrsResult {
    if (_asrsAnswers.any((answer) => answer == null)) return null;
    return AsrsScreener6.score(_asrsAnswers.whereType<AsrsResponse>());
  }

  void _chooseDemonstration() {
    setState(() {
      _mode = AcquisitionMode.demonstration;
      _step = CollectionStep.instructions;
      _showHardware = false;
      _connectionMessage = null;
    });
  }

  Future<void> _openHardware() async {
    setState(() {
      _mode = AcquisitionMode.hardware;
      _showHardware = true;
      _connectionMessage = null;
    });
    if (_connected) {
      setState(() => _step = CollectionStep.instructions);
      return;
    }
    await _scan();
  }

  Future<void> _scan() async {
    // A descoberta atrapalha a negociação RFCOMM: nunca durante uma conexão.
    if (_scanning || _connecting) return;
    setState(() {
      _scanning = true;
      _devices = const [];
      _connectionMessage = null;
    });
    try {
      final devices = await _deviceGateway.listDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        if (devices.isEmpty) {
          _connectionMessage =
              'Nenhum BrainLink encontrado. Pareie-o nas configurações do Android e toque em Buscar novamente.';
        }
      });
    } on Object catch (error) {
      if (mounted) {
        // O Android costuma explicar melhor a falha do que uma frase genérica.
        final detail = error is StateError ? error.message : null;
        setState(() => _connectionMessage = detail ??
            'Não foi possível buscar agora. Confira Bluetooth e permissões.');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(ConnectableDevice device) async {
    if (_connecting || _scanning) return;
    setState(() {
      _connecting = true;
      _connectionMessage = 'Conectando a ${device.name}…';
    });
    try {
      await _deviceGateway.connect(device);
      if (!mounted) return;
      setState(() {
        _connected = true;
        _connectionMessage = 'BrainLink conectado.';
        _step = CollectionStep.instructions;
      });
    } on Object catch (error) {
      if (mounted) {
        final detail = error is StateError ? error.message : null;
        setState(() => _connectionMessage = detail ??
            'A conexão não terminou. Desligue outros apps ligados ao BrainLink e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _startCollection() {
    if (_mode == AcquisitionMode.hardware && !_connected) {
      _message('Conecte o BrainLink antes de iniciar.');
      return;
    }
    _timer?.cancel();
    setState(() {
      _step = CollectionStep.running;
      _phase = CollectionPhase.eyesOpen;
      _phaseElapsed = Duration.zero;
      _startedAt = DateTime.now();
      _endedAt = null;
      _readings.clear();
      _clearRawState();
      _exportMessage = null;
      if (_mode == AcquisitionMode.demonstration) {
        _appendDemonstrationFrame();
      }
    });
    _timer = Timer.periodic(widget.tickInterval, (_) => _tickCollection());
  }

  void _tickCollection() {
    if (!mounted || _step != CollectionStep.running) return;
    var phaseChanged = false;
    var finished = false;
    setState(() {
      if (_mode == AcquisitionMode.demonstration) {
        _appendDemonstrationFrame();
      }
      _phaseElapsed += widget.tickInterval;
      if (_phaseElapsed >= _phaseDuration) {
        if (_phase == CollectionPhase.eyesOpen) {
          _phase = CollectionPhase.eyesClosed;
          _phaseElapsed = Duration.zero;
          phaseChanged = true;
        } else {
          finished = true;
        }
      }
    });
    if (phaseChanged) {
      _signalUser();
    } else if (finished) {
      _finishCollection();
    }
  }

  void _appendDemonstrationReading() {
    final index = _readings.length;
    final closed = _phase == CollectionPhase.eyesClosed;
    final attention = (closed ? 48 : 61) +
        (math.sin(index * 0.75) * 11).round() +
        (index % 4);
    final meditation =
        (closed ? 72 : 53) + (math.cos(index * 0.55) * 9).round();
    final poorSignal = 12 + (math.sin(index * 0.4).abs() * 22).round();
    _readings.add(
      _Reading(
        attention: attention.clamp(0, 100),
        meditation: meditation.clamp(0, 100),
        signalQuality: poorSignal,
      ),
    );
  }

  void _appendDemonstrationFrame() {
    _appendDemonstrationReading();
    final closed = _phase == CollectionPhase.eyesClosed;
    final samples = Int32List(128);
    for (var index = 0; index < samples.length; index++) {
      final sampleIndex = _demonstrationSampleIndex + index;
      final time = sampleIndex / 128;
      final delta = 2.0 * math.sin(2 * math.pi * 2 * time);
      final theta =
          (closed ? 4.0 : 7.0) * math.sin(2 * math.pi * 6 * time + 0.3);
      final alpha =
          (closed ? 14.0 : 5.0) * math.sin(2 * math.pi * 10 * time + 0.7);
      final beta =
          (closed ? 2.5 : 4.0) * math.sin(2 * math.pi * 20 * time + 1.1);
      final microvolts = delta + theta + alpha + beta;
      samples[index] = (microvolts / RawBatch.microvoltsPerUnit)
          .round()
          .clamp(-32768, 32767);
    }
    _demonstrationSampleIndex += samples.length;
    _recordRawBatch(
      RawBatch(
        seq: _demonstrationRawSequence++,
        t0: DateTime.now(),
        poorSignal: 12,
        dropped: 0,
        samples: samples,
      ),
    );
  }

  void _onHardwareData(EEGData data) {
    if (!mounted ||
        _step != CollectionStep.running ||
        _mode != AcquisitionMode.hardware) {
      return;
    }
    setState(() {
      _readings.add(
        _Reading(
          attention: data.attention,
          meditation: data.meditation,
          signalQuality: data.signalQuality,
        ),
      );
    });
  }

  void _onHardwareRaw(RawBatch batch) {
    if (!mounted ||
        _step != CollectionStep.running ||
        _mode != AcquisitionMode.hardware) {
      return;
    }
    setState(() => _recordRawBatch(batch));
  }

  void _recordRawBatch(RawBatch batch) {
    if (_phase == CollectionPhase.eyesOpen) {
      _eyesOpenRaw.add(batch);
    } else {
      _eyesClosedRaw.add(batch);
    }
    _liveRawMicrovolts.addAll(batch.toMicrovolts());
    const maximumVisibleSamples = 128 * 5;
    if (_liveRawMicrovolts.length > maximumVisibleSamples) {
      _liveRawMicrovolts.removeRange(
        0,
        _liveRawMicrovolts.length - maximumVisibleSamples,
      );
    }
  }

  void _clearRawState() {
    _eyesOpenRaw.clear();
    _eyesClosedRaw.clear();
    _liveRawMicrovolts.clear();
    _spectrumAnalysis = null;
    _demonstrationRawSequence = 0;
    _demonstrationSampleIndex = 0;
  }

  void _finishCollection() {
    _timer?.cancel();
    if (!mounted) return;
    final spectrum = _spectrumAnalyzer.analyze(
      eyesOpen: _eyesOpenRaw,
      eyesClosed: _eyesClosedRaw,
      minimumEpochsPerPhase: _mode == AcquisitionMode.demonstration ? 1 : 20,
    );
    setState(() {
      _endedAt = DateTime.now();
      _spectrumAnalysis = spectrum;
      _step = CollectionStep.result;
    });
    _signalUser(strong: true);
  }

  void _signalUser({bool strong = false}) {
    unawaited(
      (strong ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact())
          .catchError((_) {}),
    );
    unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _step = CollectionStep.choice;
      _mode = null;
      _phase = CollectionPhase.eyesOpen;
      _phaseElapsed = Duration.zero;
      _showHardware = false;
      _readings.clear();
      _clearRawState();
      _startedAt = null;
      _endedAt = null;
      _asrsAnswers.fillRange(0, _asrsAnswers.length, null);
      _exportMessage = null;
      _connectionMessage = null;
    });
  }

  GuidedCollectionReportData? get _report {
    final startedAt = _startedAt;
    final endedAt = _endedAt;
    if (startedAt == null || endedAt == null) return null;
    final asrs = _asrsResult;
    return GuidedCollectionReportData(
      startedAt: startedAt,
      endedAt: endedAt,
      source: _mode == AcquisitionMode.hardware
          ? 'BrainLink Lite'
          : 'Demonstração com dados simulados',
      qualityScore: _qualityScore,
      qualityLabel: _qualityLabel,
      readingCount: _readings.length,
      attentionMean: _displayAttentionMean,
      meditationMean: _displayMeditationMean,
      spectrum: _spectrumAnalysis,
      asrsScore: asrs?.total,
      asrsLabel: asrs?.possibilityLabel,
      asrsBandLabel: asrs?.label,
      asrsGuidance: asrs?.guidance,
      asrsAnswers: asrs == null
          ? const []
          : [
              for (var index = 0; index < AsrsScreener6.itemCount; index++)
                GuidedAsrsAnswer(
                  question: AsrsScreener6.questions[index],
                  response: _asrsAnswers[index]!.label,
                  points: _asrsAnswers[index]!.points,
                ),
            ],
    );
  }

  Future<void> _export() async {
    final report = _report;
    if (report == null) return;
    setState(() => _exportMessage = 'Preparando arquivo…');
    try {
      final root = await _bridge.getStorageRoot();
      if (root == null || root.isEmpty) {
        throw StateError('Armazenamento indisponível.');
      }
      final files = await _exporter.export(
        report,
        Directory('$root${Platform.pathSeparator}exports'),
      );
      final shared = await _bridge.shareFile(files.first.path);
      if (!mounted) return;
      setState(() => _exportMessage = shared
          ? 'Resultado pronto para compartilhar.'
          : 'Resultado salvo em ${files.first.path}');
    } on Object {
      if (mounted) {
        setState(() => _exportMessage =
            'Não foi possível exportar agora. A coleta continua nesta tela.');
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projeto BrainLink',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Coleta guiada',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAB8CA)),
            ),
          ],
        ),
        actions: [
          if (_step != CollectionStep.choice)
            IconButton(
              tooltip: 'Voltar ao início',
              onPressed: _reset,
              icon: const Icon(Icons.home_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: switch (_step) {
                  CollectionStep.choice => _choiceView(),
                  CollectionStep.instructions => _instructionsView(),
                  CollectionStep.running => _runningView(),
                  CollectionStep.result => _resultView(),
                  CollectionStep.screening => _screeningView(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceView() {
    return Column(
      key: const ValueKey('choice'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hero(),
        const SizedBox(height: 22),
        Text(
          'Como deseja começar?',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Escolha uma opção. Todo o restante acontece nesta mesma tela.',
          style: TextStyle(color: Color(0xFFAAB8CA)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _chooseDemonstration,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text('Ver demonstração'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _scanning || _connecting ? null : _openHardware,
          icon: const Icon(Icons.bluetooth_searching_rounded),
          label: const Text('Conectar BrainLink'),
        ),
        if (_showHardware) ...[
          const SizedBox(height: 16),
          _hardwarePanel(),
        ],
      ],
    );
  }

  Widget _hardwarePanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_rounded, color: Color(0xFF7DB3FF)),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Dispositivos encontrados',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: _scanning || _connecting ? null : _scan,
                  icon: _scanning
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_scanning ? 'Buscando' : 'Buscar'),
                ),
              ],
            ),
            const Text(
              'Se não aparecer, abra o Bluetooth do Android, pareie “BrainLink” e volte ao app. Se pedir um código, use 0000.',
              style: TextStyle(color: Color(0xFFAAB8CA), fontSize: 13),
            ),
            for (final device in _devices) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1828),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3A52)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            device.isPaired ? 'Pareado' : 'Disponível',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF96A7BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _connecting || _scanning
                          ? null
                          : () => _connect(device),
                      child: Text(_connecting ? 'Aguarde' : 'Conectar'),
                    ),
                  ],
                ),
              ),
            ],
            if (_connectionMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _connectionMessage!,
                style: const TextStyle(color: Color(0xFFD0DCE9)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _instructionsView() {
    final isHardware = _mode == AcquisitionMode.hardware;
    final phaseText = isHardware ? '1 minuto' : '8 segundos';
    return Column(
      key: const ValueKey('instructions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          eyebrow: isHardware ? 'BRAINLINK CONECTADO' : 'DADOS SIMULADOS',
          title: 'Antes de começar',
          subtitle: isHardware
              ? 'Prepare o sensor e siga duas etapas de $phaseText.'
              : 'A demonstração reproduz rapidamente o mesmo fluxo do hardware.',
        ),
        const SizedBox(height: 18),
        const _Instruction(
          number: '1',
          title: 'Ajuste o BrainLink',
          text:
              'Sensor metálico na testa, cerca de 1 a 2 cm acima da sobrancelha, e clipe em contato direto com o lóbulo da orelha.',
        ),
        const _Instruction(
          number: '2',
          title: 'Fique confortável',
          text:
              'Sente-se com apoio, mantenha testa e mandíbula relaxadas e evite falar, tocar no sensor ou movimentar a cabeça.',
        ),
        _Instruction(
          number: '3',
          title: 'Olhos abertos por $phaseText',
          text:
              'Olhe para um ponto fixo e pisque naturalmente. O app avisará a troca com som e vibração.',
        ),
        _Instruction(
          number: '4',
          title: 'Olhos fechados por $phaseText',
          text:
              'Depois do aviso, feche os olhos sem apertá-los e permaneça acordado e imóvel até o segundo aviso.',
        ),
        const SizedBox(height: 6),
        const _Notice(
          icon: Icons.volume_up_outlined,
          text:
              'Deixe o som ou a vibração do celular ativos. Não é preciso ficar de olhos fechados durante toda a sessão.',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _startCollection,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(isHardware
              ? 'Começar teste de 2 minutos'
              : 'Começar demonstração'),
        ),
      ],
    );
  }

  Widget _runningView() {
    final open = _phase == CollectionPhase.eyesOpen;
    final currentQuality = _readings.isEmpty
        ? null
        : _readings
            .lastWhere(
              (reading) => reading.signalQuality != null,
              orElse: () => const _Reading(),
            )
            .signalQuality;
    final contact = switch (currentQuality) {
      null => 'Aguardando sinal',
      <= 50 => 'Contato bom',
      < 200 => 'Ajuste o sensor',
      _ => 'Sem contato',
    };
    return Column(
      key: const ValueKey('running'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          eyebrow: _mode == AcquisitionMode.hardware
              ? 'COLETA COM HARDWARE'
              : 'DEMONSTRAÇÃO',
          title: open ? 'Mantenha os olhos abertos' : 'Agora feche os olhos',
          subtitle: open
              ? 'Olhe para um ponto fixo e permaneça relaxado.'
              : 'Não aperte as pálpebras. Aguarde o aviso final.',
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(
                  open
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 76,
                  color: const Color(0xFF7DB3FF),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatClock(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  contact,
                  style: TextStyle(
                    color: currentQuality != null && currentQuality <= 50
                        ? const Color(0xFF56D6B3)
                        : const Color(0xFFFFC45C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: _totalProgress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: const Color(0xFF26354A),
                ),
                const SizedBox(height: 8),
                Text(
                  'Etapa ${open ? 1 : 2} de 2 · ${_readings.length} leituras',
                  style: const TextStyle(color: Color(0xFFAAB8CA)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _LiveWaveformCard(
          samples: List<double>.of(_liveRawMicrovolts, growable: false),
        ),
        if (_mode == AcquisitionMode.hardware && !_connected) ...[
          const SizedBox(height: 14),
          _Notice(
            icon: Icons.bluetooth_disabled_rounded,
            text: _connectionMessage ??
                'A conexão foi interrompida. Encerre a coleta e conecte novamente.',
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _finishCollection,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Encerrar agora'),
        ),
      ],
    );
  }

  Widget _resultView() {
    final score = _qualityScore;
    final asrs = _asrsResult;
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          eyebrow: _mode == AcquisitionMode.hardware
              ? 'RESULTADO DO BRAINLINK'
              : 'RESULTADO SIMULADO',
          title: 'Resultado da coleta',
          subtitle:
              'Indicador visual de contato e continuidade do sinal recebido.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              children: [
                _QualityGauge(score: score),
                Text(
                  _qualityLabel,
                  style: TextStyle(
                    color: _qualityColor,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (score) {
                    null =>
                      'Nenhuma informação de contato foi recebida. Reconecte e tente novamente.',
                    >= 80 =>
                      'O sensor manteve contato e recebeu dados de forma consistente.',
                    >= 60 =>
                      'A coleta pode ser usada, mas vale ajustar o sensor antes de repetir.',
                    _ =>
                      'Reposicione o sensor e o clipe e repita. Os índices ficam ocultos para não mostrar dados pouco confiáveis.',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFAAB8CA), height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.track_changes_rounded,
                label: 'Atenção do aparelho',
                value: _formatMean(_displayAttentionMean),
                color: const Color(0xFF67A7FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.spa_outlined,
                label: 'Relaxamento do aparelho',
                value: _formatMean(_displayMeditationMean),
                color: const Color(0xFF56D6B3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (asrs == null)
          _AsrsPromptCard(
            isHardware: _mode == AcquisitionMode.hardware,
            onPressed: () => setState(() => _step = CollectionStep.screening),
          )
        else
          _AsrsResultCard(result: asrs),
        const SizedBox(height: 14),
        _SpectrumResultCard(analysis: _spectrumAnalysis),
        if (asrs != null) ...[
          const SizedBox(height: 14),
          _CombinedGuidanceCard(
            result: asrs,
            spectrum: _spectrumAnalysis,
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _export,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(asrs == null
              ? 'Exportar resultado da coleta'
              : 'Exportar os dois resultados'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _step = CollectionStep.instructions;
            _readings.clear();
            _clearRawState();
            _startedAt = null;
            _endedAt = null;
            _asrsAnswers.fillRange(0, _asrsAnswers.length, null);
            _exportMessage = null;
          }),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Repetir coleta'),
        ),
        if (_exportMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _exportMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAAB8CA)),
          ),
        ],
      ],
    );
  }

  Widget _screeningView() {
    final answered = _asrsAnswers.whereType<AsrsResponse>().length;
    final result = _asrsResult;
    return Column(
      key: const ValueKey('screening'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(
          eyebrow: 'RASTREIO ASRS V1.1',
          title: 'Seis perguntas para adultos',
          subtitle:
              'Assinale a alternativa que melhor descreve os últimos 6 meses.',
        ),
        const SizedBox(height: 14),
        const _Notice(
          icon: Icons.call_split_rounded,
          text:
              'Etapa destinada a pessoas com 18 anos ou mais. As respostas e o resumo do EEG ficam registrados juntos no relatório. A pontuação ASRS usa somente as respostas.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: answered / AsrsScreener6.itemCount,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFF26354A),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$answered de ${AsrsScreener6.itemCount}',
              style: const TextStyle(
                color: Color(0xFFAAB8CA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (var index = 0;
            index < AsrsScreener6.questions.length;
            index++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PERGUNTA ${index + 1} DE ${AsrsScreener6.itemCount}',
                    style: const TextStyle(
                      color: Color(0xFF8BBEFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AsrsScreener6.questions[index],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AsrsResponse>(
                    key: ValueKey('asrs_answer_$index'),
                    initialValue: _asrsAnswers[index],
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Resposta',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final response in AsrsResponse.values)
                        DropdownMenuItem(
                          value: response,
                          child: Text(response.label),
                        ),
                    ],
                    onChanged: (response) {
                      if (response == null) return;
                      setState(() => _asrsAnswers[index] = response);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const Text(
          AsrsScreener6.attribution,
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8493A6), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: result == null
              ? null
              : () => setState(() => _step = CollectionStep.result),
          icon: const Icon(Icons.speed_rounded),
          label: const Text('Concluir e ver os dois resultados'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = CollectionStep.result),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar ao resultado da coleta'),
        ),
      ],
    );
  }

  static double? _mean(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  static String _formatMean(double? value) =>
      value == null ? '—' : value.toStringAsFixed(0);

  static String _formatClock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _Reading {
  const _Reading({this.attention, this.meditation, this.signalQuality});

  final int? attention;
  final int? meditation;
  final int? signalQuality;
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4D7B), Color(0xFF12263E)],
        ),
        border: Border.all(color: const Color(0xFF35638E)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('SIMPLES E GUIADO'),
          SizedBox(height: 10),
          Text(
            'Conecte, siga as instruções e veja o resultado.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'O app orienta cada etapa, mostra a qualidade da coleta e compara as ondas entre olhos abertos e fechados.',
            style: TextStyle(color: Color(0xFFD2E0EE), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(eyebrow),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Color(0xFFAAB8CA))),
      ],
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF315F8C),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFFAAB8CA),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10233A),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF2B4F72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7DB3FF), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFC9D8E7), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAB8CA),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveWaveformCard extends StatelessWidget {
  const _LiveWaveformCard({required this.samples});

  final List<double> samples;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_rounded, color: Color(0xFF56D6B3)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'EEG bruto ao vivo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '5 s',
                  style: TextStyle(color: Color(0xFFAAB8CA), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: samples.isEmpty
                  ? 'Traçado de EEG aguardando dados'
                  : 'Traçado de EEG bruto ao vivo',
              child: Container(
                height: 116,
                decoration: BoxDecoration(
                  color: const Color(0xFF091422),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF263A50)),
                ),
                child: samples.length < 2
                    ? const Center(
                        child: Text(
                          'Aguardando EEG bruto…',
                          style: TextStyle(color: Color(0xFF8493A6)),
                        ),
                      )
                    : CustomPaint(painter: _WaveformPainter(samples)),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Traçado em microvolts. Piscadas e tensão muscular também aparecem '
              'aqui; a forma da onda não determina TDAH.',
              style: TextStyle(
                color: Color(0xFFAAB8CA),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpectrumResultCard extends StatelessWidget {
  const _SpectrumResultCard({required this.analysis});

  final EegSpectrumAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final value = analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.multiline_chart_rounded, color: Color(0xFF8BBEFF)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Ondas observadas nesta coleta',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HistoricalPatternCard(analysis: value),
            const SizedBox(height: 14),
            if (value == null || !value.isUsable) ...[
              const Icon(
                Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                size: 42,
                color: Color(0xFFFFC45C),
              ),
              const SizedBox(height: 9),
              const Text(
                'Bandas não exibidas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                value?.qualityExplanation ??
                    'O fluxo de EEG bruto não forneceu trechos suficientes.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFAAB8CA),
                  height: 1.4,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  _LegendDot(
                    color: const Color(0xFF67A7FF),
                    label: 'Olhos abertos',
                  ),
                  const SizedBox(width: 14),
                  _LegendDot(
                    color: const Color(0xFF56D6B3),
                    label: 'Olhos fechados',
                  ),
                ],
              ),
              const SizedBox(height: 15),
              for (final band in EegBand.values) ...[
                _BandComparisonRow(
                  band: band,
                  eyesOpen: value.eyesOpen.bands.valueFor(band),
                  eyesClosed: value.eyesClosed.bands.valueFor(band),
                ),
                if (band != EegBand.beta) const SizedBox(height: 12),
              ],
              const SizedBox(height: 15),
              Text(
                _alphaDescription(value.alphaChangePercent),
                style: const TextStyle(
                  color: Color(0xFFD0DCE9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(value.acceptedFraction * 100).round()}% dos trechos foram '
                'aproveitados após o controle de contato, perdas e artefatos.',
                style: const TextStyle(
                  color: Color(0xFFAAB8CA),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'As barras mostram a participação relativa de cada banda entre '
                '1 e 30 Hz. Elas descrevem a sessão e não indicam TDAH.',
                style: TextStyle(
                  color: Color(0xFFAAB8CA),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _alphaDescription(double? change) {
    if (change == null) return 'A variação de alfa não pôde ser calculada.';
    if (change >= 20) {
      return 'Nesta coleta, a potência alfa aumentou com os olhos fechados.';
    }
    if (change <= -20) {
      return 'Nesta coleta, a potência alfa foi menor com os olhos fechados.';
    }
    return 'Nesta coleta, a potência alfa ficou semelhante nas duas etapas.';
  }
}

class _HistoricalPatternCard extends StatelessWidget {
  const _HistoricalPatternCard({required this.analysis});

  final EegSpectrumAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final observed = analysis?.thetaAboveBetaInBothPhases;
    final status = switch (observed) {
      true => 'THETA MAIOR QUE BETA NAS DUAS ETAPAS',
      false => 'THETA MAIOR QUE BETA NÃO APARECEU NAS DUAS ETAPAS',
      null => 'COMPARAÇÃO THETA/BETA INDISPONÍVEL',
    };
    final accent =
        observed == true ? const Color(0xFFFFC45C) : const Color(0xFF8BBEFF);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: observed == true
            ? const Color(0xFF241E16)
            : const Color(0xFF111F30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: observed == true
              ? const Color(0xFF755B2D)
              : const Color(0xFF304B69),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 19, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PADRÃO HISTÓRICO PESQUISADO NO TDAH',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            EegSpectrumAnalysis.historicalAdhdContext,
            style: TextStyle(
              color: Color(0xFFE0D6C5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFAAB8CA), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandComparisonRow extends StatelessWidget {
  const _BandComparisonRow({
    required this.band,
    required this.eyesOpen,
    required this.eyesClosed,
  });

  final EegBand band;
  final double eyesOpen;
  final double eyesClosed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            band.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _PowerBar(value: eyesOpen, color: const Color(0xFF67A7FF)),
              const SizedBox(height: 5),
              _PowerBar(value: eyesClosed, color: const Color(0xFF56D6B3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PowerBar extends StatelessWidget {
  const _PowerBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100).toDouble();
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 9,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xFF26354A)),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: constraints.maxWidth * safeValue / 100,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 34,
          child: Text(
            '${safeValue.round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter(this.samples);

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas
        .clipRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(10)));
    final grid = Paint()
      ..color = const Color(0xFF1C3045)
      ..strokeWidth = 1;
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var column = 1; column < 5; column++) {
      final x = size.width * column / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    var maximum = 5.0;
    for (final sample in samples) {
      maximum = math.max(maximum, sample.abs());
    }
    maximum = math.min(maximum, 150);
    final path = Path();
    for (var index = 0; index < samples.length; index++) {
      final x =
          samples.length == 1 ? 0.0 : size.width * index / (samples.length - 1);
      final normalized = samples[index].clamp(-maximum, maximum) / maximum;
      final y = size.height / 2 - normalized * size.height * 0.42;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF56D6B3)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

class _AsrsPromptCard extends StatelessWidget {
  const _AsrsPromptCard({required this.isHardware, required this.onPressed});

  final bool isHardware;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2517), Color(0xFF141F30)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow('POSSIBILIDADE DE TDAH · RASTREIO ASRS V1.1'),
            const SizedBox(height: 8),
            Text(
              isHardware
                  ? 'Para completar o resultado do BrainLink, responda o questionário.'
                  : 'Para completar a demonstração, responda o questionário.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Isso torna o relatório mais útil para uma consulta: as seis '
              'respostas e o resumo das ondas ficam registrados juntos. O ponto '
              'de corte do ASRS usa somente as respostas.',
              style: TextStyle(color: Color(0xFFD0DCE9), height: 1.4),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: _InlineBadge('NÃO É DIAGNÓSTICO'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Responder 6 perguntas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsrsResultCard extends StatelessWidget {
  const _AsrsResultCard({required this.result});

  final AsrsScreenerResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.reachedScreeningCutoff
        ? const Color(0xFFFFC45C)
        : const Color(0xFF7DB3FF);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow('POSSIBILIDADE DE TDAH · RASTREIO ASRS V1.1'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF26354A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF52647B)),
                ),
                child: const Text(
                  'NÃO É DIAGNÓSTICO',
                  style: TextStyle(
                    color: Color(0xFFD7E2EE),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.total}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 4),
                  child: Text(
                    'de 24',
                    style: TextStyle(color: Color(0xFFAAB8CA)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: result.total / AsrsScreener6.maximumScore,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: accent,
              backgroundColor: const Color(0xFF26354A),
            ),
            const SizedBox(height: 14),
            Text(
              result.possibilityLabel,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              result.label,
              style: const TextStyle(
                color: Color(0xFFAAB8CA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.guidance,
              style: const TextStyle(color: Color(0xFFD0DCE9), height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ponto de corte da pontuação atualizada: 14. O ASRS é um '
              'rastreio para adultos. A possibilidade é calculada somente pelas '
              'respostas; elas e o resumo do EEG ficam juntos na exportação.',
              style: TextStyle(
                color: Color(0xFFAAB8CA),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombinedGuidanceCard extends StatelessWidget {
  const _CombinedGuidanceCard({
    required this.result,
    required this.spectrum,
  });

  final AsrsScreenerResult result;
  final EegSpectrumAnalysis? spectrum;

  @override
  Widget build(BuildContext context) {
    final pattern = spectrum?.thetaAboveBetaInBothPhases;
    final reached = result.reachedScreeningCutoff;
    final accent = reached ? const Color(0xFFFFC45C) : const Color(0xFF7DB3FF);
    final patternLabel = switch (pattern) {
      true => 'Theta maior que beta nas duas etapas',
      false => 'Theta maior que beta não apareceu nas duas etapas',
      null => 'Comparação theta/beta indisponível',
    };
    final guidance = switch ((reached, pattern)) {
      (true, true) =>
        'O ponto de corte do ASRS foi atingido e a combinação theta maior '
            'que beta apareceu nas duas etapas. As ondas não confirmam TDAH, '
            'mas o rastreio justifica procurar um médico para uma avaliação '
            'clínica completa.',
      (true, _) =>
        'O ponto de corte do ASRS foi atingido. A ausência ou indisponibilidade '
            'do padrão histórico nas ondas não exclui TDAH. Procure um médico '
            'para uma avaliação clínica completa.',
      (false, true) =>
        'O ponto de corte do ASRS não foi atingido. A combinação theta maior '
            'que beta também ocorre em pessoas sem TDAH e não altera esse '
            'resultado. Se houver dificuldade no dia a dia, procure um médico.',
      (false, _) =>
        'O ponto de corte do ASRS não foi atingido, o que não exclui TDAH. '
            'Se houver dificuldade no dia a dia, procure um médico.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow('RESUMO PARA LEVAR AO MÉDICO'),
            const SizedBox(height: 9),
            const Align(
              alignment: Alignment.centerLeft,
              child: _InlineBadge('NÃO É DIAGNÓSTICO'),
            ),
            const SizedBox(height: 14),
            _SummaryLine(
              label: 'Questionário ASRS',
              value: reached
                  ? '${result.total}/24 · corte 14 atingido'
                  : '${result.total}/24 · corte 14 não atingido',
              color: accent,
            ),
            const SizedBox(height: 10),
            _SummaryLine(
              label: 'Ondas desta coleta',
              value: patternLabel,
              color: pattern == true
                  ? const Color(0xFFFFC45C)
                  : const Color(0xFF8BBEFF),
            ),
            const SizedBox(height: 14),
            Text(
              guidance,
              style: const TextStyle(
                color: Color(0xFFD7E2EE),
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1828),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3A52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFAAB8CA), fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QualityGauge extends StatelessWidget {
  const _QualityGauge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: score == null
          ? 'Qualidade da coleta sem dado'
          : 'Qualidade da coleta $score de 100',
      child: Column(
        children: [
          SizedBox(
            height: 205,
            width: double.infinity,
            child: CustomPaint(painter: _GaugePainter(score)),
          ),
          const SizedBox(height: 4),
          Text(
            score?.toString() ?? '—',
            style: const TextStyle(
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'de 100',
            style: TextStyle(color: Color(0xFFAAB8CA)),
          ),
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF26354A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF52647B)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD7E2EE),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.score);

  final int? score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 34);
    final radius = math.min(size.width / 2 - 24, size.height - 54);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const gap = 0.025;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.butt;

    arcPaint.color = const Color(0xFFFF6675);
    canvas.drawArc(rect, math.pi, math.pi * (0.6 - gap), false, arcPaint);
    arcPaint.color = const Color(0xFFFFC45C);
    canvas.drawArc(
      rect,
      math.pi * 1.6,
      math.pi * (0.2 - gap),
      false,
      arcPaint,
    );
    arcPaint.color = const Color(0xFF56D6B3);
    canvas.drawArc(
      rect,
      math.pi * 1.8,
      math.pi * 0.2,
      false,
      arcPaint,
    );

    _label(canvas, center + Offset(-radius, 25), '0');
    _label(canvas, center + Offset(0, -radius - 20), '50');
    _label(canvas, center + Offset(radius, 25), '100');

    if (score != null) {
      final angle = math.pi + math.pi * score!.clamp(0, 100) / 100;
      final needleEnd = center +
          Offset(
            math.cos(angle) * (radius - 28),
            math.sin(angle) * (radius - 28),
          );
      canvas.drawLine(
        center,
        needleEnd,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(center, 9, Paint()..color = Colors.white);
      canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF172338));
    }
  }

  void _label(Canvas canvas, Offset position, String value) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(color: Color(0xFFAAB8CA), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.score != score;
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8BBEFF),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}
