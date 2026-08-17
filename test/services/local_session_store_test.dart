import 'dart:convert';
import 'dart:io';

import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:brainlink_app/data/models/context_journal_entry.dart';
import 'package:brainlink_app/data/models/session_record.dart';
import 'package:brainlink_app/services/local_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late LocalSessionStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('brainlink_store_test_');
    store = LocalSessionStore(root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('cria layout ADR-003 e exige versão do pipeline', () async {
    await store.createSession(
      sessionId: 'session-001',
      startedAt: DateTime.utc(2026, 8, 17),
      pipelineVersion: 'a1-1.0.0',
      deviceLabel: 'BrainLink Lite',
      sampleRateHz: 128,
    );

    final sessionDir = Directory('${root.path}/sessions/session-001');
    expect(File('${sessionDir.path}/meta.json').existsSync(), isTrue);
    expect(File('${sessionDir.path}/epochs.jsonl').existsSync(), isTrue);
    expect(File('${sessionDir.path}/events.jsonl').existsSync(), isTrue);
    final meta =
        jsonDecode(File('${sessionDir.path}/meta.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(meta['pipelineVersion'], 'a1-1.0.0');
    expect(
      () => store.createSession(
        sessionId: 'session-002',
        startedAt: DateTime.utc(2026),
        pipelineVersion: ' ',
        deviceLabel: 'BrainLink Lite',
      ),
      throwsArgumentError,
    );
  });

  test('acrescenta épocas e eventos em uma linha JSON por registro', () async {
    await store.createSession(
      sessionId: 's1',
      startedAt: DateTime.utc(2026, 8, 17, 10),
      pipelineVersion: 'pipeline-7',
      deviceLabel: 'BrainLink Lite',
    );
    await store.appendEpoch(
      's1',
      SessionEpochRecord(
        sequence: 0,
        capturedAt: DateTime.utc(2026, 8, 17, 10, 0, 1),
        accepted: true,
        signalQuality: 0,
        manufacturerAttention: 42,
      ),
    );
    final journal = ContextJournalEntry(
      id: 'j1',
      recordedAt: DateTime.utc(2026, 8, 17, 10),
      sleepHours: 8,
      moodLevel: 3,
      task: 'Leitura',
    );
    await store.appendEvent('s1', SessionEventRecord.journal(journal));

    final epochsLines = File('${root.path}/sessions/s1/epochs.jsonl')
        .readAsLinesSync()
        .where((line) => line.isNotEmpty);
    final eventsLines = File('${root.path}/sessions/s1/events.jsonl')
        .readAsLinesSync()
        .where((line) => line.isNotEmpty);
    expect(epochsLines, hasLength(1));
    expect(eventsLines, hasLength(1));

    final restored = await store.readSession('s1');
    expect(restored.metadata.pipelineVersion, 'pipeline-7');
    expect(restored.epochs.single.manufacturerAttention, 42);
    expect(restored.events.single.journalEntry?.task, 'Leitura');
  });

  test('registra término e lista sessões da mais recente para a mais antiga',
      () async {
    for (final entry in <(String, DateTime)>[
      ('old', DateTime.utc(2026, 1, 1)),
      ('new', DateTime.utc(2026, 2, 1)),
    ]) {
      await store.createSession(
        sessionId: entry.$1,
        startedAt: entry.$2,
        pipelineVersion: '1',
        deviceLabel: 'BrainLink Lite',
      );
    }
    final finished =
        await store.finishSession('new', DateTime.utc(2026, 2, 1, 0, 5));
    expect(finished.endedAt, isNotNull);
    expect((await store.listSessions()).map((item) => item.sessionId),
        <String>['new', 'old']);
  });

  test('questionário fica fora da pasta da sessão e preserva pontuação',
      () async {
    final result = AsrsScreenerResult(
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
    await store.saveQuestionnaire(result);

    expect(File('${root.path}/questionnaires/q1.json').existsSync(), isTrue);
    expect((await store.readQuestionnaire('q1')).score, 4);
  });

  test('raw opcional usa Int16 little-endian e valida faixa', () async {
    await store.createSession(
      sessionId: 'raw',
      startedAt: DateTime.utc(2026),
      pipelineVersion: '1',
      deviceLabel: 'BrainLink Lite',
    );
    await store.appendRawInt16('raw', <int>[1, -2]);
    expect(
      File('${root.path}/sessions/raw/raw.bin').readAsBytesSync(),
      <int>[1, 0, 254, 255],
    );
    expect(() => store.appendRawInt16('raw', <int>[40000]), throwsRangeError);
  });

  test('identificador não permite sair da raiz local', () {
    expect(
      () => store.createSession(
        sessionId: '../fora',
        startedAt: DateTime.utc(2026),
        pipelineVersion: '1',
        deviceLabel: 'BrainLink Lite',
      ),
      throwsArgumentError,
    );
  });
}
