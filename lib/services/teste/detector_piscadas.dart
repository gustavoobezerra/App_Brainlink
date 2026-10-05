import 'dart:math' as math;

import '../../data/models/raw_batch.dart';

/// Parâmetros do detector, portados de `tools/validacao/brainlink_lab.py`.
class ConfiguracaoPiscadas {
  const ConfiguracaoPiscadas({
    this.frequenciaBaixaHz = 1,
    this.frequenciaAltaHz = 15,
    this.proeminenciaMinimaMicrovolts = 80,
    this.fatorMad = 6,
    this.larguraMinimaMs = 40,
    this.larguraMaximaMs = 500,
    this.refratarioMs = 400,
    this.polaridade = 1,
  });

  final double frequenciaBaixaHz;
  final double frequenciaAltaHz;
  final double proeminenciaMinimaMicrovolts;
  final double fatorMad;
  final double larguraMinimaMs;
  final double larguraMaximaMs;
  final double refratarioMs;

  /// +1: piscada como deflexão positiva (BrainLink Pro); −1 inverte.
  final int polaridade;
}

/// Coeficientes `b`/`a` de um filtro IIR (`a[0] = 1`).
class CoeficientesFiltro {
  const CoeficientesFiltro(this.b, this.a);

  final List<double> b;
  final List<double> a;
}

/// Detector de piscadas em canal frontal único.
///
/// Porte de `detect_blinks`: Butterworth passa-banda de ordem 2 aplicado em
/// ida e volta (fase zero), limiar robusto `max(piso, k · MAD)` e seleção de
/// picos equivalente a `scipy.signal.find_peaks` (distância, proeminência e
/// largura a meia proeminência).
class DetectorPiscadas {
  const DetectorPiscadas({
    this.configuracao = const ConfiguracaoPiscadas(),
    this.taxaHz = 512,
  });

  final ConfiguracaoPiscadas configuracao;
  final double taxaHz;

  /// Filtros já projetados, por (frequência baixa, frequência alta, taxa).
  static final Map<(double, double, double), CoeficientesFiltro> _filtros = {};

  /// Índices (amostras) dos picos de piscada em [microvolts].
  ///
  /// Sinal mais curto que o preenchimento do `filtfilt` (16 amostras) devolve
  /// lista vazia.
  List<int> detectar(List<double> microvolts) {
    final c = configuracao;
    final filtro = _filtros.putIfAbsent(
      (c.frequenciaBaixaHz, c.frequenciaAltaHz, taxaHz),
      () => butterworthPassaBanda(
        2,
        c.frequenciaBaixaHz,
        c.frequenciaAltaHz,
        taxaHz,
      ),
    );
    final preenchimento =
        3 * math.max(filtro.a.length, filtro.b.length).toInt();
    if (microvolts.length <= preenchimento) return const [];
    final filtrado = filtfilt(filtro, microvolts);
    final y = List<double>.generate(
      filtrado.length,
      (i) => filtrado[i] * c.polaridade,
    );

    final centro = _mediana(y);
    final desvios = [for (final v in y) (v - centro).abs()];
    final mad = _mediana(desvios) * 1.4826;
    final proeminencia = math.max(
      c.proeminenciaMinimaMicrovolts,
      c.fatorMad * mad,
    );
    return encontrarPicos(
      y,
      proeminenciaMinima: proeminencia,
      larguraMinima: c.larguraMinimaMs * taxaHz / 1000,
      larguraMaxima: c.larguraMaximaMs * taxaHz / 1000,
      distancia: math.max(1, (c.refratarioMs * taxaHz / 1000).truncate()),
    );
  }

  /// Máscara: `true` nas amostras contaminadas por piscada.
  ///
  /// Cobre `[pico − antes, pico + depois)`, com as durações truncadas para
  /// amostras como em `blink_mask`.
  List<bool> mascara(
    int quantidade,
    List<int> picos, {
    double antesMs = 200,
    double depoisMs = 500,
  }) {
    final resultado = List<bool>.filled(quantidade, false);
    final antes = (antesMs * taxaHz / 1000).truncate();
    final depois = (depoisMs * taxaHz / 1000).truncate();
    for (final pico in picos) {
      final inicio = math.max(0, pico - antes);
      final fim = math.min(quantidade, pico + depois);
      for (var i = inicio; i < fim; i++) {
        resultado[i] = true;
      }
    }
    return resultado;
  }
}

/// Trechos contínuos de [lotes]: índices `[início, fim)` de lotes que podem
/// ser concatenados sem buraco conhecido.
///
/// Quebra em salto de seq, amostras perdidas (`dropped > 0`), lote incompleto
/// (isolado no próprio trecho) e lote sem `t0MonoNanos` (descartado).
List<(int, int)> trechosContinuos(List<RawBatch> lotes) {
  final trechos = <(int, int)>[];
  int? inicio;
  for (var i = 0; i < lotes.length; i++) {
    final lote = lotes[i];
    if (lote.t0MonoNanos == null) {
      if (inicio != null) trechos.add((inicio, i));
      inicio = null;
      continue;
    }
    final completo = lote.samples.length == RawBatch.sampleRateHz;
    if (inicio != null) {
      final anterior = lotes[i - 1];
      final continua = lote.seq == anterior.seq + 1 &&
          lote.dropped == 0 &&
          completo &&
          anterior.samples.length == RawBatch.sampleRateHz;
      if (!continua) {
        trechos.add((inicio, i));
        inicio = null;
      }
    }
    inicio ??= i;
  }
  if (inicio != null) trechos.add((inicio, lotes.length));
  return trechos;
}

/// Instante (ns, relógio monotônico) da amostra [indice] do [lote].
int instanteAmostraNanos(RawBatch lote, int indice) {
  final n = lote.samples.length;
  return lote.t0MonoNanos! -
      ((n - 1 - indice) * 1e9 / RawBatch.sampleRateHz).round();
}

/// Butterworth passa-banda digital, como `scipy.signal.butter(ordem,
/// [baixa, alta] / (fs / 2), 'band')`: protótipo analógico, pré-distorção,
/// transformação passa-banda e bilinear. Ordem 2 gera 5 coeficientes.
CoeficientesFiltro butterworthPassaBanda(
  int ordem,
  double baixaHz,
  double altaHz,
  double taxaHz,
) {
  if (!(0 < baixaHz && baixaHz < altaHz && altaHz < taxaHz / 2)) {
    throw ArgumentError('Faixa do filtro inválida: $baixaHz–$altaHz Hz.');
  }
  // Frequências normalizadas por Nyquist; scipy usa fs = 2 internamente.
  const fs = 2.0;
  final w1 = 2 * fs * math.tan(math.pi * (baixaHz / (taxaHz / 2)) / fs);
  final w2 = 2 * fs * math.tan(math.pi * (altaHz / (taxaHz / 2)) / fs);
  final banda = w2 - w1;
  final centro = math.sqrt(w1 * w2);

  // Polos do protótipo passa-baixa (sem zeros, ganho 1).
  final polosPb = <_Complexo>[
    for (var m = -ordem + 1; m < ordem; m += 2)
      -_Complexo.polar(1, math.pi * m / (2 * ordem)),
  ];

  // lp2bp_zpk: cada polo vira dois; ordem zeros na origem.
  final escalados = [for (final p in polosPb) p * (banda / 2)];
  final raizes = [
    for (final e in escalados) (e * e - _Complexo(centro * centro, 0)).sqrt(),
  ];
  final polos = <_Complexo>[
    for (var k = 0; k < escalados.length; k++) escalados[k] + raizes[k],
    for (var k = 0; k < escalados.length; k++) escalados[k] - raizes[k],
  ];
  final zeros = List<_Complexo>.filled(ordem, const _Complexo(0, 0));
  var ganho = math.pow(banda, ordem).toDouble();

  // bilinear_zpk.
  const fs2 = 2 * fs;
  const f2 = _Complexo(fs2, 0);
  final zerosZ = [for (final z in zeros) (f2 + z) / (f2 - z)];
  final polosZ = [for (final p in polos) (f2 + p) / (f2 - p)];
  for (var i = zerosZ.length; i < polosZ.length; i++) {
    zerosZ.add(const _Complexo(-1, 0));
  }
  var numerador = const _Complexo(1, 0);
  for (final z in zeros) {
    numerador = numerador * (f2 - z);
  }
  var denominador = const _Complexo(1, 0);
  for (final p in polos) {
    denominador = denominador * (f2 - p);
  }
  ganho *= (numerador / denominador).re;

  final b = [for (final v in _polinomio(zerosZ)) v * ganho];
  final a = _polinomio(polosZ);
  return CoeficientesFiltro(b, a);
}

/// Filtragem em ida e volta como `scipy.signal.filtfilt` (padtype 'odd',
/// padlen = 3 · max(len(a), len(b)), estado inicial de `lfilter_zi`).
List<double> filtfilt(CoeficientesFiltro filtro, List<double> x) {
  final p = 3 * math.max(filtro.a.length, filtro.b.length).toInt();
  final n = x.length;
  if (n <= p) {
    throw ArgumentError('Sinal com $n amostras; filtfilt exige mais que $p.');
  }
  // Extensão ímpar: 2·x[0] − x[p..1] e 2·x[n−1] − x[n−2..n−p−1].
  final estendido = List<double>.filled(n + 2 * p, 0);
  for (var i = 0; i < p; i++) {
    estendido[i] = 2 * x[0] - x[p - i];
  }
  for (var i = 0; i < n; i++) {
    estendido[p + i] = x[i];
  }
  for (var i = 0; i < p; i++) {
    estendido[p + n + i] = 2 * x[n - 1] - x[n - 2 - i];
  }

  final zi = lfilterZi(filtro);
  final ida = _lfilter(filtro, estendido, estendido.first, zi);
  final invertido = ida.reversed.toList();
  final volta = _lfilter(filtro, invertido, invertido.first, zi);
  final resultado = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    resultado[i] = volta[volta.length - 1 - p - i];
  }
  return resultado;
}

/// Estado inicial do filtro em regime para degrau unitário (`lfilter_zi`).
List<double> lfilterZi(CoeficientesFiltro filtro) {
  final a = filtro.a;
  final b = filtro.b;
  final ordem = math.max(a.length, b.length);
  final aa = List<double>.generate(ordem, (i) => i < a.length ? a[i] : 0);
  final bb = List<double>.generate(ordem, (i) => i < b.length ? b[i] : 0);
  final zi = List<double>.filled(ordem - 1, 0);
  var somaA = 0.0;
  var somaB = 0.0;
  for (var i = 0; i < ordem; i++) {
    somaA += aa[i];
    if (i > 0) somaB += bb[i] - aa[i] * bb[0];
  }
  zi[0] = somaB / somaA;
  var acumuladoA = 1.0;
  var acumuladoC = 0.0;
  for (var k = 1; k < ordem - 1; k++) {
    acumuladoA += aa[k];
    acumuladoC += bb[k] - aa[k] * bb[0];
    zi[k] = acumuladoA * zi[0] - acumuladoC;
  }
  return zi;
}

/// `lfilter` em forma direta II transposta, com estado `zi · escala`.
List<double> _lfilter(
  CoeficientesFiltro filtro,
  List<double> x,
  double escala,
  List<double> zi,
) {
  final b = filtro.b;
  final a = filtro.a;
  final ordem = math.max(a.length, b.length);
  final z = [for (final v in zi) v * escala];
  final y = List<double>.filled(x.length, 0);
  double coefB(int i) => i < b.length ? b[i] : 0;
  double coefA(int i) => i < a.length ? a[i] : 0;
  for (var n = 0; n < x.length; n++) {
    final entrada = x[n];
    final saida = coefB(0) * entrada + z[0];
    for (var i = 0; i < ordem - 2; i++) {
      z[i] = coefB(i + 1) * entrada + z[i + 1] - coefA(i + 1) * saida;
    }
    z[ordem - 2] = coefB(ordem - 1) * entrada - coefA(ordem - 1) * saida;
    y[n] = saida;
  }
  return y;
}

/// Picos como `scipy.signal.find_peaks(x, prominence=(min, None),
/// width=(larguraMinima, larguraMaxima), rel_height=0.5, distance=...)`.
List<int> encontrarPicos(
  List<double> x, {
  required double proeminenciaMinima,
  required double larguraMinima,
  required double larguraMaxima,
  required int distancia,
  double alturaRelativa = 0.5,
}) {
  // Máximos locais; platôs contam pelo ponto médio.
  var picos = <int>[];
  final limite = x.length - 1;
  var i = 1;
  while (i < limite) {
    if (x[i - 1] < x[i]) {
      var adiante = i + 1;
      while (adiante < limite && x[adiante] == x[i]) {
        adiante++;
      }
      if (x[adiante] < x[i]) {
        picos.add((i + adiante - 1) ~/ 2);
        i = adiante;
      }
    }
    i++;
  }

  // Distância: os maiores primeiro eliminam vizinhos próximos.
  if (distancia > 1 && picos.length > 1) {
    // Crescente por altura; empates mantêm a ordem dos picos (estável).
    final ordem = List<int>.generate(picos.length, (k) => k)
      ..sort((p, q) {
        final porAltura = x[picos[p]].compareTo(x[picos[q]]);
        return porAltura != 0 ? porAltura : p.compareTo(q);
      });
    final manter = List<bool>.filled(picos.length, true);
    for (var r = ordem.length - 1; r >= 0; r--) {
      final j = ordem[r];
      if (!manter[j]) continue;
      for (var k = j - 1; k >= 0 && picos[j] - picos[k] < distancia; k--) {
        manter[k] = false;
      }
      for (var k = j + 1;
          k < picos.length && picos[k] - picos[j] < distancia;
          k++) {
        manter[k] = false;
      }
    }
    picos = [
      for (var k = 0; k < picos.length; k++)
        if (manter[k]) picos[k],
    ];
  }

  // Proeminência com as bases de `_peak_prominences` (wlen ilimitado).
  final selecionados = <int>[];
  for (final pico in picos) {
    final altura = x[pico];
    var k = pico;
    var minimoEsq = altura;
    var baseEsq = pico;
    while (k >= 0 && x[k] <= altura) {
      if (x[k] < minimoEsq) {
        minimoEsq = x[k];
        baseEsq = k;
      }
      k--;
    }
    k = pico;
    var minimoDir = altura;
    var baseDir = pico;
    while (k <= limite && x[k] <= altura) {
      if (x[k] < minimoDir) {
        minimoDir = x[k];
        baseDir = k;
      }
      k++;
    }
    final proeminencia = altura - math.max(minimoEsq, minimoDir);
    if (proeminencia < proeminenciaMinima) continue;

    // Largura na altura `pico − proeminência · alturaRelativa`.
    final referencia = altura - proeminencia * alturaRelativa;
    k = pico;
    while (baseEsq < k && referencia < x[k]) {
      k--;
    }
    var esquerda = k.toDouble();
    if (x[k] < referencia) {
      esquerda += (referencia - x[k]) / (x[k + 1] - x[k]);
    }
    k = pico;
    while (k < baseDir && referencia < x[k]) {
      k++;
    }
    var direita = k.toDouble();
    if (x[k] < referencia) {
      direita -= (referencia - x[k]) / (x[k - 1] - x[k]);
    }
    final largura = direita - esquerda;
    if (largura < larguraMinima || largura > larguraMaxima) continue;
    selecionados.add(pico);
  }
  return selecionados;
}

double _mediana(List<double> valores) {
  final ordenado = List<double>.of(valores)..sort();
  final n = ordenado.length;
  if (n == 0) return 0;
  return n.isOdd
      ? ordenado[n ~/ 2]
      : (ordenado[n ~/ 2 - 1] + ordenado[n ~/ 2]) / 2;
}

/// Coeficientes reais do polinômio mônico com as [raizes] dadas.
List<double> _polinomio(List<_Complexo> raizes) {
  var coef = <_Complexo>[const _Complexo(1, 0)];
  for (final r in raizes) {
    final novo = List<_Complexo>.filled(coef.length + 1, const _Complexo(0, 0));
    for (var i = 0; i < coef.length; i++) {
      novo[i] = novo[i] + coef[i];
      novo[i + 1] = novo[i + 1] - coef[i] * r;
    }
    coef = novo;
  }
  return [for (final c in coef) c.re];
}

class _Complexo {
  const _Complexo(this.re, this.im);

  factory _Complexo.polar(double modulo, double angulo) =>
      _Complexo(modulo * math.cos(angulo), modulo * math.sin(angulo));

  final double re;
  final double im;

  _Complexo operator +(_Complexo o) => _Complexo(re + o.re, im + o.im);
  _Complexo operator -(_Complexo o) => _Complexo(re - o.re, im - o.im);
  _Complexo operator -() => _Complexo(-re, -im);
  _Complexo operator *(Object o) {
    if (o is num) return _Complexo(re * o, im * o);
    final c = o as _Complexo;
    return _Complexo(re * c.re - im * c.im, re * c.im + im * c.re);
  }

  _Complexo operator /(_Complexo o) {
    final d = o.re * o.re + o.im * o.im;
    return _Complexo(
      (re * o.re + im * o.im) / d,
      (im * o.re - re * o.im) / d,
    );
  }

  /// Raiz principal (parte real ≥ 0), como `numpy.sqrt` complexo.
  _Complexo sqrt() {
    final modulo = math.sqrt(re * re + im * im);
    final a = math.sqrt((modulo + re) / 2);
    final b = math.sqrt(math.max(0, (modulo - re) / 2));
    return _Complexo(a, im < 0 ? -b : b);
  }
}
