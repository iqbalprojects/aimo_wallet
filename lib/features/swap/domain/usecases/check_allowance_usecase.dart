import '../../../../core/blockchain/evm/erc20/erc20_service.dart';

/// Allowance status for swap preparation.
///
/// Indicates whether the owner has approved enough tokens for a swap.
/// This is used to determine if an approve transaction is needed
/// before the swap can be executed.
enum AllowanceStatus {
  /// Owner has approved enough tokens for the required amount.
  /// Swap can proceed without additional approval.
  sufficient,

  /// Owner has not approved enough tokens.
  /// An approve transaction must be signed and broadcast before swap.
  insufficient,
}

/// Result of checking token allowance.
///
/// Contains the current allowance amount and the status determination.
class AllowanceResult {
  /// Current allowance amount in smallest units.
  final BigInt currentAllowance;

  /// Required amount for the swap in smallest units.
  final BigInt requiredAmount;

  /// Determined status (sufficient or insufficient).
  final AllowanceStatus status;

  AllowanceResult({
    required this.currentAllowance,
    required this.requiredAmount,
    required this.status,
  });

  /// Amount needed to approve (if insufficient).
  /// Returns zero if allowance is already sufficient.
  BigInt get neededAmount =>
      status == AllowanceStatus.insufficient
          ? requiredAmount - currentAllowance
          : BigInt.zero;
}

/// Check Allowance Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Query current ERC20 allowance from contract
/// - Compare against required swap amount
/// - Return allowance status for swap preparation
///
/// Swap Flow Dependency:
/// This use case is a critical step in the token swap flow:
/// 1. User initiates swap (e.g., swap 100 USDT for ETH)
/// 2. Check allowance: Is USDT approved for the router contract?
/// 3. If insufficient: Build, sign, and broadcast approve transaction
/// 4. If sufficient: Proceed with swap transaction
///
/// This use case ONLY checks allowance - it does NOT:
/// - Modify allowance (no approve)
/// - Sign transactions
/// - Broadcast transactions
/// - Execute swaps
///
/// Usage:
/// ```dart
/// final useCase = CheckAllowanceUseCase(erc20Service: service);
///
/// final result = await useCase.call(
///   contractAddress: '0xUSDT...',  // USDT contract
///   ownerAddress: '0xUser...',     // User wallet
///   spenderAddress: '0xRouter...', // DEX router
///   requiredAmount: BigInt.parse('100000000'), // 100 USDT (6 decimals)
/// );
///
/// if (result.status == AllowanceStatus.insufficient) {
///   // Need to approve first
///   print('Need to approve: ${result.neededAmount}');
/// } else {
///   // Can proceed with swap
///   print('Allowance sufficient');
/// }
/// ```
///
/// Security:
/// - No private key handling
/// - No transaction signing
/// - Read-only operation
class CheckAllowanceUseCase {
  final Erc20Service _erc20Service;

  CheckAllowanceUseCase({
    required Erc20Service erc20Service,
  }) : _erc20Service = erc20Service;

  /// Execute use case
  ///
  /// Queries the ERC20 contract for current allowance and compares
  /// it against the required amount for the swap.
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  /// - ownerAddress: Address that owns the tokens (user wallet)
  /// - spenderAddress: Address that will spend tokens (DEX router)
  /// - requiredAmount: Amount needed for the swap (smallest units)
  ///
  /// Returns: AllowanceResult with status and amounts
  ///
  /// Throws:
  /// - Erc20Exception: If contract call fails
  /// - Exception: For other errors
  Future<AllowanceResult> call({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
    required BigInt requiredAmount,
  }) async {
    try {
      // Query current allowance from ERC20 contract
      final currentAllowance = await _erc20Service.allowance(
        contractAddress: contractAddress,
        owner: ownerAddress,
        spender: spenderAddress,
      );

      // Determine if allowance is sufficient
      // Note: Some tokens approve max uint256 for convenience
      // We check if currentAllowance >= requiredAmount
      final status = currentAllowance >= requiredAmount
          ? AllowanceStatus.sufficient
          : AllowanceStatus.insufficient;

      return AllowanceResult(
        currentAllowance: currentAllowance,
        requiredAmount: requiredAmount,
        status: status,
      );
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Exception('Failed to check allowance: $e');
    }
  }
}
