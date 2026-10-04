import '../../native/brainlink_bridge.dart';
import 'estimulos.dart';

// ESQUELETO (WP1): implementação a ser substituída pelo agente nativo.

/// Sons, vibração, tela acesa e volume pela camada Android.
class EstimulosNativos implements EstimulosTeste {
  EstimulosNativos([BrainLinkBridge? ponte])
      : _ponte = ponte ?? BrainLinkBridge();

  // ignore: unused_field
  final BrainLinkBridge _ponte;

  @override
  Future<void> preparar() async {}

  @override
  Future<int?> tocar(SomTeste som) async => null;

  @override
  Future<void> vibrar(VibracaoTeste vibracao) async {}

  @override
  Future<void> manterTelaAcesa(bool ligado) async {}

  @override
  Future<VolumeMidia?> volumeMidia() async => null;

  @override
  Future<int?> agoraNanos() async => null;

  @override
  Future<void> liberar() async {}
}
