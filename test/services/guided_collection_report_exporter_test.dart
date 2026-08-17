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

  test('inclui o ASRS em seção separada quando ele foi respondido', () {
    final complete = GuidedCollectionReportData(
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      source: data.source,
      qualityScore: data.qualityScore,
      qualityLabel: data.qualityLabel,
      readingCount: data.readingCount,
      attentionMean: data.attentionMean,
      meditationMean: data.meditationMean,
      asrsScore: 18,
      asrsLabel: 'Faixa superior de rastreio',
      asrsGuidance:
          'Suas respostas ficaram na faixa que merece avaliação profissional. Este rastreio não confirma TDAH.',
    );

    final html = exporter.buildHtml(complete);
    final text = exporter.buildText(complete);

    expect(html, contains('18 de 24'));
    expect(html, contains('separado dos dados do BrainLink'));
    expect(text, contains('Pontuação: 18/24'));
    expect(text, contains('não confirma TDAH'));
    expect(text, contains('ASRS_v1.1_screener%286Q%29_scoring_update.pdf'));
  });
}
