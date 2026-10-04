import 'dart:async';

import '../../data/models/raw_batch.dart';
import 'duracoes_teste.dart';
import 'fonte_sinal.dart';
import 'relogio.dart';

// ESQUELETO (WP3): implementação a ser substituída pelo agente do motor.

/// EEG simulado para percorrer o fluxo sem o headset.
class FonteSimulada implements FonteSinal, ControleSimulacao {
  FonteSimulada({
    required this.cenario,
    required this.relogio,
    this.duracoes = DuracoesTeste.simulada,
    this.semente = 7,
  });

  final CenarioSimulado cenario;
  final Relogio relogio;
  final DuracoesTeste duracoes;
  final int semente;

  @override
  bool get simulada => true;

  @override
  Stream<RawBatch> get lotes => const Stream.empty();

  @override
  Stream<int> get qualidade => const Stream.empty();

  @override
  Stream<EstadoConexao> get conexao => const Stream.empty();

  @override
  EstadoConexao get estadoConexao => EstadoConexao.desconectado;

  @override
  Future<ResultadoAutoConexao> autoConectar() async => const AutoConectado();

  @override
  Future<List<DispositivoSinal>> buscar() async => const [];

  @override
  Future<void> conectar(DispositivoSinal dispositivo) async {}

  @override
  Future<bool> reconectar() async => true;

  @override
  Future<void> desconectar() async {}

  @override
  Future<void> dispose() async {}

  @override
  void definirEstado(EstadoSimulado estado) {}

  @override
  void aoBipeCalibracao(int nanos) {}
}
