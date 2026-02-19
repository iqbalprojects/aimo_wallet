import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_error.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/secure_storage_datasource.dart';
import '../models/encrypted_wallet_data.dart';
import '../../../../core/vault/encryption_service.dart';
import '../../../../core/crypto/bip39_service.dart';
import '../../../../core/crypto/key_derivation_service.dart';

/// Wallet Repository Implementation
/// 
/// Responsibility: Implement wallet storage and operations.
/// - Coordinate encryption service and storage
/// - Enforce security constraints
/// - Handle errors gracefully
/// 
/// Security: Never stores plaintext sensitive data
class WalletRepositoryImpl implements WalletRepository {
  final SecureStorageDataSource _storage;
  // ignore: unused_field
  final EncryptionService _encryptionService;
  // ignore: unused_field
  final KeyDerivationService _keyDerivationService;
  // ignore: unused_field
  final Bip39Service _bip39Service;

  WalletRepositoryImpl({
    required SecureStorageDataSource storage,
    required EncryptionService encryptionService,
    required KeyDerivationService keyDerivationService,
    required Bip39Service bip39Service,
  })  : _storage = storage,
        _encryptionService = encryptionService,
        _keyDerivationService = keyDerivationService,
        _bip39Service = bip39Service;

  /// Store encrypted wallet data
  /// 
  /// Encrypts mnemonic with PIN and stores all data as JSON
  // ignore: unused_element
  Future<void> _storeEncryptedWallet(EncryptedWalletData data) async {
    try {
      final jsonString = data.toJsonString();
      await _storage.write(
        SecureStorageDataSource.walletDataKey,
        jsonString,
      );
    } catch (e) {
      if (e is WalletError) rethrow;
      throw WalletError(
        WalletErrorType.storageWriteFailure,
        'Failed to store wallet data',
        details: e.toString(),
      );
    }
  }

  /// Retrieve encrypted wallet data
  /// 
  /// Returns null if no wallet exists
  Future<EncryptedWalletData?> _getEncryptedWallet() async {
    try {
      final jsonString = await _storage.read(
        SecureStorageDataSource.walletDataKey,
      );

      if (jsonString == null) {
        return null;
      }

      return EncryptedWalletData.fromJsonString(jsonString);
    } catch (e) {
      if (e is WalletError) rethrow;
      throw WalletError(
        WalletErrorType.storageReadFailure,
        'Failed to retrieve wallet data',
        details: e.toString(),
      );
    }
  }

  @override
  Future<bool> hasWallet() async {
    try {
      return await _storage.containsKey(
        SecureStorageDataSource.walletDataKey,
      );
    } catch (e) {
      if (e is WalletError) rethrow;
      throw WalletError(
        WalletErrorType.storageReadFailure,
        'Failed to check wallet existence',
        details: e.toString(),
      );
    }
  }

  @override
  Future<void> deleteWallet() async {
    try {
      await _storage.delete(SecureStorageDataSource.walletDataKey);
    } catch (e) {
      if (e is WalletError) rethrow;
      throw WalletError(
        WalletErrorType.storageDeleteFailure,
        'Failed to delete wallet',
        details: e.toString(),
      );
    }
  }

  @override
  Future<Wallet> createWallet(String mnemonic, String pin) async {
    throw UnimplementedError('Will be implemented in task 8.1');
  }

  @override
  Future<Wallet> importWallet(String mnemonic, String pin) async {
    throw UnimplementedError('Will be implemented in task 8.5');
  }

  @override
  Future<Wallet> unlockWallet(String pin) async {
    throw UnimplementedError('Will be implemented in task 8.7');
  }

  @override
  Future<String?> getWalletAddress() async {
    try {
      final encryptedWallet = await _getEncryptedWallet();
      return encryptedWallet?.address;
    } catch (e) {
      if (e is WalletError) rethrow;
      throw WalletError(
        WalletErrorType.storageReadFailure,
        'Failed to get wallet address',
        details: e.toString(),
      );
    }
  }

  @override
  Future<String> exportMnemonic(String pin) async {
    throw UnimplementedError('Will be implemented in task 8.12');
  }

  @override
  Future<bool> verifyBackup(String enteredMnemonic, String pin) async {
    throw UnimplementedError('Will be implemented in task 8.14');
  }
}
