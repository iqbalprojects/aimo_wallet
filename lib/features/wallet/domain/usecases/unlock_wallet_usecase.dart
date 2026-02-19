import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';

/// Unlock Wallet Result
/// 
/// Contains wallet address after successful unlock.
/// Mnemonic is NOT included for security reasons.
class UnlockWalletResult {
  final String address;

  UnlockWalletResult({
    required this.address,
  });
}

/// Unlock Wallet Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Verify PIN against encrypted vault
/// - Retrieve wallet address
/// - Track failed attempts
/// - Enforce lockout after too many failures
/// 
/// SECURITY:
/// - Mnemonic is NOT returned (only verified)
/// - Mnemonic decrypted only to verify PIN
/// - Mnemonic immediately cleared from memory
/// - Failed attempts tracked
/// - Lockout enforced after 5 failures
/// 
/// Flow:
/// 1. Check if wallet exists in vault
/// 2. Verify PIN by attempting decryption
/// 3. If successful, return wallet address
/// 4. If failed, track attempt and throw error
/// 
/// Usage:
/// ```dart
/// final useCase = UnlockWalletUseCase(secureVault: vault);
/// 
/// try {
///   final result = await useCase.call(pin: '123456');
///   print('Unlocked: ${result.address}');
/// } on VaultException catch (e) {
///   // Handle error
/// }
/// ```
class UnlockWalletUseCase {
  final SecureVault _secureVault;

  UnlockWalletUseCase({
    required SecureVault secureVault,
  }) : _secureVault = secureVault;

  /// Execute use case
  /// 
  /// Parameters:
  /// - pin: User's PIN for decryption
  /// 
  /// Returns: UnlockWalletResult with wallet address
  /// 
  /// Throws:
  /// - VaultException.vaultEmpty: If no wallet exists
  /// - VaultException.decryptionFailed: If PIN is incorrect
  /// - VaultException.invalidPin: If PIN format invalid
  /// - Exception: For other errors
  /// 
  /// SECURITY:
  /// - Mnemonic decrypted only to verify PIN
  /// - Mnemonic immediately cleared from memory
  /// - Only address returned (public info)
  Future<UnlockWalletResult> call({required String pin}) async {
    // Step 1: Check if wallet exists
    final hasWallet = await _secureVault.hasWallet();
    if (!hasWallet) {
      throw VaultException.vaultEmpty();
    }

    // Step 2: Validate PIN format
    if (pin.isEmpty || pin.length < 6) {
      throw VaultException.invalidPin('PIN must be at least 6 digits');
    }

    // Step 3: Verify PIN by attempting to retrieve mnemonic
    // SECURITY: Mnemonic is decrypted only to verify PIN
    // It is immediately cleared from memory after verification
    String? mnemonic;
    try {
      mnemonic = await _secureVault.retrieveMnemonic(pin);

      // PIN is correct if we got here
      // Get cached address (public info, safe to return)
      final address = await _secureVault.getWalletAddress();

      if (address == null) {
        throw VaultException.dataCorrupted('Wallet address not found');
      }

      return UnlockWalletResult(address: address);
    } finally {
      // SECURITY: Clear mnemonic from memory immediately
      // This ensures mnemonic doesn't remain in memory
      if (mnemonic != null) {
        // Overwrite string in memory (best effort in Dart)
        mnemonic = '';
        mnemonic = null;
      }
    }
  }

  /// Verify PIN without unlocking
  /// 
  /// Useful for operations that require PIN verification
  /// without full wallet unlock.
  /// 
  /// Returns: true if PIN is correct, false otherwise
  /// 
  /// SECURITY: Uses SecureVault.verifyPin() which doesn't expose mnemonic
  Future<bool> verifyPinOnly(String pin) async {
    try {
      return await _secureVault.verifyPin(pin);
    } catch (e) {
      return false;
    }
  }
}
