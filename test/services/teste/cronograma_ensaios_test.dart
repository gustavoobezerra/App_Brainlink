import 'dart:math' as math;

import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/services/teste/cronograma_ensaios.dart';
import 'package:flutter_test/flutter_test.dart';

int _conta(List<Ensaio> ensaios, TipoEstimulo tipo) =>
    ensaios.where((e) => e.tipo == tipo).length;

bool _temRarosSeguidos(List<Ensaio> ensaios) {
  for (var i = 1; i < ensaios.length; i++) {
    if (ensaios[i].tipo == TipoEstimulo.raro &&
        ensaios[i - 1].tipo == TipoEstimulo.raro) {
      return true;
    }
  }
  return false;
}

void main() {
  group('gerarCronograma', () {
    test('produção: 128 comuns e 32 raros, índices em ordem', () {
      final ensaios = gerarCronograma(
        comuns: 128,
        raros: 32,
        aleatorio: math.Random(1),
      );
      expect(ensaios, hasLength(160));
      expect(_conta(ensaios, TipoEstimulo.comum), 128);
      expect(_conta(ensaios, TipoEstimulo.raro), 32);
      expect([for (final e in ensaios) e.indice], List.generate(160, (i) => i));
      expect(ensaios.every((e) => e.inicioNanos == null), isTrue);
    });

    test('treino 8/2 e simulação 14/4', () {
      final treino =
          gerarCronograma(comuns: 8, raros: 2, aleatorio: math.Random(2));
      expect(_conta(treino, TipoEstimulo.comum), 8);
      expect(_conta(treino, TipoEstimulo.raro), 2);
      final simulada =
          gerarCronograma(comuns: 14, raros: 4, aleatorio: math.Random(3));
      expect(_conta(simulada, TipoEstimulo.comum), 14);
      expect(_conta(simulada, TipoEstimulo.raro), 4);
    });

    test('nunca dois raros seguidos e os primeiros são comuns', () {
      for (var semente = 0; semente < 500; semente++) {
        for (final (comuns, raros) in [(128, 32), (8, 2), (14, 4), (4, 3)]) {
          final ensaios = gerarCronograma(
            comuns: comuns,
            raros: raros,
            aleatorio: math.Random(semente),
          );
          expect(_temRarosSeguidos(ensaios), isFalse,
              reason: 'semente $semente, $comuns/$raros');
          expect(ensaios[0].tipo, TipoEstimulo.comum);
          expect(ensaios[1].tipo, TipoEstimulo.comum);
        }
      }
    });

    test('primeirosComuns configurável', () {
      for (var semente = 0; semente < 50; semente++) {
        final ensaios = gerarCronograma(
          comuns: 20,
          raros: 5,
          primeirosComuns: 5,
          aleatorio: math.Random(semente),
        );
        expect(
          ensaios.take(5).every((e) => e.tipo == TipoEstimulo.comum),
          isTrue,
        );
      }
    });

    test('a ordem varia com a semente (sorteada)', () {
      String assinatura(int semente) => gerarCronograma(
            comuns: 14,
            raros: 4,
            aleatorio: math.Random(semente),
          ).map((e) => e.tipo == TipoEstimulo.raro ? 'R' : 'c').join();
      final ordens = {for (var s = 0; s < 30; s++) assinatura(s)};
      expect(ordens.length, greaterThan(10));
    });

    test('intervalos inteiros na faixa e média perto de 1100 ms', () {
      final ensaios = gerarCronograma(
        comuns: 128,
        raros: 32,
        aleatorio: math.Random(9),
      );
      for (final e in ensaios) {
        expect(e.intervaloMs, inInclusiveRange(900, 1300));
      }
      final media = ensaios.map((e) => e.intervaloMs).reduce((a, b) => a + b) /
          ensaios.length;
      expect(media, closeTo(1100, 30));
    });

    test('faixa personalizada inclui os extremos', () {
      final ensaios = gerarCronograma(
        comuns: 300,
        raros: 0,
        aleatorio: math.Random(4),
        intervaloMinimo: const Duration(milliseconds: 10),
        intervaloMaximo: const Duration(milliseconds: 12),
      );
      expect(ensaios.map((e) => e.intervaloMs).toSet(), {10, 11, 12});
    });

    test('determinístico pela semente', () {
      List<(TipoEstimulo, int)> gera() => [
            for (final e in gerarCronograma(
              comuns: 128,
              raros: 32,
              aleatorio: math.Random(42),
            ))
              (e.tipo, e.intervaloMs),
          ];
      expect(gera(), gera());
    });

    test('combinação impossível lança ArgumentError', () {
      // 4 comuns, 2 fixos: só 3 vãos para raros.
      expect(
        () => gerarCronograma(comuns: 4, raros: 4, aleatorio: math.Random(1)),
        throwsArgumentError,
      );
      expect(
        () => gerarCronograma(comuns: 1, raros: 0, aleatorio: math.Random(1)),
        throwsArgumentError,
      );
      expect(
        () => gerarCronograma(comuns: 5, raros: -1, aleatorio: math.Random(1)),
        throwsArgumentError,
      );
      expect(
        () => gerarCronograma(
          comuns: 5,
          raros: 1,
          aleatorio: math.Random(1),
          intervaloMinimo: const Duration(milliseconds: 1300),
          intervaloMaximo: const Duration(milliseconds: 900),
        ),
        throwsArgumentError,
      );
      // No limite ainda é possível: 4 comuns (2 livres) e 3 raros.
      final limite =
          gerarCronograma(comuns: 4, raros: 3, aleatorio: math.Random(1));
      expect([for (final e in limite) e.tipo.name].join(','),
          'comum,comum,raro,comum,raro,comum,raro');
    });
  });

  group('gerarRitmo', () {
    test('todos comuns, na faixa, determinístico', () {
      final a = gerarRitmo(quantidade: 55, aleatorio: math.Random(5));
      final b = gerarRitmo(quantidade: 55, aleatorio: math.Random(5));
      expect(a, hasLength(55));
      expect(a.every((e) => e.tipo == TipoEstimulo.comum), isTrue);
      expect([for (final e in a) e.indice], List.generate(55, (i) => i));
      for (final e in a) {
        expect(e.intervaloMs, inInclusiveRange(900, 1300));
      }
      expect([for (final e in a) e.intervaloMs],
          [for (final e in b) e.intervaloMs]);
    });
  });
}
