import 'package:web3dart/web3dart.dart';
import '../../../../core/blockchain/evm/erc20/erc20_service.dart';

/// Approve Token Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Build unsigned ERC20 approve transaction
/// - Return transaction for external signing
///
/// This use case ONLY builds the transaction - it does NOT:
/// - Sign the transaction
/// - Broadcast the transaction
/// - Execute the approval
///
/// Transaction Flow:
/// 1. This use case builds the unsigned approve transaction
/// 2. TransactionEngine signs the transaction with user's private key
/// 3. Signed transaction is broadcast to the network
/// 4. User waits for confirmation
/// 5. Swap can proceed after approval
///
/// Usage:
/// ```dart
/// final useCase = ApproveTokenUseCase(erc20Service: service);
///
/// // Build unsigned approve transaction
/// final transaction = await useCase.call(
///   contractAddress: '0xUSDT...',  // Token to approve
///   spender: '0xRouter...',        // DEX router to approve
///   amount: BigInt.parse('1000000000000000000000'), // Amount
/// );
///
/// // Pass to TransactionEngine for signing
/// // final signed = await transactionEngine.sign(transaction, privateKey);
/// // await transactionEngine.broadcast(signed);
/// ```
///
/// # Security Warning: Approve Risk
///
/// Granting token approval is a security-sensitive operation:
///
/// **Risk 1: Unlimited Approvals**
/// - Approving max uint256 allows spender to drain ALL tokens
/// - Malicious contracts can exploit unlimited approvals
/// - Recommendation: Approve only the exact amount needed
///
/// **Risk 2: Phishing Attacks**
/// - Users may be tricked into approving malicious contracts
/// - Always verify the spender address is legitimate
/// - Show clear UI warnings about what is being approved
///
/// **Risk 3: Approval Draining**
/// - Some protocols use "approval sweeping" to take approved tokens
/// - Only approve trusted DEX routers and protocols
///
/// **Best Practices:**
/// 1. Always show user what they're approving and to whom
/// 2. Default to exact amount approval, not unlimited
/// 3. Allow users to revoke approvals
/// 4. Warn about approving to unknown addresses
/// 5. Consider using permit2 for safer approvals
///
/// Implementation Notes:
/// - This use case does NOT validate the spender address
/// - Caller (presentation layer) must validate and warn user
/// - Consider adding a spender whitelist in production
class ApproveTokenUseCase {
  final Erc20Service _erc20Service;

  ApproveTokenUseCase({
    required Erc20Service erc20Service,
  }) : _erc20Service = erc20Service;

  /// Execute use case
  ///
  /// Builds an unsigned ERC20 approve transaction.
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract to approve
  /// - spender: Address to grant approval to (e.g., DEX router)
  /// - amount: Amount to approve (in smallest units)
  ///
  /// Returns: Unsigned Transaction ready for signing
  ///
  /// Throws:
  /// - Erc20Exception: If address is invalid or build fails
  /// - Exception: For other errors
  ///
  /// Security: See class documentation for approve risks
  Future<Transaction> call({
    required String contractAddress,
    required String spender,
    required BigInt amount,
  }) async {
    try {
      // Build unsigned approve transaction
      // The transaction is NOT signed here
      // Signing must be done by TransactionEngine with user's private key
      return await _erc20Service.buildApproveTransaction(
        contractAddress: contractAddress,
        spender: spender,
        amount: amount,
      );
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Exception('Failed to build approve transaction: $e');
    }
  }
}
