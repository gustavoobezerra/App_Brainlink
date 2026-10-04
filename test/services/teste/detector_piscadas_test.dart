import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:brainlink_app/services/teste/detector_piscadas.dart';
import 'package:flutter_test/flutter_test.dart';

const _fs = 512.0;

void main() {
  const detector = DetectorPiscadas();

  group('filtro', () {
    test('coeficientes para 512 Hz batem com scipy', () {
      final ref = _referencia();
      final filtro = butterworthPassaBanda(2, 1, 15, _fs);
      expect(filtro.b, hasLength(5));
      expect(filtro.a, hasLength(5));
      for (var i = 0; i < 5; i++) {
        expect(filtro.b[i], closeTo((ref['b'] as List)[i] as num, 1e-12));
        expect(filtro.a[i], closeTo((ref['a'] as List)[i] as num, 1e-12));
      }
      final zi = lfilterZi(filtro);
      for (var i = 0; i < 4; i++) {
        expect(zi[i], closeTo((ref['ziScipy'] as List)[i] as num, 1e-9));
      }
    });

    test('filtfilt reproduz scipy no sinal de referência', () {
      final ref = _referencia();
      final x = [for (final v in ref['microvolts'] as List) (v as num) * 1.0];
      final y = filtfilt(butterworthPassaBanda(2, 1, 15, _fs), x);
      final indices = ref['indicesFiltrados'] as List;
      final esperados = ref['filtrados'] as List;
      for (var k = 0; k < indices.length; k++) {
        expect(
          y[indices[k] as int],
          closeTo(esperados[k] as num, 1e-6),
          reason: 'amostra ${indices[k]}',
        );
      }
    });

    test('ganho ≈ 1 em 5 Hz, pequeno em 0,2 e 60 Hz, fase zero', () {
      final filtro = butterworthPassaBanda(2, 1, 15, _fs);
      double ganho(double hz) {
        final x = _seno(hz, 1, 60);
        final y = filtfilt(filtro, x);
        // Meio do sinal, longe das bordas.
        final meio = y.sublist(20 * 512, 40 * 512);
        return meio.map((v) => v.abs()).reduce(math.max);
      }

      expect(ganho(5), closeTo(1, 0.02));
      expect(ganho(0.2), lessThan(0.01));
      expect(ganho(60), lessThan(0.01));

      final x = _seno(5, 1, 20);
      final y = filtfilt(filtro, x);
      for (var i = 5 * 512; i < 15 * 512; i++) {
        expect(y[i], closeTo(x[i], 0.01));
      }
    });
  });

  group('detecção', () {
    test('reproduz find_peaks do scipy (±2 amostras)', () {
      final ref = _referencia();
      final x = [for (final v in ref['microvolts'] as List) (v as num) * 1.0];
      void compara(List<int> obtidos, List esperados) {
        expect(obtidos, hasLength(esperados.length));
        for (var k = 0; k < obtidos.length; k++) {
          expect(obtidos[k], closeTo(esperados[k] as num, 2));
        }
      }

      compara(detector.detectar(x), ref['picosPolaridadePositiva'] as List);
      const negativo = DetectorPiscadas(
        configuracao: ConfiguracaoPiscadas(polaridade: -1),
      );
      compara(negativo.detectar(x), ref['picosPolaridadeNegativa'] as List);
      compara(
        negativo.detectar([for (final v in x) -v]),
        ref['picosInvertidoPolaridadeNegativa'] as List,
      );
    });

    test('acha todas as piscadas bifásicas sobre ruído e alfa (±10 ms)', () {
      // Centros nas cristas do alfa de 10 Hz (k/10 + 25 ms): o alfa não
      // desloca o máximo, e o erro medido é o do detector.
      final centros = [2.025, 4.525, 7.025, 9.625, 12.125, 15.025, 18.125];
      final x = _sintetico(
        segundos: 20,
        alfaMicrovolts: 15,
        ruidoMicrovolts: 10,
        piscadas: centros,
        semente: 3,
      );
      final picos = detector.detectar(x);
      expect(picos, hasLength(centros.length));
      for (var k = 0; k < centros.length; k++) {
        expect((picos[k] - centros[k] * _fs).abs() / _fs * 1000,
            lessThanOrEqualTo(10));
      }
    });

    test('sem falso positivo em alfa de 20 µV com ruído', () {
      final x = _sintetico(
        segundos: 30,
        alfaMicrovolts: 20,
        ruidoMicrovolts: 10,
        piscadas: const [],
        semente: 5,
      );
      expect(detector.detectar(x), isEmpty);
    });

    test('refratário: duas piscadas a 200 ms contam como uma', () {
      final x = _sintetico(
        segundos: 6,
        alfaMicrovolts: 0,
        ruidoMicrovolts: 5,
        piscadas: const [2.0, 2.2, 4.0],
        semente: 7,
      );
      expect(detector.detectar(x), hasLength(2));
    });

    test('polaridade −1 acha piscadas invertidas', () {
      final centros = [1.5, 3.5, 5.5];
      final x = _sintetico(
        segundos: 7,
        alfaMicrovolts: 0,
        ruidoMicrovolts: 5,
        piscadas: centros,
        semente: 11,
      ).map((v) => -v).toList();
      const negativo = DetectorPiscadas(
        configuracao: ConfiguracaoPiscadas(polaridade: -1),
      );
      final picos = negativo.detectar(x);
      expect(picos, hasLength(3));
      for (var k = 0; k < 3; k++) {
        expect(picos[k], closeTo(centros[k] * _fs, 6));
      }
      expect(detector.detectar(x).length, lessThan(3));
    });

    test('sinal curto devolve vazio', () {
      expect(detector.detectar(List<double>.filled(15, 0)), isEmpty);
      expect(detector.detectar(const []), isEmpty);
      expect(detector.detectar(List<double>.filled(16, 0)), isEmpty);
    });
  });

  test('máscara cobre [pico − 200 ms, pico + 500 ms)', () {
    final m = detector.mascara(2000, [50, 1000]);
    expect(m.sublist(0, 50 + 256).every((v) => v), isTrue);
    expect(m[306], isFalse);
    expect(m[1000 - 102 - 1], isFalse);
    expect(m.sublist(1000 - 102, 1000 + 256).every((v) => v), isTrue);
    expect(m[1256], isFalse);
    expect(m.where((v) => v).length, 306 + 358);
  });
}

Map<String, dynamic> _referencia() => jsonDecode(
      File('test/services/teste/fixtures/piscadas_referencia.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

List<double> _seno(double hz, double amplitude, double segundos) => [
      for (var i = 0; i < (segundos * _fs).round(); i++)
        amplitude * math.sin(2 * math.pi * hz * i / _fs),
    ];

/// Ruído gaussiano + alfa de 10 Hz + piscadas bifásicas (+150 µV, σ 60 ms,
/// rebote −50 µV 250 ms depois, σ 100 ms).
List<double> _sintetico({
  required double segundos,
  required double alfaMicrovolts,
  required double ruidoMicrovolts,
  required List<double> piscadas,
  required int semente,
}) {
  final aleatorio = math.Random(semente);
  double gauss() {
    final u = 1 - aleatorio.nextDouble();
    final v = aleatorio.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  final n = (segundos * _fs).round();
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / _fs;
        var v = ruidoMicrovolts * gauss() +
            alfaMicrovolts * math.sin(2 * math.pi * 10 * t);
        for (final c in piscadas) {
          final d = t - c;
          v += 150 * math.exp(-0.5 * math.pow(d / 0.06, 2)) -
              50 * math.exp(-0.5 * math.pow((d - 0.25) / 0.1, 2));
        }
        return v;
      }(),
  ];
}
