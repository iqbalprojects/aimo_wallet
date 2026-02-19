/// Wallet Error Types
enum WalletErrorType {
  // Validation Errors
  invalidMnemonicLength,
  invalidMnemonicWords,
  invalidMnemonicChecksum,
  invalidPinFormat,

  // Authentication Errors
  wrongPin,
  walletLocked,
  authenticationRequired,

  // Storage Errors
  storageReadFailure,
  storageWriteFailure,
  storageDeleteFailure,
  dataCorrupted,

  // Constraint Errors
  walletAlreadyExists,
  walletNotFound,

  // Cryptographic Errors
  encryptionFailure,
  decryptionFailure,
  keyDerivationFailure,

  // System Errors
  insufficientEntropy,
  platformNotSupported,
}

/// Wallet Error Exception
/// 
/// Responsibility: Represent errors in wallet operations.
/// - Type: Categorize error for proper handling
/// - Message: User-friendly error description
/// - Details: Technical details for debugging (never contains sensitive data)
/// 
/// Security: Error messages never contain mnemonics, private keys, or PINs
class WalletError implements Exception {
  final WalletErrorType type;
  final String message;
  final String? details;

  WalletError(this.type, this.message, {this.details});

  @override
  String toString() => 'WalletError: $message';
}
