import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/asrs_screener_6.dart';
import '../../data/models/context_journal_entry.dart';
import '../../data/models/eeg_data.dart';
import '../../data/models/session_record.dart';
import '../../native/brainlink_bridge.dart';
import '../../services/local_session_store.dart';
import '../../services/session_report_exporter.dart';

enum AcquisitionMode { demonstration, hardware }

class ConnectableDevice {
  const ConnectableDevice(this.id, this.name, {required this.isPaired});

  final String id;
  final String name;
  final bool isPaired;
}

/// Contrato que a descoberta Bluetooth nativa pode implementar sem alterar a UI.
abstract interface class DeviceDiscoveryGateway {
  Future<List<ConnectableDevice>> listDevices();
  Future<void> connect(ConnectableDevice device);
}

/// Adaptador da interface para a descoberta Bluetooth Clássico nativa.
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
  });

  final DeviceDiscoveryGateway? deviceGateway;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pipelineVersion = 'a1-1.0.0';

  final BrainLinkBridge _bridge = BrainLinkBridge();
  final SessionReportExporter _reportExporter = const SessionReportExporter();
  late final DeviceDiscoveryGateway _deviceGateway;
  StreamSubscription<EEGData>? _hardwareDataSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<String>? _errorSubscription;
  LocalSessionStore? _store;
  Directory? _storageRoot;

  int _page = 0;
  AcquisitionMode _mode = AcquisitionMode.demonstration;
  bool _scanning = false;
  bool _connecting = false;
  bool _connected = false;
  String? _connectionMessage;
  List<ConnectableDevice> _devices = const [];

  Timer? _timer;
  bool _sessionActive = false;
  DateTime? _sessionStartedAt;
  int _tick = 0;
  final List<double> _attention = [];
  final List<double> _meditation = [];
  final List<_SessionEntry> _history = [];
  final List<SessionEpochRecord> _currentEpochs = [];
  List<SessionEpochRecord> _lastEpochs = const [];
  SessionMetadata? _lastMetadata;
  ContextJournalEntry? _lastJournal;
  String? _lastExportPath;
  double _sleepHours = 7;
  String _mood = 'Neutro';
  String _medication = 'Não informado';
  String _task = 'Rotina';

  final List<AsrsResponse?> _answers =
      List<AsrsResponse?>.filled(AsrsScreener6.items.length, null);

  @override
  void initState() {
    super.initState();
    _deviceGateway = widget.deviceGateway ?? NativeBrainLinkGateway(_bridge);
    _hardwareDataSubscription = _bridge.eegDataStream.listen(_onHardwareData);
    _connectionSubscription = _bridge.connectionStateStream.listen((connected) {
      if (mounted) setState(() => _connected = connected);
    });
    _errorSubscription = _bridge.errorStream.listen((message) {
      if (mounted) setState(() => _connectionMessage = message);
    });
    unawaited(_initializeStore());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_hardwareDataSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    super.dispose();
  }

  Future<void> _initializeStore() async {
    try {
      final path = await _bridge.getStorageRoot();
      if (path == null || path.isEmpty) return;
      _storageRoot = Directory(path);
      _store = LocalSessionStore(_storageRoot!);
      final metadata = await _store!.listSessions();
      final restored = <_SessionEntry>[];
      StoredSession? latest;
      ContextJournalEntry? latestJournal;
      for (final item in metadata.take(20)) {
        final stored = await _store!.readSession(item.sessionId);
        latest ??= stored;
        final journals = stored.events
            .where((event) => event.type == SessionEventType.journal)
            .map((event) => ContextJournalEntry.fromJson(event.payload))
            .toList();
        if (latestJournal == null && journals.isNotEmpty) {
          latestJournal = journals.last;
        }
        final acceptedAttention = stored.epochs
            .where((epoch) =>
                epoch.accepted && epoch.manufacturerAttention != null)
            .map((epoch) => epoch.manufacturerAttention!)
            .toList();
        final journal = journals.isEmpty ? null : journals.last;
        restored.add(
          _SessionEntry(
            date: item.startedAt,
            source: item.deviceLabel,
            sleepHours: journal?.sleepHours ?? 0,
            mood: journal?.moodLevel == null
                ? 'Não informado'
                : '${journal!.moodLevel}/5',
            medication: journal?.medicationNote ?? 'Não informado',
            task: journal?.task ?? 'Não informado',
            manufacturerMean: acceptedAttention.isEmpty
                ? null
                : acceptedAttention.reduce((a, b) => a + b) /
                    acceptedAttention.length,
          ),
        );
      }
      if (mounted && restored.isNotEmpty) {
        setState(() {
          _history
            ..clear()
            ..addAll(restored);
          _lastMetadata = latest?.metadata;
          _lastEpochs = latest?.epochs ?? const [];
          _lastJournal = latestJournal;
        });
      }
    } on Exception {
      // Fora do Android, a demonstração continua funcional em memória.
    }
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _devices = const [];
      _connectionMessage = null;
    });
    try {
      final result = await _deviceGateway.listDevices();
      if (!mounted) return;
      setState(() {
        _devices = result;
        if (result.isEmpty) {
          _connectionMessage =
              'Nenhum dispositivo localizado. Confira o pareamento e tente novamente.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _connectionMessage =
            'Não foi possível consultar os dispositivos agora. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(ConnectableDevice device) async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _connectionMessage = null;
    });
    try {
      await _deviceGateway.connect(device);
      if (!mounted) return;
      setState(() {
        _connected = true;
        _connectionMessage = 'BrainLink conectado e pronto para a sessão.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _connectionMessage =
            'A conexão não foi concluída. Aproxime o dispositivo e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _startSession() {
    if (_mode == AcquisitionMode.hardware && !_connected) {
      _message('Conecte um dispositivo antes de iniciar neste modo.');
      setState(() => _page = 0);
      return;
    }
    _timer?.cancel();
    setState(() {
      _sessionActive = true;
      _sessionStartedAt = DateTime.now();
      _tick = 0;
      _attention.clear();
      _meditation.clear();
      _currentEpochs.clear();
    });
    if (_mode == AcquisitionMode.demonstration) {
      _appendSample();
      _timer = Timer.periodic(
        const Duration(milliseconds: 800),
        (_) => _appendSample(),
      );
    }
  }

  void _appendSample() {
    if (!mounted) return;
    final first = 49 + ((_tick * 7) % 25) - ((_tick % 4) * 3);
    final second = 55 + ((_tick * 5) % 19) - ((_tick % 5) * 2);
    final attention = first.clamp(0, 100).toInt();
    final meditation = second.clamp(0, 100).toInt();
    setState(() {
      _tick++;
      _attention.add(attention.toDouble());
      _meditation.add(meditation.toDouble());
      _currentEpochs.add(
        SessionEpochRecord(
          sequence: _currentEpochs.length,
          capturedAt: DateTime.now(),
          accepted: true,
          signalQuality: 0,
          manufacturerAttention: attention,
          manufacturerMeditation: meditation,
        ),
      );
      if (_attention.length > 30) _attention.removeAt(0);
      if (_meditation.length > 30) _meditation.removeAt(0);
    });
  }

  void _onHardwareData(EEGData data) {
    if (!mounted || !_sessionActive || _mode != AcquisitionMode.hardware) {
      return;
    }
    final accepted = data.signalQuality != null && data.signalQuality! <= 50;
    final epoch = SessionEpochRecord(
      sequence: _currentEpochs.length,
      capturedAt: data.timestamp,
      accepted: accepted,
      rejectionReason: accepted
          ? null
          : data.signalQuality == null
              ? 'Qualidade do sinal ainda não medida.'
              : 'Qualidade do sinal insuficiente; reposicione o sensor.',
      signalQuality: data.signalQuality,
      manufacturerAttention: accepted ? data.attention : null,
      manufacturerMeditation: accepted ? data.meditation : null,
    );
    setState(() {
      _currentEpochs.add(epoch);
      if (accepted && data.attention != null) {
        _attention.add(data.attention!.toDouble());
        if (_attention.length > 30) _attention.removeAt(0);
      }
      if (accepted && data.meditation != null) {
        _meditation.add(data.meditation!.toDouble());
        if (_meditation.length > 30) _meditation.removeAt(0);
      }
    });
  }

  Future<void> _finishSession() async {
    if (!_sessionActive) return;
    _timer?.cancel();
    final endedAt = DateTime.now();
    final startedAt = _sessionStartedAt ?? endedAt;
    final sessionId = 'session_${startedAt.millisecondsSinceEpoch}';
    final deviceLabel = _mode == AcquisitionMode.demonstration
        ? 'Demonstração com dados simulados'
        : 'BrainLink Lite';
    final average = _attention.isEmpty
        ? null
        : _attention.reduce((a, b) => a + b) / _attention.length;
    final journal = ContextJournalEntry(
      id: 'journal_${endedAt.millisecondsSinceEpoch}',
      recordedAt: endedAt,
      sleepHours: _sleepHours,
      medicationTaken: switch (_medication) {
        'Não utilizada' => false,
        'Utilizada conforme orientação' => true,
        _ => null,
      },
      medicationNote: _medication == 'Não informado' ? null : _medication,
      moodLevel: const [
            'Muito baixo',
            'Baixo',
            'Neutro',
            'Elevado',
            'Muito elevado',
          ].indexOf(_mood) +
          1,
      task: _task,
    );
    final metadata = SessionMetadata(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      pipelineVersion: _pipelineVersion,
      deviceLabel: deviceLabel,
      sampleRateHz: _mode == AcquisitionMode.hardware ? 128 : null,
    );
    setState(() {
      _sessionActive = false;
      _lastMetadata = metadata;
      _lastEpochs = List<SessionEpochRecord>.unmodifiable(_currentEpochs);
      _lastJournal = journal;
      _history.insert(
        0,
        _SessionEntry(
          date: startedAt,
          source: _mode == AcquisitionMode.demonstration
              ? 'Demonstração'
              : 'BrainLink Lite',
          sleepHours: _sleepHours,
          mood: _mood,
          medication: _medication,
          task: _task,
          manufacturerMean: average,
        ),
      );
    });
    final store = _store;
    if (store != null) {
      try {
        await store.createSession(
          sessionId: sessionId,
          startedAt: startedAt,
          pipelineVersion: _pipelineVersion,
          deviceLabel: deviceLabel,
          sampleRateHz: metadata.sampleRateHz,
        );
        for (final epoch in _lastEpochs) {
          await store.appendEpoch(sessionId, epoch);
        }
        await store.appendEvent(sessionId, SessionEventRecord.journal(journal));
        await store.finishSession(sessionId, endedAt);
      } on Object catch (error) {
        if (mounted) {
          _message('Sessão mantida na tela; falha ao salvar: $error');
        }
        return;
      }
    }
    if (mounted) _message('Sessão registrada no histórico local.');
  }

  void _fillExample() {
    const example = [
      AsrsResponse.often,
      AsrsResponse.sometimes,
      AsrsResponse.sometimes,
      AsrsResponse.often,
      AsrsResponse.rarely,
      AsrsResponse.often,
    ];
    setState(() {
      for (var index = 0; index < example.length; index++) {
        _answers[index] = example[index];
      }
    });
  }

  void _clearAnswers() {
    setState(() {
      for (var index = 0; index < _answers.length; index++) {
        _answers[index] = null;
      }
    });
  }

  bool get _asrsComplete => _answers.every((answer) => answer != null);

  AsrsScreenerResult? _questionnaireResult() {
    if (!_asrsComplete) return null;
    return AsrsScreenerResult(
      id: 'asrs_${DateTime.now().millisecondsSinceEpoch}',
      completedAt: DateTime.now(),
      responses: _answers.cast<AsrsResponse>(),
    );
  }

  SessionReportData? _reportData() {
    final questionnaire = _questionnaireResult();
    if (_lastMetadata == null && questionnaire == null) return null;
    final now = DateTime.now();
    return SessionReportData(
      metadata: _lastMetadata ??
          SessionMetadata(
            sessionId: 'screening_${now.millisecondsSinceEpoch}',
            startedAt: now,
            endedAt: now,
            pipelineVersion: _pipelineVersion,
            deviceLabel: 'Sem sessão de EEG',
          ),
      epochs: _lastEpochs,
      journalEntries: _lastJournal == null
          ? const []
          : <ContextJournalEntry>[_lastJournal!],
      questionnaire: questionnaire,
    );
  }

  String? _reportText() {
    final data = _reportData();
    return data == null ? null : _reportExporter.buildText(data);
  }

  Future<void> _exportReport() async {
    final data = _reportData();
    if (data == null) return;
    if (_store == null) await _initializeStore();
    final root = _storageRoot;
    if (root == null) {
      _message(
          'A exportação de arquivo está disponível no aplicativo Android.');
      return;
    }
    try {
      final questionnaire = data.questionnaire;
      if (questionnaire != null) await _store?.saveQuestionnaire(questionnaire);
      final files = await _reportExporter.export(
        data,
        Directory('${root.path}${Platform.pathSeparator}exports'),
      );
      final html = files.firstWhere((file) => file.path.endsWith('.html'));
      final shared = await _bridge.shareFile(html.path, mimeType: 'text/html');
      if (!mounted) return;
      setState(() => _lastExportPath = html.path);
      _message(shared
          ? 'Relatório HTML gerado. Escolha onde compartilhar.'
          : 'Relatório HTML gerado em ${html.path}.');
    } on Object catch (error) {
      if (mounted) _message('Não foi possível exportar o relatório: $error');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomePage(
        mode: _mode,
        devices: _devices,
        scanning: _scanning,
        connecting: _connecting,
        connected: _connected,
        connectionMessage: _connectionMessage,
        onMode: (value) => setState(() => _mode = value),
        onScan: _scan,
        onConnect: _connect,
        onContinue: () => setState(() => _page = 1),
      ),
      _SessionPage(
        mode: _mode,
        connected: _connected,
        active: _sessionActive,
        startedAt: _sessionStartedAt,
        attention: _attention,
        meditation: _meditation,
        sleepHours: _sleepHours,
        mood: _mood,
        medication: _medication,
        task: _task,
        onSleep: (value) => setState(() => _sleepHours = value),
        onMood: (value) => setState(() => _mood = value),
        onMedication: (value) => setState(() => _medication = value),
        onTask: (value) => setState(() => _task = value),
        onToggle: _sessionActive ? _finishSession : _startSession,
      ),
      _AsrsPage(
        answers: _answers,
        onAnswer: (index, value) => setState(() => _answers[index] = value),
        onFillExample: _fillExample,
        onClear: _clearAnswers,
      ),
      _ReportPage(
        answers: _answers,
        history: _history,
        reportText: _reportText(),
        onExport: _exportReport,
        exportedPath: _lastExportPath,
        onOpenAsrs: () => setState(() => _page = 2),
        onOpenSession: () => setState(() => _page = 1),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BRAINLINK DIÁRIO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Autorregistro para adultos (18+)',
              style: TextStyle(color: Color(0xFF91A0B5), fontSize: 12),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Sem envio automático',
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 17, color: Color(0xFF83A4C5)),
                  SizedBox(width: 5),
                  Text('LOCAL',
                      style: TextStyle(
                          color: Color(0xFF93A7BA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _page,
                  onDestinationSelected: (value) =>
                      setState(() => _page = value),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.75,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: screens[_page]),
              ],
            );
          }
          return screens[_page];
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              destinations: _destinations,
            )
          : null,
    );
  }
}

const _destinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
  NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Sessão'),
  NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'ASRS'),
  NavigationDestination(
      icon: Icon(Icons.description_outlined), label: 'Relatório'),
];

const _railDestinations = [
  NavigationRailDestination(
      icon: Icon(Icons.home_outlined), label: Text('Início')),
  NavigationRailDestination(
      icon: Icon(Icons.show_chart_rounded), label: Text('Sessão')),
  NavigationRailDestination(
      icon: Icon(Icons.fact_check_outlined), label: Text('ASRS')),
  NavigationRailDestination(
      icon: Icon(Icons.description_outlined), label: Text('Relatório')),
];

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.mode,
    required this.devices,
    required this.scanning,
    required this.connecting,
    required this.connected,
    required this.connectionMessage,
    required this.onMode,
    required this.onScan,
    required this.onConnect,
    required this.onContinue,
  });

  final AcquisitionMode mode;
  final List<ConnectableDevice> devices;
  final bool scanning;
  final bool connecting;
  final bool connected;
  final String? connectionMessage;
  final ValueChanged<AcquisitionMode> onMode;
  final VoidCallback onScan;
  final ValueChanged<ConnectableDevice> onConnect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(),
          const SizedBox(height: 26),
          const _Title(
            'Como você quer usar agora?',
            'Escolha um modo. A origem dos dados continua visível durante a sessão.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final cards = [
              _ModeCard(
                selected: mode == AcquisitionMode.demonstration,
                icon: Icons.play_circle_outline_rounded,
                title: 'Demonstração',
                description:
                    'Série simulada para apresentar gráfico, diário e relatório sem o headset.',
                badge: 'DADOS SIMULADOS',
                onTap: () => onMode(AcquisitionMode.demonstration),
              ),
              _ModeCard(
                selected: mode == AcquisitionMode.hardware,
                icon: Icons.bluetooth_searching_rounded,
                title: 'Hardware',
                description:
                    'Busca dispositivos pareados e conecta ao BrainLink Lite por Bluetooth.',
                badge: 'HARDWARE REAL',
                onTap: () => onMode(AcquisitionMode.hardware),
              ),
            ];
            if (constraints.maxWidth >= 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              );
            }
            return Column(
                children: [cards[0], const SizedBox(height: 12), cards[1]]);
          }),
          if (mode == AcquisitionMode.hardware) ...[
            const SizedBox(height: 18),
            _HardwareCard(
              devices: devices,
              scanning: scanning,
              connecting: connecting,
              connected: connected,
              message: connectionMessage,
              onScan: onScan,
              onConnect: onConnect,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Abrir sessão e diário'),
            ),
          ),
          const SizedBox(height: 22),
          const _SeparationNotice(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF183E67), Color(0xFF13283F)],
        ),
        border: Border.all(color: const Color(0xFF315C85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('DIÁRIO LONGITUDINAL'),
          const SizedBox(height: 10),
          Text(
            'Observe contexto, respostas e sinais ao longo do tempo.',
            style: text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Organize autorregistros para apoiar uma conversa com profissional de saúde. Uso destinado a adultos com 18 anos ou mais.',
            style: text.bodyMedium?.copyWith(
              color: const Color(0xFFD1DFEE),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF172B43) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? theme.colorScheme.primary : const Color(0xFF25334A),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF7DB3FF), size: 28),
              const Spacer(),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? theme.colorScheme.primary
                    : const Color(0xFF67758A),
              ),
            ]),
            const SizedBox(height: 14),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(description,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFFAAB8CA), height: 1.4)),
            const SizedBox(height: 12),
            _Pill(badge),
          ],
        ),
      ),
    );
  }
}

class _HardwareCard extends StatelessWidget {
  const _HardwareCard({
    required this.devices,
    required this.scanning,
    required this.connecting,
    required this.connected,
    required this.message,
    required this.onScan,
    required this.onConnect,
  });

  final List<ConnectableDevice> devices;
  final bool scanning;
  final bool connecting;
  final bool connected;
  final String? message;
  final VoidCallback onScan;
  final ValueChanged<ConnectableDevice> onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.bluetooth_rounded, color: Color(0xFF7DB3FF)),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Conectar dispositivo',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(
                onPressed: scanning ? null : onScan,
                icon: scanning
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: Text(scanning ? 'Buscando' : 'Buscar'),
              ),
            ]),
            const SizedBox(height: 7),
            Text(
              'Dispositivos pareados aparecem primeiro. Outros dispositivos próximos surgem durante a busca.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFFAAB8CA), height: 1.4),
            ),
            if (devices.isEmpty && !scanning) ...[
              const SizedBox(height: 14),
              const _Empty(
                Icons.bluetooth_disabled_rounded,
                'Nenhum dispositivo listado',
                'Toque em Buscar para consultar dispositivos pareados.',
              ),
            ],
            for (final device in devices) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1828),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF2A3A52)),
                ),
                child: Row(children: [
                  const Icon(Icons.headphones_rounded,
                      color: Color(0xFF8BBEFF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(device.isPaired ? 'Pareado' : 'Disponível',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF93A5BB))),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: connecting || connected
                        ? null
                        : () => onConnect(device),
                    child: Text(connected
                        ? 'Conectado'
                        : connecting
                            ? 'Conectando'
                            : 'Conectar'),
                  ),
                ]),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 12),
              _Info(message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionPage extends StatelessWidget {
  const _SessionPage({
    required this.mode,
    required this.connected,
    required this.active,
    required this.startedAt,
    required this.attention,
    required this.meditation,
    required this.sleepHours,
    required this.mood,
    required this.medication,
    required this.task,
    required this.onSleep,
    required this.onMood,
    required this.onMedication,
    required this.onTask,
    required this.onToggle,
  });

  final AcquisitionMode mode;
  final bool connected;
  final bool active;
  final DateTime? startedAt;
  final List<double> attention;
  final List<double> meditation;
  final double sleepHours;
  final String mood;
  final String medication;
  final String task;
  final ValueChanged<double> onSleep;
  final ValueChanged<String> onMood;
  final ValueChanged<String> onMedication;
  final ValueChanged<String> onTask;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = attention.isNotEmpty;
    final source = mode == AcquisitionMode.demonstration
        ? 'Dados simulados'
        : connected
            ? 'BrainLink Lite • dados reais'
            : 'Hardware ainda não conectado';
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _Title('Sessão de observação', source)),
            const SizedBox(width: 8),
            _Pill(active ? 'EM EXECUÇÃO' : 'INATIVA',
                color:
                    active ? const Color(0xFF67D5B5) : const Color(0xFF8493A6)),
          ]),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diário de contexto',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    'As condições aparecem no histórico sem atribuir causa aos sinais.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF9EADBF)),
                  ),
                  const SizedBox(height: 14),
                  Text('Sono: ${sleepHours.toStringAsFixed(1)} horas'),
                  Slider(
                    value: sleepHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    onChanged: active ? null : onSleep,
                  ),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth >= 680
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth;
                    return Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                        width: width,
                        child: _Dropdown(
                          'Humor',
                          mood,
                          const [
                            'Muito baixo',
                            'Baixo',
                            'Neutro',
                            'Elevado',
                            'Muito elevado'
                          ],
                          enabled: !active,
                          onChanged: onMood,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _Dropdown(
                          'Medicação',
                          medication,
                          const [
                            'Não informado',
                            'Não utilizada',
                            'Utilizada conforme orientação'
                          ],
                          enabled: !active,
                          onChanged: onMedication,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _Dropdown(
                          'Tipo de tarefa',
                          task,
                          const [
                            'Rotina',
                            'Estudo',
                            'Trabalho',
                            'Leitura',
                            'Descanso'
                          ],
                          enabled: !active,
                          onChanged: onTask,
                        ),
                      ),
                    ]);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Title(
            'EEG descritivo',
            'Índices do fabricante (algoritmo proprietário) • escala de 0 a 100',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: hasData
                      ? _Chart(attention, meditation)
                      : const _Empty(
                          Icons.show_chart_rounded,
                          'Sem dados nesta sessão',
                          'Inicie a coleta para visualizar a série temporal.',
                        ),
                ),
                const SizedBox(height: 10),
                const Wrap(spacing: 18, runSpacing: 6, children: [
                  _Legend(Color(0xFF67A7FF), 'Attention • fabricante'),
                  _Legend(Color(0xFF67D5B5), 'Meditation • fabricante'),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _Value('Attention',
                        hasData ? attention.last.round().toString() : '—'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Value(
                        'Meditation',
                        meditation.isNotEmpty
                            ? meditation.last.round().toString()
                            : '—'),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const _Info(
            'Estes valores descrevem a saída do dispositivo. Não existe classificação positiva ou negativa, nem comparação com outras pessoas.',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onToggle,
              icon: Icon(active
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded),
              label: Text(active ? 'Finalizar e registrar' : 'Iniciar sessão'),
            ),
          ),
          if (active && startedAt != null) ...[
            const SizedBox(height: 7),
            Center(child: Text('Iniciada às ${_time(startedAt!)}')),
          ],
        ],
      ),
    );
  }
}

class _AsrsPage extends StatelessWidget {
  const _AsrsPage({
    required this.answers,
    required this.onAnswer,
    required this.onFillExample,
    required this.onClear,
  });

  final List<AsrsResponse?> answers;
  final void Function(int, AsrsResponse?) onAnswer;
  final VoidCallback onFillExample;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = answers.every((answer) => answer != null);
    final answered = answers.whereType<AsrsResponse>().length;
    final score =
        complete ? AsrsScreener6.score(answers.cast<AsrsResponse>()) : null;
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(
            'ASRS v1.1 • 6 perguntas',
            'Escala validada de rastreio para adultos (18+) • considere os últimos 6 meses',
          ),
          const SizedBox(height: 12),
          const _Info(
            'Esta é a camada validada do aplicativo. Ela permanece separada dos registros descritivos do dispositivo.',
          ),
          const SizedBox(height: 8),
          Text(
            AsrsScreener6.attribution,
            style: const TextStyle(
              color: Color(0xFF8798AD),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: answered / AsrsScreener6.items.length, minHeight: 8),
              ),
            ),
            const SizedBox(width: 10),
            Text('$answered/6 respondidas'),
          ]),
          const SizedBox(height: 16),
          for (var index = 0; index < AsrsScreener6.items.length; index++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AsrsScreener6.items[index].number}. '
                      '${AsrsScreener6.items[index].text}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AsrsResponse>(
                      key: ValueKey('asrs-$index-${answers[index]}'),
                      initialValue: answers[index],
                      decoration: const InputDecoration(
                          labelText: 'Frequência',
                          border: OutlineInputBorder()),
                      isExpanded: true,
                      items: [
                        for (final answer in AsrsResponse.values)
                          DropdownMenuItem(
                              value: answer, child: Text(answer.label)),
                      ],
                      onChanged: (value) => onAnswer(index, value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
          Row(children: [
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpar'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onFillExample,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Usar exemplo'),
            ),
          ]),
          const SizedBox(height: 12),
          if (complete)
            _AsrsResult(
              score!,
              meritsAttention: score >= AsrsScreener6.attentionThreshold,
            )
          else
            const _Empty(
              Icons.fact_check_outlined,
              'Resultado ainda indisponível',
              'Responda as 6 perguntas para calcular a pontuação.',
            ),
        ],
      ),
    );
  }
}

class _AsrsResult extends StatelessWidget {
  const _AsrsResult(this.score, {required this.meritsAttention});

  final int score;
  final bool meritsAttention;

  @override
  Widget build(BuildContext context) {
    final accent =
        meritsAttention ? const Color(0xFFFFC76B) : const Color(0xFF74CDB5);
    final message = meritsAttention
        ? AsrsScreener6.attentionMessage
        : AsrsScreener6.belowThresholdMessage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 29),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$score/6 respostas de rastreio',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 8),
            const Text(
              'A pontuação organiza o rastreio e não confirma nem exclui uma condição de saúde.',
              style: TextStyle(
                  color: Color(0xFF9DADBF), fontSize: 12, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ReportPage extends StatelessWidget {
  const _ReportPage({
    required this.answers,
    required this.history,
    required this.reportText,
    required this.onExport,
    required this.exportedPath,
    required this.onOpenAsrs,
    required this.onOpenSession,
  });

  final List<AsrsResponse?> answers;
  final List<_SessionEntry> history;
  final String? reportText;
  final VoidCallback onExport;
  final String? exportedPath;
  final VoidCallback onOpenAsrs;
  final VoidCallback onOpenSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = answers.every((answer) => answer != null);
    final score =
        complete ? AsrsScreener6.score(answers.cast<AsrsResponse>()) : null;
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(
            'Histórico e relatório',
            'Exportação somente quando você solicita • dados mantidos nesta execução',
          ),
          const SizedBox(height: 12),
          const _SeparationNotice(),
          const SizedBox(height: 16),
          _LayerCard(
            'CAMADA 1 • ESCALA VALIDADA',
            complete
                ? 'ASRS v1.1: $score/6 respostas de rastreio'
                : 'ASRS ainda não concluída',
            complete
                ? (score! >= AsrsScreener6.attentionThreshold
                    ? AsrsScreener6.attentionMessage
                    : AsrsScreener6.belowThresholdMessage)
                : 'Conclua as seis respostas para incluir esta seção.',
            Icons.fact_check_outlined,
            action: complete ? null : onOpenAsrs,
            actionLabel: 'Responder agora',
          ),
          const SizedBox(height: 12),
          _LayerCard(
            'CAMADA 2 • EEG DESCRITIVO',
            history.isEmpty
                ? 'Nenhuma sessão registrada'
                : '${history.length} ${history.length == 1 ? 'sessão' : 'sessões'} no histórico',
            history.isEmpty
                ? 'Registre uma sessão para incluir contexto e índices do fabricante.'
                : 'Autorregistro do próprio usuário, sem comparação populacional.',
            Icons.show_chart_rounded,
            action: history.isEmpty ? onOpenSession : null,
            actionLabel: 'Abrir sessão',
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Sessões recentes',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final entry in history) ...[
              _History(entry),
              const SizedBox(height: 7),
            ],
          ],
          const SizedBox(height: 18),
          Text('Prévia da exportação',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1421),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF25334A)),
            ),
            child: SelectableText(
              reportText ??
                  'A prévia será gerada depois que houver uma sessão ou um screener concluído.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB7C4D4),
                  height: 1.5,
                  fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: reportText == null ? null : onExport,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Exportar relatório HTML'),
            ),
          ),
          const SizedBox(height: 7),
          Center(
            child: Text(
              exportedPath == null
                  ? 'O arquivo só é criado quando você toca em exportar.'
                  : 'Arquivo gerado: $exportedPath',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E9EB2),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard(
    this.eyebrow,
    this.title,
    this.description,
    this.icon, {
    this.action,
    required this.actionLabel,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1B3553),
            child: Icon(icon, color: const Color(0xFF82B8FF)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Eyebrow(eyebrow),
              const SizedBox(height: 6),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(description,
                  style: const TextStyle(
                      color: Color(0xFFAAB8CA), fontSize: 12, height: 1.4)),
              if (action != null)
                TextButton(onPressed: action, child: Text(actionLabel)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History(this.entry);
  final _SessionEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF25334A)),
      ),
      child: Row(children: [
        const Icon(Icons.history_rounded, color: Color(0xFF8BBEFF)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_dateTime(entry.date)} • ${entry.source}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
                '${entry.sleepHours.toStringAsFixed(1)} h de sono • ${entry.mood} • ${entry.task}',
                style: const TextStyle(color: Color(0xFF96A6BA), fontSize: 12)),
          ]),
        ),
        Text(entry.manufacturerMean?.toStringAsFixed(1) ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart(this.attention, this.meditation);
  final List<double> attention;
  final List<double> meditation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Gráfico com ${attention.length} amostras simuladas dos índices do fabricante.',
      child: CustomPaint(painter: _ChartPainter(attention, meditation)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.attention, this.meditation);
  final List<double> attention;
  final List<double> meditation;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF26374C)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _line(canvas, size, attention, const Color(0xFF67A7FF));
    _line(canvas, size, meditation, const Color(0xFF67D5B5));
  }

  void _line(Canvas canvas, Size size, List<double> values, Color color) {
    if (values.isEmpty) return;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / math.max(1, values.length - 1);
      final y = size.height * (1 - values[index].clamp(0, 100) / 100);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.attention.length != attention.length ||
      old.meditation.length != meditation.length ||
      (attention.isNotEmpty && old.attention.last != attention.last);
}

class _Dropdown extends StatelessWidget {
  const _Dropdown(
    this.label,
    this.value,
    this.values, {
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      isExpanded: true,
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item))
      ],
      onChanged: enabled
          ? (value) {
              if (value != null) onChanged(value);
            }
          : null,
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1725),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26364B)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF91A2B7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const Text('algoritmo proprietário',
            style: TextStyle(color: Color(0xFF7F91A7), fontSize: 10)),
      ]),
    );
  }
}

class _SeparationNotice extends StatelessWidget {
  const _SeparationNotice();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF152332),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF334A60)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.call_split_rounded, color: Color(0xFF86B9E4)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Duas camadas independentes: a ASRS é uma escala validada de rastreio; o EEG é um registro descritivo do próprio usuário. Uma camada não confirma nem refuta a outra.',
            style: TextStyle(color: Color(0xFFC2D3E1), height: 1.4),
          ),
        ),
      ]),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: const Color(0xFF98A8BB), height: 1.4)),
    ]);
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.icon, this.title, this.message);
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF62748B), size: 32),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8FA0B4), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF102132),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28445D)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded,
            color: Color(0xFF7FB9E8), size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(message,
              style: const TextStyle(color: Color(0xFFBDD1E0), height: 1.4)),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.color = const Color(0xFF82B8FF)});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFF88BAF2),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8));
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _SessionEntry {
  const _SessionEntry({
    required this.date,
    required this.source,
    required this.sleepHours,
    required this.mood,
    required this.medication,
    required this.task,
    required this.manufacturerMean,
  });
  final DateTime date;
  final String source;
  final double sleepHours;
  final String mood;
  final String medication;
  final String task;
  final double? manufacturerMean;
}

String _dateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}

String _time(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}
