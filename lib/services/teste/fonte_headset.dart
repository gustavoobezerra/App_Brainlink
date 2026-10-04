import 'dart:async';

import '../../data/models/raw_batch.dart';
import '../../native/brainlink_bridge.dart';
import '../../ui/screens/home_screen.dart'
    show ConnectableDevice, DeviceDiscoveryGateway, NativeBrainLinkGateway;
import 'fonte_sinal.dart';

/// Nomes anunciados pelo aparelho: `BrainLink_Lite` e `BrainLink_pro`.
bool _ehBrainLink(String nome) =>
    nome.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '').contains('brainlink');

/// EEG do BrainLink real, por Bluetooth Clássico.
///
/// O `EventChannel` do EEG bruto aceita um ouvinte só: cada inscrição nova
/// substitui a anterior e qualquer cancelamento desliga o envio. Por isso a
/// fonte assina [lotesBrutos] uma única vez (no primeiro ouvinte de [lotes]) e
/// redistribui os lotes; [dispose] cancela essa assinatura sem desconectar.
class FonteHeadset implements FonteSinal {
  factory FonteHeadset({
    BrainLinkBridge? ponte,
    DeviceDiscoveryGateway? gateway,
    Stream<RawBatch>? lotesBrutos,
  }) {
    final ponteEfetiva = ponte ?? BrainLinkBridge();
    return FonteHeadset._(
      ponteEfetiva,
      gateway ?? NativeBrainLinkGateway(ponteEfetiva),
      lotesBrutos ?? ponteEfetiva.rawDataStream,
    );
  }

  FonteHeadset._(this._ponte, this._gateway, this._lotesBrutos)
      : _estado = _ponte.isConnected
            ? EstadoConexao.conectado
            : EstadoConexao.desconectado {
    _lotes = StreamController<RawBatch>.broadcast(onListen: _assinarLotes);
    _assinaturaConexao =
        _ponte.connectionStateStream.listen(_aoMudarConexaoNativa);
  }

  final BrainLinkBridge _ponte;
  final DeviceDiscoveryGateway _gateway;
  final Stream<RawBatch> _lotesBrutos;

  late final StreamController<RawBatch> _lotes;
  final StreamController<EstadoConexao> _conexao =
      StreamController<EstadoConexao>.broadcast();
  StreamSubscription<RawBatch>? _assinaturaLotes;
  late final StreamSubscription<bool> _assinaturaConexao;

  EstadoConexao _estado;
  DispositivoSinal? _ultimo;
  bool _conectando = false;
  bool _descartada = false;

  @override
  bool get simulada => false;

  @override
  Stream<RawBatch> get lotes => _lotes.stream;

  @override
  Stream<int> get qualidade => _ponte.signalQualityStream;

  @override
  Stream<EstadoConexao> get conexao => _conexao.stream;

  @override
  EstadoConexao get estadoConexao => _estado;

  /// Única assinatura do canal bruto, mantida até [dispose].
  void _assinarLotes() {
    if (_descartada || _assinaturaLotes != null) return;
    _assinaturaLotes = _lotesBrutos.listen(
      (lote) {
        if (!_lotes.isClosed) _lotes.add(lote);
      },
      onError: (Object erro, StackTrace pilha) {
        if (!_lotes.isClosed) _lotes.addError(erro, pilha);
      },
    );
  }

  void _aoMudarConexaoNativa(bool conectado) {
    // Durante a conexão o Android relata estados intermediários como `false`.
    if (!conectado && _conectando) return;
    _definirEstado(
      conectado ? EstadoConexao.conectado : EstadoConexao.desconectado,
    );
  }

  void _definirEstado(EstadoConexao estado) {
    if (_estado == estado) return;
    _estado = estado;
    if (!_conexao.isClosed) _conexao.add(estado);
  }

  @override
  Future<ResultadoAutoConexao> autoConectar() async {
    if (_ponte.isConnected) {
      _definirEstado(EstadoConexao.conectado);
      return const AutoConectado();
    }
    final pareados = [
      for (final aparelho in await _ponte.getPairedDevices())
        if (aparelho.address.isNotEmpty)
          DispositivoSinal(
            id: aparelho.address,
            nome: aparelho.name,
            pareado: true,
          ),
    ];
    final brainLinks = pareados.where((d) => _ehBrainLink(d.nome)).toList();
    if (brainLinks.length == 1) {
      try {
        await conectar(brainLinks.single);
        return const AutoConectado();
      } catch (erro) {
        return AutoFalhou(_mensagem(erro));
      }
    }
    return AutoEscolher([
      ...brainLinks,
      ...pareados.where((d) => !_ehBrainLink(d.nome)),
    ]);
  }

  @override
  Future<List<DispositivoSinal>> buscar() async {
    final aparelhos = await _gateway.listDevices();
    return [
      for (final aparelho in aparelhos)
        DispositivoSinal(
          id: aparelho.id,
          nome: aparelho.name,
          pareado: aparelho.isPaired,
        ),
    ];
  }

  @override
  Future<void> conectar(DispositivoSinal dispositivo) async {
    _ultimo = dispositivo;
    _conectando = true;
    _definirEstado(EstadoConexao.conectando);
    try {
      await _gateway.connect(
        ConnectableDevice(
          dispositivo.id,
          dispositivo.nome,
          isPaired: dispositivo.pareado,
        ),
      );
      _conectando = false;
      _definirEstado(EstadoConexao.conectado);
    } catch (erro) {
      _conectando = false;
      _definirEstado(
        _ponte.isConnected
            ? EstadoConexao.conectado
            : EstadoConexao.desconectado,
      );
      throw StateError(_mensagem(erro));
    }
  }

  @override
  Future<bool> reconectar() async {
    final ultimo = _ultimo;
    if (ultimo == null) return false;
    try {
      await conectar(ultimo);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> desconectar() async {
    await _ponte.disconnect();
    _definirEstado(EstadoConexao.desconectado);
  }

  /// Cancela a assinatura do EEG bruto e fecha os streams. O headset continua
  /// conectado para a tela seguinte.
  @override
  Future<void> dispose() async {
    if (_descartada) return;
    _descartada = true;
    final assinatura = _assinaturaLotes;
    _assinaturaLotes = null;
    await assinatura?.cancel();
    await _assinaturaConexao.cancel();
    await _lotes.close();
    await _conexao.close();
  }

  String _mensagem(Object erro) => switch (erro) {
        StateError(:final message) => message,
        TimeoutException() => 'O BrainLink não respondeu a tempo.',
        _ => erro.toString(),
      };
}
