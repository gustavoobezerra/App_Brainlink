import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../data/models/asrs_screener_6.dart';
import '../data/models/session_record.dart';

/// Conteúdo de uma sessão carregado do armazenamento local.
class StoredSession {
  const StoredSession({
    required this.metadata,
    required this.epochs,
    required this.events,
  });

  final SessionMetadata metadata;
  final List<SessionEpochRecord> epochs;
  final List<SessionEventRecord> events;
}

/// Persistência local append-only definida pelo ADR-003.
///
/// A raiz é injetada para manter a classe testável e independente de plugins.
/// No Android, a integração fornece o diretório privado retornado pela ponte
/// nativa. Nenhuma operação de rede é realizada por este serviço.
class LocalSessionStore {
  LocalSessionStore(this.rootDirectory);

  final Directory rootDirectory;

  Directory get _sessionsDirectory => Directory(_join('sessions'));
  Directory get _questionnairesDirectory => Directory(_join('questionnaires'));

  Future<SessionMetadata> createSession({
    required String sessionId,
    required DateTime startedAt,
    required String pipelineVersion,
    required String deviceLabel,
    int? sampleRateHz,
  }) async {
    _validateIdentifier(sessionId, 'sessionId');
    if (pipelineVersion.trim().isEmpty) {
      throw ArgumentError.value(
        pipelineVersion,
        'pipelineVersion',
        'A versão do pipeline é obrigatória.',
      );
    }

    final sessionDirectory = _sessionDirectory(sessionId);
    if (await sessionDirectory.exists()) {
      throw StateError('A sessão $sessionId já existe.');
    }
    await sessionDirectory.create(recursive: true);

    final metadata = SessionMetadata(
      sessionId: sessionId,
      startedAt: startedAt,
      pipelineVersion: pipelineVersion.trim(),
      deviceLabel: deviceLabel.trim(),
      sampleRateHz: sampleRateHz,
    );
    await _writeJson(_metadataFile(sessionId), metadata.toJson());
    await _epochsFile(sessionId).create();
    await _eventsFile(sessionId).create();
    return metadata;
  }

  Future<void> appendEpoch(
    String sessionId,
    SessionEpochRecord epoch,
  ) async {
    await _ensureSessionExists(sessionId);
    await _appendJsonLine(_epochsFile(sessionId), epoch.toJson());
  }

  Future<void> appendEvent(
    String sessionId,
    SessionEventRecord event,
  ) async {
    await _ensureSessionExists(sessionId);
    await _appendJsonLine(_eventsFile(sessionId), event.toJson());
  }

  /// Acrescenta dados crus como Int16 little-endian, se a coleta optar por
  /// retê-los. A chamada é deliberadamente separada: o arquivo não é criado
  /// como efeito colateral de [createSession].
  Future<void> appendRawInt16(String sessionId, Iterable<int> samples) async {
    await _ensureSessionExists(sessionId);
    final values = List<int>.of(samples);
    final bytes = ByteData(values.length * 2);
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value < -32768 || value > 32767) {
        throw RangeError.range(value, -32768, 32767, 'samples[$index]');
      }
      bytes.setInt16(index * 2, value, Endian.little);
    }
    final file = File(_join('sessions', sessionId, 'raw.bin'));
    await file.writeAsBytes(
      bytes.buffer.asUint8List(),
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<SessionMetadata> finishSession(
    String sessionId,
    DateTime endedAt,
  ) async {
    final current = await readMetadata(sessionId);
    final finished = current.finish(endedAt);
    await _writeJson(_metadataFile(sessionId), finished.toJson());
    return finished;
  }

  Future<void> saveQuestionnaire(AsrsScreenerResult result) async {
    _validateIdentifier(result.id, 'questionnaire.id');
    await _questionnairesDirectory.create(recursive: true);
    final file = File(_join('questionnaires', '${result.id}.json'));
    await _writeJson(file, result.toJson());
  }

  Future<AsrsScreenerResult> readQuestionnaire(String id) async {
    _validateIdentifier(id, 'questionnaire.id');
    final file = File(_join('questionnaires', '$id.json'));
    return AsrsScreenerResult.fromJson(await _readJson(file));
  }

  Future<SessionMetadata> readMetadata(String sessionId) async {
    _validateIdentifier(sessionId, 'sessionId');
    return SessionMetadata.fromJson(await _readJson(_metadataFile(sessionId)));
  }

  Future<StoredSession> readSession(String sessionId) async {
    final metadata = await readMetadata(sessionId);
    final epochs = await _readJsonLines(
      _epochsFile(sessionId),
      SessionEpochRecord.fromJson,
    );
    final events = await _readJsonLines(
      _eventsFile(sessionId),
      SessionEventRecord.fromJson,
    );
    return StoredSession(
      metadata: metadata,
      epochs: List<SessionEpochRecord>.unmodifiable(epochs),
      events: List<SessionEventRecord>.unmodifiable(events),
    );
  }

  Future<List<SessionMetadata>> listSessions() async {
    if (!await _sessionsDirectory.exists()) return const <SessionMetadata>[];
    final sessions = <SessionMetadata>[];
    await for (final entry in _sessionsDirectory.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id =
          entry.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
      try {
        sessions.add(await readMetadata(id));
      } on FileSystemException {
        // Um diretório incompleto não esconde as sessões válidas restantes.
      } on FormatException {
        // Metadado corrompido é ignorado na listagem, mas continua no disco para
        // inspeção/auditoria.
      }
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List<SessionMetadata>.unmodifiable(sessions);
  }

  Directory _sessionDirectory(String sessionId) {
    _validateIdentifier(sessionId, 'sessionId');
    return Directory(_join('sessions', sessionId));
  }

  File _metadataFile(String sessionId) =>
      File(_join('sessions', sessionId, 'meta.json'));
  File _epochsFile(String sessionId) =>
      File(_join('sessions', sessionId, 'epochs.jsonl'));
  File _eventsFile(String sessionId) =>
      File(_join('sessions', sessionId, 'events.jsonl'));

  Future<void> _ensureSessionExists(String sessionId) async {
    if (!await _metadataFile(sessionId).exists()) {
      throw StateError('Sessão $sessionId inexistente.');
    }
  }

  Future<void> _writeJson(File file, Map<String, Object?> value) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(value)}\n', flush: true);
  }

  Future<Map<String, Object?>> _readJson(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw FormatException('Objeto JSON esperado em ${file.path}.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<void> _appendJsonLine(
    File file,
    Map<String, Object?> value,
  ) async {
    await file.writeAsString(
      '${jsonEncode(value)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<T>> _readJsonLines<T>(
    File file,
    T Function(Map<String, Object?>) decode,
  ) async {
    if (!await file.exists()) return <T>[];
    final result = <T>[];
    var lineNumber = 0;
    await for (final line in file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      lineNumber++;
      if (line.trim().isEmpty) continue;
      try {
        final value = jsonDecode(line);
        if (value is! Map) throw const FormatException('Objeto esperado.');
        result.add(decode(Map<String, Object?>.from(value)));
      } on Object catch (error) {
        throw FormatException(
          'Linha $lineNumber inválida em ${file.path}: $error',
        );
      }
    }
    return result;
  }

  String _join(String first, [String? second, String? third]) {
    final parts = <String>[rootDirectory.path, first];
    if (second != null) parts.add(second);
    if (third != null) parts.add(third);
    return parts.join(Platform.pathSeparator);
  }

  static void _validateIdentifier(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        name,
        'Use apenas letras, números, hífen e sublinhado.',
      );
    }
  }
}
