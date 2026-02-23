import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';
import '../entities/wallet_error.dart';

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
  final SecureVault secureVault;

  ExportMnemonicUseCase({required this.secureVault});

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
    final hasWallet = await secureVault.hasWallet();
    if (!hasWallet) {
      throw WalletError(
        WalletErrorType.walletNotFound,
        'No wallet found on this device',
      );
    }

    try {
      return await secureVault.retrieveMnemonic(pin);
    } on VaultException catch (e) {
      if (e.type == VaultExceptionType.decryptionFailed ||
          e.type == VaultExceptionType.invalidPin) {
        throw WalletError(WalletErrorType.wrongPin, 'Incorrect PIN');
      }
      throw WalletError(
        WalletErrorType.decryptionFailure,
        'Failed to decrypt wallet: ${e.message}',
      );
    } catch (e) {
      throw WalletError(
        WalletErrorType.decryptionFailure,
        'Unexpected error during decryption',
      );
    }
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
