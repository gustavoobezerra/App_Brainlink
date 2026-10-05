import 'dart:math' as math;

import '../../data/models/sessao_teste.dart';
import 'alfa_por_fase.dart';
import 'duracoes_teste.dart';
import 'pontuacao_tarefa.dart';

/// Os primeiros segundos de cada fase são descartados: a pessoa ainda está
/// fechando os olhos ou se acomodando (Embasamento §6, item 6).
const Duration descarteInicialFase = Duration(seconds: 2);

/// Medida sem sinal (fase não gravada ou cálculo que falhou).
const MedidaAlfa _semMedida = MedidaAlfa(potencia: null, segundosLimpos: 0);

/// Monta os quatro cartões da tela de resultados da demonstração (10B).
///
/// Cada medida segue a regra do ADR-004: sem sinal limpo suficiente, o cartão
/// recebe o motivo em vez do número. Nada aqui compara a pessoa com outras.
ResumoDemonstracao montarResumoDemonstracao(
  SessaoTeste sessao,
  DuracoesTeste duracoes,
) {
  final calibracao = sessao.ultimaCalibracao;

  // Cartão 1: olhos abertos (calibração, sem piscadas) × repouso fechado.
  final abertos = calibracao == null || calibracao.fimNanos == null
      ? _semMedida
      : _medir(
          sessao,
          [(calibracao.inicioNanos, calibracao.fimNanos!)],
          duracoes.minimoLimpoCalibracaoSegundos,
        );
  final repouso = _medirFase(sessao, FaseTeste.repouso, duracoes);
  final alfaDb = _seguro(
    () => reatividadeAlfaDb(olhosAbertos: abertos, olhosFechados: repouso),
  );

  // Cartão 2: alfa no repouso, na tarefa e no repouso final.
  final tarefa = _medirFase(sessao, FaseTeste.tarefa, duracoes);
  final repousoFinal = _medirFase(sessao, FaseTeste.repousoFinal, duracoes);
  final potencias = [repouso.potencia, tarefa.potencia, repousoFinal.potencia];
  List<double>? alfaPorFase;
  if (potencias.every((p) => p != null && p > 0)) {
    final maior = potencias.map((p) => p!).reduce(math.max);
    alfaPorFase = [for (final p in potencias) p! / maior];
  }

  // Cartão 4: desempenho descritivo na tarefa.
  final resultado = _seguro(
        () => pontuarTarefa(
          ensaios: sessao.tarefa,
          toquesNanos: sessao.toquesDa(FaseTeste.tarefa),
          respostaMinima: duracoes.respostaMinima,
        ),
      ) ??
      const ResultadoTarefa(
        comuns: 0,
        acertos: 0,
        omissoes: 0,
        raros: 0,
        comissoes: 0,
        antecipacoes: 0,
        temposMs: [],
      );
  final auditiva = sessao.versao == VersaoTeste.auditiva;

  return ResumoDemonstracao(
    versao: sessao.versao,
    alfaDb: alfaDb,
    motivoAlfaDb: alfaDb == null
        ? 'Sinal limpo insuficiente na calibração ou no repouso para '
            'calcular.'
        : null,
    alfaPorFase: alfaPorFase,
    motivoAlfaPorFase: alfaPorFase == null
        ? 'Sinal limpo insuficiente em uma das fases para comparar.'
        : null,
    piscadasDetectadas: calibracao?.detectadas ?? 0,
    piscadasTotal: duracoes.bipesCalibracao,
    acertos: resultado.acertos,
    comuns: resultado.comuns,
    toquesRaros: resultado.comissoes,
    raros: resultado.raros,
    tempoMedioMs: resultado.tempoMedioMs,
    motivoTempoMedio: resultado.tempoMedioMs == null
        ? (auditiva
            ? 'Sem toques no som grave.'
            : 'Sem toques na figura comum.')
        : null,
  );
}

MedidaAlfa _medirFase(
  SessaoTeste sessao,
  FaseTeste fase,
  DuracoesTeste duracoes,
) {
  final janelas = <(int, int)>[];
  final descarte = descarteInicialFase.inMicroseconds * 1000;
  final registro = sessao.fases[fase];
  if (registro != null) {
    for (final (inicio, fim) in registro.janelas) {
      if (fim - inicio > descarte) janelas.add((inicio + descarte, fim));
    }
  }
  if (janelas.isEmpty) {
    return _semMedida;
  }
  return _medir(sessao, janelas, duracoes.minimoLimpoFaseSegundos);
}

MedidaAlfa _medir(
  SessaoTeste sessao,
  List<(int, int)> janelas,
  double minimo,
) =>
    _seguro(
      () => medirAlfa(
        lotes: sessao.lotes,
        janelas: janelas,
        minimoSegundosLimpos: minimo,
      ),
    ) ??
    _semMedida;

/// Uma medida que falha vira "sem número" (com o motivo) em vez de impedir a
/// tela de resultados de abrir.
T? _seguro<T>(T Function() calcular) {
  try {
    return calcular();
  } catch (_) {
    return null;
  }
}
