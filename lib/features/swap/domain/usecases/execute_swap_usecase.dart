import '../../../transaction/domain/entities/transaction.dart';
import '../entities/swap_quote.dart';

/// Execute Swap Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Build unsigned transaction from swap quote
/// - Apply chain ID for EIP-155 replay protection
/// - Return transaction for external signing
///
/// This use case ONLY builds the transaction - it does NOT:
/// - Sign the transaction
/// - Broadcast the transaction
/// - Execute the swap
/// - Store private keys
///
/// Transaction Flow:
/// 1. Get swap quote (GetSwapQuoteUseCase)
/// 2. Prepare swap - check balance & allowance (SwapPreparationUseCase)
/// 3. Approve if needed (ApproveTokenUseCase)
/// 4. Build swap transaction (this use case)
/// 5. Sign transaction (TransactionEngine)
/// 6. Broadcast transaction
///
/// Usage:
/// ```dart
/// final useCase = ExecuteSwapUseCase();
///
/// final transaction = useCase.call(
///   quote: swapQuote,
///   chainId: 1, // Ethereum mainnet
///   nonce: 42,  // From GetNonceUseCase
/// );
///
/// // Pass to TransactionEngine for signing
/// // final signed = await transactionEngine.sign(transaction, privateKey);
/// ```
///
/// # Security Considerations
///
/// **EIP-155 Replay Protection:**
/// - Chain ID is included in the transaction
/// - Prevents transaction from being replayed on other chains
/// - Required for all modern EVM transactions
///
/// **No Private Key Handling:**
/// - This use case never touches private keys
/// - Signing is delegated to TransactionEngine
/// - Private keys remain in secure storage
///
/// **No Broadcast:**
/// - Transaction is returned unsigned
/// - Caller controls when/if to broadcast
/// - Allows for preview, approval, and confirmation steps
///
/// **Gas Parameters:**
/// - Uses gas/gasPrice from quote (0x estimates)
/// - Caller may override before signing if needed
/// - Consider adding gas estimation fallback
class ExecuteSwapUseCase {
  /// Execute use case
  ///
  /// Builds an unsigned EVM transaction from a swap quote.
  ///
  /// Parameters:
  /// - quote: SwapQuote entity containing transaction data
  /// - chainId: Chain ID for EIP-155 replay protection
  /// - nonce: Transaction nonce (from GetNonceUseCase)
  ///
  /// Returns: Unsigned EvmTransaction ready for signing
  ///
  /// Security:
  /// - Chain ID provides replay protection
  /// - No private key handling
  /// - No network operations
  EvmTransaction call({
    required SwapQuote quote,
    required int chainId,
    required int nonce,
  }) {
    // Build transaction from quote data
    // - to: DEX router contract address
    // - data: Encoded swap function call
    // - value: ETH amount (0 for token-to-token swaps)
    // - gas/gasPrice: From 0x API estimates
    return EvmTransaction(
      to: quote.to,
      data: quote.data,
      value: quote.value,
      gasLimit: quote.gas,
      gasPrice: quote.gasPrice,
      chainId: chainId,
      nonce: nonce,
    );
  }
}
