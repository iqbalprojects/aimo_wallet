import '../../../../core/crypto/wallet_engine.dart';
import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';

/// Import New Wallet Result
///
/// Contains address of the imported wallet.
class ImportNewWalletResult {
  final String address;

  ImportNewWalletResult({required this.address});
}

/// Import New Wallet Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Check if wallet already exists (single wallet constraint)
/// - Validate imported mnemonic via WalletEngine
/// - Derive wallet address
/// - Store encrypted mnemonic in SecureVault
///
/// Flow:
/// 1. Check vault for existing wallet
/// 2. Validate mnemonic using WalletEngine
/// 3. Store encrypted mnemonic in vault with PIN
/// 4. Return address
///
/// Security:
/// - Enforces single wallet per device
/// - Mnemonic encrypted before storage
/// - PIN never stored
///
class ImportNewWalletUseCase {
  final WalletEngine _walletEngine;
  final SecureVault _secureVault;

  ImportNewWalletUseCase({
    required WalletEngine walletEngine,
    required SecureVault secureVault,
  }) : _walletEngine = walletEngine,
       _secureVault = secureVault;

  /// Execute use case
  ///
  /// Parameters:
  /// - mnemonic: The 24-word recovery phrase
  /// - pin: User's PIN for encryption (6-8 digits recommended)
  ///
  /// Returns: ImportNewWalletResult with the derived address
  ///
  /// Throws:
  /// - VaultException.vaultNotEmpty: If wallet already exists
  /// - VaultException.invalidPin: If PIN format invalid
  /// - VaultException.encryptionFailed: If encryption fails
  /// - VaultException.storageFailed: If storage fails
  /// - Exception: For validation errors
  Future<ImportNewWalletResult> call({
    required String mnemonic,
    required String pin,
  }) async {
    // Step 1: Check if wallet already exists
    final hasWallet = await _secureVault.hasWallet();
    if (hasWallet) {
      throw VaultException.vaultNotEmpty();
    }

    // Step 2: Validate PIN format
    if (pin.isEmpty || pin.length < 6) {
      throw VaultException.invalidPin('PIN must be at least 6 digits');
    }

    // Step 3: Validate and import wallet using WalletEngine
    final walletResult = _walletEngine.importWallet(mnemonic);
    if (!walletResult.isValid) {
      throw Exception(walletResult.error ?? 'Invalid mnemonic phrase');
    }

    // Step 4: Store encrypted mnemonic in vault
    // To ensure the exact wording is kept, we also use the normalized version, but for storage we can store the original or normalized. WalletEngine uses normalized.
    // However securely storing the mnemonic is our priority.
    await _secureVault.storeMnemonic(
      mnemonic, // We might want to store normalized but the engine returns it implicitly or not
      pin,
      address: walletResult.address,
    );

    return ImportNewWalletResult(address: walletResult.address);
  }
}
