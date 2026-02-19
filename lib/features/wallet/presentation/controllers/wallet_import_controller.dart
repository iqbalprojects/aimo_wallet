import 'package:get/get.dart';
import '../../domain/usecases/import_wallet_usecase.dart';
import '../../domain/usecases/save_wallet_usecase.dart';
import '../../domain/entities/wallet_error.dart';

/// Wallet Import Controller
/// 
/// Orchestrates wallet import flow:
/// 1. Accept user input (24 words)
/// 2. Validate and normalize mnemonic using ImportWalletUseCase
/// 3. Display derived address for confirmation
/// 4. After user confirms, save wallet using SaveWalletUseCase
/// 5. Update WalletController state
/// 
/// Requirements: 2.1, 2.2, 2.3, 2.4
/// 
/// Security: Validates mnemonic before storage, enforces single wallet constraint
/// 
/// Usage:
/// ```dart
/// final controller = Get.find<WalletImportController>();
/// 
/// // Step 1: Validate mnemonic and derive address
/// await controller.validateAndDeriveAddress(mnemonic);
/// 
/// // Step 2: Display derived address for confirmation
/// print('Address: ${controller.derivedAddress}');
/// 
/// // Step 3: After user confirms, import wallet
/// await controller.importWallet(mnemonic, pin);
/// ```
class WalletImportController extends GetxController {
  final ImportWalletUseCase _importWalletUseCase;
  final SaveWalletUseCase _saveWalletUseCase;

  final RxBool _isLoading = false.obs;
  final RxnString _derivedAddress = RxnString();
  final RxnString _normalizedMnemonic = RxnString();
  final RxnString _errorMessage = RxnString();
  final RxBool _addressConfirmed = false.obs;

  WalletImportController({
    required ImportWalletUseCase importWalletUseCase,
    required SaveWalletUseCase saveWalletUseCase,
  })  : _importWalletUseCase = importWalletUseCase,
        _saveWalletUseCase = saveWalletUseCase;

  // Observable getters
  bool get isLoading => _isLoading.value;
  String? get derivedAddress => _derivedAddress.value;
  String? get normalizedMnemonic => _normalizedMnemonic.value;
  String? get errorMessage => _errorMessage.value;
  bool get addressConfirmed => _addressConfirmed.value;

  /// Validate mnemonic and derive address
  /// 
  /// Validates mnemonic format and derives address for user confirmation.
  /// 
  /// Requirements: 2.1, 2.2, 2.4
  /// 
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase to import
  /// 
  /// Returns: true if validation successful, false otherwise
  /// 
  /// Throws: WalletError with specific error types:
  /// - invalidMnemonicLength: Not 24 words
  /// - invalidMnemonicWords: Contains invalid words
  /// - invalidMnemonicChecksum: Checksum verification failed
  Future<bool> validateAndDeriveAddress(String mnemonic) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _derivedAddress.value = null;
    _normalizedMnemonic.value = null;
    _addressConfirmed.value = false;

    try {
      // Validate and normalize mnemonic, derive address
      final credentials = await _importWalletUseCase(mnemonic);

      // Store for confirmation
      _normalizedMnemonic.value = credentials.mnemonic;
      _derivedAddress.value = credentials.address;

      return true;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to validate mnemonic. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Confirm address
  /// 
  /// User confirms the derived address is correct.
  /// This enables the import wallet button.
  void confirmAddress() {
    _addressConfirmed.value = true;
  }

  /// Import wallet with PIN
  /// 
  /// Saves imported wallet after user confirms address.
  /// Updates WalletController state to locked.
  /// 
  /// Requirements: 2.3
  /// 
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase (should be same as validated)
  /// - pin: User's PIN (4-8 digits)
  /// 
  /// Returns: true if import successful, false otherwise
  Future<bool> importWallet(String mnemonic, String pin) async {
    // Use normalized mnemonic if available, otherwise validate first
    String mnemonicToImport = _normalizedMnemonic.value ?? mnemonic;

    // If no normalized mnemonic, validate first
    if (_normalizedMnemonic.value == null) {
      final validated = await validateAndDeriveAddress(mnemonic);
      if (!validated) {
        return false;
      }
      mnemonicToImport = _normalizedMnemonic.value!;
    }

    if (!_addressConfirmed.value) {
      _errorMessage.value = 'Please confirm the derived address.';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Save wallet (encrypt and store)
      await _saveWalletUseCase(
        mnemonicToImport,
        pin,
      );

      // Note: WalletController state is automatically updated
      // when wallet is saved to vault. No manual update needed.

      // Clear sensitive data from memory
      _clearSensitiveData();

      return true;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to import wallet. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear sensitive data from memory
  /// 
  /// Clears mnemonic after successful import or when controller is disposed.
  void _clearSensitiveData() {
    _normalizedMnemonic.value = null;
    _derivedAddress.value = null;
    _addressConfirmed.value = false;
  }

  /// Get user-friendly error message
  /// 
  /// Converts WalletError to user-friendly message with specific details.
  /// 
  /// Requirements: 2.1, 2.2, 2.3
  String _getUserFriendlyErrorMessage(WalletError error) {
    switch (error.type) {
      case WalletErrorType.invalidMnemonicLength:
        return 'Invalid mnemonic length. Please enter exactly 24 words.';
      case WalletErrorType.invalidMnemonicWords:
        return 'Invalid mnemonic. One or more words are not in the BIP39 word list.';
      case WalletErrorType.invalidMnemonicChecksum:
        return 'Invalid mnemonic. Checksum verification failed. Please check your words.';
      case WalletErrorType.walletAlreadyExists:
        return 'A wallet already exists. Please delete it before importing a new one.';
      case WalletErrorType.invalidPinFormat:
        return 'PIN must be 4-8 digits.';
      case WalletErrorType.encryptionFailure:
        return 'Failed to encrypt wallet. Please try again.';
      case WalletErrorType.storageWriteFailure:
        return 'Failed to save wallet. Please check storage permissions.';
      default:
        return error.message;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Reset controller state
  /// 
  /// Clears all data and resets to initial state.
  void reset() {
    _clearSensitiveData();
    _errorMessage.value = null;
    _isLoading.value = false;
  }

  @override
  void onClose() {
    // Clear sensitive data when controller is disposed
    _clearSensitiveData();
    super.onClose();
  }
}
