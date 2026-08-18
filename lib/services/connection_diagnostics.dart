import 'dart:io';

/// Um acontecimento do caminho de conexão, com o instante em que ocorreu.
class DiagnosticEvent {
  const DiagnosticEvent(this.moment, this.category, this.detail);

  final DateTime moment;
  final String category;
  final String detail;
}

/// Histórico do que aconteceu entre o app e o Android durante a conexão.
///
/// Existe para o teste em campo: sem o rastro, uma falha no aparelho de outra
/// pessoa chega apenas como "não conectou". O [Logger] do projeto é silencioso
/// em build release justamente por não ser feito para isso.
class ConnectionDiagnostics {
  ConnectionDiagnostics({this.capacity = 200});

  /// Quantidade máxima de eventos guardados; os mais antigos são descartados.
  final int capacity;

  final List<DiagnosticEvent> _events = [];

  List<DiagnosticEvent> get events => List.unmodifiable(_events);

  bool get isEmpty => _events.isEmpty;

  void record(String category, String detail) {
    _events.add(DiagnosticEvent(DateTime.now(), category, detail));
    if (_events.length > capacity) {
      _events.removeRange(0, _events.length - capacity);
    }
  }

  void clear() => _events.clear();

  /// Monta o relatório que a pessoa que testa envia de volta.
  String compose({
    required String appVersion,
    Map<String, Object?> device = const {},
  }) {
    final buffer = StringBuffer()
      ..writeln('Diagnóstico de conexão — Projeto BrainLink')
      ..writeln('Gerado em ${_timestamp(DateTime.now())}')
      ..writeln('Versão do app: $appVersion')
      ..writeln();

    buffer.writeln('== Aparelho ==');
    if (device.isEmpty) {
      buffer.writeln('Não foi possível ler o estado do Android.');
    } else {
      buffer
        ..writeln('Modelo: ${device['manufacturer']} ${device['model']}')
        ..writeln(
            'Android: ${device['androidRelease']} (API ${device['sdkInt']})')
        ..writeln('Bluetooth ligado: ${_yesNo(device['bluetoothEnabled'])}')
        ..writeln(
            'Localização do sistema ligada: ${_yesNo(device['locationServiceEnabled'])}')
        ..writeln();
      buffer
        ..writeln('== Permissões ==')
        ..writeln('Buscar Bluetooth: ${_yesNo(device['permissionScan'])}')
        ..writeln('Conectar Bluetooth: ${_yesNo(device['permissionConnect'])}')
        ..writeln('Localização: ${_yesNo(device['permissionLocation'])}')
        ..writeln();

      final bonded = device['bondedCount'];
      buffer.writeln('== Aparelhos pareados ==');
      if (bonded is int && bonded >= 0) {
        buffer.writeln('Total: $bonded');
        final names = device['bondedNames'];
        if (names is String && names.isNotEmpty) {
          buffer.writeln('Nomes: $names');
        }
      } else {
        buffer.writeln('Indisponível sem a permissão de conexão.');
      }
    }

    buffer
      ..writeln()
      ..writeln('== Eventos ==');
    if (_events.isEmpty) {
      buffer.writeln('Nenhum evento registrado nesta sessão.');
    } else {
      for (final event in _events) {
        buffer.writeln(
            '${_timestamp(event.moment)}  ${event.category}: ${event.detail}');
      }
    }
    return buffer.toString();
  }

  /// Grava o relatório e devolve o arquivo pronto para compartilhar.
  Future<File> write(
    Directory directory, {
    required String appVersion,
    Map<String, Object?> device = const {},
  }) async {
    await directory.create(recursive: true);
    final stamp = _timestamp(DateTime.now()).replaceAll(RegExp('[^0-9]'), '');
    final file = File(
      '${directory.path}${Platform.pathSeparator}diagnostico-$stamp.txt',
    );
    await file.writeAsString(
      compose(appVersion: appVersion, device: device),
    );
    return file;
  }

  static String _yesNo(Object? value) {
    if (value is bool) return value ? 'sim' : 'NÃO';
    return 'desconhecido';
  }

  static String _timestamp(DateTime moment) {
    String pad(int value, [int width = 2]) =>
        value.toString().padLeft(width, '0');
    return '${moment.year}-${pad(moment.month)}-${pad(moment.day)} '
        '${pad(moment.hour)}:${pad(moment.minute)}:${pad(moment.second)}.'
        '${pad(moment.millisecond, 3)}';
  }
}
