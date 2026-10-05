import '../../native/brainlink_bridge.dart';
import 'estimulos.dart';

/// Sons, vibração, tela acesa e volume pela camada Android.
///
/// Nunca lança: falhas da plataforma viram `null`/silêncio, porque um som
/// perdido não pode derrubar o teste.
class EstimulosNativos implements EstimulosTeste {
  EstimulosNativos([BrainLinkBridge? ponte])
      : _ponte = ponte ?? BrainLinkBridge();

  final BrainLinkBridge _ponte;

  /// Preparação em andamento ou concluída com sucesso.
  Future<bool>? _preparo;

  /// Padrão de cada vibração: (pausas/vibrações em ms, amplitudes 0–255).
  static const Map<VibracaoTeste, (List<int>, List<int>)> padroesVibracao = {
    VibracaoTeste.curta: ([0, 60], [0, 180]),
    VibracaoTeste.dupla: ([0, 60, 120, 60], [0, 180, 0, 180]),
    VibracaoTeste.longa: ([0, 600], [0, 200]),
    VibracaoTeste.firme: ([0, 40], [0, 255]),
    VibracaoTeste.fraca: ([0, 40], [0, 60]),
  };

  @override
  Future<void> preparar() async {
    final emAndamento = _preparo ??= _protegido(_ponte.audioPrepare, false);
    // Uma falha libera nova tentativa na próxima chamada.
    if (!await emAndamento && identical(_preparo, emAndamento)) {
      _preparo = null;
    }
  }

  /// O nome nativo do som é o próprio nome do enum.
  @override
  Future<int?> tocar(SomTeste som) =>
      _protegido(() => _ponte.audioPlay(som.name), null);

  @override
  Future<void> vibrar(VibracaoTeste vibracao) async {
    final (tempos, amplitudes) = padroesVibracao[vibracao]!;
    await _protegido(() => _ponte.vibrate(tempos, amplitudes), false);
  }

  @override
  Future<void> manterTelaAcesa(bool ligado) async {
    await _protegido(() => _ponte.setKeepScreenOn(ligado), false);
  }

  @override
  Future<VolumeMidia?> volumeMidia() => _protegido(() async {
        final volume = await _ponte.getMediaVolume();
        return volume == null ? null : VolumeMidia(volume.current, volume.max);
      }, null);

  @override
  Future<int?> agoraNanos() => _protegido(_ponte.monotonicNowNanos, null);

  @override
  Future<void> liberar() async {
    _preparo = null;
    await _protegido(_ponte.audioRelease, false);
  }

  /// Executa [acao] devolvendo [padrao] em qualquer erro.
  Future<T> _protegido<T>(Future<T> Function() acao, T padrao) async {
    try {
      return await acao();
    } catch (_) {
      return padrao;
    }
  }
}
