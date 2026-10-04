import '../../data/models/raw_batch.dart';

/// Situação da ligação com o headset (ou com a simulação).
enum EstadoConexao { desconectado, conectando, conectado }

/// Aparelho Bluetooth que pode ser escolhido na lista.
class DispositivoSinal {
  const DispositivoSinal({
    required this.id,
    required this.nome,
    required this.pareado,
  });

  /// Endereço Bluetooth.
  final String id;
  final String nome;
  final bool pareado;

  @override
  bool operator ==(Object other) => other is DispositivoSinal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Resultado da tentativa automática de conectar ao BrainLink pareado.
sealed class ResultadoAutoConexao {
  const ResultadoAutoConexao();
}

/// Havia exatamente um BrainLink pareado e ele conectou.
final class AutoConectado extends ResultadoAutoConexao {
  const AutoConectado();
}

/// Nenhum ou mais de um BrainLink pareado: a pessoa escolhe na lista.
final class AutoEscolher extends ResultadoAutoConexao {
  const AutoEscolher(this.dispositivos);

  final List<DispositivoSinal> dispositivos;
}

/// A conexão automática falhou; [motivo] vem do Android.
final class AutoFalhou extends ResultadoAutoConexao {
  const AutoFalhou(this.motivo);

  final String motivo;
}

/// Fonte do EEG do teste: o headset real ou a simulação.
///
/// Cada fonte mantém uma única assinatura do EEG bruto (o canal nativo aceita
/// um ouvinte só) e a redistribui em [lotes].
abstract interface class FonteSinal {
  /// Dados simulados: a interface identifica a simulação.
  bool get simulada;

  /// EEG bruto em lotes de 1 s (512 amostras).
  Stream<RawBatch> get lotes;

  /// `poorSignal` do SDK, 0 (bom) a 200 (fora da cabeça), ~1 por segundo.
  Stream<int> get qualidade;

  Stream<EstadoConexao> get conexao;

  EstadoConexao get estadoConexao;

  /// Conecta sozinho se houver exatamente um BrainLink pareado.
  Future<ResultadoAutoConexao> autoConectar();

  /// Busca aparelhos (pareados primeiro, depois a varredura).
  Future<List<DispositivoSinal>> buscar();

  /// Conecta ao aparelho escolhido; lança erro com o motivo se falhar.
  Future<void> conectar(DispositivoSinal dispositivo);

  /// Uma tentativa de reconectar ao último aparelho; `true` se conectou.
  Future<bool> reconectar();

  Future<void> desconectar();

  /// Encerra a assinatura do EEG bruto. Precisa terminar antes de abrir a
  /// coleta anterior, que usa o mesmo canal nativo.
  Future<void> dispose();
}

/// O que a simulação deve imitar no corpo da pessoa.
enum EstadoSimulado {
  olhosAbertos,
  olhosFechados,
  tarefaOlhosFechados,
  tarefaOlhosAbertos,
}

/// Cenários da simulação, para ver também as telas de erro.
enum CenarioSimulado {
  tudoCerto('Tudo certo'),
  poucasPiscadas('Poucas piscadas'),
  perdaContato('Perda de contato'),
  bluetoothCai('Bluetooth cai');

  const CenarioSimulado(this.rotulo);

  final String rotulo;
}

/// Ganchos que só a fonte simulada usa: o controlador avisa o que a pessoa
/// estaria fazendo, e a simulação gera o sinal correspondente.
abstract interface class ControleSimulacao {
  void definirEstado(EstadoSimulado estado);

  /// Um bipe da calibração tocou em [nanos]; a simulação pisca logo depois.
  void aoBipeCalibracao(int nanos);
}
