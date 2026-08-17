import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ASRS v1.1 Screener 6Q', () {
    test('mantém seis itens, cinco respostas e metadados de uso', () {
      expect(AsrsScreener6.items, hasLength(6));
      expect(AsrsResponse.values, hasLength(5));
      expect(AsrsScreener6.minimumAge, 18);
      expect(AsrsScreener6.attribution, contains('World Health Organization'));
      expect(AsrsScreener6.officialSource, startsWith('https://'));
      expect(AsrsScreener6.licensingSource, startsWith('https://'));
    });

    test('itens 1 a 3 contam a partir de Algumas vezes', () {
      expect(
        AsrsScreener6.score(<AsrsResponse>[
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
          AsrsResponse.never,
          AsrsResponse.never,
          AsrsResponse.never,
        ]),
        3,
      );
    });

    test('itens 4 a 6 contam somente a partir de Frequentemente', () {
      expect(
        AsrsScreener6.score(<AsrsResponse>[
          AsrsResponse.never,
          AsrsResponse.never,
          AsrsResponse.never,
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
        ]),
        0,
      );
      expect(
        AsrsScreener6.score(<AsrsResponse>[
          AsrsResponse.never,
          AsrsResponse.never,
          AsrsResponse.never,
          AsrsResponse.often,
          AsrsResponse.often,
          AsrsResponse.often,
        ]),
        3,
      );
    });

    test('quatro de seis usa orientação neutra acordada', () {
      final result = AsrsScreenerResult(
        id: 'asrs-1',
        completedAt: DateTime.utc(2026, 8, 17),
        responses: const <AsrsResponse>[
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
          AsrsResponse.sometimes,
          AsrsResponse.often,
          AsrsResponse.never,
          AsrsResponse.never,
        ],
      );

      expect(result.score, 4);
      expect(result.meritsAttention, isTrue);
      expect(
        result.guidance,
        'Sua pontuação merece atenção. Converse com um profissional de saúde.',
      );
    });

    test('rejeita quantidade incompleta em vez de pontuar ausência como zero',
        () {
      expect(
        () => AsrsScreener6.score(const <AsrsResponse>[AsrsResponse.never]),
        throwsArgumentError,
      );
    });

    test('JSON preserva respostas e recalcula o escore', () {
      final original = AsrsScreenerResult(
        id: 'asrs-json',
        completedAt: DateTime.utc(2026, 8, 17, 12, 30),
        responses: AsrsResponse.values.take(5).followedBy(
          const <AsrsResponse>[AsrsResponse.veryOften],
        ),
      );

      final restored = AsrsScreenerResult.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.responses, original.responses);
      expect(restored.score, original.score);
    });
  });
}
