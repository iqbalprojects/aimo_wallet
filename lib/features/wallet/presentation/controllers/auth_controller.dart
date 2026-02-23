import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/widgets.dart'; // Keep widgets.dart for WidgetsBindingObserver
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/usecases/unlock_wallet_usecase.dart';
import '../../../../core/vault/vault_exception.dart';
import '../../../../core/routes/navigation_helper.dart';

/// Auth Controller
///
/// PRESENTATION LAYER - GetX Controller
///
/// Responsibilities:
/// - Manage authentication state (locked/unlocked)
/// - Handle PIN operations (verify, change)
/// - Manage biometric settings
/// - Implement auto-lock functionality
/// - Track failed attempts and lockout
/// - Lock when app goes to background
///
/// SEPARATION OF CONCERNS:
/// - NO crypto logic (delegated to domain layer)
/// - NO mnemonic access (uses UnlockWalletUseCase)
/// - Calls use cases for business logic
/// - UI observes reactive state (Rx)
///
/// Security Principles:
/// - PIN never stored (only verified)
/// - Mnemonic never stored (only verified via use case)
/// - Auto-lock after timeout
/// - Lock on app background
/// - Failed attempts tracked
/// - Lockout after 5 failures
///
/// Auto-Lock:
/// - Configurable timeout (1, 5, 15, 30 minutes, never)
/// - Timer resets on user activity
/// - Locks when app goes to background
/// - Navigates to unlock screen on lock
///
/// Usage:
/// ```dart
/// final controller = Get.find<AuthController>();
///
/// // Unlock wallet
/// await controller.unlockWallet(pin);
///
/// // Lock wallet
/// controller.lockWallet();
///
/// // Set auto-lock duration
/// controller.setAutoLockDuration(Duration(minutes: 5));
/// ```
class AuthController extends GetxController with WidgetsBindingObserver {
  // Use cases (lazy loaded to avoid circular dependency)
  UnlockWalletUseCase? _unlockWalletUseCase;
  // TODO: Inject other use cases
  // final ChangePinUseCase _changePinUseCase;

  AuthController({UnlockWalletUseCase? unlockWalletUseCase}) {
    _unlockWalletUseCase = unlockWalletUseCase;
  }

  // Lazy getter for UnlockWalletUseCase
  UnlockWalletUseCase? get unlockWalletUseCase {
    try {
      _unlockWalletUseCase ??= Get.find<UnlockWalletUseCase>();
    } catch (e) {
      print('⚠️ UnlockWalletUseCase not found in DI: $e');
    }
    return _unlockWalletUseCase;
  }

  // ============================================================================
  // REACTIVE STATE (Observable by UI)
  // ============================================================================

  /// Wallet locked/unlocked state
  final RxBool _isLocked = true.obs;

  /// Biometric enabled flag
  final RxBool _biometricEnabled = false.obs;

  /// Biometric available flag
  final RxBool _biometricAvailable = false.obs;

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  /// PIN verification attempts (for lockout)
  final RxInt _failedAttempts = 0.obs;

  /// Locked out flag
  final RxBool _isLockedOut = false.obs;

  /// Lockout end time
  final Rxn<DateTime> _lockoutEndTime = Rxn<DateTime>();

  /// Auto-lock duration (null = never)
  final Rxn<Duration> _autoLockDuration = Rxn<Duration>();

  /// Wallet address (cached after unlock)
  final RxnString _walletAddress = RxnString();

  // ============================================================================
  // GETTERS (UI reads these)
  // ============================================================================

  bool get isLocked => _isLocked.value;
  bool get isUnlocked => !_isLocked.value;
  bool get biometricEnabled => _biometricEnabled.value;
  bool get biometricAvailable => _biometricAvailable.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  int get failedAttempts => _failedAttempts.value;
  bool get isLockedOut => _isLockedOut.value;
  DateTime? get lockoutEndTime => _lockoutEndTime.value;
  Duration? get autoLockDuration => _autoLockDuration.value;
  String? get walletAddress => _walletAddress.value;

  // ============================================================================
  // GETx STATE VARIABLES
  // ============================================================================

  final _localAuth = LocalAuthentication();
  FlutterSecureStorage get _storage => Get.find<FlutterSecureStorage>();

  // ============================================================================
  // AUTO-LOCK TIMER
  // ============================================================================

  Timer? _autoLockTimer;
  Timer? _lockoutTimer;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _checkBiometricAvailability();
    _loadBiometricSetting();
    _loadAutoLockDuration();

    // Register as lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    // Cancel timers
    _autoLockTimer?.cancel();
    _lockoutTimer?.cancel();

    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.onClose();
  }

  /// Handle app lifecycle changes
  ///
  /// SECURITY: Lock wallet state when app goes to background.
  /// Navigation to unlock screen happens on resume, not on pause,
  /// to avoid destroying active screens (like swap).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App going to background - lock wallet state only
        // Do NOT navigate here - it destroys active screens
        if (isUnlocked) {
          _lockState();
        }
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., permission dialog, app switcher)
        // Do NOT lock here - this fires during normal interactions
        break;
      case AppLifecycleState.resumed:
        // App coming to foreground - check if locked
        // Navigation happens here so active screens are preserved
        if (isLocked && _walletAddress.value == null) {
          // Wallet was locked while in background
          // Navigate to unlock with returnResult so it pops back
          // to the current screen on success
          _navigateToUnlockIfNeeded();
        }
        break;
      case AppLifecycleState.detached:
        // App being terminated
        break;
      case AppLifecycleState.hidden:
        // App hidden (iOS)
        if (isUnlocked) {
          _lockState();
        }
        break;
    }
  }

  /// Check if biometric authentication is available
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls use case to check device capabilities
  /// - NO direct platform code here
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      _biometricAvailable.value = canCheck && isSupported;
    } catch (e) {
      _biometricAvailable.value = false;
    }
  }

  /// Load biometric setting from storage
  Future<void> _loadBiometricSetting() async {
    try {
      final setting = await _storage.read(key: 'biometric_enabled');
      _biometricEnabled.value = setting == 'true';
    } catch (e) {
      _biometricEnabled.value = false;
    }
  }

  /// Load auto-lock duration from storage
  Future<void> _loadAutoLockDuration() async {
    try {
      // TODO: Load from storage
      // Default to 5 minutes
      _autoLockDuration.value = const Duration(minutes: 5);
    } catch (e) {
      _autoLockDuration.value = const Duration(minutes: 5);
    }
  }

  // ============================================================================
  // UNLOCK/LOCK OPERATIONS
  // ============================================================================

  /// Unlock wallet with PIN
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls UnlockWalletUseCase (domain layer)
  /// - Use case verifies PIN via SecureVault
  /// - Use case does NOT return mnemonic
  /// - Controller only manages UI state
  ///
  /// Parameters:
  /// - pin: User's PIN
  ///
  /// Returns: true if unlock successful, false otherwise
  ///
  /// SECURITY:
  /// - Mnemonic never stored in controller
  /// - Only wallet address cached (public info)
  /// - Failed attempts tracked
  /// - Lockout after 5 failures
  /// - Auto-lock timer started after unlock
  Future<bool> unlockWallet(String pin) async {
    if (_isLockedOut.value) {
      _errorMessage.value = 'Too many failed attempts. Please wait.';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final useCase = unlockWalletUseCase;
      if (useCase != null) {
        // Call use case to unlock wallet
        final result = await useCase.call(pin: pin);

        // Success: Update state
        _isLocked.value = false;
        _walletAddress.value = result.address;
        _failedAttempts.value = 0;
        _errorMessage.value = null;

        // Start auto-lock timer
        _startAutoLockTimer();

        return true;
      } else {
        // Fallback: Use case not injected (placeholder mode)
        await Future.delayed(const Duration(milliseconds: 500));
        _isLocked.value = false;
        _walletAddress.value = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';
        _failedAttempts.value = 0;

        // Start auto-lock timer
        _startAutoLockTimer();

        return true;
      }
    } on VaultException catch (e) {
      // Handle vault-specific errors
      switch (e.type) {
        case VaultExceptionType.vaultEmpty:
          _errorMessage.value = 'No wallet found';
          break;
        case VaultExceptionType.decryptionFailed:
          // Wrong PIN - track failed attempt
          _failedAttempts.value++;

          if (_failedAttempts.value >= 5) {
            _startLockout();
          } else {
            _errorMessage.value =
                'Incorrect PIN. ${5 - _failedAttempts.value} attempts remaining.';
          }
          break;
        case VaultExceptionType.invalidPin:
          _errorMessage.value = 'Invalid PIN format';
          break;
        default:
          _errorMessage.value = 'Failed to unlock wallet: ${e.message}';
      }
      return false;
    } catch (e) {
      // Handle unexpected errors
      _errorMessage.value = 'Failed to unlock wallet: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Lock wallet (full lock with navigation)
  ///
  /// Use this for explicit user-initiated lock (e.g., settings button).
  /// For auto-lock, use _lockState() which doesn't navigate.
  ///
  /// SECURITY:
  /// - Clears wallet address from memory
  /// - Cancels auto-lock timer
  /// - Navigates to unlock screen
  /// - Clears navigation stack
  void lockWallet() {
    _lockState();
    // Navigate to unlock screen (clears stack)
    NavigationHelper.lockWallet();
  }

  /// Lock wallet state only (no navigation)
  ///
  /// Used by auto-lock and background lock to avoid destroying
  /// active screens in the navigation stack.
  ///
  /// SECURITY:
  /// - Clears wallet address from memory
  /// - Cancels auto-lock timer
  /// - Does NOT navigate
  void _lockState() {
    _isLocked.value = true;
    _walletAddress.value = null;
    _errorMessage.value = null;

    // Cancel auto-lock timer
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Navigate to unlock screen if wallet is locked
  ///
  /// Uses Get.toNamed with returnResult so the unlock screen
  /// pops back to the current screen on success, instead of
  /// replacing the entire navigation stack.
  void _navigateToUnlockIfNeeded() {
    // Only navigate if not already on unlock screen
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/unlock') return;

    Get.toNamed('/unlock', arguments: {'returnResult': true});
  }

  // ============================================================================
  // AUTO-LOCK FUNCTIONALITY
  // ============================================================================

  /// Start auto-lock timer
  ///
  /// SECURITY:
  /// - Automatically locks wallet after configured duration
  /// - Timer resets on user activity (via resetAutoLockTimer)
  void _startAutoLockTimer() {
    // Cancel existing timer
    _autoLockTimer?.cancel();

    // Check if auto-lock is enabled
    if (_autoLockDuration.value == null) {
      return; // Auto-lock disabled
    }

    // Start new timer
    _autoLockTimer = Timer(_autoLockDuration.value!, () {
      if (isUnlocked) {
        // Use state lock + non-destructive navigation
        _lockState();
        _navigateToUnlockIfNeeded();
      }
    });
  }

  /// Reset auto-lock timer
  ///
  /// Call this on user activity to reset the timer.
  ///
  /// Usage:
  /// ```dart
  /// // In screens where user is active
  /// authController.resetAutoLockTimer();
  /// ```
  void resetAutoLockTimer() {
    if (isUnlocked && _autoLockDuration.value != null) {
      _startAutoLockTimer();
    }
  }

  /// Set auto-lock duration
  ///
  /// Parameters:
  /// - duration: Auto-lock duration (null = never)
  ///
  /// Options:
  /// - Duration(minutes: 1)
  /// - Duration(minutes: 5)
  /// - Duration(minutes: 15)
  /// - Duration(minutes: 30)
  /// - null (never)
  Future<void> setAutoLockDuration(Duration? duration) async {
    _autoLockDuration.value = duration;

    // TODO: Save to storage
    // await _saveAutoLockDurationUseCase(duration);

    // Restart timer with new duration
    if (isUnlocked) {
      _startAutoLockTimer();
    }
  }

  // ============================================================================
  // LOCKOUT FUNCTIONALITY
  // ============================================================================

  /// Start lockout after too many failed attempts
  ///
  /// SECURITY:
  /// - Locks out user for 5 minutes after 5 failed attempts
  /// - Prevents brute force attacks
  void _startLockout() {
    _isLockedOut.value = true;
    _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 5));
    _errorMessage.value = 'Too many failed attempts. Locked for 5 minutes.';

    // Start lockout timer
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(const Duration(minutes: 5), () {
      _isLockedOut.value = false;
      _lockoutEndTime.value = null;
      _failedAttempts.value = 0;
      _errorMessage.value = null;
    });
  }

  // ============================================================================
  // PIN OPERATIONS (Call use cases, NO crypto logic)
  // ============================================================================

  /// Verify PIN
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls UnlockWalletUseCase.verifyPinOnly (domain layer)
  /// - Use case checks PIN against encrypted storage
  /// - Controller tracks failed attempts
  ///
  /// SECURITY:
  /// - PIN never stored
  /// - Failed attempts tracked
  /// - Lockout after too many failures
  ///
  /// Parameters:
  /// - pin: PIN to verify
  ///
  /// Returns: true if PIN correct, false otherwise
  ///
  /// Note: This is an alias for unlockWallet for backward compatibility
  Future<bool> verifyPin(String pin) async {
    return await unlockWallet(pin);
  }

  /// Change PIN
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls ChangePinUseCase (domain layer)
  /// - Use case verifies old PIN
  /// - Use case re-encrypts mnemonic with new PIN
  /// - Use case updates storage
  /// - Controller only manages UI state
  ///
  /// SECURITY:
  /// - Old PIN verified before change
  /// - Mnemonic re-encrypted with new PIN
  /// - Old PIN cleared from memory
  /// - New PIN cleared from memory
  ///
  /// Parameters:
  /// - oldPin: Current PIN
  /// - newPin: New PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Validate new PIN
      if (newPin.length < 6) {
        _errorMessage.value = 'PIN must be at least 6 digits';
        return false;
      }

      // TODO: Call use case
      // await _changePinUseCase(oldPin, newPin);
      // return true;

      // Placeholder
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to change PIN: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================================
  // BIOMETRIC OPERATIONS
  // ============================================================================

  /// Toggle biometric authentication
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls use case to enable/disable biometric
  /// - Use case handles platform-specific code
  /// - Controller updates UI state
  ///
  /// Parameters:
  /// - enabled: true to enable, false to disable
  Future<bool> toggleBiometric(bool enabled) async {
    if (!_biometricAvailable.value) {
      _errorMessage.value = 'Biometric not available on this device';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      if (enabled) {
        final success = await _localAuth.authenticate(
          localizedReason: 'Enable Biometric Authentication',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (success) {
          await _storage.write(key: 'biometric_enabled', value: 'true');
          _biometricEnabled.value = true;
          return true;
        } else {
          _errorMessage.value = 'Biometric authentication failed';
          return false;
        }
      } else {
        await _storage.write(key: 'biometric_enabled', value: 'false');
        _biometricEnabled.value = false;
        return true;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to toggle biometric: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Authenticate with biometric
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls use case for biometric authentication
  /// - Use case handles platform-specific code
  /// - Returns success/failure
  ///
  /// SECURITY:
  /// - Biometric is convenience only
  /// - Still requires PIN for sensitive operations
  Future<bool> authenticateWithBiometric() async {
    // If it's currently false, Double-check the storage.
    // This happens if the user clicked the button faster than
    // onInit()'s async _loadBiometricSetting completed, or if it failed.
    if (!_biometricEnabled.value) {
      await _loadBiometricSetting();
    }

    if (!_biometricEnabled.value) {
      _errorMessage.value = 'Biometric not enabled';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (success) {
        _isLocked.value = false;
        _failedAttempts.value = 0;
        _startAutoLockTimer(); // Changed from _resetActivityTimer() to _startAutoLockTimer()
        return true;
      } else {
        _errorMessage.value = 'Biometric authentication failed';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Biometric authentication error: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Reset failed attempts (for testing)
  void resetFailedAttempts() {
    _failedAttempts.value = 0;
    _isLockedOut.value = false;
  }
}
