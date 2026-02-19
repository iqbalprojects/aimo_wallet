import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';

/// Get Current Address Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Retrieve cached wallet address from SecureVault
/// - No decryption required (address is public info)
/// - Fast operation (no crypto operations)
/// 
/// SECURITY:
/// - Address is public information (safe to cache)
/// - No mnemonic access required
/// - No private key derivation
/// - Read-only operation
/// 
/// Flow:
/// 1. Check if wallet exists
/// 2. Retrieve cached address from vault
/// 3. Return address
/// 
/// Usage:
/// ```dart
/// final useCase = GetCurrentAddressUseCase(secureVault: vault);
/// 
/// try {
///   final address = await useCase.call();
///   print('Address: $address');
/// } catch (e) {
///   // Handle error
/// }
/// ```
class GetCurrentAddressUseCase {
  final SecureVault _secureVault;

  GetCurrentAddressUseCase({
    required SecureVault secureVault,
  }) : _secureVault = secureVault;

  /// Execute use case
  /// 
  /// Returns: Wallet address (Ethereum format: 0x...)
  /// 
  /// Throws:
  /// - VaultException.vaultEmpty: If no wallet exists
  /// - VaultException.dataCorrupted: If address not found
  /// - Exception: For other errors
  /// 
  /// SECURITY:
  /// - Address is public information
  /// - No sensitive data accessed
  /// - No decryption performed
  /// - Fast operation (cached value)
  Future<String> call() async {
    // Step 1: Check if wallet exists
    final hasWallet = await _secureVault.hasWallet();
    if (!hasWallet) {
      throw VaultException.vaultEmpty();
    }

    // Step 2: Get cached address
    // SECURITY: Address is cached separately from encrypted mnemonic
    // This allows fast access without decryption
    final address = await _secureVault.getWalletAddress();

    if (address == null || address.isEmpty) {
      throw VaultException.dataCorrupted('Wallet address not found');
    }

    return address;
  }
}
