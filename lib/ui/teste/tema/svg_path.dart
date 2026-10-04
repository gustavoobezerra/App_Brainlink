import 'dart:ui';

/// Converte o atributo `d` de um `<path>` SVG em um [Path] do Flutter.
///
/// Cobre os comandos usados nos ícones do protótipo — `M L H V C S Q T A Z`,
/// absolutos e relativos, com repetição implícita — sem depender de pacotes.
/// Arcos usam [Path.arcToPoint], que segue a mesma semântica do SVG
/// (raios corrigidos quando pequenos demais; `sweep-flag = 1` é horário).
Path caminhoSvg(String d) => _AnalisadorCaminho(d).analisar();

class _AnalisadorCaminho {
  _AnalisadorCaminho(this._d);

  final String _d;
  int _i = 0;

  final Path _caminho = Path();
  double _x = 0;
  double _y = 0;
  double _inicioX = 0;
  double _inicioY = 0;

  // Pontos de controle refletidos por S/s e T/t.
  double _controleCubicoX = 0;
  double _controleCubicoY = 0;
  double _controleQuadraticoX = 0;
  double _controleQuadraticoY = 0;
  String _comandoAnterior = '';

  Path analisar() {
    var comando = '';
    while (true) {
      _pularSeparadores();
      if (_i >= _d.length) break;
      final caractere = _d[_i];
      if (_ehComando(caractere)) {
        comando = caractere;
        _i++;
      } else if (comando.isEmpty) {
        throw FormatException('Caminho SVG sem comando inicial', _d, _i);
      }
      comando = _executar(comando);
    }
    return _caminho;
  }

  /// Executa uma ocorrência de [comando] e devolve o comando implícito para
  /// os números seguintes (depois de um `M`, pares extras viram `L`).
  String _executar(String comando) {
    final relativo = comando.toLowerCase() == comando;
    final baseX = relativo ? _x : 0.0;
    final baseY = relativo ? _y : 0.0;
    var proximo = comando;
    switch (comando.toUpperCase()) {
      case 'M':
        _x = baseX + _numero();
        _y = baseY + _numero();
        _caminho.moveTo(_x, _y);
        _inicioX = _x;
        _inicioY = _y;
        proximo = relativo ? 'l' : 'L';
      case 'L':
        _x = baseX + _numero();
        _y = baseY + _numero();
        _caminho.lineTo(_x, _y);
      case 'H':
        _x = baseX + _numero();
        _caminho.lineTo(_x, _y);
      case 'V':
        _y = baseY + _numero();
        _caminho.lineTo(_x, _y);
      case 'C':
        final x1 = baseX + _numero();
        final y1 = baseY + _numero();
        final x2 = baseX + _numero();
        final y2 = baseY + _numero();
        final x = baseX + _numero();
        final y = baseY + _numero();
        _caminho.cubicTo(x1, y1, x2, y2, x, y);
        _controleCubicoX = x2;
        _controleCubicoY = y2;
        _x = x;
        _y = y;
      case 'S':
        final refletir =
            _comandoAnterior.isNotEmpty && 'CcSs'.contains(_comandoAnterior);
        final x1 = refletir ? 2 * _x - _controleCubicoX : _x;
        final y1 = refletir ? 2 * _y - _controleCubicoY : _y;
        final x2 = baseX + _numero();
        final y2 = baseY + _numero();
        final x = baseX + _numero();
        final y = baseY + _numero();
        _caminho.cubicTo(x1, y1, x2, y2, x, y);
        _controleCubicoX = x2;
        _controleCubicoY = y2;
        _x = x;
        _y = y;
      case 'Q':
        final x1 = baseX + _numero();
        final y1 = baseY + _numero();
        final x = baseX + _numero();
        final y = baseY + _numero();
        _caminho.quadraticBezierTo(x1, y1, x, y);
        _controleQuadraticoX = x1;
        _controleQuadraticoY = y1;
        _x = x;
        _y = y;
      case 'T':
        final refletir =
            _comandoAnterior.isNotEmpty && 'QqTt'.contains(_comandoAnterior);
        final x1 = refletir ? 2 * _x - _controleQuadraticoX : _x;
        final y1 = refletir ? 2 * _y - _controleQuadraticoY : _y;
        final x = baseX + _numero();
        final y = baseY + _numero();
        _caminho.quadraticBezierTo(x1, y1, x, y);
        _controleQuadraticoX = x1;
        _controleQuadraticoY = y1;
        _x = x;
        _y = y;
      case 'A':
        final rx = _numero().abs();
        final ry = _numero().abs();
        final rotacao = _numero();
        final arcoGrande = _bandeira();
        final horario = _bandeira();
        final x = baseX + _numero();
        final y = baseY + _numero();
        if (rx == 0 || ry == 0) {
          _caminho.lineTo(x, y);
        } else {
          _caminho.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rotacao,
            largeArc: arcoGrande,
            clockwise: horario,
          );
        }
        _x = x;
        _y = y;
      case 'Z':
        _caminho.close();
        _x = _inicioX;
        _y = _inicioY;
      default:
        throw FormatException('Comando SVG não suportado: $comando', _d, _i);
    }
    _comandoAnterior = comando;
    return proximo;
  }

  static bool _ehComando(String c) => 'MmLlHhVvCcSsQqTtAaZz'.contains(c);

  void _pularSeparadores() {
    while (_i < _d.length) {
      final c = _d.codeUnitAt(_i);
      // espaço, vírgula, tabulação, quebras de linha
      if (c == 0x20 || c == 0x2C || c == 0x09 || c == 0x0A || c == 0x0D) {
        _i++;
      } else {
        break;
      }
    }
  }

  bool _bandeira() {
    _pularSeparadores();
    if (_i >= _d.length) {
      throw FormatException('Bandeira de arco ausente', _d, _i);
    }
    final c = _d[_i];
    if (c != '0' && c != '1') {
      throw FormatException('Bandeira de arco inválida', _d, _i);
    }
    _i++;
    return c == '1';
  }

  double _numero() {
    _pularSeparadores();
    final inicio = _i;
    if (_i < _d.length && (_d[_i] == '-' || _d[_i] == '+')) _i++;
    var digitos = false;
    while (_i < _d.length && _ehDigito(_d.codeUnitAt(_i))) {
      _i++;
      digitos = true;
    }
    if (_i < _d.length && _d[_i] == '.') {
      _i++;
      while (_i < _d.length && _ehDigito(_d.codeUnitAt(_i))) {
        _i++;
        digitos = true;
      }
    }
    if (!digitos) {
      throw FormatException('Número esperado no caminho SVG', _d, inicio);
    }
    if (_i < _d.length && (_d[_i] == 'e' || _d[_i] == 'E')) {
      final marca = _i;
      _i++;
      if (_i < _d.length && (_d[_i] == '-' || _d[_i] == '+')) _i++;
      var expoente = false;
      while (_i < _d.length && _ehDigito(_d.codeUnitAt(_i))) {
        _i++;
        expoente = true;
      }
      if (!expoente) _i = marca;
    }
    return double.parse(_d.substring(inicio, _i));
  }

  static bool _ehDigito(int c) => c >= 0x30 && c <= 0x39;
}
