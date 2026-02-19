import 'package:get/get.dart';
import '../../domain/usecases/export_mnemonic_usecase.dart';
import '../../domain/usecases/verify_backup_usecase.dart';
import '../../domain/usecases/delete_wallet_usecase.dart';
import '../../domain/entities/wallet_error.dart';

/// Wallet Settings Controller
/// 
/// Manages wallet settings and sensitive operations:
/// 1. Export mnemonic (with PIN authentication)
/// 2. Verify backup (with PIN authentication)
/// 3. Delete wallet (with confirmation)
/// 
/// Requirements: 11.4, 12.1, 12.2, 12.3, 12.4, 12.5, 7.4
/// 
/// Security: All sensitive operations require PIN authentication
/// 
/// Usage:
/// ```dart
/// final controller = Get.find<WalletSettingsController>();
/// 
/// // Export mnemonic
/// await controller.exportMnemonic(pin);
/// print(controller.exportedMnemonic);
/// 
/// // Verify backup
/// final isValid = await controller.verifyBackup(enteredMnemonic, pin);
/// 
/// // Delete wallet
/// await controller.deleteWallet();
/// ```
class WalletSettingsController extends GetxController {
  final ExportMnemonicUseCase _exportMnemonicUseCase;
  final VerifyBackupUseCase _verifyBackupUseCase;
  final DeleteWalletUseCase _deleteWalletUseCase;

  final RxBool _isLoading = false.obs;
  final RxnString _exportedMnemonic = RxnString();
  final RxnString _errorMessage = RxnString();
  final RxBool _backupVerified = false.obs;

  WalletSettingsController({
    required ExportMnemonicUseCase exportMnemonicUseCase,
    required VerifyBackupUseCase verifyBackupUseCase,
    required DeleteWalletUseCase deleteWalletUseCase,
  })  : _exportMnemonicUseCase = exportMnemonicUseCase,
        _verifyBackupUseCase = verifyBackupUseCase,
        _deleteWalletUseCase = deleteWalletUseCase;

  // Observable getters
  bool get isLoading => _isLoading.value;
  String? get exportedMnemonic => _exportedMnemonic.value;
  String? get errorMessage => _errorMessage.value;
  bool get backupVerified => _backupVerified.value;

  /// Export mnemonic with PIN authentication
  /// 
  /// Requires PIN authentication before exporting mnemonic.
  /// Mnemonic is held in memory for display to user.
  /// 
  /// Requirements: 11.4, 12.5
  /// 
  /// Parameters:
  /// - pin: User's PIN for authentication
  /// 
  /// Returns: true if export successful, false otherwise
  /// 
  /// Security:
  /// - Requires PIN authentication
  /// - Caller must clear mnemonic after display
  /// - Should warn user about security risks
  Future<bool> exportMnemonic(String pin) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _exportedMnemonic.value = null;

    try {
      // Export mnemonic (requires PIN authentication)
      final mnemonic = await _exportMnemonicUseCase(pin);

      // Store for display
      _exportedMnemonic.value = mnemonic;

      return true;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to export mnemonic. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get exported mnemonic words as list
  /// 
  /// Returns mnemonic split into individual words for display with numbering.
  /// 
  /// Usage:
  /// ```dart
  /// final words = controller.getExportedMnemonicWords();
  /// for (int i = 0; i < words.length; i++) {
  ///   print('${i + 1}. ${words[i]}');
  /// }
  /// ```
  List<String> getExportedMnemonicWords() {
    if (_exportedMnemonic.value == null) {
      return [];
    }
    return _exportedMnemonic.value!.split(' ');
  }

  /// Clear exported mnemonic from memory
  /// 
  /// Should be called after user has finished viewing mnemonic.
  void clearExportedMnemonic() {
    _exportedMnemonic.value = null;
  }

  /// Verify backup with PIN authentication
  /// 
  /// Verifies that entered mnemonic matches stored mnemonic.
  /// Requires PIN authentication before verification.
  /// 
  /// Requirements: 12.2, 12.3, 12.4, 12.5
  /// 
  /// Parameters:
  /// - enteredMnemonic: Mnemonic entered by user for verification
  /// - pin: User's PIN for authentication
  /// 
  /// Returns: true if mnemonic matches, false otherwise
  /// 
  /// Security: Requires PIN authentication before verification
  Future<bool> verifyBackup(String enteredMnemonic, String pin) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _backupVerified.value = false;

    try {
      // Verify backup (requires PIN authentication)
      final isValid = await _verifyBackupUseCase(enteredMnemonic, pin);

      _backupVerified.value = isValid;

      if (!isValid) {
        _errorMessage.value = 'Mnemonic does not match. Please check your backup.';
      }

      return isValid;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to verify backup. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete wallet
  /// 
  /// Permanently deletes wallet from device.
  /// Updates WalletController state to notCreated.
  /// 
  /// Requirements: 7.4
  /// 
  /// Returns: true if deletion successful, false otherwise
  /// 
  /// Security:
  /// - Requires explicit user confirmation
  /// - Cannot be recovered after deletion
  /// - User should backup mnemonic before deletion
  Future<bool> deleteWallet() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Delete wallet
      await _deleteWalletUseCase();

      // Note: WalletController state is automatically updated
      // when wallet is deleted from vault. The controller will
      // detect the empty vault on next initialization.

      // Clear any exported mnemonic
      _exportedMnemonic.value = null;
      _backupVerified.value = false;

      return true;
    } on WalletError catch (e) {
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to delete wallet. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get user-friendly error message
  /// 
  /// Converts WalletError to user-friendly message.
  String _getUserFriendlyErrorMessage(WalletError error) {
    switch (error.type) {
      case WalletErrorType.wrongPin:
        return 'Incorrect PIN. Please try again.';
      case WalletErrorType.invalidPinFormat:
        return 'PIN must be 4-8 digits.';
      case WalletErrorType.walletNotFound:
        return 'No wallet found on this device.';
      case WalletErrorType.dataCorrupted:
        return 'Wallet data is corrupted. You may need to restore from backup.';
      case WalletErrorType.storageReadFailure:
        return 'Failed to read wallet data. Please check storage permissions.';
      case WalletErrorType.storageDeleteFailure:
        return 'Failed to delete wallet. Please try again.';
      case WalletErrorType.decryptionFailure:
        return 'Failed to decrypt wallet. Please try again.';
      default:
        return error.message;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Reset controller state
  void reset() {
    _exportedMnemonic.value = null;
    _backupVerified.value = false;
    _errorMessage.value = null;
    _isLoading.value = false;
  }

  @override
  void onClose() {
    // Clear sensitive data when controller is disposed
    _exportedMnemonic.value = null;
    super.onClose();
  }
}
