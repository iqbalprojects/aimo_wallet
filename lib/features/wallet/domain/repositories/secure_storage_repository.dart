import 'dart:typed_data';

/// Secure Storage Repository Interface
/// 
/// Responsibility: Abstract interface for secure storage operations.
/// - Store and retrieve encrypted wallet data
/// - Check wallet existence
/// - Delete wallet data
/// 
/// Security: Uses platform-specific secure storage (Keychain/KeyStore)
/// 
/// Note: This is a domain-layer interface. The data layer provides the implementation
/// using flutter_secure_storage or other secure storage mechanisms.
abstract class SecureStorageRepository {
  /// Store encrypted mnemonic
  Future<void> storeEncryptedMnemonic(Uint8List encryptedData);

  /// Store encryption salt
  Future<void> storeSalt(Uint8List salt);

  /// Store initialization vector (IV)
  Future<void> storeIV(Uint8List iv);

  /// Store authentication tag (for GCM mode)
  Future<void> storeAuthTag(Uint8List authTag);

  /// Store wallet address (cached for quick access)
  Future<void> storeAddress(String address);

  /// Retrieve encrypted mnemonic
  Future<Uint8List?> getEncryptedMnemonic();

  /// Retrieve encryption salt
  Future<Uint8List?> getSalt();

  /// Retrieve initialization vector (IV)
  Future<Uint8List?> getIV();

  /// Retrieve authentication tag (for GCM mode)
  Future<Uint8List?> getAuthTag();

  /// Retrieve wallet address
  Future<String?> getAddress();

  /// Check if wallet exists
  Future<bool> hasWallet();

  /// Delete all wallet data
  Future<void> deleteWallet();
}
