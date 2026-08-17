import 'context_journal_entry.dart';

/// Metadados imutáveis de uma sessão local.
class SessionMetadata {
  const SessionMetadata({
    required this.sessionId,
    required this.startedAt,
    required this.pipelineVersion,
    required this.deviceLabel,
    this.endedAt,
    this.sampleRateHz,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String pipelineVersion;
  final String deviceLabel;
  final int? sampleRateHz;

  SessionMetadata finish(DateTime value) {
    if (value.isBefore(startedAt)) {
      throw ArgumentError.value(value, 'endedAt', 'Anterior ao início.');
    }
    return SessionMetadata(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: value,
      pipelineVersion: pipelineVersion,
      deviceLabel: deviceLabel,
      sampleRateHz: sampleRateHz,
    );
  }

  Map<String, Object?> toJson() {
    final result = <String, Object?>{
      'schemaVersion': 1,
      'sessionId': sessionId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'pipelineVersion': pipelineVersion,
      'deviceLabel': deviceLabel,
    };
    if (endedAt != null) {
      result['endedAt'] = endedAt!.toUtc().toIso8601String();
    }
    if (sampleRateHz != null) result['sampleRateHz'] = sampleRateHz;
    return result;
  }

  factory SessionMetadata.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Versão de metadados não suportada.');
    }
    final endedAt = json['endedAt'];
    return SessionMetadata(
      sessionId: json['sessionId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: endedAt == null ? null : DateTime.parse(endedAt as String),
      pipelineVersion: json['pipelineVersion'] as String,
      deviceLabel: json['deviceLabel'] as String,
      sampleRateHz: (json['sampleRateHz'] as num?)?.toInt(),
    );
  }
}

/// Linha de `epochs.jsonl`.
///
/// Os índices do fabricante são armazenados individualmente e nunca combinados
/// em um escore. [accepted] controla se valores podem ser exibidos.
class SessionEpochRecord {
  SessionEpochRecord({
    required this.sequence,
    required this.capturedAt,
    required this.accepted,
    this.rejectionReason,
    this.signalQuality,
    this.manufacturerAttention,
    this.manufacturerMeditation,
    Map<String, double> features = const <String, double>{},
  }) : features = Map<String, double>.unmodifiable(features) {
    if (!accepted &&
        (rejectionReason == null || rejectionReason!.trim().isEmpty)) {
      throw ArgumentError('Uma época rejeitada precisa registrar o motivo.');
    }
  }

  final int sequence;
  final DateTime capturedAt;
  final bool accepted;
  final String? rejectionReason;
  final int? signalQuality;
  final int? manufacturerAttention;
  final int? manufacturerMeditation;
  final Map<String, double> features;

  Map<String, Object?> toJson() {
    final result = <String, Object?>{
      'schemaVersion': 1,
      'sequence': sequence,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'accepted': accepted,
    };
    void put(String key, Object? value) {
      if (value != null) result[key] = value;
    }

    put('rejectionReason', rejectionReason);
    put('signalQuality', signalQuality);
    put('manufacturerAttention', manufacturerAttention);
    put('manufacturerMeditation', manufacturerMeditation);
    if (features.isNotEmpty) result['features'] = features;
    return result;
  }

  factory SessionEpochRecord.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Versão de época não suportada.');
    }
    final rawFeatures = json['features'];
    return SessionEpochRecord(
      sequence: (json['sequence'] as num).toInt(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      accepted: json['accepted'] as bool,
      rejectionReason: json['rejectionReason'] as String?,
      signalQuality: (json['signalQuality'] as num?)?.toInt(),
      manufacturerAttention: (json['manufacturerAttention'] as num?)?.toInt(),
      manufacturerMeditation: (json['manufacturerMeditation'] as num?)?.toInt(),
      features: rawFeatures is Map
          ? rawFeatures.map(
              (key, value) =>
                  MapEntry(key as String, (value as num).toDouble()),
            )
          : const <String, double>{},
    );
  }
}

enum SessionEventType { journal }

/// Linha de `events.jsonl`.
class SessionEventRecord {
  const SessionEventRecord({
    required this.type,
    required this.occurredAt,
    required this.payload,
  });

  factory SessionEventRecord.journal(ContextJournalEntry entry) =>
      SessionEventRecord(
        type: SessionEventType.journal,
        occurredAt: entry.recordedAt,
        payload: entry.toJson(),
      );

  final SessionEventType type;
  final DateTime occurredAt;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'type': type.name,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  factory SessionEventRecord.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Versão de evento não suportada.');
    }
    final typeName = json['type'];
    final type = SessionEventType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => throw FormatException('Evento não suportado: $typeName'),
    );
    return SessionEventRecord(
      type: type,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      payload: Map<String, Object?>.from(json['payload'] as Map),
    );
  }

  ContextJournalEntry? get journalEntry => type == SessionEventType.journal
      ? ContextJournalEntry.fromJson(payload)
      : null;
}
