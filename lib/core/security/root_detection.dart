import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Root/Jailbreak Detection
/// 
/// Detects if device is rooted (Android) or jailbroken (iOS).
/// 
/// SECURITY:
/// - Warns users about security risks on rooted devices
/// - Optionally blocks app usage on compromised devices
/// - Detects common root/jailbreak indicators
/// 
/// Platform Support:
/// - Android: Checks for su binary, root management apps, test-keys
/// - iOS: Checks for Cydia, suspicious file paths, sandbox violations
/// 
/// Usage:
/// ```dart
/// final isRooted = await RootDetection.isDeviceRooted();
/// if (isRooted) {
///   // Show warning or block app
/// }
/// ```
class RootDetection {
  static const MethodChannel _channel = MethodChannel('aimo_wallet/security');

  /// Check if device is rooted/jailbroken
  /// 
  /// Returns true if device is compromised.
  static Future<bool> isDeviceRooted() async {
    if (kDebugMode) {
      // Skip check in debug mode
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isDeviceRooted');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check root status: $e');
      // Assume not rooted if check fails
      return false;
    }
  }

  /// Get detailed root detection information
  /// 
  /// Returns map with detection details:
  /// - isRooted: bool
  /// - detectionMethod: String (e.g., "su_binary", "cydia_detected")
  /// - riskLevel: String ("low", "medium", "high")
  static Future<Map<String, dynamic>> getDetectionDetails() async {
    if (kDebugMode) {
      return {
        'isRooted': false,
        'detectionMethod': 'debug_mode',
        'riskLevel': 'none',
      };
    }

    try {
      final result = await _channel.invokeMethod<Map>('getRootDetectionDetails');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Failed to get root detection details: $e');
      return {
        'isRooted': false,
        'detectionMethod': 'check_failed',
        'riskLevel': 'unknown',
      };
    }
  }
}

/// Root Detection Result
class RootDetectionResult {
  final bool isRooted;
  final String detectionMethod;
  final RiskLevel riskLevel;

  RootDetectionResult({
    required this.isRooted,
    required this.detectionMethod,
    required this.riskLevel,
  });

  factory RootDetectionResult.fromMap(Map<String, dynamic> map) {
    return RootDetectionResult(
      isRooted: map['isRooted'] as bool? ?? false,
      detectionMethod: map['detectionMethod'] as String? ?? 'unknown',
      riskLevel: _parseRiskLevel(map['riskLevel'] as String?),
    );
  }

  static RiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.unknown;
    }
  }
}

enum RiskLevel {
  none,
  low,
  medium,
  high,
  unknown,
}
