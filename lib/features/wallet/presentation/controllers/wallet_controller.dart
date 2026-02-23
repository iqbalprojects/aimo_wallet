import 'package:get/get.dart';
import '../../domain/usecases/create_new_wallet_usecase.dart';
import '../../domain/usecases/get_current_address_usecase.dart';
import '../../domain/usecases/get_balance_usecase.dart';
import '../../../../core/vault/vault_exception.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../../../core/network/rpc_client_impl.dart';

/// Wallet Controller (REFACTORED)
///
/// PRESENTATION LAYER - GetX Controller
///
/// CLEAN ARCHITECTURE COMPLIANCE:
/// ✅ NO crypto logic (delegated to domain layer)
/// ✅ NO mnemonic storage (passed via callback only)
/// ✅ NO private key storage (never touches private keys)
/// ✅ Calls use cases for business logic
/// ✅ UI observes reactive state (Rx)
///
/// SECURITY PRINCIPLES:
/// ✅ Address is public info (safe to cache)
/// ✅ Balance is public info (safe to cache)
/// ✅ Mnemonic NEVER stored in controller
/// ✅ Private keys NEVER stored in controller
/// ✅ All sensitive operations via use cases
///
/// Responsibilities:
/// - Expose reactive state for UI
/// - Coordinate wallet operations via use cases
/// - Manage wallet lifecycle (create, import, backup)
/// - Provide wallet information (address, balance)
///
/// Usage:
/// ```dart
/// final controller = Get.find<WalletController>();
///
/// // Create wallet with callback
/// await controller.createWallet(
///   pin: pin,
///   onSuccess: (mnemonic, address) {
///     // Handle mnemonic immediately
///     NavigationHelper.navigateToBackup(mnemonic: mnemonic);
///   },
/// );
///
/// // Get address (reactive)
/// Obx(() => Text(controller.currentAddress.value));
/// ```
class WalletController extends GetxController {
  // Use cases (injected via dependency injection)
  final CreateNewWalletUseCase? _createNewWalletUseCase;
  final GetCurrentAddressUseCase? _getCurrentAddressUseCase;
  final GetBalanceUseCase? _getBalanceUseCase;

  WalletController({
    CreateNewWalletUseCase? createNewWalletUseCase,
    GetCurrentAddressUseCase? getCurrentAddressUseCase,
    GetBalanceUseCase? getBalanceUseCase,
  }) : _createNewWalletUseCase = createNewWalletUseCase,
       _getCurrentAddressUseCase = getCurrentAddressUseCase,
       _getBalanceUseCase = getBalanceUseCase;

  // ============================================================================
  // REACTIVE STATE (Observable by UI)
  // ============================================================================

  /// Current wallet address (public info, safe to cache)
  ///
  /// SECURITY: Address is public information
  /// - Safe to display in UI
  /// - Safe to cache in memory
  /// - No sensitive data
  final RxString _currentAddress = ''.obs;

  /// Wallet balance in ETH
  final RxString _balance = '0.0'.obs;

  /// USD value of balance
  final RxString _balanceUsd = '0.00'.obs;

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  /// Wallet exists flag
  final RxBool _hasWallet = false.obs;

  // ============================================================================
  // GETTERS (UI reads these)
  // ============================================================================

  /// Current wallet address (reactive)
  RxString get currentAddress => _currentAddress;

  String get balance => _balance.value;
  String get balanceUsd => _balanceUsd.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  bool get hasWallet => _hasWallet.value;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _initializeWallet();
  }

  /// Initialize wallet state
  ///
  /// Checks if wallet exists and loads address if available.
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls GetCurrentAddressUseCase (domain layer)
  /// - Use case checks vault for wallet
  /// - Controller updates reactive state
  Future<void> _initializeWallet() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final useCase = _getCurrentAddressUseCase;
      if (useCase != null) {
        try {
          final address = await useCase.call();

          // Wallet exists
          _hasWallet.value = true;
          _currentAddress.value = address;

          // Load balance
          await refreshBalance();
        } on VaultException catch (e) {
          if (e.type == VaultExceptionType.vaultEmpty) {
            // No wallet exists
            _hasWallet.value = false;
            _currentAddress.value = '';
          } else {
            rethrow;
          }
        }
      } else {
        // Use case not injected - check manually
        // This is fallback for testing
        _hasWallet.value = false;
        _currentAddress.value = '';
      }
    } catch (e) {
      _errorMessage.value = 'Failed to initialize wallet';
      _hasWallet.value = false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================================
  // WALLET OPERATIONS (Call use cases, NO crypto logic, NO mnemonic storage)
  // ============================================================================

  /// Create new wallet
  ///
  /// CLEAN ARCHITECTURE:
  /// - Calls CreateNewWalletUseCase (domain layer)
  /// - Use case generates mnemonic via WalletEngine
  /// - Use case stores encrypted mnemonic in SecureVault
  /// - Mnemonic returned via callback ONLY
  /// - Controller NEVER stores mnemonic
  ///
  /// SECURITY:
  /// - Mnemonic passed to callback immediately
  /// - Caller must handle mnemonic securely
  /// - Controller does not retain mnemonic
  ///
  /// Parameters:
  /// - pin: User's PIN for encryption
  /// - onSuccess: Callback with mnemonic and address
  ///
  /// Usage:
  /// ```dart
  /// await controller.createWallet(
  ///   pin: '123456',
  ///   onSuccess: (mnemonic, address) {
  ///     // Navigate to backup screen
  ///     NavigationHelper.navigateToBackup(mnemonic: mnemonic);
  ///   },
  /// );
  /// ```
  Future<void> createWallet({
    required String pin,
    required Function(String mnemonic, String address) onSuccess,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final useCase = _createNewWalletUseCase;
      if (useCase != null) {
        // Call use case
        final result = await useCase.call(pin: pin);

        // Update state
        _hasWallet.value = true;
        _currentAddress.value = result.address;

        // Pass mnemonic to callback immediately
        // Controller does NOT store mnemonic
        onSuccess(result.mnemonic, result.address);
      } else {
        throw Exception('CreateNewWalletUseCase not initialized');
      }
    } on VaultException catch (e) {
      // Handle vault-specific errors
      switch (e.type) {
        case VaultExceptionType.vaultNotEmpty:
          _errorMessage.value = 'Wallet already exists';
          break;
        case VaultExceptionType.invalidPin:
          _errorMessage.value = 'Invalid PIN format';
          break;
        case VaultExceptionType.encryptionFailed:
          _errorMessage.value = 'Failed to encrypt wallet';
          break;
        case VaultExceptionType.storageFailed:
          _errorMessage.value = 'Failed to store wallet';
          break;
        default:
          _errorMessage.value = e.message;
      }
    } catch (e) {
      // Handle unexpected errors
      _errorMessage.value = 'Failed to create wallet: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Import existing wallet
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls ImportWalletUseCase (domain layer)
  /// - Use case validates mnemonic
  /// - Use case stores encrypted mnemonic
  /// - Controller updates UI state
  ///
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase
  /// - pin: User's PIN for encryption
  Future<bool> importWallet(String mnemonic, String pin) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // TODO: Call use case
      // final address = await _importWalletUseCase(mnemonic, pin);
      // _currentAddress.value = address;

      // Placeholder
      await Future.delayed(const Duration(seconds: 2));
      _currentAddress.value = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';
      _hasWallet.value = true;
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to import wallet: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh wallet balance
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls GetBalanceUseCase (domain layer)
  /// - Use case queries blockchain via RPC
  /// - Controller updates reactive state
  Future<void> refreshBalance() async {
    if (_currentAddress.value.isEmpty) return;

    // Reset balance to indicate loading state for flawless UI transition
    _balance.value = '...';
    _balanceUsd.value = '...';
    _isLoading.value = true;

    try {
      final networkController = Get.find<NetworkController>();

      // If "All Networks" is active (currentNetwork == null)
      if (networkController.currentNetwork == null) {
        double totalBalanceEth = 0.0;
        double totalBalanceUsd = 0.0;
        final ethPrice = 2000.0; // Placeholder

        // Only query mainnets to avoid testnet fake ETH from inflating true sum
        final mainnets = networkController.networks.where((n) => !n.isTestnet);

        for (final network in mainnets) {
          try {
            final rpcClient = RpcClientImpl(rpcUrl: network.rpcUrl);
            final useCase = GetBalanceUseCase(rpcClient: rpcClient);
            final balanceResult = await useCase.call(
              address: _currentAddress.value,
            );
            final balanceValue =
                double.tryParse(balanceResult.balanceEth) ?? 0.0;
            totalBalanceEth += balanceValue;
          } catch (e) {
            print('Failed to fetch balance for ${network.name}: $e');
            // Continue to next network even if one fails
          }
        }

        // Format and remove trailing zeros
        String formattedEth = totalBalanceEth.toStringAsFixed(6);
        formattedEth = formattedEth.replaceAll(RegExp(r'0+$'), '');
        formattedEth = formattedEth.replaceAll(RegExp(r'\.$'), '');
        if (formattedEth.isEmpty || formattedEth == '.') {
          formattedEth = '0.00';
        }

        _balance.value = formattedEth;

        totalBalanceUsd = totalBalanceEth * ethPrice;
        _balanceUsd.value = totalBalanceUsd.toStringAsFixed(2);

        return;
      }

      // Single network logic
      GetBalanceUseCase? useCase;
      try {
        useCase = Get.find<GetBalanceUseCase>();
      } catch (e) {
        useCase = _getBalanceUseCase;
      }

      if (useCase != null) {
        // Query real balance from blockchain
        final balanceResult = await useCase.call(
          address: _currentAddress.value,
        );

        _balance.value = balanceResult.balanceEth;

        // TODO: Get USD price and calculate balanceUsd
        // For now, use placeholder
        final ethPrice = 2000.0; // Placeholder
        final balanceValue = double.tryParse(balanceResult.balanceEth) ?? 0.0;
        _balanceUsd.value = (balanceValue * ethPrice).toStringAsFixed(2);
      } else {
        // Fallback: Use placeholder
        await Future.delayed(const Duration(milliseconds: 800));
        _balance.value = '1.234';
        _balanceUsd.value = '2,468.00';
      }
    } catch (e, st) {
      print('WalletController.refreshBalance Error: $e\n$st');
      _errorMessage.value = 'Failed to refresh balance: ${e.toString()}';
      // Fallback to 0.00 so it doesn't get stuck at ...
      _balance.value = '0.00';
      _balanceUsd.value = '0.00';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }
}
