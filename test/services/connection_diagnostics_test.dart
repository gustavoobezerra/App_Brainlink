import 'package:brainlink_app/services/connection_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('descreve o estado do aparelho em português', () {
    final diagnostics = ConnectionDiagnostics();

    final texto = diagnostics.compose(
      appVersion: '1.3.1',
      device: const {
        'manufacturer': 'Samsung',
        'model': 'SM-A546E',
        'androidRelease': '14',
        'sdkInt': 34,
        'bluetoothEnabled': true,
        'locationServiceEnabled': false,
        'permissionScan': true,
        'permissionConnect': true,
        'permissionLocation': false,
        'bondedCount': 2,
        'bondedNames': 'BrainLink Lite, Fone',
      },
    );

    expect(texto, contains('Versão do app: 1.3.1'));
    expect(texto, contains('Samsung SM-A546E'));
    expect(texto, contains('Android: 14 (API 34)'));
    // O que estiver negado precisa saltar aos olhos de quem lê.
    expect(texto, contains('Localização do sistema ligada: NÃO'));
    expect(texto, contains('Localização: NÃO'));
    expect(texto, contains('Buscar Bluetooth: sim'));
    expect(texto, contains('BrainLink Lite'));
    expect(texto, contains('Nenhum evento registrado nesta sessão.'));
  });

  test('preserva a ordem dos eventos registrados', () {
    final diagnostics = ConnectionDiagnostics();

    diagnostics.record('busca', 'iniciada');
    diagnostics.record('erro', 'Ative a Localização do Android.');
    diagnostics.record('conexão', 'falhou: tempo esgotado');

    final texto = diagnostics.compose(appVersion: '1.3.1');
    final posicaoBusca = texto.indexOf('busca: iniciada');
    final posicaoErro = texto.indexOf('Ative a Localização do Android.');
    final posicaoConexao = texto.indexOf('falhou: tempo esgotado');

    expect(posicaoBusca, greaterThan(-1));
    expect(posicaoBusca, lessThan(posicaoErro));
    expect(posicaoErro, lessThan(posicaoConexao));
  });

  test('descarta os eventos mais antigos ao encher', () {
    final diagnostics = ConnectionDiagnostics(capacity: 3);

    for (var indice = 1; indice <= 5; indice++) {
      diagnostics.record('estado', 'evento $indice');
    }

    expect(diagnostics.events, hasLength(3));
    expect(diagnostics.events.first.detail, 'evento 3');
    expect(diagnostics.events.last.detail, 'evento 5');
  });

  test('avisa quando o Android não devolve estado algum', () {
    final texto = ConnectionDiagnostics().compose(appVersion: '1.3.1');

    expect(texto, contains('Não foi possível ler o estado do Android.'));
  });

  test('sinaliza permissão de conexão ausente na lista de pareados', () {
    final texto = ConnectionDiagnostics().compose(
      appVersion: '1.3.1',
      device: const {'bondedCount': -1},
    );

    expect(texto, contains('Indisponível sem a permissão de conexão.'));
  });
}
