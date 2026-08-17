import 'dart:io';

import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:brainlink_app/services/eeg_spectrum_analyzer.dart';
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
      spectrum: const EegSpectrumAnalysis(
        eyesOpen: EegPhaseSpectrum(
          acceptedEpochs: 22,
          rejectedEpochs: 2,
          bands: EegBandPowers(
            delta: 10,
            theta: 34,
            alpha: 38,
            beta: 18,
          ),
          absoluteBands: EegBandPowers(
            delta: 10,
            theta: 34,
            alpha: 20,
            beta: 18,
          ),
          spectrum: [],
        ),
        eyesClosed: EegPhaseSpectrum(
          acceptedEpochs: 23,
          rejectedEpochs: 1,
          bands: EegBandPowers(
            delta: 8,
            theta: 24,
            alpha: 58,
            beta: 10,
          ),
          absoluteBands: EegBandPowers(
            delta: 8,
            theta: 24,
            alpha: 35,
            beta: 10,
          ),
          spectrum: [],
        ),
        minimumEpochsPerPhase: 20,
      ),
      asrsScore: 18,
      asrsLabel: 'Possibilidade aumentada no ASRS',
      asrsBandLabel: 'Faixa superior de rastreio',
      asrsGuidance:
          'As respostas atingiram o ponto de corte e apontam possibilidade aumentada de TDAH neste rastreio. Este resultado não é diagnóstico.',
      asrsAnswers: [
        for (final question in AsrsScreener6.questions)
          GuidedAsrsAnswer(
            question: question,
            response: 'Frequentemente',
            points: 3,
          ),
      ],
    );

    final html = exporter.buildHtml(complete);
    final text = exporter.buildText(complete);

    expect(html, contains('18 de 24'));
    expect(html, contains('registrados no mesmo relatório'));
    expect(html, contains('Possibilidade aumentada no ASRS'));
    expect(html, contains('NÃO É DIAGNÓSTICO'));
    expect(html, contains('Ondas observadas nesta coleta'));
    expect(html, contains('Olhos fechados'));
    expect(html, contains('58.0%'));
    expect(html, contains('Respostas registradas junto com o EEG'));
    expect(html, contains(AsrsScreener6.questions.first));
    expect(html, contains(AsrsScreener6.questions.last));
    expect(RegExp('<li>').allMatches(html), hasLength(6));
    expect(html, contains('Frequentemente — 3 pontos'));
    expect(html, contains('Resumo para levar ao médico'));
    expect(text, contains('Pontuação: 18/24'));
    expect(text, contains('possibilidade aumentada de TDAH'));
    expect(text, contains('não é diagnóstico'));
    expect(text, isNot(contains('NÃO ENTRA NO RASTREIO DE TDAH')));
    expect(text, contains('Pipeline: spectrum-v1.0.0'));
    expect(text, contains('RESPOSTAS REGISTRADAS JUNTO COM O EEG'));
    expect(text, contains('corte 14 atingido'));
    expect(text, contains('rastreio justifica procurar um médico'));
    expect(text, contains('ASRS_v1.1_screener%286Q%29_scoring_update.pdf'));
  });

  test('não exporta bandas derivadas quando a sessão é inválida', () {
    const invalidSpectrum = EegSpectrumAnalysis(
      eyesOpen: EegPhaseSpectrum(
        acceptedEpochs: 2,
        rejectedEpochs: 8,
        bands: EegBandPowers(delta: 10, theta: 20, alpha: 50, beta: 20),
        absoluteBands: EegBandPowers.empty(),
        spectrum: [],
      ),
      eyesClosed: EegPhaseSpectrum(
        acceptedEpochs: 1,
        rejectedEpochs: 9,
        bands: EegBandPowers(delta: 8, theta: 22, alpha: 55, beta: 15),
        absoluteBands: EegBandPowers.empty(),
        spectrum: [],
      ),
      minimumEpochsPerPhase: 20,
    );
    final invalid = GuidedCollectionReportData(
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      source: data.source,
      qualityScore: data.qualityScore,
      qualityLabel: data.qualityLabel,
      readingCount: data.readingCount,
      spectrum: invalidSpectrum,
    );

    final html = exporter.buildHtml(invalid);
    final text = exporter.buildText(invalid);

    expect(html, contains('Bandas não exibidas'));
    expect(html, contains('Poucos trechos aproveitáveis'));
    expect(html, isNot(contains('<table class="bands">')));
    expect(text, isNot(contains('Delta:')));
    expect(text, contains('Pipeline: spectrum-v1.0.0'));
  });
}
