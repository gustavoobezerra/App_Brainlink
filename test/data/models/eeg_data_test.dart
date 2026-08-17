import 'package:brainlink_app/data/models/eeg_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ausência de dado', () {
    test('absent() não inventa zeros', () {
      final d = EEGData.absent();
      expect(d.attention, isNull);
      expect(d.delta, isNull);
      expect(d.signalQuality, isNull);
      expect(d.hasAnyData, isFalse);
    });

    test('fromMap distingue campo ausente de campo zero', () {
      final comZero = EEGData.fromMap({'attention': 0, 'timestamp': 0});
      final semCampo = EEGData.fromMap({'timestamp': 0});

      expect(comZero.attention, 0);
      expect(semCampo.attention, isNull);
      expect(comZero, isNot(equals(semCampo)));
    });

    test('qualidade não medida não vira "sem contato"', () {
      final d = EEGData.absent();
      expect(d.hasContact, isNull);
      expect(d.hasGoodSignal, isNull);
    });
  });

  group('serialização', () {
    test('toMap e fromMap fazem ida e volta', () {
      final original = EEGData.fromMap({
        'attention': 42,
        'meditation': 17,
        'signalQuality': 0,
        'delta': 1,
        'theta': 2,
        'lowAlpha': 3,
        'highAlpha': 4,
        'lowBeta': 5,
        'highBeta': 6,
        'lowGamma': 7,
        'midGamma': 8,
        'timestamp': 1700000000000,
      });

      expect(EEGData.fromMap(original.toMap()), equals(original));
    });

    test('a ida e volta preserva a ausência, não a converte em zero', () {
      final parcial = EEGData.fromMap({'attention': 5, 'timestamp': 0});
      final voltou = EEGData.fromMap(parcial.toMap());

      expect(voltou.attention, 5);
      expect(voltou.delta, isNull);
      expect(voltou, equals(parcial));
    });

    test('toMap omite campos nulos em vez de gravá-los como null', () {
      final map = EEGData.fromMap({'attention': 5, 'timestamp': 0}).toMap();
      expect(map.containsKey('attention'), isTrue);
      expect(map.containsKey('delta'), isFalse);
    });
  });

  group('igualdade estrutural', () {
    test('duas amostras iguais são iguais, e o hashCode acompanha', () {
      final a = EEGData.fromMap({'attention': 1, 'timestamp': 5});
      final b = EEGData.fromMap({'attention': 1, 'timestamp': 5});

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect({a, b}.length, 1);
    });

    test('diferença em qualquer campo quebra a igualdade', () {
      final base =
          EEGData.fromMap({'attention': 1, 'theta': 2, 'timestamp': 5});
      expect(base, isNot(equals(base.copyWith(theta: 3))));
      expect(base, isNot(equals(base.copyWith(clearAttention: true))));
    });
  });

  group('derivados', () {
    test('totalAlpha é null quando falta uma das metades', () {
      final d = EEGData.fromMap({'lowAlpha': 10, 'timestamp': 0});
      expect(d.totalAlpha, isNull);
    });

    test('totalAlpha soma quando as duas metades existem', () {
      final d =
          EEGData.fromMap({'lowAlpha': 10, 'highAlpha': 15, 'timestamp': 0});
      expect(d.totalAlpha, 25);
    });
  });

  group('copyWith', () {
    test('preserva o resto e substitui o que foi passado', () {
      final a =
          EEGData.fromMap({'attention': 1, 'meditation': 2, 'timestamp': 5});
      expect(a.copyWith(attention: 9).meditation, 2);
      expect(a.copyWith(attention: 9).attention, 9);
    });

    test('clearX apaga explicitamente', () {
      final a = EEGData.fromMap({'attention': 1, 'timestamp': 5});
      expect(a.copyWith(clearAttention: true).attention, isNull);
    });

    test('clearBands apaga as oito bandas de uma vez', () {
      final a = EEGData.fromMap({
        'attention': 1,
        'delta': 1,
        'theta': 2,
        'lowAlpha': 3,
        'timestamp': 5,
      });
      final limpo = a.copyWith(clearBands: true);

      expect(limpo.delta, isNull);
      expect(limpo.theta, isNull);
      expect(limpo.lowAlpha, isNull);
      expect(limpo.attention, 1, reason: 'clearBands não toca nos índices');
    });
  });
}
