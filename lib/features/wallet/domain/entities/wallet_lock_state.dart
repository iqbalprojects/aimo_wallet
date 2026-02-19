/// Wallet Lock State
/// 
/// Represents the current lock state of the wallet.
enum WalletLockState {
  /// Wallet is locked - requires authentication
  locked,

  /// Wallet is unlocked - can perform operations
  unlocked,
}

/// Wallet Lock Configuration
/// 
/// Configuration for auto-lock behavior.
class WalletLockConfig {
  /// Auto-lock timeout in seconds
  /// Default: 5 minutes (300 seconds)
  final int autoLockTimeoutSeconds;

  /// Lock when app moves to background
  /// Default: true
  final bool lockOnBackground;

  /// Enable biometric authentication
  /// Default: false (requires setup)
  final bool biometricEnabled;

  const WalletLockConfig({
    this.autoLockTimeoutSeconds = 300, // 5 minutes
    this.lockOnBackground = true,
    this.biometricEnabled = false,
  });

  WalletLockConfig copyWith({
    int? autoLockTimeoutSeconds,
    bool? lockOnBackground,
    bool? biometricEnabled,
  }) {
    return WalletLockConfig(
      autoLockTimeoutSeconds:
          autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
