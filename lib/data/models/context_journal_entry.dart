/// Registro contextual preenchido pelo próprio usuário.
///
/// Os valores servem para observar o próprio histórico. O modelo não produz
/// conclusões a partir de sono, medicação, humor ou tarefa.
class ContextJournalEntry {
  ContextJournalEntry({
    required this.id,
    required this.recordedAt,
    this.sleepHours,
    this.medicationTaken,
    this.medicationNote,
    this.moodLevel,
    this.task,
    this.notes,
  }) {
    if (sleepHours != null && (sleepHours! < 0 || sleepHours! > 24)) {
      throw ArgumentError.value(
        sleepHours,
        'sleepHours',
        'Informe um valor entre 0 e 24 horas.',
      );
    }
    if (moodLevel != null && (moodLevel! < 1 || moodLevel! > 5)) {
      throw ArgumentError.value(
        moodLevel,
        'moodLevel',
        'Informe um valor entre 1 e 5.',
      );
    }
  }

  final String id;
  final DateTime recordedAt;
  final double? sleepHours;
  final bool? medicationTaken;
  final String? medicationNote;

  /// Autoavaliação de humor de 1 a 5, sem interpretação automática.
  final int? moodLevel;
  final String? task;
  final String? notes;

  bool get isEmpty =>
      sleepHours == null &&
      medicationTaken == null &&
      _blank(medicationNote) &&
      moodLevel == null &&
      _blank(task) &&
      _blank(notes);

  Map<String, Object?> toJson() {
    final result = <String, Object?>{
      'schemaVersion': 1,
      'id': id,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
    void put(String key, Object? value) {
      if (value != null && (value is! String || value.trim().isNotEmpty)) {
        result[key] = value is String ? value.trim() : value;
      }
    }

    put('sleepHours', sleepHours);
    put('medicationTaken', medicationTaken);
    put('medicationNote', medicationNote);
    put('moodLevel', moodLevel);
    put('task', task);
    put('notes', notes);
    return result;
  }

  factory ContextJournalEntry.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Versão de diário não suportada.');
    }
    return ContextJournalEntry(
      id: json['id'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      medicationTaken: json['medicationTaken'] as bool?,
      medicationNote: json['medicationNote'] as String?,
      moodLevel: (json['moodLevel'] as num?)?.toInt(),
      task: json['task'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static bool _blank(String? value) => value == null || value.trim().isEmpty;
}
