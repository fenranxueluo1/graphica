import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper around haptics so desktop and unsupported platforms stay quiet.
class Haptics {
  const Haptics._();

  static void tap() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick().catchError((Object _) {});
  }

  static void impact() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact().catchError((Object _) {});
  }
}
