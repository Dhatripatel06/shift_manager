import 'package:flutter/foundation.dart';

/// Central logging facade. Keeps debug logs out of release builds by default.
class AppLogger {
  AppLogger._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    debugPrint('[Shiftly] $message');
    if (error != null) {
      debugPrint('[Shiftly] error: $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void error(String message, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[Shiftly] $message');
      debugPrint('[Shiftly] error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
