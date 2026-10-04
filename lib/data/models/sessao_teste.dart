import 'asrs_screener_6.dart';
import 'raw_batch.dart';

/// Versão do teste escolhida no início.
enum VersaoTeste {
  /// Tons de olhos fechados (principal).
  auditiva,

  /// Figuras no centro da tela, de olhos abertos (alternativa).
  visual,
}

/// Fases do teste que gravam EEG.
enum FaseTeste {
  calibracao('Calibração'),
  repouso('Repouso'),
  treino('Treino'),
  tarefa('Tarefa'),
  ritmo('Tarefa · parte 2'),
  repousoFinal('Repouso final');

  const FaseTeste(this.rotulo);

  /// Nome mostrado ao pesquisador ("pausado em Tarefa, 1:47").
  final String rotulo;

  /// Fases em que a pessoa fica de olhos fechados (na versão auditiva, a
  /// tarefa e o ritmo também são de olhos fechados).
  bool olhosFechados(VersaoTeste versao) => switch (this) {
        FaseTeste.repouso || FaseTeste.repousoFinal => true,
        FaseTeste.tarefa || FaseTeste.ritmo => versao == VersaoTeste.auditiva,
        FaseTeste.calibracao || FaseTeste.treino => false,
      };
}

/// Ponto de qualidade do sinal mostrado ao pesquisador.
enum QualidadeSinal { boa, ajuste, ruim, semDados }

/// Estado do indicador grande de contato (tela "Coloque o sensor").
enum EstadoContato { procurando, ajuste, bom }

/// Estímulo da tarefa: o comum pede toque; o raro pede para não tocar.
///
/// Na versão auditiva, comum = tom grave (600 Hz) e raro = tom agudo
/// (1200 Hz). Na visual, comum = barco e raro = barco pirata.
enum TipoEstimulo { comum, raro }

/// Retorno suave do treino. Só existe no treino: a tarefa não dá retorno.
enum FeedbackTreino {
  /// Tocou no comum ou não tocou no raro.
  certo,

  /// Tocou no raro.
  naoTocar,

  /// Não tocou no comum.
  naoTocou,
}

/// O que a tela visual mostra no centro neste instante.
enum EstimuloVisual { nenhum, fixacao, comum, raro }

/// "Quantas horas você dormiu na última noite?"
enum HorasSono {
  menosDe5('< 5'),
  de5a7('5–7'),
  maisDe7('> 7');

  const HorasSono(this.rotulo);

  final String rotulo;
}

/// "Toma medicação para atenção? Tomou hoje?"
enum MedicacaoAtencao {
  naoToma('Não tomo'),
  tomouHoje('Tomo e tomei hoje'),
  naoTomouHoje('Tomo e não tomei hoje'),
  prefiroNaoDizer('Prefiro não dizer');

  const MedicacaoAtencao(this.rotulo);

  final String rotulo;
}

/// Respostas da tela "Algumas perguntas sobre hoje".
class RespostasContexto {
  HorasSono? sono;
  bool? cafeina;
  MedicacaoAtencao? medicacao;
  bool? lenteContato;

  bool get completas =>
      sono != null &&
      cafeina != null &&
      medicacao != null &&
      lenteContato != null;
}

/// Um estímulo do treino, da tarefa ou do bloco de ritmo.
class Ensaio {
  Ensaio({
    required this.indice,
    required this.tipo,
    required this.intervaloMs,
  });

  final int indice;
  final TipoEstimulo tipo;

  /// Tempo planejado entre o início deste estímulo e o início do próximo
  /// (0,9 a 1,3 s sorteado). No último, é a janela final de resposta.
  final int intervaloMs;

  /// Início real no relógio monotônico (som enviado ao áudio ou primeiro
  /// quadro com a figura), em nanossegundos. Nulo se não chegou a acontecer.
  int? inicioNanos;

  /// Primeiro toque atribuído a este estímulo, no mesmo relógio.
  int? toqueNanos;

  /// Estímulo cortado por uma pausa: sai dos denominadores.
  bool interrompido = false;
}

/// Toque registrado na tela, em qualquer fase com área de toque.
class ToqueRegistrado {
  const ToqueRegistrado(this.nanos, this.fase);

  final int nanos;
  final FaseTeste fase;
}

/// Uma tentativa da calibração de piscadas.
class TentativaCalibracao {
  TentativaCalibracao(this.inicioNanos);

  final int inicioNanos;
  int? fimNanos;

  /// Início de cada bipe tocado, no relógio monotônico.
  final List<int> bipesNanos = [];

  /// Se houve piscada atribuída a cada bipe (preenchido ao final).
  List<bool> porBipe = const [];

  /// Piscadas atribuídas a algum bipe.
  int get detectadas => porBipe.where((v) => v).length;

  /// Piscadas detectadas fora das janelas dos bipes.
  int extras = 0;

  /// Cortada por pausa ou saída; não conta.
  bool interrompida = false;
}

/// Intervalo contínuo de gravação de uma fase (entre pausas).
class TrechoRegistro {
  TrechoRegistro(this.inicioNanos);

  final int inicioNanos;
  int? fimNanos;
}

/// Trechos gravados de uma fase.
class RegistroFase {
  RegistroFase(this.fase);

  final FaseTeste fase;
  final List<TrechoRegistro> trechos = [];

  /// Fase concluída até o fim (sem ser descartada por "Recomeçar").
  bool concluida = false;

  /// Janelas `(início, fim)` em nanossegundos dos trechos fechados.
  List<(int, int)> get janelas => [
        for (final trecho in trechos)
          if (trecho.fimNanos != null) (trecho.inicioNanos, trecho.fimNanos!),
      ];
}

/// Registro cronológico de acontecimentos da sessão (pausas, retomadas…).
class EventoSessao {
  const EventoSessao(this.nanos, this.tipo, [this.detalhe]);

  final int nanos;
  final String tipo;
  final String? detalhe;
}

enum EncerramentoSessao { completo, abortado }

/// Sessão do teste, mantida só em memória nesta versão.
///
/// A gravação em disco e o envio ficam para uma etapa posterior; o modelo já
/// reúne o que será persistido: EEG bruto, estímulos, toques, calibração,
/// questionários e eventos.
class SessaoTeste {
  SessaoTeste({
    required this.codigoParticipante,
    required this.versao,
    required this.demonstracao,
    required this.simulada,
    required this.semente,
    DateTime? iniciadaEm,
  }) : iniciadaEm = iniciadaEm ?? DateTime.now();

  final String codigoParticipante;
  final VersaoTeste versao;
  final bool demonstracao;
  final bool simulada;

  /// Semente dos sorteios de ordem e intervalos dos estímulos.
  final int semente;
  final DateTime iniciadaEm;

  /// Todos os lotes de EEG bruto recebidos durante a sessão, em ordem.
  final List<RawBatch> lotes = [];

  final List<TentativaCalibracao> calibracoes = [];
  final Map<FaseTeste, RegistroFase> fases = {};
  final List<Ensaio> treino = [];
  final List<Ensaio> tarefa = [];
  final List<Ensaio> ritmo = [];
  final List<ToqueRegistrado> toques = [];
  final List<AsrsResponse?> asrs =
      List<AsrsResponse?>.filled(AsrsScreener6.itemCount, null);
  final RespostasContexto contexto = RespostasContexto();
  final List<EventoSessao> eventos = [];
  EncerramentoSessao? encerramento;

  RegistroFase registro(FaseTeste fase) =>
      fases.putIfAbsent(fase, () => RegistroFase(fase));

  TentativaCalibracao? get ultimaCalibracao {
    for (final tentativa in calibracoes.reversed) {
      if (!tentativa.interrompida && tentativa.fimNanos != null) {
        return tentativa;
      }
    }
    return null;
  }

  List<int> toquesDa(FaseTeste fase) => [
        for (final toque in toques)
          if (toque.fase == fase) toque.nanos,
      ];
}

/// Valores dos cartões da tela de resultados da demonstração (10B).
///
/// Cada medida vem com o número ou com o motivo de não haver número
/// (ADR-004: sessão inválida mostra o motivo, nunca o número).
class ResumoDemonstracao {
  const ResumoDemonstracao({
    required this.versao,
    required this.alfaDb,
    required this.motivoAlfaDb,
    required this.alfaPorFase,
    required this.motivoAlfaPorFase,
    required this.piscadasDetectadas,
    required this.piscadasTotal,
    required this.acertos,
    required this.comuns,
    required this.toquesRaros,
    required this.raros,
    required this.tempoMedioMs,
    required this.motivoTempoMedio,
  });

  final VersaoTeste versao;

  /// Cartão 1: variação do alfa (dB) dos olhos abertos da calibração para o
  /// repouso de olhos fechados, arredondada.
  final int? alfaDb;
  final String? motivoAlfaDb;

  /// Cartão 2: alfa no repouso, na tarefa e no repouso final, normalizado
  /// pelo maior valor (0 a 1).
  final List<double>? alfaPorFase;
  final String? motivoAlfaPorFase;

  /// Cartão 3: piscadas da última tentativa de calibração.
  final int piscadasDetectadas;
  final int piscadasTotal;

  /// Cartão 4: desempenho na tarefa, sem comparação com outras pessoas.
  final int acertos;
  final int comuns;
  final int toquesRaros;
  final int raros;
  final int? tempoMedioMs;
  final String? motivoTempoMedio;
}
