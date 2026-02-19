import 'package:get/get.dart';
import '../../domain/usecases/unlock_wallet_usecase.dart';
import '../../domain/entities/wallet_error.dart';

/// Wallet Unlock Controller
/// 
/// Handles wallet authentication and unlocking:
/// 1. Accept PIN input
/// 2. Call UnlockWalletUseCase to authenticate and decrypt
/// 3. Update WalletController state to unlocked
/// 4. Handle authentication errors with specific messages
/// 
/// Requirements: 6.1, 6.2, 6.3, 6.4, 9.5
/// 
/// Security: Uses constant-time PIN comparison, distinguishes error types
/// 
/// Usage:
/// ```dart
/// final controller = Get.find<WalletUnlockController>();
/// 
/// // Unlock wallet with PIN
/// final success = await controller.unlockWallet(pin);
/// if (success) {
///   // Wallet is now unlocked
/// } else {
///   // Show error message
///   print(controller.errorMessage);
/// }
/// ```
class WalletUnlockController extends GetxController {
  final UnlockWalletUseCase _unlockWalletUseCase;

  final RxBool _isLoading = false.obs;
  final RxnString _errorMessage = RxnString();
  final Rxn<WalletErrorType> _errorType = Rxn<WalletErrorType>();

  WalletUnlockController({
    required UnlockWalletUseCase unlockWalletUseCase,
  }) : _unlockWalletUseCase = unlockWalletUseCase;

  // Observable getters
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  WalletErrorType? get errorType => _errorType.value;

  /// Unlock wallet with PIN
  /// 
  /// Authenticates user and unlocks wallet.
  /// Updates WalletController state to unlocked on success.
  /// 
  /// Requirements: 6.1, 6.2, 6.3, 6.4
  /// 
  /// Parameters:
  /// - pin: User's PIN (4-8 digits)
  /// 
  /// Returns: true if unlock successful, false otherwise
  /// 
  /// Error handling (Requirement 9.5):
  /// - wrongPin: Incorrect PIN entered
  /// - dataCorrupted: Stored data is corrupted
  /// - storageReadFailure: Failed to read from storage
  /// - walletNotFound: No wallet exists on device
  Future<bool> unlockWallet(String pin) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _errorType.value = null;

    try {
      // Unlock wallet (authenticate and decrypt)
      await _unlockWalletUseCase.call(pin: pin);

      // Note: Wallet is now unlocked. The AuthController manages
      // the lock/unlock state. WalletController manages wallet existence.
      // No manual state update needed here.

      return true;
    } on WalletError catch (e) {
      // Store error type for specific handling
      _errorType.value = e.type;
      _errorMessage.value = _getUserFriendlyErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to unlock wallet. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get user-friendly error message
  /// 
  /// Converts WalletError to user-friendly message.
  /// Distinguishes between authentication failures and system errors.
  /// 
  /// Requirements: 9.5
  String _getUserFriendlyErrorMessage(WalletError error) {
    switch (error.type) {
      // Authentication errors
      case WalletErrorType.wrongPin:
        return 'Incorrect PIN. Please try again.';
      case WalletErrorType.invalidPinFormat:
        return 'PIN must be 4-8 digits.';
      case WalletErrorType.walletNotFound:
        return 'No wallet found on this device.';

      // System errors
      case WalletErrorType.dataCorrupted:
        return 'Wallet data is corrupted. You may need to restore from backup.';
      case WalletErrorType.storageReadFailure:
        return 'Failed to read wallet data. Please check storage permissions.';
      case WalletErrorType.decryptionFailure:
        return 'Failed to decrypt wallet. Please try again.';

      // Generic error
      default:
        return error.message;
    }
  }

  /// Check if error is authentication failure
  /// 
  /// Returns true if error is due to wrong PIN (not system error).
  bool get isAuthenticationError {
    return _errorType.value == WalletErrorType.wrongPin ||
        _errorType.value == WalletErrorType.invalidPinFormat;
  }

  /// Check if error is system error
  /// 
  /// Returns true if error is due to storage/corruption (not wrong PIN).
  bool get isSystemError {
    return _errorType.value == WalletErrorType.dataCorrupted ||
        _errorType.value == WalletErrorType.storageReadFailure ||
        _errorType.value == WalletErrorType.decryptionFailure;
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
    _errorType.value = null;
  }

  /// Reset controller state
  void reset() {
    _errorMessage.value = null;
    _errorType.value = null;
    _isLoading.value = false;
  }
}
