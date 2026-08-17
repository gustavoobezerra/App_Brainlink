import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a interface não usa linguagem clínica proibida pelo vault', () {
    final uiDirectory = Directory('lib/ui');
    expect(uiDirectory.existsSync(), isTrue);

    final violations = <String>[];
    for (final entity in uiDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = _withoutComments(entity.readAsStringSync());
      final searchable = _fold(source);
      for (final pattern in _forbiddenPatterns) {
        if (pattern.hasMatch(searchable)) {
          violations.add('${entity.path}: ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Texto visível deve obedecer a '
          'vault/30-regulatorio/linguagem-permitida.md:\n'
          '${violations.join('\n')}',
    );
  });

  test('possibilidade fica qualificada como rastreio e não diagnóstico', () {
    final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();
    final spectrumSource =
        File('lib/services/eeg_spectrum_analyzer.dart').readAsStringSync();

    expect(source, contains('POSSIBILIDADE DE TDAH · RASTREIO ASRS V1.1'));
    expect(source, contains('NÃO É DIAGNÓSTICO'));
    expect(source, isNot(contains('NÃO ENTRA NO RASTREIO DE TDAH')));
    expect(source, contains('pontuação ASRS usa somente as respostas'));
    expect(source, contains('PADRÃO HISTÓRICO PESQUISADO NO TDAH'));
    expect(
      spectrumSource,
      contains('mas isso não é diagnóstico'),
    );
    expect(spectrumSource, contains('Responda ao questionário'));
    expect(source.toLowerCase(), isNot(contains('velocímetro')));
    expect(source, isNot(contains('Ela não avalia saúde, TDAH')));
  });
}

final _forbiddenPatterns = <RegExp>[
  RegExp(
      r'\b(?:faz|fornece|realiza|confirma)\s+(?:um\s+|o\s+)?diagnostic[a-z]*\b'),
  RegExp(r'\bdetecta\s+tdah\b'),
  RegExp(r'\bidentifica\s+tdah\b'),
  RegExp(r'\brisco\s+de\s+tdah\b'),
  RegExp(r'\bprobabilidade\s+de\s+tdah\b'),
  RegExp(r'\bvoce\s+tem\b'),
  RegExp(r'\bresultado\s+indica\s+que\b'),
  RegExp(r'\b(?:normal|anormal|alterado)\b'),
  RegExp(r'\bacima\s+do\s+esperado\s+para\s+a\s+idade\b'),
  RegExp(r'\b(?:exame|laudo)\b'),
  RegExp(r'\bteste\s+clinico\b'),
  RegExp(r'\btrata\b'),
  RegExp(r'\bmelhora\b'),
  RegExp(r'\breduz\s+sintomas\b'),
  RegExp(r'\bcientificamente\s+comprovado\b'),
  RegExp(r'\baprovado\s+pelo\s+fda\b'),
  RegExp(r'\bvalidado\s+clinicamente\b'),
];

String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
    .replaceAll(RegExp(r'//.*$', multiLine: true), ' ');

String _fold(String value) => value.toLowerCase().replaceAllMapped(
      RegExp('[áàâãäéèêëíìîïóòôõöúùûüç]'),
      (match) => const {
        'á': 'a',
        'à': 'a',
        'â': 'a',
        'ã': 'a',
        'ä': 'a',
        'é': 'e',
        'è': 'e',
        'ê': 'e',
        'ë': 'e',
        'í': 'i',
        'ì': 'i',
        'î': 'i',
        'ï': 'i',
        'ó': 'o',
        'ò': 'o',
        'ô': 'o',
        'õ': 'o',
        'ö': 'o',
        'ú': 'u',
        'ù': 'u',
        'û': 'u',
        'ü': 'u',
        'ç': 'c',
      }[match.group(0)]!,
    );
