import 'dart:typed_data';

import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap lê o lote do canal nativo', () {
    final b = RawBatch.fromMap({
      'seq': 3,
      't0': 1700000000000,
      'poorSignal': 26,
      'dropped': 0,
      'samples': Int32List.fromList([0, 100, -100]),
    });

    expect(b.seq, 3);
    expect(b.samples.length, 3);
    expect(b.poorSignal, 26);
    expect(b.t0.millisecondsSinceEpoch, 1700000000000);
  });

  test('converte para microvolts pela constante do TGAM', () {
    final b = RawBatch.fromMap({
      'seq': 0,
      't0': 0,
      'poorSignal': 0,
      'dropped': 0,
      'samples': Int32List.fromList([0, 1000, -1000]),
    });

    final uv = b.toMicrovolts();
    expect(uv[0], 0.0);
    expect(uv[1], closeTo(219.7, 0.01));
    expect(uv[2], closeTo(-219.7, 0.01));
  });

  test('corrige o sinal de inteiro de 16 bits sem sinal', () {
    // 65036 sem sinal == -500 com sinal.
    final b = RawBatch.fromMap({
      'seq': 0,
      't0': 0,
      'poorSignal': 0,
      'dropped': 0,
      'samples': Int32List.fromList([65036, 500]),
    });

    final uv = b.toMicrovolts();
    expect(uv[0], closeTo(-109.85, 0.01));
    expect(uv[1], closeTo(109.85, 0.01));
  });

  test('aceita lista genérica além de Int32List', () {
    final b = RawBatch.fromMap({
      'seq': 1,
      't0': 0,
      'poorSignal': 0,
      'dropped': 0,
      'samples': <int>[1, 2, 3],
    });

    expect(b.samples, isA<Int32List>());
    expect(b.samples.length, 3);
  });

  test('reusa o buffer de saída quando fornecido', () {
    final b = RawBatch.fromMap({
      'seq': 0,
      't0': 0,
      'poorSignal': 0,
      'dropped': 0,
      'samples': Int32List.fromList([1000, 2000]),
    });

    final buffer = Float64List(2);
    expect(identical(b.toMicrovolts(buffer), buffer), isTrue);
    expect(buffer[0], closeTo(219.7, 0.01));
  });
}
