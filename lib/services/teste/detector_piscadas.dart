// ESQUELETO (WP2): implementação a ser substituída pelo agente de DSP.

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

/// Detector de piscadas em canal frontal único.
class DetectorPiscadas {
  const DetectorPiscadas({
    this.configuracao = const ConfiguracaoPiscadas(),
    this.taxaHz = 512,
  });

  final ConfiguracaoPiscadas configuracao;
  final double taxaHz;

  /// Índices (amostras) dos picos de piscada em [microvolts].
  List<int> detectar(List<double> microvolts) {
    throw UnimplementedError('DetectorPiscadas.detectar');
  }

  /// Máscara: `true` nas amostras contaminadas por piscada.
  List<bool> mascara(
    int quantidade,
    List<int> picos, {
    double antesMs = 200,
    double depoisMs = 500,
  }) {
    throw UnimplementedError('DetectorPiscadas.mascara');
  }
}
