/// Keychain Service (iOS Keychain / Android KeyStore wrapper)
/// 
/// Responsibility: Platform-specific secure storage.
/// - Store encrypted data in platform keychain
/// - Retrieve encrypted data
/// - Delete data
/// 
/// Security: Uses flutter_secure_storage for platform abstraction
abstract class KeychainService {
  /// Store value in keychain
  Future<void> store(String key, String value);

  /// Retrieve value from keychain
  Future<String?> retrieve(String key);

  /// Delete value from keychain
  Future<void> delete(String key);

  /// Check if key exists
  Future<bool> contains(String key);

  /// Clear all data
  Future<void> clear();
}
