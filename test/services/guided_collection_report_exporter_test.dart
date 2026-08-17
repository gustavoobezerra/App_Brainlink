import 'dart:io';

import 'package:brainlink_app/services/guided_collection_report_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const exporter = GuidedCollectionReportExporter();
  final data = GuidedCollectionReportData(
    startedAt: DateTime.utc(2026, 8, 17, 20),
    endedAt: DateTime.utc(2026, 8, 17, 20, 2),
    source: 'BrainLink Lite',
    qualityScore: 86,
    qualityLabel: 'Coleta boa',
    readingCount: 120,
    attentionMean: 61.5,
    meditationMean: 57,
  );

  test('relatório destaca qualidade da coleta e o limite do resultado', () {
    final html = exporter.buildHtml(data);
    final text = exporter.buildText(data);

    expect(html, contains('86'));
    expect(html, contains('Coleta boa'));
    expect(text, contains('Qualidade da coleta: 86/100'));
    expect(text, contains('não avaliam saúde, TDAH ou capacidade da pessoa'));
    expect(text.toLowerCase(), isNot(contains('diário')));
    expect(text, isNot(contains('ASRS')));
  });

  test('exporta HTML e TXT no diretório solicitado', () async {
    final directory =
        await Directory.systemTemp.createTemp('brainlink_guided_');
    addTearDown(() => directory.delete(recursive: true));

    final files = await exporter.export(data, directory);

    expect(files, hasLength(2));
    expect(files.every((file) => file.existsSync()), isTrue);
    expect(files.first.path, endsWith('.html'));
    expect(files.last.path, endsWith('.txt'));
  });
}
