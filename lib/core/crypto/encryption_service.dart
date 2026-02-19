import 'dart:typed_data';

/// Encrypted Data Container
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List? authTag; // For GCM mode

  EncryptedData({
    required this.ciphertext,
    required this.iv,
    this.authTag,
  });
}

/// Encryption Service using AES-256-GCM
/// 
/// Responsibility: Encrypt and decrypt sensitive data.
/// - Encrypt mnemonics using AES-256-GCM with PIN-derived keys
/// - Decrypt mnemonics for authentication
/// - Derive encryption keys from PINs using PBKDF2
/// - Generate cryptographically secure salts and IVs
/// 
/// Security: Uses authenticated encryption (GCM), 100k+ PBKDF2 iterations
abstract class EncryptionService {
  /// Encrypt plaintext using AES-256-GCM
  EncryptedData encrypt(String plaintext, Uint8List key);

  /// Decrypt ciphertext using AES-256-GCM
  /// Throws exception if authentication fails
  String decrypt(EncryptedData encrypted, Uint8List key);

  /// Derive encryption key from PIN using PBKDF2-SHA256
  /// Uses minimum 100,000 iterations, outputs 32-byte key
  Uint8List deriveKeyFromPin(String pin, Uint8List salt, {int iterations = 100000});

  /// Generate cryptographically secure random salt (32 bytes)
  Uint8List generateSalt({int length = 32});

  /// Generate cryptographically secure random IV (12 bytes for GCM)
  Uint8List generateIV({int length = 12});
}
