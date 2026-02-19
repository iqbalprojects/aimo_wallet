import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/wallet_error.dart';
import 'secure_storage_datasource.dart';

/// Secure Storage Data Source Implementation
/// 
/// Responsibility: Implement secure storage using flutter_secure_storage.
/// - Wraps flutter_secure_storage
/// - Handles platform exceptions
/// - Provides error handling
/// 
/// Security: Uses platform-specific secure storage
/// - iOS: Keychain
/// - Android: KeyStore
class SecureStorageDataSourceImpl implements SecureStorageDataSource {
  final FlutterSecureStorage _storage;

  SecureStorageDataSourceImpl(this._storage);

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw WalletError(
        WalletErrorType.storageWriteFailure,
        'Failed to write to secure storage',
        details: e.toString(),
      );
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw WalletError(
        WalletErrorType.storageReadFailure,
        'Failed to read from secure storage',
        details: e.toString(),
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw WalletError(
        WalletErrorType.storageReadFailure,
        'Failed to check key existence in secure storage',
        details: e.toString(),
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw WalletError(
        WalletErrorType.storageDeleteFailure,
        'Failed to delete from secure storage',
        details: e.toString(),
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw WalletError(
        WalletErrorType.storageDeleteFailure,
        'Failed to delete all from secure storage',
        details: e.toString(),
      );
    }
  }
}
