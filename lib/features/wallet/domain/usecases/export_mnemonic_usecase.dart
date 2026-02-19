import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';

/// Export Mnemonic Use Case
/// 
/// Responsibility: Export mnemonic for backup.
/// - Require PIN authentication
/// - Decrypt mnemonic
/// - Return mnemonic for display
/// - Clear mnemonic from memory after use
/// 
/// Security: Requires authentication, clears sensitive data after use
class ExportMnemonicUseCase {
  final WalletRepository repository;

  ExportMnemonicUseCase({required this.repository});

  /// Export mnemonic with PIN authentication
  /// 
  /// Requirements: 11.4, 12.5
  /// 
  /// Parameters:
  /// - pin: User's PIN for authentication
  /// 
  /// Returns: Decrypted mnemonic phrase
  /// 
  /// Throws:
  /// - WalletError.walletNotFound: If no wallet exists
  /// - WalletError.invalidPinFormat: If PIN format is invalid
  /// - WalletError.wrongPin: If PIN is incorrect
  /// - WalletError.decryptionFailure: If decryption fails
  /// 
  /// Security:
  /// - Requires PIN authentication before export
  /// - Caller must clear mnemonic from memory after use
  /// - Should warn user about security risks of screenshots/digital copies
  Future<String> call(String pin) async {
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
    // - Retrieving encrypted mnemonic
    // - Deriving decryption key from PIN
    // - Decrypting mnemonic
    // - Returning mnemonic for display
    // Note: Caller must clear mnemonic from memory after use
    return await repository.exportMnemonic(pin);
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
