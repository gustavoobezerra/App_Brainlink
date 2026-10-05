import 'dart:io';

import 'package:flutter/services.dart';

bool _carregadas = false;

/// Carrega as fontes Atkinson de `assets/fonts` nos testes.
///
/// Sem isso o `flutter test` mede o texto com a fonte de teste, mais larga,
/// e as capturas não se parecem com o aparelho.
Future<void> carregarFontesTeste() async {
  if (_carregadas) return;
  Future<ByteData> ler(String arquivo) async => ByteData.sublistView(
        Uint8List.fromList(File('assets/fonts/$arquivo').readAsBytesSync()),
      );
  final next = FontLoader('Atkinson Hyperlegible Next')
    ..addFont(ler('AtkinsonHyperlegibleNext-Regular.ttf'))
    ..addFont(ler('AtkinsonHyperlegibleNext-SemiBold.ttf'))
    ..addFont(ler('AtkinsonHyperlegibleNext-Bold.ttf'));
  final mono = FontLoader('Atkinson Hyperlegible Mono')
    ..addFont(ler('AtkinsonHyperlegibleMono-Regular.ttf'))
    ..addFont(ler('AtkinsonHyperlegibleMono-Medium.ttf'));
  await next.load();
  await mono.load();
  _carregadas = true;
}
