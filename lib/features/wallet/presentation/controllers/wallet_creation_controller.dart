import 'package:get/get.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/save_wallet_usecase.dart';
import '../../domain/entities/wallet_error.dart';

/// Wallet Creation Controller
/// 
/// Orchestrates wallet creation flow:
/// 1. Generate mnemonic using CreateWalletUseCase
/// 2. Display mnemonic to user with numbering (1-24)
/// 3. After user confirms backup, save wallet using SaveWalletUseCase
/// 4. Update WalletController state
/// 
/// Requirements: 11.1, 11.2, 11.3
/// 
/// Security: Mnemonic displayed once for backup, then encrypted and stored
/// 
/// Usage:
/// ```dart
/// final controller = Get.find<WalletCreationController>();
/// 
/// // Step 1: Generate mnemonic
/// await controller.generateMnemonic();
/// 
/// // Step 2: Display mnemonic to user (with numbering)
/// final words = controller.getMnemonicWords();
/// for (int i = 0; i < words.length; i++) {
///   print('${i + 1}. ${words[i]}');
/// }
/// 
/// // Step 3: After user confirms backup, save wallet
/// await controller.saveWallet(pin);
/// ```
class WalletCreationController extends GetxController {
  final CreateWalletUseCase _createWalletUseCase;
  final SaveWalletUseCase _saveWalletUseCase;

  final RxBool _isLoading = false.obs;
  final RxnString _generatedMnemonic = RxnString();
  final RxnString _derivedAddress = RxnString();
  final RxnString _errorMessage = RxnString();
  final RxBool _backupConfirmed = false.obs;

  WalletCreationController({
    required CreateWalletUseCase createWalletUseCase,
    required SaveWalletUseCase saveWalletUseCase,
  })  : _createWalletUseCase = createWalletUseCase,
        _saveWalletUseCase = saveWalletUseCase;

  // Observable getters
  bool get isLoading => _isLoading.value;
  String? get generatedMnemonic => _generatedMnemonic.value;
  String? get derivedAddress => _derivedAddress.value;
  String? get errorMessage => _errorMessage.value;
  bool get backupConfirmed => _backupConfirmed.value;

  /// Generate new mnemonic
  /// 
  /// Calls CreateWalletUseCase to generate 24-word mnemonic and derive address.
  /// Mnemonic is held in memory for display to user.
  /// 
  /// Requirements: 11.1
  /// 
  /// Throws: WalletError if wallet already exists or generation fails
  Future<void> generateMnemonic() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _generatedMnemonic.value = null;
    _derivedAddress.value = null;
    _backupConfirmed.value = false;

    try {
      // Generate mnemonic and derive address
      final credentials = await _createWalletUseCase();

      // Store for display
      _generatedMnemonic.value = credentials.mnemonic;
      _derivedAddress.value = credentials.address;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
    } catch (e) {
      _errorMessage.value = 'Failed to generate wallet. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get mnemonic words as list
  /// 
  /// Returns mnemonic split into individual words for display with numbering.
  /// 
  /// Requirements: 11.2
  /// 
  /// Usage:
  /// ```dart
  /// final words = controller.getMnemonicWords();
  /// for (int i = 0; i < words.length; i++) {
  ///   print('${i + 1}. ${words[i]}');
  /// }
  /// ```
  List<String> getMnemonicWords() {
    if (_generatedMnemonic.value == null) {
      return [];
    }
    return _generatedMnemonic.value!.split(' ');
  }

  /// Confirm backup
  /// 
  /// User confirms they have backed up the mnemonic.
  /// This enables the save wallet button.
  void confirmBackup() {
    _backupConfirmed.value = true;
  }

  /// Save wallet with PIN
  /// 
  /// Encrypts and stores mnemonic after user confirms backup.
  /// Updates WalletController state to locked.
  /// 
  /// Requirements: 11.3
  /// 
  /// Parameters:
  /// - pin: User's PIN (4-8 digits)
  /// 
  /// Returns: true if save successful, false otherwise
  Future<bool> saveWallet(String pin) async {
    if (_generatedMnemonic.value == null) {
      _errorMessage.value = 'No mnemonic to save. Please generate a wallet first.';
      return false;
    }

    if (!_backupConfirmed.value) {
      _errorMessage.value = 'Please confirm you have backed up your mnemonic.';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Save wallet (encrypt and store)
      await _saveWalletUseCase(
        _generatedMnemonic.value!,
        pin,
      );

      // Note: WalletController state is automatically updated
      // when wallet is saved to vault. No manual update needed.

      // Clear mnemonic from memory
      _clearSensitiveData();

      return true;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to save wallet. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear sensitive data from memory
  /// 
  /// Clears mnemonic after successful save or when controller is disposed.
  void _clearSensitiveData() {
    _generatedMnemonic.value = null;
    _derivedAddress.value = null;
    _backupConfirmed.value = false;
  }

  /// Get user-friendly error message
  /// 
  /// Converts WalletError to user-friendly message.
  String _getUserFriendlyErrorMessage(WalletError error) {
    switch (error.type) {
      case WalletErrorType.walletAlreadyExists:
        return 'A wallet already exists. Please delete it before creating a new one.';
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
