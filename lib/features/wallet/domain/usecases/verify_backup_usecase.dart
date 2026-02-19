import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';

/// Verify Backup Use Case
/// 
/// Responsibility: Verify user's mnemonic backup.
/// - Require PIN authentication
/// - Decrypt stored mnemonic
/// - Normalize entered mnemonic
/// - Compare entered with stored mnemonic
/// 
/// Security: Requires authentication before verification
class VerifyBackupUseCase {
  final WalletRepository repository;

  VerifyBackupUseCase({required this.repository});

  /// Verify backup mnemonic matches stored mnemonic
  /// 
  /// Requirements: 12.2, 12.3, 12.4, 12.5
  /// 
  /// Parameters:
  /// - enteredMnemonic: Mnemonic entered by user for verification
  /// - pin: User's PIN for authentication
  /// 
  /// Returns: true if entered mnemonic matches stored mnemonic, false otherwise
  /// 
  /// Throws:
  /// - WalletError.walletNotFound: If no wallet exists
  /// - WalletError.invalidPinFormat: If PIN format is invalid
  /// - WalletError.wrongPin: If PIN is incorrect
  /// - WalletError.decryptionFailure: If decryption fails
  /// 
  /// Security:
  /// - Requires PIN authentication before verification
  /// - Normalizes entered mnemonic before comparison
  /// - Clears sensitive data from memory after comparison
  Future<bool> call(String enteredMnemonic, String pin) async {
    // Validate PIN format
    if (!_isValidPin(pin)) {
      throw WalletError(
        WalletErrorType.invalidPinFormat,
        'PIN must be 4-8 digits',
      );
    }

    // Check if wallet exists
    final hasWallet = await repository.hasWallet();
    if (!hasWallet) {
      throw WalletError(
        WalletErrorType.walletNotFound,
        'No wallet found on this device',
      );
    }

    // Delegate to repository which handles:
    // - Retrieving and decrypting stored mnemonic with PIN authentication
    // - Normalizing entered mnemonic
    // - Comparing entered with stored mnemonic
    // - Returning success or failure
    // - Clearing sensitive data from memory
    return await repository.verifyBackup(enteredMnemonic, pin);
  }

  /// Validate PIN format
  /// PIN must be 4-8 digits
  bool _isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      return false;
    }
    // Check if all characters are digits
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
