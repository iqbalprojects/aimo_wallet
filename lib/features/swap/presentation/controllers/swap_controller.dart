import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../../domain/entities/swap_quote.dart';
import '../../domain/usecases/check_allowance_usecase.dart';
import '../../domain/usecases/get_swap_quote_usecase.dart';
import '../../domain/usecases/swap_preparation_usecase.dart';
import '../../domain/usecases/approve_token_usecase.dart';
import '../../domain/usecases/execute_swap_usecase.dart';
import '../helpers/swap_error_helper.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../wallet/presentation/controllers/auth_controller.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../../transaction/domain/usecases/get_nonce_usecase.dart';
import '../../../transaction/domain/usecases/estimate_gas_usecase.dart';
import '../../../transaction/domain/usecases/sign_transaction_usecase.dart';
import '../../../transaction/domain/usecases/broadcast_transaction_usecase.dart';
import '../../../../core/blockchain/evm/gas/gas_price_oracle_service.dart';

/// Swap Controller
///
/// PRESENTATION LAYER - GetX Controller
///
/// Responsibilities:
/// - Manage swap operation state
/// - Coordinate swap flow via use cases
/// - Provide reactive state for UI binding
///
/// SEPARATION OF CONCERNS:
/// - NO crypto logic (delegated to domain layer)
/// - NO signing logic (uses SignTransactionUseCase)
/// - NO mnemonic access (uses AuthController)
/// - Calls use cases for business logic
/// - UI observes reactive state (Rx)
///
/// Security Principles:
/// - Private keys NEVER stored
/// - Mnemonic NEVER stored
/// - Signing happens in domain layer
/// - Wallet must be unlocked before signing
/// - All sensitive operations via use cases
/// - Clear sensitive data after operations
///
/// Swap Flow:
/// 1. getQuote() - Fetch swap quote from 0x
/// 2. prepareSwap() - Validate balance & allowance
/// 3. If allowance insufficient:
///    - buildApproveTransaction()
///    - Sign and broadcast approval
/// 4. executeSwap() - Build, sign, broadcast swap
///
/// Usage:
/// ```dart
/// final controller = Get.find<SwapController>();
///
/// // Get quote
/// await controller.getQuote(
///   sellToken: '0xUSDT...',
///   buyToken: '0xWETH...',
///   sellAmount: BigInt.from(100000000),
///   slippage: 0.01,
/// );
///
/// // Observe state
/// Obx(() => {
///   if (controller.isLoading) return LoadingWidget();
///   if (controller.error != null) return ErrorWidget(controller.error!);
///   return SwapQuoteWidget(controller.swapQuote);
/// });
/// ```
class SwapController extends GetxController {
  // Services (fetched lazily via getters)
  AuthController? _authController;
  NetworkController? _networkController;
  GasPriceOracleService? _gasPriceOracleService;

  SwapController({
    AuthController? authController,
    NetworkController? networkController,
    GasPriceOracleService? gasPriceOracleService,
  }) {
    _authController = authController;
    _networkController = networkController;
    _gasPriceOracleService = gasPriceOracleService;
  }

  // Lazy getters for dependencies
  // We use Get.find directly rather than caching so they get properly reinitialized on network change
  GetSwapQuoteUseCase? get getSwapQuoteUseCase {
    try {
      return Get.find<GetSwapQuoteUseCase>();
    } catch (e) {
      return null;
    }
  }

  SwapPreparationUseCase? get swapPreparationUseCase {
    try {
      return Get.find<SwapPreparationUseCase>();
    } catch (e) {
      return null;
    }
  }

  CheckAllowanceUseCase? get checkAllowanceUseCase {
    try {
      return Get.find<CheckAllowanceUseCase>();
    } catch (e) {
      return null;
    }
  }

  ApproveTokenUseCase? get approveTokenUseCase {
    try {
      return Get.find<ApproveTokenUseCase>();
    } catch (e) {
      return null;
    }
  }

  ExecuteSwapUseCase? get executeSwapUseCase {
    try {
      return Get.find<ExecuteSwapUseCase>();
    } catch (e) {
      return null;
    }
  }

  GetNonceUseCase? get getNonceUseCase {
    try {
      return Get.find<GetNonceUseCase>();
    } catch (e) {
      return null;
    }
  }

  SignTransactionUseCase? get signTransactionUseCase {
    try {
      return Get.find<SignTransactionUseCase>();
    } catch (e) {
      return null;
    }
  }

  BroadcastTransactionUseCase? get broadcastTransactionUseCase {
    try {
      return Get.find<BroadcastTransactionUseCase>();
    } catch (e) {
      return null;
    }
  }

  AuthController? get authController {
    try {
      _authController ??= Get.find<AuthController>();
    } catch (e) {
      // Controller not registered yet
    }
    return _authController;
  }

  NetworkController? get networkController {
    try {
      _networkController ??= Get.find<NetworkController>();
    } catch (e) {
      // Controller not registered yet
    }
    return _networkController;
  }

  GasPriceOracleService? get gasPriceOracleService {
    try {
      _gasPriceOracleService ??= Get.find<GasPriceOracleService>();
    } catch (e) {
      // Service not registered yet
    }
    return _gasPriceOracleService;
  }

  // ============================================================================
  // REACTIVE STATE (Observable by UI)
  // ============================================================================

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  /// Current swap quote
  final Rxn<SwapQuote> _swapQuote = Rxn<SwapQuote>();

  /// Swap preparation result
  final Rxn<SwapPreparationResult> _preparationResult =
      Rxn<SwapPreparationResult>();

  /// Current swap step (for UI progress)
  final Rx<SwapStep> _currentStep = SwapStep.idle.obs;

  /// Approval transaction (unsigned)
  final Rxn<Transaction> _approveTransaction = Rxn<Transaction>();

  /// Swap transaction hash (after broadcast)
  final RxnString _swapTxHash = RxnString();

  /// Approval transaction hash (after broadcast)
  final RxnString _approveTxHash = RxnString();

  /// Sell token address (stored when getting quote)
  final RxnString _sellTokenAddress = RxnString();

  // ============================================================================
  // GETTERS (UI reads these)
  // ============================================================================

  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  SwapQuote? get swapQuote => _swapQuote.value;
  SwapPreparationResult? get preparationResult => _preparationResult.value;
  SwapStep get currentStep => _currentStep.value;
  Transaction? get approveTransaction => _approveTransaction.value;
  String? get swapTxHash => _swapTxHash.value;
  String? get approveTxHash => _approveTxHash.value;
  String? get sellTokenAddress => _sellTokenAddress.value;

  // Convenience getters
  bool get hasEnoughBalance =>
      _preparationResult.value?.hasEnoughBalance ?? false;
  bool get needsApproval => _preparationResult.value?.needsApproval ?? false;
  BigInt? get balanceShortfall => _preparationResult.value?.balanceShortfall;
  BigInt? get neededAllowance => _preparationResult.value?.neededAllowance;

  /// Check if wallet is unlocked (via AuthController)
  bool get isWalletUnlocked {
    final auth = authController;
    if (auth == null) return false;
    return auth.isUnlocked;
  }

  /// Check if swap is ready (all conditions met)
  bool get canSwap {
    return swapQuote != null &&
        !needsApproval &&
        hasEnoughBalance &&
        isWalletUnlocked &&
        !isLoading;
  }

  // ============================================================================
  // SWAP OPERATIONS
  // ============================================================================

  /// Step 1: Get swap quote from 0x API
  ///
  /// Fetches the best available swap route for the token pair.
  ///
  /// Parameters:
  /// - sellToken: Token address to sell
  /// - buyToken: Token address to buy
  /// - sellAmount: Amount to sell in smallest units
  /// - slippage: Maximum acceptable price movement (0.01 = 1%)
  ///
  /// Returns: SwapQuote or null on error
  Future<SwapQuote?> getQuote({
    required String sellToken,
    required String buyToken,
    required BigInt sellAmount,
    required double slippage,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _currentStep.value = SwapStep.gettingQuote;

    try {
      final walletAddress = Get.find<WalletController>().currentAddress.value;
      if (walletAddress.isEmpty) {
        _errorMessage.value = 'Wallet not connected';
        return null;
      }

      final useCase = getSwapQuoteUseCase;
      if (useCase == null) {
        _errorMessage.value = 'Swap service not available';
        return null;
      }

      final quote = await useCase.call(
        sellToken: sellToken,
        buyToken: buyToken,
        sellAmount: sellAmount,
        walletAddress: walletAddress,
        slippage: slippage,
      );

      _swapQuote.value = quote;
      _sellTokenAddress.value = sellToken;
      _currentStep.value = SwapStep.quoteReady;
      return quote;
    } catch (e, stackTrace) {
      _errorMessage.value = SwapErrorHelper.handleError(
        'getQuote',
        e,
        stackTrace: stackTrace,
      );
      _currentStep.value = SwapStep.error;
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Step 2: Prepare swap - validate balance and allowance
  ///
  /// Checks if user has enough balance and if token is approved.
  ///
  /// Parameters:
  /// - tokenAddress: Token to sell
  /// - spenderAddress: DEX router or allowance target
  /// - sellAmount: Amount to sell
  ///
  /// Returns: SwapPreparationResult or null on error
  Future<SwapPreparationResult?> prepareSwap({
    required String tokenAddress,
    required String spenderAddress,
    required BigInt sellAmount,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _currentStep.value = SwapStep.preparing;

    try {
      final walletAddress = Get.find<WalletController>().currentAddress.value;
      if (walletAddress.isEmpty) {
        _errorMessage.value = 'Wallet not connected';
        return null;
      }

      final useCase = swapPreparationUseCase;
      if (useCase == null) {
        _errorMessage.value = 'Swap service not available';
        return null;
      }

      final result = await useCase.call(
        tokenAddress: tokenAddress,
        walletAddress: walletAddress,
        spenderAddress: spenderAddress,
        sellAmount: sellAmount,
      );

      _preparationResult.value = result;

      if (!result.hasEnoughBalance) {
        _errorMessage.value = 'Insufficient balance';
        _currentStep.value = SwapStep.error;
      } else if (result.needsApproval) {
        _currentStep.value = SwapStep.needsApproval;
      } else {
        _currentStep.value = SwapStep.readyToSwap;
      }

      return result;
    } catch (e, stackTrace) {
      _errorMessage.value = SwapErrorHelper.handleError(
        'prepareSwap',
        e,
        stackTrace: stackTrace,
      );
      _currentStep.value = SwapStep.error;
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Step 3a: Build approve transaction (if allowance insufficient)
  ///
  /// Creates an unsigned approve transaction for signing.
  ///
  /// Parameters:
  /// - tokenAddress: Token to approve
  /// - spenderAddress: Address to approve
  /// - amount: Amount to approve
  ///
  /// Returns: Unsigned Transaction or null on error
  Future<Transaction?> buildApproveTransaction({
    required String tokenAddress,
    required String spenderAddress,
    required BigInt amount,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    _currentStep.value = SwapStep.buildingApproval;

    try {
      final useCase = approveTokenUseCase;
      if (useCase == null) {
        _errorMessage.value = 'Swap service not available';
        return null;
      }

      final transaction = await useCase.call(
        contractAddress: tokenAddress,
        spender: spenderAddress,
        amount: amount,
      );

      _approveTransaction.value = transaction;
      _currentStep.value = SwapStep.approvalReady;
      return transaction;
    } catch (e, stackTrace) {
      _errorMessage.value = SwapErrorHelper.handleError(
        'buildApproveTransaction',
        e,
        stackTrace: stackTrace,
      );
      _currentStep.value = SwapStep.error;
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Step 3b: Sign and broadcast approval transaction
  ///
  /// Signs the approval transaction with user's private key and broadcasts.
  /// Requires PIN for signing.
  ///
  /// Parameters:
  /// - tokenAddress: Token address (for nonce)
  /// - pin: User's PIN for signing
  ///
  /// Returns: Transaction hash or null on error
  Future<String?> signAndBroadcastApproval({
    required String tokenAddress,
    required String pin,
  }) async {
    final transaction = _approveTransaction.value;
    if (transaction == null) {
      _errorMessage.value = 'No approval transaction built';
      return null;
    }

    _isLoading.value = true;
    _errorMessage.value = null;
    _currentStep.value = SwapStep.signingApproval;

    try {
      final walletAddress = Get.find<WalletController>().currentAddress.value;
      if (walletAddress.isEmpty) {
        _errorMessage.value = 'Wallet not connected';
        return null;
      }

      final network = networkController?.currentNetwork;
      if (network == null) {
        _errorMessage.value = 'No network selected';
        return null;
      }

      // Get nonce
      final nonceUseCase = getNonceUseCase;
      if (nonceUseCase == null) {
        _errorMessage.value = 'Nonce service not available';
        return null;
      }
      final nonce = await nonceUseCase.call(address: walletAddress);

      // Fetch dynamic gas price from oracle, fallback to 20 Gwei
      BigInt gasPrice;
      try {
        final oracle = gasPriceOracleService;
        if (oracle != null) {
          gasPrice = await oracle.getRecommendedGasPrice(GasSpeed.standard);
        } else {
          gasPrice = BigInt.from(20000000000); // 20 Gwei fallback
        }
      } catch (_) {
        gasPrice = BigInt.from(20000000000); // 20 Gwei fallback
      }

      // Estimate gas dynamically instead of hardcoding.
      // Use EstimateGasUseCase if available, fallback to safe 150_000.
      BigInt gasLimit;
      try {
        final estimateUseCase = Get.find<EstimateGasUseCase>();
        final gasEstimate = await estimateUseCase.call(
          from: walletAddress,
          to: tokenAddress,
          data: transaction.data != null
              ? '0x${_bytesToHex(transaction.data!)}'
              : null,
          value: BigInt.zero,
        );
        // Add 20% buffer on top of the estimate (which already includes 10% buffer)
        gasLimit = (gasEstimate.gasLimit * BigInt.from(12)) ~/ BigInt.from(10);
      } catch (_) {
        gasLimit = BigInt.from(150000); // Safe fallback for approve
      }

      // Build EvmTransaction with dynamically estimated gas
      final evmTransaction = EvmTransaction(
        to: tokenAddress,
        data: transaction.data != null
            ? '0x${_bytesToHex(transaction.data!)}'
            : null,
        value: BigInt.zero,
        gasLimit: gasLimit,
        gasPrice: gasPrice,
        chainId: network.chainId,
        nonce: nonce,
      );

      // Sign transaction
      final signUseCase = signTransactionUseCase;
      if (signUseCase == null) {
        _errorMessage.value = 'Signing service not available';
        return null;
      }

      final signedTx = await signUseCase.call(
        transaction: evmTransaction,
        pin: pin,
      );

      // Broadcast transaction
      final broadcastUseCase = broadcastTransactionUseCase;
      if (broadcastUseCase == null) {
        _errorMessage.value = 'Broadcast service not available';
        return null;
      }

      final result = await broadcastUseCase.call(signedTransaction: signedTx);

      _approveTxHash.value = result.transactionHash;

      // Clear approval transaction after use
      _approveTransaction.value = null;

      // Wait 3 seconds for tx to propagate before rechecking allowance
      await Future.delayed(const Duration(seconds: 3));
      await _recheckAllowance();

      return result.transactionHash;
    } catch (e, stackTrace) {
      _errorMessage.value = SwapErrorHelper.handleError(
        'signAndBroadcastApproval',
        e,
        stackTrace: stackTrace,
      );
      _currentStep.value = SwapStep.error;
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Re-check allowance after approval transaction
  ///
  /// Fetches fresh allowance state from blockchain (no manual storage).
  /// Called automatically after successful approval.
  Future<void> _recheckAllowance() async {
    final quote = _swapQuote.value;
    final sellToken = _sellTokenAddress.value;
    if (quote == null || sellToken == null) return;

    final walletAddress = Get.find<WalletController>().currentAddress.value;
    if (walletAddress.isEmpty) return;

    final useCase = swapPreparationUseCase;
    if (useCase == null) return;

    try {
      final result = await useCase.call(
        tokenAddress: sellToken,
        walletAddress: walletAddress,
        spenderAddress: quote.allowanceTarget,
        sellAmount: quote.sellAmount,
      );

      _preparationResult.value = result;

      if (!result.needsApproval) {
        // Approval successful, ready to swap
        _currentStep.value = SwapStep.readyToSwap;
      }
      // If still needs approval, user may need to wait for tx confirmation
    } catch (e) {
      // Log but don't fail - allowance check can be retried
      _errorMessage.value =
          'Could not verify approval. Please wait for transaction confirmation.';
    }
  }

  /// Step 4: Execute swap - build, sign, and broadcast
  ///
  /// Builds the swap transaction, signs with user's private key,
  /// and broadcasts to the network.
  ///
  /// Parameters:
  /// - pin: User's PIN for signing
  ///
  /// Returns: Transaction hash or null on error
  Future<String?> executeSwap({required String pin}) async {
    final quote = _swapQuote.value;
    if (quote == null) {
      _errorMessage.value = 'No swap quote available';
      return null;
    }

    _isLoading.value = true;
    _errorMessage.value = null;
    _currentStep.value = SwapStep.executing;

    try {
      final walletAddress = Get.find<WalletController>().currentAddress.value;
      if (walletAddress.isEmpty) {
        _errorMessage.value = 'Wallet not connected';
        return null;
      }

      final network = networkController?.currentNetwork;
      if (network == null) {
        _errorMessage.value = 'No network selected';
        return null;
      }

      // Get nonce
      final nonceUseCase = getNonceUseCase;
      if (nonceUseCase == null) {
        _errorMessage.value = 'Nonce service not available';
        return null;
      }
      final nonce = await nonceUseCase.call(address: walletAddress);

      // Build swap transaction
      final executeUseCase = executeSwapUseCase;
      if (executeUseCase == null) {
        _errorMessage.value = 'Swap service not available';
        return null;
      }

      final evmTransaction = executeUseCase.call(
        quote: quote,
        chainId: network.chainId,
        nonce: nonce,
      );

      // Sign transaction
      final signUseCase = signTransactionUseCase;
      if (signUseCase == null) {
        _errorMessage.value = 'Signing service not available';
        return null;
      }

      final signedTx = await signUseCase.call(
        transaction: evmTransaction,
        pin: pin,
        permit2Eip712: quote.permit2Eip712,
      );

      // Broadcast transaction
      final broadcastUseCase = broadcastTransactionUseCase;
      if (broadcastUseCase == null) {
        _errorMessage.value = 'Broadcast service not available';
        return null;
      }

      final result = await broadcastUseCase.call(signedTransaction: signedTx);

      _swapTxHash.value = result.transactionHash;
      _currentStep.value = SwapStep.completed;

      return result.transactionHash;
    } catch (e, stackTrace) {
      _errorMessage.value = SwapErrorHelper.handleError(
        'executeSwap',
        e,
        stackTrace: stackTrace,
      );
      _currentStep.value = SwapStep.error;
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  /// Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Reset swap state (clear all data)
  void reset() {
    _isLoading.value = false;
    _errorMessage.value = null;
    _swapQuote.value = null;
    _preparationResult.value = null;
    _currentStep.value = SwapStep.idle;
    _approveTransaction.value = null;
    _swapTxHash.value = null;
    _approveTxHash.value = null;
    _sellTokenAddress.value = null;
  }

  /// Clear sensitive data after operation
  void clearSensitiveData() {
    _approveTransaction.value = null;
  }

  @override
  void onClose() {
    // Clear sensitive data on controller disposal
    clearSensitiveData();
    super.onClose();
  }
}

/// Swap step enum for UI progress tracking
enum SwapStep {
  /// Initial state
  idle,

  /// Fetching quote from 0x
  gettingQuote,

  /// Quote ready for review
  quoteReady,

  /// Preparing swap (checking balance/allowance)
  preparing,

  /// Needs approval before swap
  needsApproval,

  /// Building approval transaction
  buildingApproval,

  /// Approval transaction ready for signing
  approvalReady,

  /// Signing approval transaction
  signingApproval,

  /// Ready to execute swap
  readyToSwap,

  /// Executing swap
  executing,

  /// Swap completed successfully
  completed,

  /// Error occurred
  error,
}
