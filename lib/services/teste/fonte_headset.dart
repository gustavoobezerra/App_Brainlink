import 'dart:async';

import '../../data/models/raw_batch.dart';
import '../../native/brainlink_bridge.dart';
import '../../ui/screens/home_screen.dart' show DeviceDiscoveryGateway;
import 'fonte_sinal.dart';

// ESQUELETO (WP1): implementação a ser substituída pelo agente nativo.

/// EEG do BrainLink real, por Bluetooth Clássico.
class FonteHeadset implements FonteSinal {
  FonteHeadset({BrainLinkBridge? ponte, DeviceDiscoveryGateway? gateway})
      : _ponte = ponte ?? BrainLinkBridge(),
        _gateway = gateway;

  // ignore: unused_field
  final BrainLinkBridge _ponte;
  // ignore: unused_field
  final DeviceDiscoveryGateway? _gateway;

  @override
  bool get simulada => false;

  @override
  Stream<RawBatch> get lotes => const Stream.empty();

  @override
  Stream<int> get qualidade => const Stream.empty();

  @override
  Stream<EstadoConexao> get conexao => const Stream.empty();

  @override
  EstadoConexao get estadoConexao => EstadoConexao.desconectado;

  @override
  Future<ResultadoAutoConexao> autoConectar() async => const AutoEscolher([]);

  @override
  Future<List<DispositivoSinal>> buscar() async => const [];

  @override
  Future<void> conectar(DispositivoSinal dispositivo) async {}

  @override
  Future<bool> reconectar() async => false;

  @override
  Future<void> desconectar() async {}

  @override
  Future<void> dispose() async {}
}
