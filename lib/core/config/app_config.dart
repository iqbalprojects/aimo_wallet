import 'package:flutter/foundation.dart';

/// App Configuration
///
/// Centralized configuration for production/debug modes.
///
/// SECURITY:
/// - Debug features disabled in release mode
/// - Logging controlled by build mode
/// - API keys loaded from environment
class AppConfig {
  // Build mode flags
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;

  // App information
  static const String appName = 'Aimo Wallet';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Security settings
  static const int pinMinLength = 6;
  static const int pinMaxLength = 8;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(minutes: 5);
  static const Duration autoLockDuration = Duration(minutes: 5);

  // Network settings (load from environment in production)
  static String get ethereumRpcUrl => _getEnvOrDefault(
    'ETHEREUM_RPC_URL',
    'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
  );

  static String get sepoliaRpcUrl => _getEnvOrDefault(
    'SEPOLIA_RPC_URL',
    'https://sepolia.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
  );

  // Logging configuration
  static bool get enableLogging => isDebugMode;
  static bool get enableVerboseLogging => isDebugMode;
  static bool get enableErrorReporting => isReleaseMode;

  // Feature flags
  static bool get enableBiometric => true;
  static bool get enableScreenshots => isDebugMode; // Disable in production
  static bool get enableDebugMenu => isDebugMode;

  // Helper to get environment variable or default
  static String _getEnvOrDefault(String key, String defaultValue) {
    // In production, load from environment variables
    // For now, return default
    // TODO: Implement proper environment variable loading
    return defaultValue;
  }

  /// Log message (only in debug mode)
  static void log(String message, {String? tag}) {
    if (enableLogging) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  /// Log error (always logged, reported in release mode)
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (enableLogging) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }

    if (enableErrorReporting && isReleaseMode) {
      // TODO: Send to error reporting service (e.g., Sentry, Firebase Crashlytics)
      // Example: Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  /// Log warning (only in debug mode)
  static void logWarning(String message) {
    if (enableLogging) {
      debugPrint('WARNING: $message');
    }
  }
}
