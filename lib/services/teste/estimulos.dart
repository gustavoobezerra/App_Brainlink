/// Sons do teste, sintetizados pela camada Android.
enum SomTeste {
  /// Tom grave da tarefa: 600 Hz, 100 ms, rampas de 10 ms.
  grave,

  /// Tom agudo da tarefa: 1200 Hz, 100 ms, rampas de 10 ms.
  agudo,

  /// Um sino: fechar os olhos / começar a fase.
  sino,

  /// Dois sinos: abrir os olhos / fim da fase.
  sinoDuplo,

  /// Bipe curto da calibração de piscadas.
  bipeCalibracao,

  /// Alerta suave de perda de contato.
  alerta,
}

/// Padrões de vibração do teste.
enum VibracaoTeste {
  /// Uma vibração curta (começar a fase).
  curta,

  /// Duas vibrações curtas (fim da fase).
  dupla,

  /// Uma vibração longa (perda de contato).
  longa,

  /// Curta e firme (treino: "Certo").
  firme,

  /// Curta e fraca (treino: "Era para não tocar").
  fraca,
}

/// Volume da mídia do Android, em passos do sistema.
class VolumeMidia {
  const VolumeMidia(this.atual, this.maximo);

  final int atual;
  final int maximo;

  double get fracao => maximo <= 0 ? 0 : (atual / maximo).clamp(0.0, 1.0);
}

/// Saídas físicas do teste: sons, vibração, tela acesa e volume.
///
/// A implementação de produção fala com `MainActivity` pelo canal
/// `com.brainlink.app/sdk`; os testes usam uma versão falsa que registra as
/// chamadas.
abstract interface class EstimulosTeste {
  /// Gera os sons uma vez, antes do teste, para o primeiro tom não atrasar.
  Future<void> preparar();

  /// Toca [som] e devolve o instante do início no relógio monotônico
  /// (`System.nanoTime()`), ou nulo se o som não pôde ser tocado.
  Future<int?> tocar(SomTeste som);

  Future<void> vibrar(VibracaoTeste vibracao);

  /// Mantém a tela acesa durante o teste.
  Future<void> manterTelaAcesa(bool ligado);

  /// Volume atual da mídia, ou nulo se indisponível.
  Future<VolumeMidia?> volumeMidia();

  /// Instante atual no relógio monotônico do Android, em nanossegundos.
  Future<int?> agoraNanos();

  Future<void> liberar();
}
