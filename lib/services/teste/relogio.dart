import 'dart:developer' as developer;

import 'package:flutter/gestures.dart';

/// Relógio único para estímulos, toques e EEG (ADR-005).
abstract interface class Relogio {
  /// Agora, em nanossegundos monotônicos.
  int agoraNanos();

  /// Instante do toque [evento] no mesmo relógio.
  int nanosDoToque(PointerEvent evento);
}

/// Relógio monotônico do aparelho (`CLOCK_MONOTONIC`).
///
/// No Android, `System.nanoTime()` (início dos sons e fechamento dos lotes de
/// EEG), o horário dos toques entregue ao Flutter (`MotionEvent`, em
/// `uptimeMillis`) e o relógio de linha do tempo do Dart usam essa mesma
/// base. [sincronizar] confere a base com a camada nativa e corrige um
/// eventual deslocamento.
class RelogioMonotonico implements Relogio {
  int _deslocamentoNanos = 0;

  /// Diferença tolerada entre o toque e "agora": acima disso a base do toque
  /// é considerada diferente e o instante de chegada é usado.
  static const int _toleranciaToqueNanos = 5 * 1000 * 1000 * 1000;

  @override
  int agoraNanos() => developer.Timeline.now * 1000 + _deslocamentoNanos;

  @override
  int nanosDoToque(PointerEvent evento) {
    final agora = agoraNanos();
    final toque = evento.timeStamp.inMicroseconds * 1000;
    if (toque <= 0 || (agora - toque).abs() > _toleranciaToqueNanos) {
      return agora;
    }
    return toque;
  }

  /// Ajusta a base com o relógio nativo, se [nativoNanos] responder.
  ///
  /// Pequenas diferenças são latência do canal e são ignoradas; só um
  /// deslocamento grande (bases diferentes) é corrigido.
  Future<void> sincronizar(Future<int?> Function() nativoNanos) async {
    final antes = developer.Timeline.now * 1000;
    final nativo = await nativoNanos();
    final depois = developer.Timeline.now * 1000;
    if (nativo == null) return;
    final diferenca = nativo - (antes + depois) ~/ 2;
    _deslocamentoNanos = diferenca.abs() > 1000 * 1000 * 1000 ? diferenca : 0;
  }
}
