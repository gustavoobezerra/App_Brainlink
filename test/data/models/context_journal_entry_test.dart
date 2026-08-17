import 'package:brainlink_app/data/models/context_journal_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registra sono, medicação, humor e tarefa com ida e volta JSON', () {
    final original = ContextJournalEntry(
      id: 'journal-1',
      recordedAt: DateTime.utc(2026, 8, 17, 10),
      sleepHours: 7.5,
      medicationTaken: true,
      medicationNote: '  conforme prescrição  ',
      moodLevel: 4,
      task: '  leitura  ',
      notes: 'sem interrupções',
    );

    final restored = ContextJournalEntry.fromJson(original.toJson());
    expect(restored.sleepHours, 7.5);
    expect(restored.medicationTaken, isTrue);
    expect(restored.medicationNote, 'conforme prescrição');
    expect(restored.moodLevel, 4);
    expect(restored.task, 'leitura');
    expect(restored.isEmpty, isFalse);
  });

  test('campos ausentes continuam ausentes', () {
    final entry = ContextJournalEntry(
      id: 'empty',
      recordedAt: DateTime.utc(2026),
    );
    expect(entry.isEmpty, isTrue);
    expect(entry.toJson().containsKey('sleepHours'), isFalse);
    expect(entry.toJson().containsKey('moodLevel'), isFalse);
  });

  test('valida limites humanos de sono e escala de humor', () {
    expect(
      () => ContextJournalEntry(
        id: 'bad-sleep',
        recordedAt: DateTime.utc(2026),
        sleepHours: 25,
      ),
      throwsArgumentError,
    );
    expect(
      () => ContextJournalEntry(
        id: 'bad-mood',
        recordedAt: DateTime.utc(2026),
        moodLevel: 0,
      ),
      throwsArgumentError,
    );
  });
}
