/// Tempos e quantidades do protocolo (ADR-005 e brief de 04/10/2026).
///
/// [DuracoesTeste.padrao] é o teste real; [DuracoesTeste.simulada] encurta
/// tudo para percorrer o fluxo com dados simulados.
class DuracoesTeste {
  const DuracoesTeste({
    required this.contatoEstavel,
    required this.calibracao,
    required this.primeiroBipe,
    required this.intervaloBipes,
    required this.variacaoBipe,
    required this.repouso,
    required this.repousoFinal,
    required this.tarefaComuns,
    required this.tarefaRaros,
    required this.ritmo,
    required this.preparacaoTarefa,
    required this.intervaloReconexao,
    required this.contatoParaPausar,
    required this.contatoParaRetomar,
    required this.minimoLimpoCalibracaoSegundos,
    required this.minimoLimpoFaseSegundos,
    this.bipesCalibracao = 5,
    this.treinoComuns = 8,
    this.treinoRaros = 2,
    this.tentativasReconexao = 5,
    this.semDadosParaBluetooth = const Duration(seconds: 3),
    this.intervaloMinimo = const Duration(milliseconds: 900),
    this.intervaloMaximo = const Duration(milliseconds: 1300),
    this.janelaTreino = const Duration(milliseconds: 1500),
    this.feedbackTreino = const Duration(milliseconds: 1500),
    this.pausaEntreEnsaiosTreino = const Duration(milliseconds: 700),
    this.exibicaoFigura = const Duration(milliseconds: 250),
    this.respostaMinima = const Duration(milliseconds: 100),
    this.janelaPiscadaInicio = const Duration(milliseconds: 150),
    this.janelaPiscadaFim = const Duration(milliseconds: 1500),
    this.limiteVolumeBaixo = 0.6,
  });

  /// Contato bom contínuo para liberar "Continuar" (10 s).
  final Duration contatoEstavel;

  /// Duração total da calibração de piscadas (20 s).
  final Duration calibracao;
  final int bipesCalibracao;

  /// Início do primeiro bipe e espaçamento entre bipes.
  final Duration primeiroBipe;
  final Duration intervaloBipes;

  /// Variação sorteada (±) de cada bipe, para a piscada não ser antecipada.
  final Duration variacaoBipe;

  final Duration repouso;
  final Duration repousoFinal;

  /// Estímulos comuns e raros da tarefa (128 e 32 = 160 em ~3 min).
  final int tarefaComuns;
  final int tarefaRaros;
  final int treinoComuns;
  final int treinoRaros;

  /// Bloco "toque no ritmo" (1 min).
  final Duration ritmo;

  /// Tempo entre o sino de início e o primeiro estímulo.
  final Duration preparacaoTarefa;

  final int tentativasReconexao;
  final Duration intervaloReconexao;

  /// Sem lote de EEG por este tempo durante o teste = Bluetooth caiu.
  final Duration semDadosParaBluetooth;

  /// Contato ruim contínuo que pausa a fase (E1).
  final Duration contatoParaPausar;

  /// Contato bom contínuo que libera "Retomar".
  final Duration contatoParaRetomar;

  final Duration intervaloMinimo;
  final Duration intervaloMaximo;

  /// Treino: janela de resposta, tempo do retorno e pausa até o próximo.
  final Duration janelaTreino;
  final Duration feedbackTreino;
  final Duration pausaEntreEnsaiosTreino;

  /// Figura da versão visual na tela (250 ms).
  final Duration exibicaoFigura;

  /// Toques mais rápidos que isto após o estímulo são antecipação.
  final Duration respostaMinima;

  /// Janela, após cada bipe, em que a piscada conta para aquele bipe.
  final Duration janelaPiscadaInicio;
  final Duration janelaPiscadaFim;

  /// Sinal limpo mínimo para mostrar números do alfa.
  final double minimoLimpoCalibracaoSegundos;
  final double minimoLimpoFaseSegundos;

  /// Abaixo desta fração do volume máximo aparece "Aumente o volume".
  final double limiteVolumeBaixo;

  /// Quantidade de estímulos do bloco de ritmo (um a cada ~1,1 s).
  int get ritmoEnsaios => (ritmo.inMilliseconds / 1100).round().clamp(1, 1000);

  static const DuracoesTeste padrao = DuracoesTeste(
    contatoEstavel: Duration(seconds: 10),
    calibracao: Duration(seconds: 20),
    primeiroBipe: Duration(seconds: 2),
    intervaloBipes: Duration(milliseconds: 3500),
    variacaoBipe: Duration(milliseconds: 300),
    repouso: Duration(seconds: 60),
    repousoFinal: Duration(seconds: 40),
    tarefaComuns: 128,
    tarefaRaros: 32,
    ritmo: Duration(seconds: 60),
    preparacaoTarefa: Duration(seconds: 3),
    intervaloReconexao: Duration(seconds: 2),
    contatoParaPausar: Duration(seconds: 3),
    contatoParaRetomar: Duration(seconds: 3),
    minimoLimpoCalibracaoSegundos: 10,
    minimoLimpoFaseSegundos: 30,
  );

  /// Tempos encurtados para percorrer o fluxo com dados simulados.
  static const DuracoesTeste simulada = DuracoesTeste(
    contatoEstavel: Duration(seconds: 3),
    calibracao: Duration(seconds: 9),
    primeiroBipe: Duration(seconds: 1),
    intervaloBipes: Duration(milliseconds: 1500),
    variacaoBipe: Duration(milliseconds: 150),
    repouso: Duration(seconds: 10),
    repousoFinal: Duration(seconds: 8),
    tarefaComuns: 14,
    tarefaRaros: 4,
    ritmo: Duration(seconds: 8),
    preparacaoTarefa: Duration(seconds: 1),
    intervaloReconexao: Duration(milliseconds: 500),
    contatoParaPausar: Duration(seconds: 1),
    contatoParaRetomar: Duration(seconds: 1),
    minimoLimpoCalibracaoSegundos: 3,
    minimoLimpoFaseSegundos: 4,
  );
}
