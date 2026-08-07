import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Registra eventos de desenvolvimento sem expor mensagens em builds release.
class Logger {
  const Logger(this.name);

  final String name;

  void info(String message) => _log('INFO', message);

  void warning(String message) => _log('WARN', message);

  void debug(String message) => _log('DEBUG', message);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kReleaseMode) {
      return;
    }

    developer.log(
      message,
      name: '$level/$name',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
