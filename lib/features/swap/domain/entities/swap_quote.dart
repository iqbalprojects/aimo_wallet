/// Domain entity representing a swap quote.
///
/// This is a pure domain object that represents the data needed
/// to execute a token swap. It is independent of any external API
/// or data source.
///
/// The entity contains:
/// - Transaction data for execution
/// - Gas estimation for fee calculation
/// - Amount information for user display
/// - Allowance target for approval checking
class SwapQuote {
  /// Target contract address for the swap transaction.
  /// This is where the transaction should be sent.
  final String to;

  /// Encoded calldata for the swap transaction.
  /// This contains the function call data for the DEX router.
  final String data;

  /// Amount of ETH to send with the transaction (in wei).
  /// Zero for token-to-token swaps.
  /// Contains ETH amount for token-to-ETH or ETH-to-token swaps.
  final BigInt value;

  /// Estimated gas limit for the swap.
  final BigInt gas;

  /// Suggested gas price (in wei).
  final BigInt gasPrice;

  /// Address that needs approval to spend user's tokens.
  /// User must approve this address before executing swap.
  final String allowanceTarget;

  /// Amount of tokens user will receive (in smallest units).
  final BigInt buyAmount;

  /// Amount of tokens user is selling (in smallest units).
  final BigInt sellAmount;

  SwapQuote({
    required this.to,
    required this.data,
    required this.value,
    required this.gas,
    required this.gasPrice,
    required this.allowanceTarget,
    required this.buyAmount,
    required this.sellAmount,
  });

  /// Estimated total gas fee (gas * gasPrice).
  BigInt get estimatedFee => gas * gasPrice;

  @override
  String toString() {
    return 'SwapQuote(to: $to, sellAmount: $sellAmount, buyAmount: $buyAmount)';
  }
}
