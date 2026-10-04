import 'package:brainlink_app/services/teste/estimulos.dart';
import 'package:brainlink_app/services/teste/relogio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relógio controlado pelo teste; avance junto com o tempo falso do Flutter.
class RelogioManual implements Relogio {
  int _agora = 1000000000000;

  void avancar(Duration duracao) => _agora += duracao.inMicroseconds * 1000;

  @override
  int agoraNanos() => _agora;

  @override
  int nanosDoToque(PointerEvent evento) => _agora;
}

/// Avança [duracao] em passos, mantendo relógio e temporizadores juntos.
Future<void> passar(
  WidgetTester tester,
  RelogioManual relogio,
  Duration duracao, {
  Duration passo = const Duration(milliseconds: 50),
}) async {
  var restante = duracao;
  while (restante > Duration.zero) {
    final agora = restante < passo ? restante : passo;
    relogio.avancar(agora);
    await tester.pump(agora);
    restante -= agora;
  }
}

/// Saídas físicas falsas: registram cada chamada.
class EstimulosFalsos implements EstimulosTeste {
  EstimulosFalsos(this.relogio, {this.volume = const VolumeMidia(12, 15)});

  final RelogioManual relogio;
  VolumeMidia? volume;
  final List<SomTeste> sons = [];
  final List<VibracaoTeste> vibracoes = [];
  final List<bool> telaAcesa = [];

  @override
  Future<void> preparar() async {}

  @override
  Future<int?> tocar(SomTeste som) async {
    sons.add(som);
    return relogio.agoraNanos();
  }

  @override
  Future<void> vibrar(VibracaoTeste vibracao) async => vibracoes.add(vibracao);

  @override
  Future<void> manterTelaAcesa(bool ligado) async => telaAcesa.add(ligado);

  @override
  Future<VolumeMidia?> volumeMidia() async => volume;

  @override
  Future<int?> agoraNanos() async => relogio.agoraNanos();

  @override
  Future<void> liberar() async {}
}
