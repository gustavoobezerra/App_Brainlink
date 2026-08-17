import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/eeg_data.dart';
import '../../services/mock_data_service.dart';

/// Painel de demonstração para visualização de indicadores de EEG.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MockDataService _mockDataService = MockDataService();

  StreamSubscription<EEGData>? _dataSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  EEGData _latestData = EEGData.absent();
  bool _isCollecting = false;
  bool _isChangingState = false;

  @override
  void initState() {
    super.initState();

    _dataSubscription = _mockDataService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _latestData = data);
      }
    });

    _connectionSubscription = _mockDataService.connectionStream.listen((value) {
      if (mounted) {
        setState(() => _isCollecting = value);
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(_mockDataService.stopMockData());
    super.dispose();
  }

  Future<void> _toggleCollection() async {
    if (_isChangingState) {
      return;
    }

    setState(() => _isChangingState = true);
    try {
      if (_isCollecting) {
        await _mockDataService.stopMockData();
      } else {
        await _mockDataService.startMockData();
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingState = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bands = <_BandData>[
      _BandData('Delta', '0,5–4 Hz', _latestData.delta),
      _BandData('Theta', '4–8 Hz', _latestData.theta),
      _BandData('Alfa', '8–12 Hz', _latestData.totalAlpha),
      _BandData('Beta', '12–18 Hz', _latestData.totalBeta),
      _BandData('Gama', '18–40 Hz', _latestData.totalGamma),
    ];
    final maximumBandPower = bands.fold<int>(
      1,
      (current, band) =>
          (band.value != null && band.value! > current) ? band.value! : current,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BRAINLINK EEG MONITOR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Ambiente de demonstração acadêmica',
              style: TextStyle(
                color: Color(0xFF9AABC2),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusIndicator(isActive: _isCollecting),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IntroductionPanel(
                    isCollecting: _isCollecting,
                    isChangingState: _isChangingState,
                    onToggle: _toggleCollection,
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Indicadores cognitivos',
                    subtitle: _isCollecting
                        ? 'Amostra atualizada às ${_formatTime(_latestData.timestamp)}'
                        : 'Aguardando início da demonstração',
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final columns = availableWidth >= 680 ? 3 : 1;
                      final itemWidth = columns == 1
                          ? availableWidth
                          : (availableWidth - 24) / columns;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _MetricCard(
                              label: 'Atenção',
                              value: _formatValue(_latestData.attention),
                              detail: 'Índice do fabricante '
                                  '(algoritmo proprietário)',
                              progress: (_latestData.attention ?? 0) / 100,
                              icon: Icons.center_focus_strong_outlined,
                              color: const Color(0xFF69A7FF),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _MetricCard(
                              label: 'Meditação',
                              value: _formatValue(_latestData.meditation),
                              detail: 'Índice do fabricante '
                                  '(algoritmo proprietário)',
                              progress: (_latestData.meditation ?? 0) / 100,
                              icon: Icons.self_improvement_outlined,
                              color: const Color(0xFF62D4B5),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _MetricCard(
                              label: 'Qualidade do sinal',
                              value: _formatValue(_latestData.signalQuality),
                              detail: _signalDescription(_latestData),
                              progress:
                                  (200 - (_latestData.signalQuality ?? 200)) /
                                      200,
                              icon: Icons.sensors_outlined,
                              color: const Color(0xFFF4C56A),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    title: 'Potência relativa por banda',
                    subtitle:
                        'Distribuição comparativa da amostra mais recente',
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < bands.length;
                              index++) ...[
                            _BandRow(
                              band: bands[index],
                              maximum: maximumBandPower,
                            ),
                            if (index < bands.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E2230),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF21465A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: Color(0xFF79C9E8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Os valores exibidos são simulados e destinam-se '
                            'exclusivamente à validação da interface. Este '
                            'aplicativo não realiza diagnóstico clínico.',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFB8CDDA),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
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

  static String _formatTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }

  /// Ausência de dado é exibida como ausência, nunca como zero: um "0" na tela
  /// é indistinguível de uma medida real de valor zero.
  static String _formatValue(int? value) => value?.toString() ?? '—';

  static String _signalDescription(EEGData data) {
    final contato = data.hasContact;
    if (contato == null) {
      return 'Sem leitura de qualidade';
    }
    if (!contato) {
      return 'Sem contato com o sensor';
    }
    if (data.hasGoodSignal ?? false) {
      return 'Sinal adequado para aquisição';
    }
    return 'Recomenda-se ajustar o sensor';
  }
}

class _IntroductionPanel extends StatelessWidget {
  const _IntroductionPanel({
    required this.isCollecting,
    required this.isChangingState,
    required this.onToggle,
  });

  final bool isCollecting;
  final bool isChangingState;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF142747), Color(0xFF102035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF29466D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONITORAMENTO EXPERIMENTAL',
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFF8DBBFF),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Visualização de sinais eletroencefalográficos',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Acompanhe indicadores de atenção, meditação, qualidade '
            'do sinal e potência das bandas de frequência em um fluxo '
            'controlado de dados simulados.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFC2CEE0),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isChangingState ? null : onToggle,
            icon: isChangingState
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(isCollecting
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded),
            label: Text(
              isCollecting ? 'Encerrar demonstração' : 'Iniciar demonstração',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF62D4B5) : const Color(0xFF718096);

    return Semantics(
      label: isActive ? 'Coleta simulada ativa' : 'Coleta simulada inativa',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF111C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF25334A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              isActive ? 'EM EXECUÇÃO' : 'INATIVO',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: const Color(0xFF91A0B5)),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.progress,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final double progress;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFB5C2D4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: normalizedProgress,
                minHeight: 6,
                color: color,
                backgroundColor: const Color(0xFF25334A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF91A0B5),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({required this.band, required this.maximum});

  final _BandData band;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final proportion = ((band.value ?? 0) / maximum).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                band.name,
                style: textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                band.range,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF91A0B5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: proportion,
              minHeight: 8,
              color: const Color(0xFF5B95E8),
              backgroundColor: const Color(0xFF25334A),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 72,
          child: Text(
            _compactNumber(band.value),
            textAlign: TextAlign.end,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFFC8D2E0),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  static String _compactNumber(int? value) {
    if (value == null) {
      return '—';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} k';
    }
    return '$value';
  }
}

class _BandData {
  const _BandData(this.name, this.range, this.value);

  final String name;
  final String range;
  final int? value;
}
