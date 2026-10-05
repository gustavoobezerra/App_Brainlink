import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regras de linguagem do brief das telas do teste (04/10/2026), além das do
/// vault já verificadas em `interface_language_test.dart`.
void main() {
  final arquivos = [
    for (final pasta in ['lib/ui/teste', 'lib/services/teste'])
      for (final entidade in Directory(pasta).listSync(recursive: true))
        if (entidade is File && entidade.path.endsWith('.dart')) entidade,
  ];

  test('textos do teste não falam em nota, score ou chance', () {
    final proibidos = <RegExp>[
      RegExp(r'\bnota\b'),
      RegExp(r'\bscore\b'),
      RegExp(r'atencao\s+baixa'),
      RegExp(r'porcentagem\s+de\s+chance'),
      RegExp(r'tdah\s+detectado'),
      RegExp(r'\b(?:normal|anormal)\b'),
      RegExp(r'\d+\s*%\s*de\s*chance'),
    ];
    final violacoes = <String>[];
    for (final arquivo in arquivos) {
      for (final literal in _literais(arquivo.readAsStringSync())) {
        final texto = _dobrar(literal);
        for (final padrao in proibidos) {
          if (padrao.hasMatch(texto)) {
            violacoes.add('${arquivo.path}: "$literal"');
          }
        }
      }
    }
    expect(violacoes, isEmpty, reason: violacoes.join('\n'));
  });

  test('avisos de não diagnóstico e remoção do encaminhamento', () {
    final fim = _literais(
      File('lib/ui/teste/telas/fim_pesquisa.dart').readAsStringSync(),
    ).join('\n');
    final resultados =
        File('lib/ui/teste/telas/resultados_demo.dart').readAsStringSync();
    expect(fim, contains('não é diagnóstico'));
    expect(fim, isNot(contains('Ver serviços de atendimento')));
    expect(
      resultados,
      contains('Demonstração de pesquisa. Não é diagnóstico.'),
    );
  });
}

Iterable<String> _literais(String fonte) sync* {
  final semComentarios = fonte
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
      .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), ' ');
  for (final m in RegExp(r"'((?:[^'\\\n]|\\.)*)'").allMatches(semComentarios)) {
    yield m.group(1)!;
  }
}

String _dobrar(String texto) => texto
    .toLowerCase()
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éê]'), 'e')
    .replaceAll('í', 'i')
    .replaceAll(RegExp('[óôõ]'), 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ç', 'c');
