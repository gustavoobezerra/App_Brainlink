import 'dart:io';

import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:brainlink_app/data/models/context_journal_entry.dart';
import 'package:brainlink_app/data/models/session_record.dart';
import 'package:brainlink_app/services/session_report_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final metadata = SessionMetadata(
    sessionId: 'demo-1',
    startedAt: DateTime.utc(2026, 8, 17, 13),
    endedAt: DateTime.utc(2026, 8, 17, 13, 5),
    pipelineVersion: 'a1-1.0.0',
    deviceLabel: 'BrainLink Lite',
  );

  final questionnaire = AsrsScreenerResult(
    id: 'q1',
    completedAt: DateTime.utc(2026, 8, 17),
    responses: const <AsrsResponse>[
      AsrsResponse.sometimes,
      AsrsResponse.sometimes,
      AsrsResponse.sometimes,
      AsrsResponse.often,
      AsrsResponse.never,
      AsrsResponse.never,
    ],
  );

  test('HTML autocontido separa rastreio de índices proprietários', () {
    final data = SessionReportData(
      metadata: metadata,
      questionnaire: questionnaire,
      journalEntries: <ContextJournalEntry>[
        ContextJournalEntry(
          id: 'j1',
          recordedAt: DateTime.utc(2026, 8, 17, 13),
          sleepHours: 7.5,
          medicationTaken: true,
          moodLevel: 3,
          task: '<leitura & escrita>',
        ),
      ],
      epochs: <SessionEpochRecord>[
        SessionEpochRecord(
          sequence: 0,
          capturedAt: DateTime.utc(2026, 8, 17, 13, 0, 1),
          accepted: true,
          manufacturerAttention: 40,
          manufacturerMeditation: 50,
        ),
        SessionEpochRecord(
          sequence: 1,
          capturedAt: DateTime.utc(2026, 8, 17, 13, 0, 2),
          accepted: true,
          manufacturerAttention: 60,
          manufacturerMeditation: 70,
        ),
      ],
    );

    const exporter = SessionReportExporter();
    final html = exporter.buildHtml(data);
    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('<svg'));
    expect(html, contains('Pontuação de rastreio'));
    expect(html, contains('Sua pontuação merece atenção.'));
    expect(html, contains('Índices do fabricante (algoritmo proprietário)'));
    expect(html, contains('50.0'));
    expect(html, contains('&lt;leitura &amp; escrita&gt;'));
    expect(html, isNot(contains('<script')));
  });

  test('época rejeitada não expõe o número', () {
    final html = const SessionReportExporter().buildHtml(
      SessionReportData(
        metadata: metadata,
        epochs: <SessionEpochRecord>[
          SessionEpochRecord(
            sequence: 0,
            capturedAt: DateTime.utc(2026),
            accepted: false,
            rejectionReason: 'Contato insuficiente',
            manufacturerAttention: 99,
          ),
        ],
      ),
    );

    expect(html, contains('Dados indisponíveis para exibição.'));
    expect(html, isNot(contains('99')));
  });

  test('exporta HTML e TXT somente quando solicitado', () async {
    final destination =
        await Directory.systemTemp.createTemp('brainlink_report_');
    addTearDown(() async => destination.delete(recursive: true));
    const exporter = SessionReportExporter();
    final files = await exporter.export(
      SessionReportData(
        metadata: metadata,
        epochs: const <SessionEpochRecord>[],
        questionnaire: questionnaire,
      ),
      destination,
    );

    expect(files.map((file) => file.path), contains(endsWith('.html')));
    expect(files.map((file) => file.path), contains(endsWith('.txt')));
    expect(await files.first.readAsString(), contains('a1-1.0.0'));
  });
}
