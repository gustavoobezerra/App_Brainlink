import 'dart:io';

/// Resultado simples de uma coleta guiada do BrainLink.
class GuidedCollectionReportData {
  const GuidedCollectionReportData({
    required this.startedAt,
    required this.endedAt,
    required this.source,
    required this.qualityScore,
    required this.qualityLabel,
    required this.readingCount,
    this.attentionMean,
    this.meditationMean,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final String source;
  final int? qualityScore;
  final String qualityLabel;
  final int readingCount;
  final double? attentionMean;
  final double? meditationMean;
}

/// Exporta a tela final em formatos autocontidos e fáceis de compartilhar.
class GuidedCollectionReportExporter {
  const GuidedCollectionReportExporter();

  String buildHtml(GuidedCollectionReportData data) {
    final score = data.qualityScore;
    final scoreText = score == null ? '—' : score.toString();
    final color = switch (score) {
      null => '#8290a3',
      >= 80 => '#15866f',
      >= 60 => '#b27608',
      _ => '#bf3f4d',
    };
    return '''<!doctype html>
<html lang="pt-BR"><head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Resultado da coleta BrainLink</title>
  <style>
    body{margin:0;background:#edf2f7;color:#162033;font:16px/1.5 system-ui,sans-serif}
    main{width:min(760px,calc(100% - 32px));margin:32px auto;background:white;padding:36px;border-radius:18px}
    h1{margin:0 0 6px}.muted{color:#627086}.score{margin:28px 0;padding:24px;border-radius:16px;background:#f5f8fb;text-align:center}
    .number{font-size:64px;line-height:1;color:$color;font-weight:800}.label{color:$color;font-size:21px;font-weight:750}
    .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.item{padding:16px;border:1px solid #dbe3ec;border-radius:12px}
    .item span{display:block;color:#627086;font-size:13px}.notice{margin-top:26px;padding:15px;border-left:4px solid #315f8c;background:#f0f5fa}
    @media(max-width:560px){main{padding:24px}.grid{grid-template-columns:1fr}}
  </style>
</head><body><main>
  <h1>Resultado da coleta BrainLink</h1>
  <div class="muted">${_escape(_format(data.startedAt))} · ${_escape(data.source)}</div>
  <section class="score"><div class="number">$scoreText</div><div>de 100</div><div class="label">${_escape(data.qualityLabel)}</div></section>
  <div class="grid">
    ${_item('Leituras recebidas', data.readingCount.toString())}
    ${_item('Duração', _duration(data))}
    ${_item('Atenção do aparelho', _number(data.attentionMean))}
    ${_item('Relaxamento do aparelho', _number(data.meditationMean))}
  </div>
  <p class="notice">A nota avalia contato e continuidade do sinal durante a coleta. Os demais valores são índices proprietários do fabricante. Eles não avaliam saúde, TDAH ou capacidade da pessoa.</p>
</main></body></html>''';
  }

  String buildText(GuidedCollectionReportData data) => '''
RESULTADO DA COLETA BRAINLINK

Data: ${_format(data.startedAt)}
Fonte: ${data.source}
Qualidade da coleta: ${data.qualityScore?.toString() ?? '—'}/100 — ${data.qualityLabel}
Leituras recebidas: ${data.readingCount}
Duração: ${_duration(data)}
Atenção do aparelho: ${_number(data.attentionMean)}
Relaxamento do aparelho: ${_number(data.meditationMean)}

A nota avalia contato e continuidade do sinal durante a coleta. Os demais valores são índices proprietários do fabricante. Eles não avaliam saúde, TDAH ou capacidade da pessoa.
''';

  Future<List<File>> export(
    GuidedCollectionReportData data,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    final stamp = data.startedAt.toUtc().toIso8601String().replaceAll(':', '-');
    final html = File(
      '${destination.path}${Platform.pathSeparator}brainlink_$stamp.html',
    );
    final text = File(
      '${destination.path}${Platform.pathSeparator}brainlink_$stamp.txt',
    );
    await html.writeAsString(buildHtml(data), flush: true);
    await text.writeAsString(buildText(data), flush: true);
    return [html, text];
  }

  static String _item(String label, String value) =>
      '<div class="item"><span>${_escape(label)}</span><strong>${_escape(value)}</strong></div>';

  static String _number(double? value) =>
      value == null ? 'Sem dado' : value.toStringAsFixed(1);

  static String _duration(GuidedCollectionReportData data) {
    final seconds = data.endedAt.difference(data.startedAt).inSeconds;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}min ${remaining.toString().padLeft(2, '0')}s';
  }

  static String _format(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
