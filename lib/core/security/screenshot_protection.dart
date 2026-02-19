import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Screenshot Protection
/// 
/// Prevents screenshots and screen recording on sensitive screens.
/// 
/// SECURITY:
/// - Prevents screenshots of mnemonic backup screen
/// - Prevents screenshots of PIN entry screens
/// - Prevents screenshots of private key displays
/// 
/// Platform Support:
/// - Android: Uses FLAG_SECURE
/// - iOS: Requires native implementation
/// 
/// Usage:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   ScreenshotProtection.enable();
/// }
/// 
/// @override
/// void dispose() {
///   ScreenshotProtection.disable();
///   super.dispose();
/// }
/// ```
class ScreenshotProtection {
  static const MethodChannel _channel = MethodChannel('aimo_wallet/security');

  /// Enable screenshot protection
  /// 
  /// Call this in initState() of sensitive screens.
  static Future<void> enable() async {
    if (kReleaseMode) {
      try {
        await _channel.invokeMethod('enableScreenshotProtection');
      } catch (e) {
        debugPrint('Failed to enable screenshot protection: $e');
      }
    }
  }

  /// Disable screenshot protection
  /// 
  /// Call this in dispose() of sensitive screens.
  static Future<void> disable() async {
    if (kReleaseMode) {
      try {
        await _channel.invokeMethod('disableScreenshotProtection');
      } catch (e) {
        debugPrint('Failed to disable screenshot protection: $e');
      }
    }
  }
}

/// Screenshot Protection Mixin
/// 
/// Convenience mixin for screens that need screenshot protection.
/// 
/// Usage:
/// ```dart
/// class BackupMnemonicScreen extends StatefulWidget {
///   // ...
/// }
/// 
/// class _BackupMnemonicScreenState extends State<BackupMnemonicScreen>
///     with ScreenshotProtectionMixin {
///   // Screenshot protection automatically enabled/disabled
/// }
/// ```
mixin ScreenshotProtectionMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ScreenshotProtection.enable();
  }

  @override
  void dispose() {
    ScreenshotProtection.disable();
    super.dispose();
  }
}
