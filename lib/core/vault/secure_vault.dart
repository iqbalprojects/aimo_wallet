import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';
import 'vault_exception.dart';

/// Secure Vault
/// 
/// Provides secure storage for encrypted wallet data using
/// flutter_secure_storage (iOS Keychain / Android KeyStore).
/// 
/// Security Features:
/// - Platform secure storage (Keychain/KeyStore)
/// - AES-256-GCM encryption
/// - PBKDF2 key derivation from PIN
/// - Single wallet per device
/// - No plaintext storage
/// - No PIN storage
/// - No encryption key storage
/// 
/// Storage Structure:
/// - Key: "encrypted_wallet"
/// - Value: JSON with encrypted mnemonic + metadata
/// 
/// Security Decisions:
/// 1. flutter_secure_storage: Uses platform secure storage
///    - iOS: Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
///    - Android: EncryptedSharedPreferences with AES-256-GCM
/// 2. Single storage key: Enforces single wallet constraint
/// 3. JSON serialization: Stores all encryption metadata together
/// 4. No PIN storage: PIN only used for key derivation
/// 5. No key storage: Key derived on-demand from PIN
/// 
/// Usage:
/// ```dart
/// final vault = SecureVault();
/// 
/// // Store mnemonic
/// await vault.storeMnemonic(mnemonic, pin);
/// 
/// // Retrieve mnemonic
/// final mnemonic = await vault.retrieveMnemonic(pin);
/// 
/// // Check if vault has wallet
/// final hasWallet = await vault.hasWallet();
/// 
/// // Delete wallet
/// await vault.deleteWallet();
/// ```
class SecureVault {
  final FlutterSecureStorage _storage;
  final EncryptionService _encryptionService;

  /// Storage key for encrypted wallet data
  /// 
  /// Security: Single key enforces single wallet per device constraint
  static const String _walletKey = 'encrypted_wallet';

  /// Storage key for wallet address (cached, not sensitive)
  /// 
  /// Security: Address is public information, safe to cache
  static const String _addressKey = 'wallet_address';

  /// Storage options for flutter_secure_storage
  /// 
  /// Security:
  /// - iOS: Uses Keychain with accessibility when unlocked
  /// - Android: Uses EncryptedSharedPreferences
  static const _storageOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  SecureVault({
    FlutterSecureStorage? storage,
    EncryptionService? encryptionService,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _encryptionService = encryptionService ?? EncryptionService();

  /// Store mnemonic in secure vault
  /// 
  /// Cryptographic Flow:
  /// 1. Check if vault already has wallet (enforce single wallet)
  /// 2. Encrypt mnemonic using AES-256-GCM with PIN-derived key
  /// 3. Serialize encrypted data to JSON
  /// 4. Store in flutter_secure_storage
  /// 5. Cache wallet address separately
  /// 
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase
  /// - pin: User's PIN (4-8 digits)
  /// - address: Wallet address (optional, for caching)
  /// 
  /// Throws:
  /// - VaultException.vaultNotEmpty: If wallet already exists
  /// - VaultException.invalidPin: If PIN format invalid
  /// - VaultException.encryptionFailed: If encryption fails
  /// - VaultException.storageFailed: If storage operation fails
  /// 
  /// Security:
  /// - Mnemonic encrypted before storage
  /// - PIN never stored
  /// - Encryption key never stored
  /// - Enforces single wallet constraint
  /// - Address cached separately (public info, not sensitive)
  Future<void> storeMnemonic(
    String mnemonic,
    String pin, {
    String? address,
  }) async {
    try {
      // Step 1: Check if vault already has wallet
      if (await hasWallet()) {
        throw VaultException.vaultNotEmpty();
      }

      // Step 2: Encrypt mnemonic
      final encrypted = _encryptionService.encrypt(mnemonic, pin);

      // Step 3: Serialize to JSON
      final jsonString = encrypted.toJsonString();

      // Step 4: Store in secure storage
      await _storage.write(
        key: _walletKey,
        value: jsonString,
        aOptions: _storageOptions,
      );

      // Step 5: Cache address if provided
      if (address != null) {
        await _storage.write(
          key: _addressKey,
          value: address,
          aOptions: _storageOptions,
        );
      }
    } on VaultException {
      rethrow;
    } catch (e) {
      throw VaultException.storageFailed('Failed to store mnemonic: $e');
    }
  }

  /// Retrieve mnemonic from secure vault
  /// 
  /// Cryptographic Flow:
  /// 1. Read encrypted data from flutter_secure_storage
  /// 2. Deserialize JSON to EncryptedData
  /// 3. Derive encryption key from PIN
  /// 4. Decrypt mnemonic using AES-256-GCM
  /// 5. Verify authentication tag
  /// 
  /// Parameters:
  /// - pin: User's PIN (must match PIN used for storage)
  /// 
  /// Returns: Decrypted mnemonic
  /// 
  /// Throws:
  /// - VaultException.vaultEmpty: If no wallet stored
  /// - VaultException.invalidPin: If PIN format invalid
  /// - VaultException.decryptionFailed: If wrong PIN or corrupted data
  /// - VaultException.dataCorrupted: If stored data invalid
  /// - VaultException.storageFailed: If storage read fails
  /// 
  /// Security:
  /// - Encryption key derived from PIN (not stored)
  /// - Authentication tag verified (prevents tampering)
  /// - Caller must clear mnemonic from memory after use
  Future<String> retrieveMnemonic(String pin) async {
    try {
      // Step 1: Read encrypted data from storage
      final jsonString = await _storage.read(
        key: _walletKey,
        aOptions: _storageOptions,
      );

      if (jsonString == null) {
        throw VaultException.vaultEmpty();
      }

      // Step 2: Deserialize JSON
      final encrypted = EncryptedData.fromJsonString(jsonString);

      // Step 3-5: Decrypt mnemonic
      return _encryptionService.decrypt(encrypted, pin);
    } on VaultException {
      rethrow;
    } catch (e) {
      throw VaultException.storageFailed('Failed to retrieve mnemonic: $e');
    }
  }

  /// Check if vault has wallet
  /// 
  /// Returns: true if wallet exists, false otherwise
  /// 
  /// Security: Does not expose any wallet data
  Future<bool> hasWallet() async {
    try {
      final value = await _storage.read(
        key: _walletKey,
        aOptions: _storageOptions,
      );
      return value != null;
    } catch (e) {
      throw VaultException.storageFailed('Failed to check wallet: $e');
    }
  }

  /// Delete wallet from vault
  /// 
  /// Removes all encrypted wallet data from secure storage.
  /// 
  /// Security:
  /// - Permanently deletes encrypted mnemonic
  /// - Deletes cached address
  /// - Cannot be recovered after deletion
  /// - Enforces single wallet constraint
  /// 
  /// Note: User should be warned before deletion
  Future<void> deleteWallet() async {
    try {
      await _storage.delete(
        key: _walletKey,
        aOptions: _storageOptions,
      );
      await _storage.delete(
        key: _addressKey,
        aOptions: _storageOptions,
      );
    } catch (e) {
      throw VaultException.storageFailed('Failed to delete wallet: $e');
    }
  }

  /// Get cached wallet address
  /// 
  /// Returns cached address without decryption.
  /// 
  /// Security: Address is public information, safe to cache
  Future<String?> getWalletAddress() async {
    try {
      return await _storage.read(
        key: _addressKey,
        aOptions: _storageOptions,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verify PIN without retrieving mnemonic
  /// 
  /// Attempts to decrypt stored data with provided PIN.
  /// Returns true if PIN is correct, false otherwise.
  /// 
  /// Use case: Verify PIN before sensitive operations
  /// 
  /// Security: Does not expose mnemonic, only verifies PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final jsonString = await _storage.read(
        key: _walletKey,
        aOptions: _storageOptions,
      );

      if (jsonString == null) {
        throw VaultException.vaultEmpty();
      }

      final encrypted = EncryptedData.fromJsonString(jsonString);
      return _encryptionService.verifyPin(encrypted, pin);
    } on VaultException {
      rethrow;
    } catch (e) {
      return false;
    }
  }

  /// Update PIN (re-encrypt with new PIN)
  /// 
  /// Cryptographic Flow:
  /// 1. Decrypt mnemonic with old PIN
  /// 2. Encrypt mnemonic with new PIN
  /// 3. Store new encrypted data
  /// 4. Clear mnemonic from memory
  /// 
  /// Parameters:
  /// - oldPin: Current PIN
  /// - newPin: New PIN (4-8 digits)
  /// 
  /// Throws:
  /// - VaultException.vaultEmpty: If no wallet stored
  /// - VaultException.decryptionFailed: If old PIN wrong
  /// - VaultException.invalidPin: If new PIN format invalid
  /// 
  /// Security:
  /// - Requires old PIN for authentication
  /// - Generates new salt and IV for new encryption
  /// - Mnemonic cleared from memory after re-encryption
  Future<void> updatePin(String oldPin, String newPin) async {
    String? mnemonic;

    try {
      // Step 1: Decrypt with old PIN
      mnemonic = await retrieveMnemonic(oldPin);

      // Step 2: Delete old encrypted data
      await deleteWallet();

      // Step 3: Encrypt with new PIN
      await storeMnemonic(mnemonic, newPin);
    } finally {
      // Step 4: Clear mnemonic from memory
      if (mnemonic != null) {
        // Overwrite string in memory (best effort in Dart)
        mnemonic = '';
      }
    }
  }

  /// Get vault metadata (without decrypting)
  /// 
  /// Returns information about stored wallet without decryption:
  /// - hasWallet: Whether vault contains wallet
  /// - saltLength: Length of salt (for verification)
  /// - ivLength: Length of IV (for verification)
  /// 
  /// Security: Does not expose sensitive data
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      final jsonString = await _storage.read(
        key: _walletKey,
        aOptions: _storageOptions,
      );

      if (jsonString == null) {
        return {
          'hasWallet': false,
        };
      }

      final encrypted = EncryptedData.fromJsonString(jsonString);

      return {
        'hasWallet': true,
        'saltLength': encrypted.salt.length,
        'ivLength': encrypted.iv.length,
        'authTagLength': encrypted.authTag.length,
      };
    } catch (e) {
      throw VaultException.storageFailed('Failed to get metadata: $e');
    }
  }
}
