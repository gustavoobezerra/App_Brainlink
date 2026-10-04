import '../../data/models/sessao_teste.dart';

/// Desempenho descritivo na tarefa, sem comparação com outras pessoas.
class ResultadoTarefa {
  const ResultadoTarefa({
    required this.comuns,
    required this.acertos,
    required this.omissoes,
    required this.raros,
    required this.comissoes,
    required this.antecipacoes,
    required this.temposMs,
  });

  /// Estímulos comuns válidos (não interrompidos) e os que receberam toque.
  final int comuns;
  final int acertos;
  final int omissoes;

  /// Estímulos raros válidos e os que receberam toque (impulsividade).
  final int raros;
  final int comissoes;

  /// Toques antes de [respostaMinima] após um estímulo.
  final int antecipacoes;

  /// Tempos de resposta dos acertos, em ms, na ordem dos estímulos.
  final List<int> temposMs;

  /// Média dos tempos de resposta dos acertos; nulo sem acertos.
  int? get tempoMedioMs => temposMs.isEmpty
      ? null
      : (temposMs.reduce((a, b) => a + b) / temposMs.length).round();
}

/// Atribui toques aos estímulos e conta acertos, omissões e comissões.
///
/// O toque de um estímulo é o primeiro em `[início + respostaMinima,
/// início do próximo estímulo)`; no último, até `início + intervaloMs`
/// (inclusive). Toques antes de `respostaMinima` contam como antecipação e
/// não são atribuídos. Estímulos interrompidos ou sem início ficam fora da
/// conta. Preenche `Ensaio.toqueNanos` (e limpa valores anteriores).
ResultadoTarefa pontuarTarefa({
  required List<Ensaio> ensaios,
  required List<int> toquesNanos,
  Duration respostaMinima = const Duration(milliseconds: 100),
}) {
  for (final ensaio in ensaios) {
    ensaio.toqueNanos = null;
  }
  final validos = [
    for (final ensaio in ensaios)
      if (ensaio.inicioNanos != null && !ensaio.interrompido) ensaio,
  ]..sort((a, b) => a.inicioNanos!.compareTo(b.inicioNanos!));
  final toques = [...toquesNanos]..sort();
  final minimaNanos = respostaMinima.inMicroseconds * 1000;

  var comuns = 0, acertos = 0, omissoes = 0;
  var raros = 0, comissoes = 0, antecipacoes = 0;
  final temposMs = <int>[];

  for (var i = 0; i < validos.length; i++) {
    final ensaio = validos[i];
    final inicio = ensaio.inicioNanos!;
    final inicioJanela = inicio + minimaNanos;
    final ultimo = i == validos.length - 1;
    // Fim exclusivo da janela; no último, `início + intervaloMs` entra.
    final fimJanela = ultimo
        ? inicio + ensaio.intervaloMs * 1000000 + 1
        : validos[i + 1].inicioNanos!;

    int? resposta;
    for (final toque in toques) {
      if (toque < inicio) continue;
      if (toque < inicioJanela) {
        if (toque < fimJanela) antecipacoes++;
        continue;
      }
      if (toque >= fimJanela) break;
      resposta = toque;
      break;
    }
    ensaio.toqueNanos = resposta;

    switch (ensaio.tipo) {
      case TipoEstimulo.comum:
        comuns++;
        if (resposta != null) {
          acertos++;
          temposMs.add(((resposta - inicio) / 1000000).round());
        } else {
          omissoes++;
        }
      case TipoEstimulo.raro:
        raros++;
        if (resposta != null) comissoes++;
    }
  }

  return ResultadoTarefa(
    comuns: comuns,
    acertos: acertos,
    omissoes: omissoes,
    raros: raros,
    comissoes: comissoes,
    antecipacoes: antecipacoes,
    temposMs: temposMs,
  );
}
