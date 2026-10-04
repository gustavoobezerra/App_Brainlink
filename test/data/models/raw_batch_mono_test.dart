import 'package:brainlink_app/data/models/raw_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê t0MonoNanos do lote nativo', () {
    final lote = RawBatch.fromMap({
      'seq': 3,
      't0': 1700000000000,
      't0MonoNanos': 123456789012345,
      'poorSignal': 0,
      'dropped': 0,
      'samples': List<int>.filled(512, 1),
    });
    expect(lote.t0MonoNanos, 123456789012345);
    expect(lote.samples, hasLength(512));
  });

  test('t0MonoNanos fica nulo em dados legados', () {
    final lote = RawBatch.fromMap({'seq': 0, 't0': 0, 'samples': <int>[]});
    expect(lote.t0MonoNanos, isNull);
  });
}
