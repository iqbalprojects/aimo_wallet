/// Secure Storage Data Source Interface
/// 
/// Responsibility: Abstract interface for secure storage operations.
/// - Store encrypted wallet data
/// - Retrieve encrypted wallet data
/// - Check wallet existence
/// - Delete wallet data
/// 
/// Security: Uses flutter_secure_storage (Keychain/KeyStore)
abstract class SecureStorageDataSource {
  /// Storage key for wallet data
  static const String walletDataKey = 'wallet_data';

  /// Store encrypted wallet data as JSON string
  Future<void> write(String key, String value);

  /// Read encrypted wallet data
  Future<String?> read(String key);

  /// Check if key exists
  Future<bool> containsKey(String key);

  /// Delete data for key
  Future<void> delete(String key);

  /// Delete all data
  Future<void> deleteAll();
}
