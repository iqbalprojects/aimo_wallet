import 'package:get/get.dart';
import '../../domain/usecases/sign_transaction_usecase.dart';
import '../../domain/entities/transaction.dart';
import '../../../wallet/presentation/controllers/auth_controller.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../domain/usecases/get_nonce_usecase.dart';
import '../../domain/usecases/estimate_gas_usecase.dart';
import '../../domain/usecases/broadcast_transaction_usecase.dart';

/// Transaction Controller
///
/// PRESENTATION LAYER - GetX Controller
///
/// Responsibilities:
/// - Manage transaction state
/// - Coordinate transaction operations via use cases
/// - Provide transaction history
/// - Estimate gas fees
/// - Send transactions
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
/// - Signing happens in domain layer
/// - Wallet must be unlocked before signing
/// - All sensitive operations via use cases
///
/// Usage:
/// ```dart
/// final controller = Get.find<TransactionController>();
///
/// // Estimate gas
/// await controller.estimateGas(to, amount);
///
/// // Send transaction
/// final txHash = await controller.sendTransaction(to, amount, pin);
///
/// // Get transaction history
/// Obx(() => ListView(children: controller.transactions));
/// ```
class TransactionController extends GetxController {
  // Use cases (lazy loaded to avoid circular dependency)
  SignTransactionUseCase? _signTransactionUseCase;
  AuthController? _authController;
  NetworkController? _networkController;

  TransactionController({
    SignTransactionUseCase? signTransactionUseCase,
    AuthController? authController,
    NetworkController? networkController,
    GetNonceUseCase? getNonceUseCase,
    EstimateGasUseCase? estimateGasUseCase,
    BroadcastTransactionUseCase? broadcastTransactionUseCase,
  }) {
    _signTransactionUseCase = signTransactionUseCase;
    _authController = authController;
    _networkController = networkController;
  }

  // Lazy getters for dependencies (fallback to Get.find if not injected)
  SignTransactionUseCase? get signTransactionUseCase {
    try {
      _signTransactionUseCase ??= Get.find<SignTransactionUseCase>();
    } catch (e) {
      print('⚠️ SignTransactionUseCase not found in DI: $e');
    }
    return _signTransactionUseCase;
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

  // RPC-dependent use cases: always fetch fresh from GetX container
  // so network switches properly refresh the RpcClient dependency chain.
  // These are NOT cached with ??= because _refreshRpcClient() deletes
  // and recreates them with a new RpcClient instance.

  GetNonceUseCase? get getNonceUseCase {
    try {
      return Get.find<GetNonceUseCase>();
    } catch (e) {
      print('⚠️ GetNonceUseCase not found in DI: $e');
      return null;
    }
  }

  EstimateGasUseCase? get estimateGasUseCase {
    try {
      return Get.find<EstimateGasUseCase>();
    } catch (e) {
      print('⚠️ EstimateGasUseCase not found in DI: $e');
      return null;
    }
  }

  BroadcastTransactionUseCase? get broadcastTransactionUseCase {
    try {
      return Get.find<BroadcastTransactionUseCase>();
    } catch (e) {
      print('⚠️ BroadcastTransactionUseCase not found in DI: $e');
      return null;
    }
  }

  // ============================================================================
  // REACTIVE STATE (Observable by UI)
  // ============================================================================

  /// Transaction history
  final RxList<TransactionItem> _transactions = <TransactionItem>[].obs;

  /// Pending transaction
  final Rxn<TransactionItem> _pendingTransaction = Rxn<TransactionItem>();

  /// Gas estimate
  final RxnString _estimatedGas = RxnString();

  /// Gas price in Gwei
  final RxnString _gasPrice = RxnString();

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Estimating gas flag
  final RxBool _isEstimatingGas = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  // ============================================================================
  // GETTERS (UI reads these)
  // ============================================================================

  List<TransactionItem> get transactions => _transactions;
  TransactionItem? get pendingTransaction => _pendingTransaction.value;
  String? get estimatedGas => _estimatedGas.value;
  String? get gasPrice => _gasPrice.value;
  bool get isLoading => _isLoading.value;
  bool get isEstimatingGas => _isEstimatingGas.value;
  String? get errorMessage => _errorMessage.value;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _loadTransactionHistory();
    _loadGasPrice();
  }

  /// Load transaction history
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls GetTransactionHistoryUseCase (domain layer)
  /// - Use case queries blockchain/indexer
  /// - Controller updates reactive state
  Future<void> _loadTransactionHistory() async {
    try {
      // TODO: Call use case
      // final history = await _getTransactionHistoryUseCase();
      // _transactions.value = history;

      // Placeholder
      _transactions.value = [];
    } catch (e) {
      _errorMessage.value = 'Failed to load transaction history';
    }
  }

  /// Load current gas price from blockchain
  ///
  /// SEPARATION OF CONCERNS:
  /// - Uses EstimateGasUseCase to query blockchain gas price
  /// - Controller updates reactive state
  Future<void> _loadGasPrice() async {
    try {
      final useCase = estimateGasUseCase;
      if (useCase != null) {
        // Use a dummy estimation to get current gas price from blockchain
        // EstimateGasUseCase.call() fetches real gas price via RPC eth_gasPrice
        final estimate = await useCase.call(
          from: '0x0000000000000000000000000000000000000000',
          to: '0x0000000000000000000000000000000000000000',
          value: BigInt.zero,
        );
        _gasPrice.value = estimate.gasPriceGwei;
        print(
          '📊 Gas price loaded from blockchain: ${estimate.gasPriceGwei} Gwei',
        );
      } else {
        _gasPrice.value = '25'; // Default fallback if use case not available
        print(
          '⚠️ EstimateGasUseCase not available, using default gas price: 25 Gwei',
        );
      }
    } catch (e) {
      _gasPrice.value = '25'; // Default fallback on error
      print('⚠️ Failed to load gas price from blockchain, using default: $e');
    }
  }

  // ============================================================================
  // TRANSACTION OPERATIONS (Call use cases, NO crypto logic)
  // ============================================================================

  /// Validate Ethereum address
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls ValidateAddressUseCase (domain layer)
  /// - Use case checks format and checksum
  /// - Controller returns result
  ///
  /// Parameters:
  /// - address: Address to validate
  Future<bool> validateAddress(String address) async {
    try {
      // TODO: Call use case
      // return await _validateAddressUseCase(address);

      // Placeholder: Basic validation
      return address.startsWith('0x') && address.length == 42;
    } catch (e) {
      return false;
    }
  }

  /// Get nonce for address
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls GetNonceUseCase (domain layer)
  /// - Use case queries blockchain for transaction count
  /// - Returns nonce for next transaction
  ///
  /// Parameters:
  /// - address: Wallet address
  ///
  /// Returns: Transaction nonce (transaction count)
  Future<int> getNonce(String address) async {
    try {
      final useCase = getNonceUseCase;
      if (useCase != null) {
        return await useCase.call(address: address);
      } else {
        // Fallback: Return 0 (first transaction)
        return 0;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to get nonce: ${e.toString()}';
      rethrow;
    }
  }

  /// Estimate gas for transaction
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls EstimateGasUseCase (domain layer)
  /// - Use case queries blockchain for gas estimate
  /// - Controller updates reactive state
  ///
  /// Parameters:
  /// - to: Recipient address
  /// - amount: Amount in ETH
  Future<void> estimateGas(String to, String amount) async {
    _isEstimatingGas.value = true;
    _errorMessage.value = null;

    try {
      final useCase = estimateGasUseCase;
      if (useCase != null) {
        // Get sender address for estimation
        final auth = authController;
        final fromAddress =
            auth?.walletAddress ?? '0x0000000000000000000000000000000000000000';

        // Convert amount to Wei
        final amountInWei = _parseToWei(amount, 18);

        // Call use case to estimate gas from blockchain
        final estimate = await useCase.call(
          from: fromAddress,
          to: to,
          value: amountInWei,
        );

        _estimatedGas.value = estimate.totalFeeEth;
        _gasPrice.value = estimate.gasPriceGwei;
        print(
          '📊 Gas estimated: ${estimate.totalFeeEth} ETH (${estimate.gasPriceGwei} Gwei)',
        );
      } else {
        // Fallback if use case not available
        _estimatedGas.value = '0.0021';
        print(
          '⚠️ EstimateGasUseCase not available, using default gas estimate',
        );
      }
    } catch (e) {
      _errorMessage.value = 'Failed to estimate gas: ${e.toString()}';
      _estimatedGas.value = '0.0021'; // Default fallback
      print('⚠️ Gas estimation failed: $e');
    } finally {
      _isEstimatingGas.value = false;
    }
  }

  /// Send transaction
  ///
  /// SEPARATION OF CONCERNS:
  /// - Calls SignTransactionUseCase (domain layer)
  /// - Calls BroadcastTransactionUseCase (domain layer)
  /// - Use case coordinates with TransactionSigner
  /// - Controller updates UI state
  /// - Broadcasts signed transaction to blockchain
  ///
  /// SECURITY:
  /// - Wallet must be unlocked before signing
  /// - Private key derived at runtime only
  /// - Signing happens in domain layer
  /// - PIN required for operation
  /// - Uses AuthController for lock state check
  ///
  /// Parameters:
  /// - to: Recipient address
  /// - amount: Amount in ETH
  /// - pin: User's PIN (for mnemonic decryption)
  /// - gasPrice: Gas price in Gwei (optional, uses current if not provided)
  /// - gasLimit: Gas limit (optional, uses 21000 for simple transfers)
  /// - nonce: Transaction nonce (optional, must be provided by caller)
  ///
  /// Returns: SignedTransaction with raw hex and hash from blockchain
  Future<SignedTransaction?> sendTransaction({
    required String to,
    required String amount,
    required String pin,
    String? gasPrice,
    String? gasLimit,
    int? nonce,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Step 1: Validate inputs
      if (!await validateAddress(to)) {
        _errorMessage.value = 'Invalid recipient address';
        return null;
      }

      final amountValue = double.tryParse(amount);
      if (amountValue == null || amountValue <= 0) {
        _errorMessage.value = 'Invalid amount';
        return null;
      }

      // Step 2: Get network configuration
      final network = networkController;
      final currentNetwork = network?.currentNetwork;

      if (currentNetwork == null) {
        _errorMessage.value = 'No network selected';
        return null;
      }

      final chainId = currentNetwork.chainId;

      // Step 3: Convert amount to Wei (string-based to avoid floating point errors)
      final amountInWei = _parseToWei(amount, 18);

      // Step 4: Get gas parameters (string-based to avoid floating point errors)
      final gasPriceValue = gasPrice ?? _gasPrice.value ?? '25';
      final gasPriceInWei = _parseToWei(gasPriceValue, 9);

      final gasLimitValue = gasLimit ?? '21000';
      final gasLimitBigInt = BigInt.parse(gasLimitValue);

      // Step 5: Validate nonce is provided
      if (nonce == null) {
        _errorMessage.value = 'Transaction nonce is required';
        return null;
      }

      // Step 6: Create transaction
      final transaction = EvmTransaction(
        to: to,
        value: amountInWei,
        gasPrice: gasPriceInWei,
        gasLimit: gasLimitBigInt,
        nonce: nonce,
        chainId: chainId,
      );

      // Step 7: Sign transaction via use case
      final useCase = signTransactionUseCase;
      if (useCase != null) {
        final signedTransaction = await useCase.call(
          transaction: transaction,
          pin: pin,
        );

        // Step 9: Broadcast signed transaction to blockchain
        final broadcastUseCase = broadcastTransactionUseCase;
        if (broadcastUseCase != null) {
          try {
            final result = await broadcastUseCase.call(
              signedTransaction: signedTransaction,
            );

            // Update transaction hash from blockchain
            final broadcastedTransaction = SignedTransaction(
              rawTransaction: signedTransaction.rawTransaction,
              transactionHash: result.transactionHash,
              transaction: signedTransaction.transaction,
            );

            // Add to pending transactions
            _pendingTransaction.value = TransactionItem(
              hash: result.transactionHash,
              to: to,
              amount: amount,
              status: TransactionStatus.pending,
              timestamp: DateTime.now(),
            );

            // Refresh history
            await _loadTransactionHistory();

            return broadcastedTransaction;
          } catch (e) {
            _errorMessage.value =
                'Failed to broadcast transaction: ${e.toString()}';
            return null;
          }
        } else {
          // Broadcast use case not available - FAIL instead of returning unbroadcast tx
          _errorMessage.value =
              'Broadcast service not available. Transaction was signed but NOT sent to the blockchain.';
          print(
            '❌ BroadcastTransactionUseCase is null - transaction NOT broadcast!',
          );
          return null;
        }
      } else {
        // SignTransactionUseCase not available - FAIL instead of returning fake hash
        _errorMessage.value =
            'Transaction signing service not available. Please restart the app.';
        print('❌ SignTransactionUseCase is null - cannot sign transaction!');
        return null;
      }
    } on SignTransactionException catch (e) {
      // Handle signing-specific errors (include details for debugging)
      _errorMessage.value = e.details != null
          ? '${e.message}: ${e.details}'
          : e.message;
      return null;
    } catch (e) {
      _errorMessage.value = 'Failed to send transaction: ${e.toString()}';
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh transaction history
  Future<void> refreshTransactions() async {
    await _loadTransactionHistory();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Clear pending transaction
  void clearPendingTransaction() {
    _pendingTransaction.value = null;
  }

  /// Convert decimal string to Wei BigInt without floating point errors
  ///
  /// Parameters:
  /// - amount: Decimal string (e.g., "0.0079", "25")
  /// - decimals: Number of decimal places (18 for ETH, 9 for Gwei)
  ///
  /// Returns: BigInt value in smallest unit (Wei)
  BigInt _parseToWei(String amount, int decimals) {
    // Remove leading/trailing whitespace
    amount = amount.trim();

    // Split into integer and decimal parts
    final parts = amount.split('.');
    final integerPart = parts[0].isEmpty ? '0' : parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Pad or truncate decimal part to exact number of decimals
    final paddedDecimal = decimalPart.length >= decimals
        ? decimalPart.substring(0, decimals)
        : decimalPart.padRight(decimals, '0');

    // Combine and parse as BigInt (avoids floating point entirely)
    final weiString = '$integerPart$paddedDecimal'.replaceFirst(
      RegExp(r'^0+'),
      '',
    );
    if (weiString.isEmpty) return BigInt.zero;
    return BigInt.parse(weiString);
  }
}

// ============================================================================
// MODELS (UI-friendly data structures)
// ============================================================================

/// Transaction status
enum TransactionStatus { pending, confirmed, failed }

/// Transaction item for UI display
class TransactionItem {
  final String hash;
  final String to;
  final String amount;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? from;

  TransactionItem({
    required this.hash,
    required this.to,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.from,
  });
}
