import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/eeg_data.dart';
import '../../native/brainlink_bridge.dart';
import '../../services/guided_collection_report_exporter.dart';

enum AcquisitionMode { demonstration, hardware }

enum CollectionStep { choice, instructions, running, result }

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
      final started = await bridge.startScan();
      if (!started) throw StateError('A busca Bluetooth não foi iniciada.');
      await Future.any<void>([
        finished.future,
        Future<void>.delayed(const Duration(seconds: 8)),
      ]);
      final result = devices.values.toList()
        ..sort((a, b) {
          if (a.isPaired != b.isPaired) return a.isPaired ? -1 : 1;
          return a.name.compareTo(b.name);
        });
      return result;
    } finally {
      await bridge.stopScan();
      await deviceSubscription.cancel();
      await scanSubscription.cancel();
    }
  }

  @override
  Future<void> connect(ConnectableDevice device) async {
    final connected = Completer<void>();
    final connectionSubscription = bridge.connectionStateStream.listen((value) {
      if (value && !connected.isCompleted) connected.complete();
    });
    final errorSubscription = bridge.errorStream.listen((message) {
      if (!connected.isCompleted) connected.completeError(StateError(message));
    });
    try {
      final started = await bridge.connect(device.id);
      if (!started) throw StateError('A conexão Bluetooth não foi iniciada.');
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
    this.demonstrationPhaseDuration = const Duration(seconds: 8),
    this.hardwarePhaseDuration = const Duration(minutes: 1),
    this.tickInterval = const Duration(seconds: 1),
  });

  final DeviceDiscoveryGateway? deviceGateway;
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

  late final DeviceDiscoveryGateway _deviceGateway;
  StreamSubscription<EEGData>? _dataSubscription;
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
    _dataSubscription = _bridge.eegDataStream.listen(_onHardwareData);
    _connectionSubscription = _bridge.connectionStateStream.listen((connected) {
      if (!mounted) return;
      setState(() => _connected = connected);
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
    if (_scanning) return;
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
    } on Object {
      if (mounted) {
        setState(() => _connectionMessage =
            'Não foi possível buscar agora. Confira Bluetooth e permissões.');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(ConnectableDevice device) async {
    if (_connecting) return;
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
    } on Object {
      if (mounted) {
        setState(() => _connectionMessage =
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
      _exportMessage = null;
      if (_mode == AcquisitionMode.demonstration) {
        _appendDemonstrationReading();
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
        _appendDemonstrationReading();
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

  void _finishCollection() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _endedAt = DateTime.now();
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
      _startedAt = null;
      _endedAt = null;
      _exportMessage = null;
      _connectionMessage = null;
    });
  }

  GuidedCollectionReportData? get _report {
    final startedAt = _startedAt;
    final endedAt = _endedAt;
    if (startedAt == null || endedAt == null) return null;
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
          onPressed: _scanning ? null : _openHardware,
          icon: const Icon(Icons.bluetooth_searching_rounded),
          label: const Text('Conectar BrainLink'),
        ),
        if (_showHardware) ...[
          const SizedBox(height: 16),
          _hardwarePanel(),
        ],
        const SizedBox(height: 18),
        const _Notice(
          icon: Icons.verified_user_outlined,
          text:
              'A nota final avalia a qualidade da coleta. Ela não avalia saúde, TDAH ou capacidade da pessoa.',
        ),
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
                  onPressed: _scanning ? null : _scan,
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
                      onPressed: _connecting ? null : () => _connect(device),
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
              'O velocímetro resume contato e continuidade do sinal recebido.',
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
        const _Notice(
          icon: Icons.info_outline_rounded,
          text:
              'A nota do velocímetro é da coleta, não da pessoa. Os dois índices são cálculos proprietários do fabricante e não avaliam saúde ou TDAH.',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _export,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Exportar resultado'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _step = CollectionStep.instructions;
            _readings.clear();
            _startedAt = null;
            _endedAt = null;
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
            'O app orienta cada etapa e mostra a qualidade da coleta em um velocímetro fácil de entender.',
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

class _QualityGauge extends StatelessWidget {
  const _QualityGauge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: score == null
          ? 'Qualidade da coleta sem dado'
          : 'Qualidade da coleta $score de 100',
      child: SizedBox(
        height: 205,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _GaugePainter(score))),
            Positioned(
              bottom: 5,
              child: Column(
                children: [
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
            ),
          ],
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
