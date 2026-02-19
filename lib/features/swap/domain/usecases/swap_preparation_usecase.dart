import '../../../../core/blockchain/evm/erc20/erc20_service.dart';
import 'check_allowance_usecase.dart';

/// Result of swap preparation validation.
///
/// Contains all validation results needed to determine
/// if a swap can proceed or what actions are needed first.
class SwapPreparationResult {
  /// Whether user has enough token balance for the swap.
  final bool hasEnoughBalance;

  /// Current token balance in smallest units.
  final BigInt currentBalance;

  /// Required sell amount in smallest units.
  final BigInt requiredAmount;

  /// Allowance status for the swap.
  final AllowanceStatus allowanceStatus;

  /// Current allowance amount (from AllowanceResult).
  final BigInt currentAllowance;

  SwapPreparationResult({
    required this.hasEnoughBalance,
    required this.currentBalance,
    required this.requiredAmount,
    required this.allowanceStatus,
    required this.currentAllowance,
  });

  /// Whether approval is needed before swap.
  bool get needsApproval => allowanceStatus == AllowanceStatus.insufficient;

  /// Amount needed to approve (if insufficient allowance).
  BigInt get neededAllowance =>
      needsApproval ? requiredAmount - currentAllowance : BigInt.zero;

  /// Shortfall amount (if insufficient balance).
  BigInt get balanceShortfall =>
      hasEnoughBalance ? BigInt.zero : requiredAmount - currentBalance;
}

/// Swap Preparation Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Validate user has sufficient token balance
/// - Check token allowance for swap router
/// - Return comprehensive preparation result
///
/// This use case performs ONLY validation - it does NOT:
/// - Modify any state
/// - Sign transactions
/// - Broadcast transactions
/// - Execute approvals
///
/// Swap Preparation Flow:
/// =====================
/// Before executing a swap, the wallet must verify:
///
/// 1. **Balance Check**
///    - User has enough tokens to sell
///    - If not, show error and stop
///
/// 2. **Allowance Check**
///    - Token is approved for the DEX router
///    - If not, user must approve first
///
/// Usage:
/// ```dart
/// final useCase = SwapPreparationUseCase(
///   erc20Service: erc20Service,
///   checkAllowanceUseCase: checkAllowanceUseCase,
/// );
///
/// final result = await useCase.call(
///   tokenAddress: '0xUSDT...',
///   walletAddress: '0xUser...',
///   spenderAddress: '0xRouter...', // 0x allowance target
///   sellAmount: BigInt.from(100000000),
/// );
///
/// if (!result.hasEnoughBalance) {
///   print('Insufficient balance. Shortfall: ${result.balanceShortfall}');
///   return;
/// }
///
/// if (result.needsApproval) {
///   print('Need to approve: ${result.neededAllowance}');
///   // Trigger approval flow
/// } else {
///   print('Ready to swap!');
///   // Proceed with swap
/// }
/// ```
///
/// Clean Architecture:
/// - Uses Erc20Service for balance queries
/// - Uses CheckAllowanceUseCase for allowance logic
/// - Returns pure domain result
class SwapPreparationUseCase {
  final Erc20Service _erc20Service;
  final CheckAllowanceUseCase _checkAllowanceUseCase;

  SwapPreparationUseCase({
    required Erc20Service erc20Service,
    required CheckAllowanceUseCase checkAllowanceUseCase,
  })  : _erc20Service = erc20Service,
        _checkAllowanceUseCase = checkAllowanceUseCase;

  /// Execute use case
  ///
  /// Validates balance and allowance for a swap operation.
  ///
  /// Parameters:
  /// - tokenAddress: ERC20 token address to sell
  /// - walletAddress: User's wallet address
  /// - spenderAddress: DEX router or allowance target address
  /// - sellAmount: Amount to sell in smallest units
  ///
  /// Returns: SwapPreparationResult with validation results
  ///
  /// Throws:
  /// - Erc20Exception: If balance query fails
  /// - Exception: For other errors
  Future<SwapPreparationResult> call({
    required String tokenAddress,
    required String walletAddress,
    required String spenderAddress,
    required BigInt sellAmount,
  }) async {
    // Step 1: Check token balance
    final balance = await _erc20Service.balanceOf(
      contractAddress: tokenAddress,
      walletAddress: walletAddress,
    );

    final hasEnoughBalance = balance >= sellAmount;

    // Step 2: Check allowance
    // Only check allowance if balance is sufficient
    // (optimization: skip if user can't swap anyway)
    final allowanceResult = await _checkAllowanceUseCase.call(
      contractAddress: tokenAddress,
      ownerAddress: walletAddress,
      spenderAddress: spenderAddress,
      requiredAmount: sellAmount,
    );

    return SwapPreparationResult(
      hasEnoughBalance: hasEnoughBalance,
      currentBalance: balance,
      requiredAmount: sellAmount,
      allowanceStatus: allowanceResult.status,
      currentAllowance: allowanceResult.currentAllowance,
    );
  }
}
