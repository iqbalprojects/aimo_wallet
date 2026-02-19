import '../entities/wallet.dart';

/// Wallet Repository Interface
/// 
/// Responsibility: Define contract for wallet storage and operations.
/// - Create and import wallets
/// - Unlock wallets with PIN authentication
/// - Export mnemonics (with authentication)
/// - Delete wallets
/// 
/// Security: All operations enforce security constraints
abstract class WalletRepository {
  /// Create new wallet with mnemonic and PIN
  /// Generates mnemonic, derives address, encrypts and stores
  Future<Wallet> createWallet(String mnemonic, String pin);

  /// Import existing wallet with mnemonic and PIN
  /// Validates mnemonic, derives address, encrypts and stores
  Future<Wallet> importWallet(String mnemonic, String pin);

  /// Unlock wallet with PIN
  /// Decrypts mnemonic, derives private key, returns unlocked wallet
  Future<Wallet> unlockWallet(String pin);

  /// Get wallet address without unlocking
  /// Returns cached address from storage
  Future<String?> getWalletAddress();

  /// Check if wallet exists on device
  Future<bool> hasWallet();

  /// Delete wallet from device
  /// Removes all encrypted data from secure storage
  Future<void> deleteWallet();

  /// Export mnemonic (requires prior authentication)
  /// Decrypts and returns mnemonic for backup
  Future<String> exportMnemonic(String pin);

  /// Verify backup mnemonic matches stored mnemonic
  Future<bool> verifyBackup(String enteredMnemonic, String pin);
}
