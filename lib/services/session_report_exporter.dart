import 'dart:io';

import '../data/models/asrs_screener_6.dart';
import '../data/models/context_journal_entry.dart';
import '../data/models/session_record.dart';

/// Dados necessários para gerar uma representação humana da sessão.
class SessionReportData {
  const SessionReportData({
    required this.metadata,
    required this.epochs,
    this.journalEntries = const <ContextJournalEntry>[],
    this.questionnaire,
  });

  final SessionMetadata metadata;
  final List<SessionEpochRecord> epochs;
  final List<ContextJournalEntry> journalEntries;
  final AsrsScreenerResult? questionnaire;
}

/// Gera relatórios autocontidos, imprimíveis e sem dependências externas.
///
/// A geração é pura; [export] grava os arquivos somente quando a camada de UI
/// solicitar explicitamente a exportação.
class SessionReportExporter {
  const SessionReportExporter();

  String buildHtml(SessionReportData data) {
    final accepted = data.epochs.where((epoch) => epoch.accepted).toList();
    final attention = accepted
        .where((epoch) => epoch.manufacturerAttention != null)
        .map((epoch) => epoch.manufacturerAttention!)
        .toList();
    final meditation = accepted
        .where((epoch) => epoch.manufacturerMeditation != null)
        .map((epoch) => epoch.manufacturerMeditation!)
        .toList();

    return '''<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Registro de sessão BrainLink</title>
  <style>
    :root { color-scheme: light; --ink:#172033; --muted:#5f6b7a; --line:#dbe2ea; --accent:#315f8c; }
    * { box-sizing: border-box; }
    body { margin:0; color:var(--ink); background:#eef2f6; font:15px/1.5 system-ui,-apple-system,sans-serif; }
    main { width:min(920px,calc(100% - 32px)); margin:32px auto; background:#fff; padding:42px; border-radius:14px; box-shadow:0 8px 30px #14233a18; }
    h1,h2 { line-height:1.2; } h1 { margin:0; font-size:28px; } h2 { margin-top:34px; font-size:19px; border-bottom:1px solid var(--line); padding-bottom:8px; }
    .eyebrow { color:var(--accent); font-weight:700; letter-spacing:.08em; text-transform:uppercase; font-size:12px; }
    .notice { margin:24px 0; padding:15px 18px; border-left:4px solid var(--accent); background:#f3f7fb; }
    .grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px 24px; }
    .label { color:var(--muted); font-size:12px; } .value { font-weight:650; }
    table { width:100%; border-collapse:collapse; } th,td { text-align:left; vertical-align:top; padding:9px 7px; border-bottom:1px solid var(--line); } th { color:var(--muted); font-size:12px; }
    .chart { width:100%; height:auto; border:1px solid var(--line); border-radius:8px; background:#fbfcfe; }
    .foot { color:var(--muted); font-size:12px; margin-top:34px; }
    @media print { body { background:#fff; } main { width:100%; margin:0; padding:18mm; box-shadow:none; } }
    @media (max-width:600px) { main { padding:24px; } .grid { grid-template-columns:1fr; } }
  </style>
</head>
<body><main>
  <div class="eyebrow">Registro para levar à consulta</div>
  <h1>Relatório de observação BrainLink</h1>
  <p class="notice">Informações descritivas do próprio usuário. Este relatório não substitui uma avaliação profissional.</p>
  <section>
    <h2>Sessão</h2>
    <div class="grid">
      ${_fact('Identificador', data.metadata.sessionId)}
      ${_fact('Início', _formatDateTime(data.metadata.startedAt))}
      ${_fact('Término', data.metadata.endedAt == null ? 'Em aberto' : _formatDateTime(data.metadata.endedAt!))}
      ${_fact('Dispositivo', data.metadata.deviceLabel)}
      ${_fact('Versão do pipeline', data.metadata.pipelineVersion)}
      ${_fact('Épocas aproveitadas', '${accepted.length} de ${data.epochs.length}')}
    </div>
  </section>
  ${_questionnaireHtml(data.questionnaire)}
  ${_contextHtml(data.journalEntries)}
  <section>
    <h2>Índices do fabricante (algoritmo proprietário)</h2>
    <p>Valores registrados ao longo desta sessão, sem comparação com outras pessoas.</p>
    ${attention.isEmpty ? '<p>Dados indisponíveis para exibição.</p>' : '''
      <div class="grid">
        ${_fact('Atenção — média descritiva', _average(attention))}
        ${_fact('Meditação — média descritiva', meditation.isEmpty ? 'Sem dado' : _average(meditation))}
      </div>
      <h3>Tendência durante a sessão</h3>
      ${_attentionChart(attention)}
    '''}
  </section>
  <p class="foot">${_escape(AsrsScreener6.attribution)}<br>Fonte: ${_escape(AsrsScreener6.officialSource)}</p>
</main></body></html>''';
  }

  String buildText(SessionReportData data) {
    final buffer = StringBuffer()
      ..writeln('RELATÓRIO DE OBSERVAÇÃO BRAINLINK')
      ..writeln('Registro para levar à consulta')
      ..writeln()
      ..writeln('Informações descritivas do próprio usuário. Este relatório '
          'não substitui uma avaliação profissional.')
      ..writeln()
      ..writeln('SESSÃO')
      ..writeln('Identificador: ${data.metadata.sessionId}')
      ..writeln('Início: ${_formatDateTime(data.metadata.startedAt)}')
      ..writeln(
          'Término: ${data.metadata.endedAt == null ? 'Em aberto' : _formatDateTime(data.metadata.endedAt!)}')
      ..writeln('Dispositivo: ${data.metadata.deviceLabel}')
      ..writeln('Versão do pipeline: ${data.metadata.pipelineVersion}')
      ..writeln('Epocas aproveitadas: '
          '${data.epochs.where((epoch) => epoch.accepted).length} de '
          '${data.epochs.length}');

    final questionnaire = data.questionnaire;
    if (questionnaire != null) {
      buffer
        ..writeln()
        ..writeln('RASTREIO ASRS V1.1 — 6 PERGUNTAS')
        ..writeln('Pontuação de rastreio: ${questionnaire.score} de 6')
        ..writeln(questionnaire.guidance)
        ..writeln(AsrsScreener6.scopeNotice);
    }

    if (data.journalEntries.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('DIÁRIO DE CONTEXTO');
      for (final entry in data.journalEntries) {
        buffer.writeln(_contextText(entry));
      }
    }

    final accepted = data.epochs.where((epoch) => epoch.accepted);
    final attention = accepted
        .where((epoch) => epoch.manufacturerAttention != null)
        .map((epoch) => epoch.manufacturerAttention!)
        .toList();
    final meditation = accepted
        .where((epoch) => epoch.manufacturerMeditation != null)
        .map((epoch) => epoch.manufacturerMeditation!)
        .toList();
    buffer
      ..writeln()
      ..writeln('ÍNDICES DO FABRICANTE (ALGORITMO PROPRIETÁRIO)');
    if (attention.isEmpty) {
      buffer.writeln('Dados indisponíveis para exibição.');
    } else {
      buffer.writeln('Atenção — média descritiva: ${_average(attention)}');
      buffer.writeln('Meditação — média descritiva: '
          '${meditation.isEmpty ? 'Sem dado' : _average(meditation)}');
    }
    buffer
      ..writeln()
      ..writeln(AsrsScreener6.attribution)
      ..writeln('Fonte: ${AsrsScreener6.officialSource}');
    return buffer.toString();
  }

  Future<List<File>> export(
    SessionReportData data,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    final base = 'brainlink_${_safeFileName(data.metadata.sessionId)}';
    final html = File('${destination.path}${Platform.pathSeparator}$base.html');
    final text = File('${destination.path}${Platform.pathSeparator}$base.txt');
    await html.writeAsString(buildHtml(data), flush: true);
    await text.writeAsString(buildText(data), flush: true);
    return <File>[html, text];
  }

  static String _questionnaireHtml(AsrsScreenerResult? result) {
    if (result == null) return '';
    final rows = <String>[];
    for (var index = 0; index < result.responses.length; index++) {
      rows.add(
          '<tr><td>${index + 1}</td><td>${_escape(AsrsScreener6.items[index].text)}</td>'
          '<td>${_escape(result.responses[index].label)}</td></tr>');
    }
    return '''<section>
      <h2>Rastreio ASRS v1.1 — 6 perguntas</h2>
      <p><span class="label">Pontuação de rastreio</span><br><span class="value">${result.score} de 6</span></p>
      <p>${_escape(result.guidance)}</p>
      <p>${_escape(AsrsScreener6.scopeNotice)}</p>
      <table><thead><tr><th>#</th><th>Pergunta</th><th>Resposta</th></tr></thead><tbody>${rows.join()}</tbody></table>
    </section>''';
  }

  static String _contextHtml(List<ContextJournalEntry> entries) {
    if (entries.isEmpty) return '';
    final rows = entries.map((entry) => '''<tr>
      <td>${_escape(_formatDateTime(entry.recordedAt))}</td>
      <td>${entry.sleepHours?.toStringAsFixed(1) ?? '—'}</td>
      <td>${_medication(entry.medicationTaken)}</td>
      <td>${entry.moodLevel ?? '—'}</td>
      <td>${_escape(_orDash(entry.task))}</td>
      <td>${_escape(_orDash(entry.notes))}</td>
    </tr>''').join();
    return '''<section><h2>Diário de contexto</h2>
      <table><thead><tr><th>Momento</th><th>Sono (h)</th><th>Medicação</th><th>Humor (1–5)</th><th>Tarefa</th><th>Observações</th></tr></thead><tbody>$rows</tbody></table>
    </section>''';
  }

  static String _attentionChart(List<int> values) {
    const width = 700.0;
    const height = 180.0;
    const padding = 24.0;
    final usableWidth = width - padding * 2;
    final usableHeight = height - padding * 2;
    final points = <String>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? width / 2
          : padding + (index / (values.length - 1)) * usableWidth;
      final y = padding + (1 - values[index] / 100) * usableHeight;
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return '''<svg class="chart" viewBox="0 0 700 180" role="img" aria-label="Tendência do índice de atenção do fabricante durante a sessão">
      <line x1="24" y1="24" x2="24" y2="156" stroke="#c8d1dc"/><line x1="24" y1="156" x2="676" y2="156" stroke="#c8d1dc"/>
      <polyline fill="none" stroke="#315f8c" stroke-width="3" stroke-linejoin="round" points="${points.join(' ')}"/>
    </svg>''';
  }

  static String _fact(String label, String value) =>
      '<div><div class="label">${_escape(label)}</div><div class="value">${_escape(value)}</div></div>';

  static String _average(List<int> values) =>
      (values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1);

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _contextText(ContextJournalEntry entry) {
    return '${_formatDateTime(entry.recordedAt)} | sono: '
        '${entry.sleepHours?.toStringAsFixed(1) ?? '—'} h | medicação: '
        '${_medication(entry.medicationTaken)} | humor: '
        '${entry.moodLevel ?? '—'}/5 | tarefa: ${_orDash(entry.task)} | '
        'observações: ${_orDash(entry.notes)}';
  }

  static String _medication(bool? value) =>
      value == null ? '—' : (value ? 'Registrada' : 'Não registrada');
  static String _orDash(String? value) =>
      value == null || value.trim().isEmpty ? '—' : value.trim();
  static String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
