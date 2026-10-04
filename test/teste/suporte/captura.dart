import 'dart:io';
import 'dart:ui' as ui;

import 'package:brainlink_app/ui/teste/tema/tema_teste.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fontes.dart';

/// Monta [tela] em um aparelho de [tamanho] lógico (390 × 844, como o
/// protótipo), com o brilho do sistema em [brilho].
Future<void> montarTela(
  WidgetTester tester,
  Widget tela, {
  Size tamanho = const Size(390, 844),
  Brightness brilho = Brightness.dark,
  double escala = 2,
  Key? chave,
}) async {
  await carregarFontesTeste();
  tester.view.physicalSize = tamanho * escala;
  tester.view.devicePixelRatio = escala;
  tester.platformDispatcher.platformBrightnessTestValue = brilho;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: chave,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BrilhoTeste(brilho: brilho, child: tela),
      ),
    ),
  );
  await tester.pump();
}

/// Monta [tela] e grava um PNG em [arquivo] (para comparar com o design).
///
/// Só grava quando a variável de ambiente `CAPTURAS` aponta uma pasta; sem
/// ela, apenas monta a tela (o teste continua útil para detectar estouros).
Future<void> capturarTela(
  WidgetTester tester,
  Widget tela,
  String nome, {
  Size tamanho = const Size(390, 844),
  Brightness brilho = Brightness.dark,
}) async {
  final chave = GlobalKey();
  await montarTela(tester, tela,
      tamanho: tamanho, brilho: brilho, chave: chave);
  final pasta = Platform.environment['CAPTURAS'];
  if (pasta == null || pasta.isEmpty) return;
  final limite =
      chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final imagem = await limite.toImage(pixelRatio: 2);
    final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
    File('$pasta/$nome.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(dados!.buffer.asUint8List());
  });
}
