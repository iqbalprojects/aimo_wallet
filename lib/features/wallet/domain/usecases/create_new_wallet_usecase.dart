import '../../../../core/crypto/wallet_engine.dart';
import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';

/// Create New Wallet Result
/// 
/// Contains mnemonic and address for user backup.
/// Mnemonic must be cleared from memory after backup confirmation.
class CreateNewWalletResult {
  final String mnemonic;
  final String address;

  CreateNewWalletResult({
    required this.mnemonic,
    required this.address,
  });
}

/// Create New Wallet Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Check if wallet already exists (single wallet constraint)
/// - Generate new mnemonic via WalletEngine
/// - Derive wallet address
/// - Store encrypted mnemonic in SecureVault
/// - Return mnemonic for user backup
/// 
/// Flow:
/// 1. Check vault for existing wallet
/// 2. Generate mnemonic using WalletEngine
/// 3. Store encrypted mnemonic in vault with PIN
/// 4. Return mnemonic + address for backup screen
/// 
/// Security:
/// - Enforces single wallet per device
/// - Mnemonic encrypted before storage
/// - PIN never stored
/// - Mnemonic returned only for immediate backup
/// - Caller must clear mnemonic after backup
/// 
/// Usage:
/// ```dart
/// final useCase = CreateNewWalletUseCase(
///   walletEngine: walletEngine,
///   secureVault: secureVault,
/// );
/// 
/// try {
///   final result = await useCase.call(pin: '123456');
///   print('Address: ${result.address}');
///   // Show mnemonic to user for backup
///   // Clear mnemonic after backup
/// } catch (e) {
///   // Handle error
/// }
/// ```
class CreateNewWalletUseCase {
  final WalletEngine _walletEngine;
  final SecureVault _secureVault;

  CreateNewWalletUseCase({
    required WalletEngine walletEngine,
    required SecureVault secureVault,
  })  : _walletEngine = walletEngine,
        _secureVault = secureVault;

  /// Execute use case
  /// 
  /// Parameters:
  /// - pin: User's PIN for encryption (6-8 digits recommended)
  /// 
  /// Returns: CreateNewWalletResult with mnemonic and address
  /// 
  /// Throws:
  /// - VaultException.vaultNotEmpty: If wallet already exists
  /// - VaultException.invalidPin: If PIN format invalid
  /// - VaultException.encryptionFailed: If encryption fails
  /// - VaultException.storageFailed: If storage fails
  /// - Exception: For other errors
  Future<CreateNewWalletResult> call({required String pin}) async {
    // Step 1: Check if wallet already exists
    final hasWallet = await _secureVault.hasWallet();
    if (hasWallet) {
      throw VaultException.vaultNotEmpty();
    }

    // Step 2: Validate PIN format
    if (pin.isEmpty || pin.length < 6) {
      throw VaultException.invalidPin('PIN must be at least 6 digits');
    }

    // Step 3: Generate wallet using WalletEngine
    final walletResult = _walletEngine.createWallet();

    // Step 4: Store encrypted mnemonic in vault
    await _secureVault.storeMnemonic(
      walletResult.mnemonic,
      pin,
      address: walletResult.address,
    );

    // Step 5: Return mnemonic and address for backup
    return CreateNewWalletResult(
      mnemonic: walletResult.mnemonic,
      address: walletResult.address,
    );
  }
}
