import '../../data/models/sessao_teste.dart';

// ESQUELETO (WP3): implementação a ser substituída pelo agente do motor.

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
/// início do próximo estímulo)`; no último, até `início + intervaloMs`.
/// Toques antes de `respostaMinima` contam como antecipação e não são
/// atribuídos. Estímulos interrompidos ou sem início ficam fora da conta.
/// Preenche `Ensaio.toqueNanos`.
ResultadoTarefa pontuarTarefa({
  required List<Ensaio> ensaios,
  required List<int> toquesNanos,
  Duration respostaMinima = const Duration(milliseconds: 100),
}) {
  throw UnimplementedError('pontuarTarefa');
}
