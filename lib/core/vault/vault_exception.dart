/// Vault Exception Types
enum VaultExceptionType {
  /// Encryption operation failed
  encryptionFailed,

  /// Decryption operation failed (wrong PIN or corrupted data)
  decryptionFailed,

  /// Storage operation failed (read/write error)
  storageFailed,

  /// Vault is empty (no wallet stored)
  vaultEmpty,

  /// Vault already contains a wallet
  vaultNotEmpty,

  /// Invalid PIN format
  invalidPin,

  /// Data corruption detected
  dataCorrupted,

  /// Key derivation failed
  keyDerivationFailed,
}

/// Vault Exception
/// 
/// Represents errors in vault operations.
/// 
/// Security: Error messages never contain sensitive data
/// (mnemonics, private keys, PINs, or encryption keys)
class VaultException implements Exception {
  final VaultExceptionType type;
  final String message;
  final String? details;
  final dynamic originalError;

  VaultException({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
  });

  /// Create encryption failure exception
  factory VaultException.encryptionFailed([String? details]) {
    return VaultException(
      type: VaultExceptionType.encryptionFailed,
      message: 'Failed to encrypt data',
      details: details,
    );
  }

  /// Create decryption failure exception
  factory VaultException.decryptionFailed([String? details]) {
    return VaultException(
      type: VaultExceptionType.decryptionFailed,
      message: 'Failed to decrypt data. Wrong PIN or corrupted data.',
      details: details,
    );
  }

  /// Create storage failure exception
  factory VaultException.storageFailed([String? details]) {
    return VaultException(
      type: VaultExceptionType.storageFailed,
      message: 'Storage operation failed',
      details: details,
    );
  }

  /// Create vault empty exception
  factory VaultException.vaultEmpty() {
    return VaultException(
      type: VaultExceptionType.vaultEmpty,
      message: 'Vault is empty. No wallet stored.',
    );
  }

  /// Create vault not empty exception
  factory VaultException.vaultNotEmpty() {
    return VaultException(
      type: VaultExceptionType.vaultNotEmpty,
      message: 'Vault already contains a wallet. Delete existing wallet first.',
    );
  }

  /// Create invalid PIN exception
  factory VaultException.invalidPin(String reason) {
    return VaultException(
      type: VaultExceptionType.invalidPin,
      message: 'Invalid PIN format',
      details: reason,
    );
  }

  /// Create data corruption exception
  factory VaultException.dataCorrupted([String? details]) {
    return VaultException(
      type: VaultExceptionType.dataCorrupted,
      message: 'Stored data is corrupted',
      details: details,
    );
  }

  /// Create key derivation failure exception
  factory VaultException.keyDerivationFailed([String? details]) {
    return VaultException(
      type: VaultExceptionType.keyDerivationFailed,
      message: 'Failed to derive encryption key from PIN',
      details: details,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('VaultException: $message');
    if (details != null) {
      buffer.write(' ($details)');
    }
    return buffer.toString();
  }
}
