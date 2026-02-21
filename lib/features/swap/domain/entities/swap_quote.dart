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
/// - Price impact for risk display
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
  /// In 0x v2, this is typically the permit2 contract.
  final String allowanceTarget;

  /// Amount of tokens user will receive (in smallest units).
  final BigInt buyAmount;

  /// Amount of tokens user is selling (in smallest units).
  final BigInt sellAmount;

  /// Minimum buy amount after slippage (in smallest units).
  /// Returns buyAmount if not provided by API.
  final BigInt minBuyAmount;

  /// Estimated price impact as a percentage (0.0032 = 0.32%).
  /// Null if not provided by API.
  final double? estimatedPriceImpact;

  SwapQuote({
    required this.to,
    required this.data,
    required this.value,
    required this.gas,
    required this.gasPrice,
    required this.allowanceTarget,
    required this.buyAmount,
    required this.sellAmount,
    BigInt? minBuyAmount,
    this.estimatedPriceImpact,
  }) : minBuyAmount = minBuyAmount ?? buyAmount;

  /// Estimated total gas fee (gas * gasPrice).
  BigInt get estimatedFee => gas * gasPrice;

  /// Price impact as a human-readable percentage string.
  /// Returns '<0.1%' if unknown, or formatted percentage (e.g. '0.32%').
  String get priceImpactText {
    if (estimatedPriceImpact == null) return '<0.1%';
    final percent = estimatedPriceImpact! * 100;
    if (percent < 0.01) return '<0.01%';
    return '${percent.toStringAsFixed(2)}%';
  }

  /// Whether price impact is high (> 2%).
  bool get isHighPriceImpact => (estimatedPriceImpact ?? 0) > 0.02;

  /// Whether price impact is very high (> 5%), extremely dangerous.
  bool get isVeryHighPriceImpact => (estimatedPriceImpact ?? 0) > 0.05;

  @override
  String toString() {
    return 'SwapQuote(to: $to, sellAmount: $sellAmount, buyAmount: $buyAmount, priceImpact: $priceImpactText)';
  }
}
