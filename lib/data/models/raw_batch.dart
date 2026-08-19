import 'dart:typed_data';

/// Lote de amostras de EEG bruto vindo da camada nativa.
///
/// O SDK entrega uma amostra por vez, a 512 Hz. Enviar cada uma pelo canal
/// seria 512 mensagens por segundo de serialização desperdiçada; o lado Android
/// acumula e envia em lotes de 1 segundo.
class RawBatch {
  const RawBatch({
    required this.seq,
    required this.t0,
    required this.poorSignal,
    required this.dropped,
    required this.samples,
  });

  /// Sequencial do lote, reiniciado a cada conexão.
  ///
  /// Um salto aqui significa perda de pacote: um buraco silencioso no meio de
  /// uma época desloca o espectro sem deixar rastro, então quem consome precisa
  /// poder detectar isso.
  final int seq;

  /// Instante em que o lote foi fechado no Android.
  ///
  /// Não é o instante da coleta no chip: entre um e outro há buffer do chip,
  /// transmissão SPP, buffer do socket e escalonamento de thread. A soma é de
  /// dezenas de milissegundos e é variável — jitter, não atraso constante.
  /// Tolerável para épocas de segundos, fatal para análise por evento.
  final DateTime t0;

  /// Qualidade de contato vigente, escala 0 a 200 do SDK; menor é melhor.
  final int poorSignal;

  /// Amostras perdidas por estouro de buffer desde o lote anterior.
  final int dropped;

  /// Contagens do conversor, sem conversão de unidade.
  final Int32List samples;

  /// Taxa do EEG bruto, em hertz.
  ///
  /// O chip TGAM do BrainLink Lite amostra a 512 Hz e é isso que governa o
  /// eixo de frequência da análise espectral: subestimar a taxa desloca
  /// todas as bandas na mesma proporção, sem nenhum sinal de erro.
  /// Um lote fechado carrega exatamente esta quantidade de amostras.
  static const int sampleRateHz = 512;

  /// Fator de conversão do ThinkGear: `µV = raw × (1,8 / 4096) / 2000 × 1e6`.
  static const double microvoltsPerUnit = 0.2197;

  /// Maior magnitude representável em 16 bits com sinal.
  static const int signedMax = 32767;

  factory RawBatch.fromMap(Map<Object?, Object?> map) {
    final raw = map['samples'];
    return RawBatch(
      seq: (map['seq'] as num?)?.toInt() ?? 0,
      t0: DateTime.fromMillisecondsSinceEpoch(
        (map['t0'] as num?)?.toInt() ?? 0,
      ),
      poorSignal: (map['poorSignal'] as num?)?.toInt() ?? 200,
      dropped: (map['dropped'] as num?)?.toInt() ?? 0,
      samples: raw is Int32List
          ? raw
          : Int32List.fromList(
              (raw as List?)?.map((e) => (e as num).toInt()).toList() ??
                  const <int>[],
            ),
    );
  }

  /// Converte para microvolts, corrigindo o sinal do inteiro de 16 bits.
  ///
  /// Se a camada nativa entregar o valor como inteiro sem sinal, tudo acima de
  /// 32767 é amplitude negativa. Sem essa correção metade da forma de onda vira
  /// um degrau gigante e o espectro fica dominado por artefato — de um jeito que
  /// parece plausível. A correção é inofensiva quando o valor já vem com sinal,
  /// porque amostras legítimas nunca passam de 32767.
  Float64List toMicrovolts([Float64List? out]) {
    final result = out ?? Float64List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      final signed = v > signedMax ? v - 65536 : v;
      result[i] = signed * microvoltsPerUnit;
    }
    return result;
  }

  @override
  String toString() =>
      'RawBatch(seq: $seq, n: ${samples.length}, poorSignal: $poorSignal, '
      'dropped: $dropped)';
}
