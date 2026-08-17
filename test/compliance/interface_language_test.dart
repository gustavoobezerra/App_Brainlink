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
}

final _forbiddenPatterns = <RegExp>[
  RegExp(r'\bdiagnostic[a-z]*\b'),
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
