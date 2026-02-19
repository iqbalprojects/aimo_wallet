import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/vault/secure_vault.dart';
import '../../../../core/vault/vault_exception.dart';
import '../../../../core/vault/secure_memory.dart';
import '../../../../core/crypto/wallet_engine.dart';
import '../../domain/entities/wallet_lock_state.dart';

/// Wallet Lock Controller
/// 
/// Manages wallet lock state with GetX.
/// 
/// Features:
/// - Lock/unlock wallet with PIN
/// - Auto-lock after inactivity
/// - Lock on app background
/// - Biometric authentication (optional)
/// - Secure operation execution
/// 
/// Security:
/// - Decrypted mnemonic never stored globally
/// - Mnemonic exists only during operations
/// - Auto-lock prevents unauthorized access
/// - Background lock protects against shoulder surfing
/// 
/// Usage:
/// ```dart
/// final controller = Get.find<WalletLockController>();
/// 
/// // Unlock wallet
/// await controller.unlock(pin);
/// 
/// // Execute secure operation
/// final result = await controller.executeSecureOperation((mnemonic) {
///   return signTransaction(mnemonic);
/// });
/// 
/// // Lock wallet
/// controller.lock();
/// ```
class WalletLockController extends GetxController with WidgetsBindingObserver {
  final SecureVault _vault;
  final WalletEngine _walletEngine;
  final LocalAuthentication _localAuth;

  /// Current lock state
  final Rx<WalletLockState> _lockState = WalletLockState.locked.obs;

  /// Lock configuration
  final Rx<WalletLockConfig> _config = const WalletLockConfig().obs;

  /// Last activity timestamp
  DateTime? _lastActivityTime;

  /// Auto-lock timer
  Timer? _autoLockTimer;

  /// Wallet address (cached, safe to store)
  final RxnString _walletAddress = RxnString();

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  /// Biometric availability
  final RxBool _biometricAvailable = false.obs;

  WalletLockController({
    SecureVault? vault,
    WalletEngine? walletEngine,
    LocalAuthentication? localAuth,
  })  : _vault = vault ?? SecureVault(),
        _walletEngine = walletEngine ?? WalletEngine(),
        _localAuth = localAuth ?? LocalAuthentication();

  // Getters
  WalletLockState get lockState => _lockState.value;
  bool get isLocked => _lockState.value == WalletLockState.locked;
  bool get isUnlocked => _lockState.value == WalletLockState.unlocked;
  WalletLockConfig get config => _config.value;
  String? get walletAddress => _walletAddress.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  bool get biometricAvailable => _biometricAvailable.value;

  @override
  void onInit() {
    super.onInit();

    // Register as lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Check biometric availability
    _checkBiometricAvailability();

    // Initialize wallet state
    _initializeWalletState();

    // Start auto-lock timer
    _startAutoLockTimer();
  }

  @override
  void onClose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel auto-lock timer
    _autoLockTimer?.cancel();

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Lock wallet when app moves to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_config.value.lockOnBackground && isUnlocked) {
        lock();
      }
    }
  }

  /// Initialize wallet state
  Future<void> _initializeWalletState() async {
    try {
      // Check if wallet exists
      final hasWallet = await _vault.hasWallet();

      if (hasWallet) {
        // Get cached address from vault
        final address = await _vault.getWalletAddress();
        _walletAddress.value = address;

        // Wallet starts locked
        _lockState.value = WalletLockState.locked;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to initialize wallet state';
    }
  }

  /// Check biometric availability
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      _biometricAvailable.value = canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      _biometricAvailable.value = false;
    }
  }

  /// Unlock wallet with PIN
  /// 
  /// Cryptographic Flow:
  /// 1. Verify PIN with vault
  /// 2. Update lock state to unlocked
  /// 3. Reset auto-lock timer
  /// 
  /// Security:
  /// - Mnemonic NOT retrieved during unlock
  /// - Mnemonic only retrieved during operations
  /// - PIN verified without decryption
  /// 
  /// Parameters:
  /// - pin: User's PIN
  /// 
  /// Returns: true if unlock successful, false otherwise
  Future<bool> unlock(String pin) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Verify PIN (does not retrieve mnemonic)
      final isValid = await _vault.verifyPin(pin);

      if (!isValid) {
        _errorMessage.value = 'Invalid PIN';
        return false;
      }

      // Update lock state
      _lockState.value = WalletLockState.unlocked;

      // Reset activity timer
      _resetActivityTimer();

      return true;
    } on VaultException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to unlock wallet';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Unlock wallet with biometric authentication
  /// 
  /// Uses device biometric (fingerprint, face) for authentication.
  /// 
  /// SECURITY CRITICAL:
  /// - Biometric authentication MUST be followed by PIN verification
  /// - Biometric only provides convenience, not security
  /// - PIN is still required for actual mnemonic decryption
  /// 
  /// Flow:
  /// 1. Authenticate with biometric
  /// 2. Prompt user for PIN
  /// 3. Verify PIN with vault
  /// 4. Update lock state
  /// 
  /// Note: This method only handles biometric auth.
  /// Caller must still call unlock(pin) after biometric succeeds.
  Future<bool> authenticateWithBiometric() async {
    if (!_biometricAvailable.value || !_config.value.biometricEnabled) {
      _errorMessage.value = 'Biometric authentication not available';
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Authenticate with biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        _errorMessage.value = 'Biometric authentication failed';
        return false;
      }

      // Biometric authentication successful
      // Caller must still provide PIN for actual unlock
      return true;
    } catch (e) {
      _errorMessage.value = 'Biometric authentication error';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Lock wallet
  /// 
  /// Immediately locks wallet and clears any cached data.
  /// 
  /// Security:
  /// - No mnemonic to clear (never stored globally)
  /// - Lock state prevents operations
  /// - Auto-lock timer reset
  void lock() {
    _lockState.value = WalletLockState.locked;
    _lastActivityTime = null;
    _autoLockTimer?.cancel();
    _errorMessage.value = null;
  }

  /// Execute secure operation with mnemonic
  /// 
  /// Retrieves mnemonic, executes operation, then clears mnemonic.
  /// 
  /// Cryptographic Flow:
  /// 1. Check if wallet is unlocked
  /// 2. Retrieve mnemonic from vault
  /// 3. Execute operation with mnemonic
  /// 4. Clear mnemonic from memory
  /// 5. Reset activity timer
  /// 
  /// Security:
  /// - Mnemonic exists only during operation
  /// - Automatic cleanup (even on error)
  /// - Requires unlocked state
  /// - Resets activity timer
  /// 
  /// Parameters:
  /// - operation: Function that receives mnemonic and returns result
  /// - pin: User's PIN (required for mnemonic retrieval)
  /// 
  /// Returns: Operation result
  /// 
  /// Throws: Exception if wallet locked or operation fails
  /// 
  /// Usage:
  /// ```dart
  /// final signature = await controller.executeSecureOperation(
  ///   (mnemonic) => signTransaction(transaction, mnemonic),
  ///   pin: '123456',
  /// );
  /// ```
  Future<T> executeSecureOperation<T>(
    Future<T> Function(String mnemonic) operation, {
    required String pin,
  }) async {
    // Check if wallet is unlocked
    if (isLocked) {
      throw Exception('Wallet is locked. Unlock before performing operations.');
    }

    String? mnemonic;

    try {
      // Step 1: Retrieve mnemonic from vault
      mnemonic = await _vault.retrieveMnemonic(pin);

      // Step 2: Execute operation with mnemonic
      final result = await operation(mnemonic);

      // Step 3: Reset activity timer
      _resetActivityTimer();

      return result;
    } finally {
      // Step 4: Clear mnemonic from memory (CRITICAL)
      if (mnemonic != null) {
        SecureMemory.clearString(mnemonic);
        mnemonic = null; // Clear reference
      }
    }
  }

  /// Execute secure operation with private key
  /// 
  /// Derives private key from mnemonic, executes operation, then clears key.
  /// 
  /// Security:
  /// - Private key exists only during operation
  /// - Automatic cleanup (even on error)
  /// - Mnemonic cleared after key derivation
  /// 
  /// Parameters:
  /// - operation: Function that receives private key and returns result
  /// - pin: User's PIN (required for mnemonic retrieval)
  /// - accountIndex: Account index for key derivation (default: 0)
  /// 
  /// Usage:
  /// ```dart
  /// final signature = await controller.executeWithPrivateKey(
  ///   (privateKey) => signTransaction(transaction, privateKey),
  ///   pin: '123456',
  /// );
  /// ```
  Future<T> executeWithPrivateKey<T>(
    Future<T> Function(Uint8List privateKey) operation, {
    required String pin,
    int accountIndex = 0,
  }) async {
    return executeSecureOperation((mnemonic) async {
      Uint8List? privateKey;

      try {
        // Derive private key for specified account
        privateKey = _walletEngine.derivePrivateKeyForAccount(
          mnemonic,
          index: accountIndex,
        );

        // Execute operation
        return await operation(privateKey);
      } finally {
        // Clear private key from memory
        if (privateKey != null) {
          SecureMemory.clear(privateKey);
        }
      }
    }, pin: pin);
  }

  /// Update lock configuration
  /// 
  /// Updates auto-lock timeout, background lock, and biometric settings.
  void updateConfig(WalletLockConfig newConfig) {
    _config.value = newConfig;

    // Restart auto-lock timer with new timeout
    if (isUnlocked) {
      _startAutoLockTimer();
    }
  }

  /// Enable biometric authentication
  /// 
  /// Enables biometric unlock if device supports it.
  Future<bool> enableBiometric() async {
    if (!_biometricAvailable.value) {
      _errorMessage.value = 'Biometric not available on this device';
      return false;
    }

    try {
      // Test biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _config.value = _config.value.copyWith(biometricEnabled: true);
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to enable biometric';
      return false;
    }
  }

  /// Disable biometric authentication
  void disableBiometric() {
    _config.value = _config.value.copyWith(biometricEnabled: false);
  }

  /// Reset activity timer
  /// 
  /// Called after successful operations to prevent auto-lock.
  void _resetActivityTimer() {
    _lastActivityTime = DateTime.now();
  }

  /// Start auto-lock timer
  /// 
  /// Checks for inactivity and locks wallet after timeout.
  void _startAutoLockTimer() {
    _autoLockTimer?.cancel();

    _autoLockTimer = Timer.periodic(
      const Duration(seconds: 10), // Check every 10 seconds
      (_) {
        if (isUnlocked && _lastActivityTime != null) {
          final inactiveSeconds =
              DateTime.now().difference(_lastActivityTime!).inSeconds;

          if (inactiveSeconds >= _config.value.autoLockTimeoutSeconds) {
            lock();
          }
        }
      },
    );
  }

  /// Get time until auto-lock
  /// 
  /// Returns seconds until wallet auto-locks.
  /// Returns null if wallet is locked or no activity.
  int? getTimeUntilAutoLock() {
    if (isLocked || _lastActivityTime == null) {
      return null;
    }

    final inactiveSeconds =
        DateTime.now().difference(_lastActivityTime!).inSeconds;
    final remainingSeconds =
        _config.value.autoLockTimeoutSeconds - inactiveSeconds;

    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  /// Check if wallet has been created
  Future<bool> hasWallet() async {
    try {
      return await _vault.hasWallet();
    } catch (e) {
      return false;
    }
  }
}
