import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';

/// Delete Wallet Use Case
/// 
/// Responsibility: Securely delete wallet from device.
/// - Remove all encrypted data from secure storage
/// - Verify deletion completed successfully
/// 
/// Security: Ensures complete removal of all wallet data
class DeleteWalletUseCase {
  final WalletRepository repository;

  DeleteWalletUseCase({required this.repository});

  /// Delete wallet from device
  /// 
  /// Requirements: 4.5, 7.4
  /// 
  /// Removes all wallet data including:
  /// - Encrypted mnemonic
  /// - Encryption salt and IV
  /// - Cached wallet address
  /// 
  /// Throws:
  /// - WalletError.walletNotFound: If no wallet exists
  /// - WalletError.storageDeleteFailure: If deletion fails
  /// 
  /// Security: Permanently deletes all wallet data, cannot be recovered
  Future<void> call() async {
    // Check if wallet exists
    final hasWallet = await repository.hasWallet();
    if (!hasWallet) {
      throw WalletError(
        WalletErrorType.walletNotFound,
        'No wallet found on this device',
      );
    }

    // Delete all wallet data from storage
    await repository.deleteWallet();

    // Verify deletion completed successfully
    final stillExists = await repository.hasWallet();
    if (stillExists) {
      throw WalletError(
        WalletErrorType.storageDeleteFailure,
        'Failed to verify wallet deletion',
      );
    }
  }
}
