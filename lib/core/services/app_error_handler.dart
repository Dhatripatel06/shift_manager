import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// Registers crash-safe global error hooks for Flutter and Dart zones.
class AppErrorHandler {
  AppErrorHandler._();

  static void register() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.error('Uncaught platform error', error, stackTrace);
      return true;
    };
  }

  static void runGuarded(FutureOr<void> Function() body) {
    runZonedGuarded(
      body,
      (error, stackTrace) {
        AppLogger.error('Uncaught zone error', error, stackTrace);
      },
    );
  }
}
