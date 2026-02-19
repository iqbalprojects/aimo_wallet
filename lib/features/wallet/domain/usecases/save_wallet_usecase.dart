import '../entities/wallet.dart';
import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';

/// Save Wallet Use Case
/// 
/// Responsibility: Save wallet after user confirms backup.
/// - Accept mnemonic, PIN, and address
/// - Validate PIN format (4-8 digits)
/// - Derive encryption key from PIN using PBKDF2
/// - Encrypt mnemonic using AES-256-GCM
/// - Store encrypted wallet data
/// - Clear sensitive data from memory
/// 
/// Security: Validates PIN format, encrypts before storage
class SaveWalletUseCase {
  final WalletRepository repository;

  SaveWalletUseCase({required this.repository});

  /// Save wallet with mnemonic and PIN
  /// 
  /// Requirements: 3.1, 11.3
  /// 
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase
  /// - pin: User's PIN (4-8 digits)
  /// 
  /// Returns: Wallet entity in locked state
  /// 
  /// Throws:
  /// - WalletError.invalidPinFormat: If PIN is not 4-8 digits
  /// - WalletError.encryptionFailure: If encryption fails
  /// - WalletError.storageWriteFailure: If storage fails
  Future<Wallet> call(String mnemonic, String pin) async {
    // Validate PIN format (4-8 digits)
    if (!_isValidPin(pin)) {
      throw WalletError(
        WalletErrorType.invalidPinFormat,
        'PIN must be 4-8 digits',
      );
    }

    // Delegate to repository which handles:
    // - Deriving encryption key from PIN using PBKDF2
    // - Encrypting mnemonic using AES-256-GCM
    // - Storing encrypted wallet data
    // - Clearing sensitive data from memory
    return await repository.createWallet(mnemonic, pin);
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
