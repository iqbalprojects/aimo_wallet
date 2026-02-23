/// Swap quote response model from 0x API v2 (permit2).
///
/// Contains the essential data needed to execute a swap transaction.
/// This model only includes fields necessary for transaction building
/// and user display.
///
/// Supports both 0x API v1 (flat format) and v2 (nested transaction format).
class SwapQuoteModel {
  /// Target contract address for the swap transaction.
  final String to;

  /// Encoded transaction data for the swap.
  final String data;

  /// Amount of ETH to send with the transaction (in wei).
  /// "0" for token-to-token swaps.
  final String value;

  /// Estimated gas limit for the swap transaction.
  final String gas;

  /// Suggested gas price for the transaction (in wei).
  final String gasPrice;

  /// Address that needs token approval before swap.
  /// In v2, this is the permit2 contract address.
  final String allowanceTarget;

  /// Amount of tokens the user will receive (in smallest units).
  final String buyAmount;

  /// Amount of tokens the user is selling (in smallest units).
  final String sellAmount;

  /// Minimum buy amount considering slippage (optional, v2 field).
  final String? minBuyAmount;

  /// Estimated price impact as a decimal string (optional, v2 field).
  /// Example: "0.0032" means 0.32% price impact.
  final String? estimatedPriceImpact;

  /// Permit2 EIP-712 data for off-chain signature.
  final Map<String, dynamic>? permit2Eip712;

  SwapQuoteModel({
    required this.to,
    required this.data,
    required this.value,
    required this.gas,
    required this.gasPrice,
    required this.allowanceTarget,
    required this.buyAmount,
    required this.sellAmount,
    this.minBuyAmount,
    this.estimatedPriceImpact,
    this.permit2Eip712,
  });

  /// Parses SwapQuoteModel from JSON response.
  ///
  /// Supports both 0x API v1 (legacy flat) and v2 (nested transaction) formats.
  ///
  /// V1 flat format:
  /// ```json
  /// {
  ///   "to": "0x...", "data": "0x...", "value": "0",
  ///   "gas": "150000", "gasPrice": "20000000000",
  ///   "allowanceTarget": "0x...",
  ///   "buyAmount": "1000000000000000000",
  ///   "sellAmount": "500000000"
  /// }
  /// ```
  ///
  /// V2 nested format:
  /// ```json
  /// {
  ///   "transaction": { "to": "0x...", "data": "0x...", "value": "0",
  ///     "gas": "150000", "gasPrice": "20000000000" },
  ///   "issues": { "allowance": { "spender": "0x..." } },
  ///   "buyAmount": "1000000000000000000",
  ///   "sellAmount": "500000000",
  ///   "minBuyAmount": "990000000000000000",
  ///   "estimatedPriceImpact": "0.0032",
  ///   "permit2": { "eip712": { ... } }
  /// }
  /// ```
  factory SwapQuoteModel.fromJson(Map<String, dynamic> json) {
    // Detect if v2 format (has 'transaction' key) or v1 format (flat)
    if (json.containsKey('transaction')) {
      return _parseV2Format(json);
    } else {
      return _parseV1Format(json);
    }
  }

  /// Parse from v2 API response format (permit2).
  static SwapQuoteModel _parseV2Format(Map<String, dynamic> json) {
    final transaction = json['transaction'] as Map<String, dynamic>?;
    if (transaction == null) {
      throw ArgumentError('Missing required field: transaction');
    }

    // Validate critical transaction fields
    if (transaction['to'] == null) {
      throw ArgumentError('Missing required transaction field: to');
    }
    if (transaction['data'] == null) {
      throw ArgumentError('Missing required transaction field: data');
    }

    // Validate root-level amount fields
    if (json['buyAmount'] == null) {
      throw ArgumentError('Missing required field: buyAmount');
    }
    if (json['sellAmount'] == null) {
      throw ArgumentError('Missing required field: sellAmount');
    }

    // Get allowance target:
    // 1. Check root-level 'allowanceTarget' (returned by 0x API v2)
    // 2. Fallback to issues.allowance.spender
    // 3. Default to zero address if not found (ETH native or not required)
    String allowanceTarget = '0x0000000000000000000000000000000000000000';

    // First check root-level allowanceTarget (per 0x v2 docs)
    final rootAllowanceTarget = json['allowanceTarget'] as String?;
    if (rootAllowanceTarget != null && rootAllowanceTarget.isNotEmpty) {
      allowanceTarget = rootAllowanceTarget;
    } else {
      // Fallback: check issues.allowance.spender
      final issues = json['issues'] as Map<String, dynamic>?;
      if (issues != null) {
        final allowanceIssue = issues['allowance'] as Map<String, dynamic>?;
        if (allowanceIssue != null) {
          final spender = allowanceIssue['spender'] as String?;
          if (spender != null && spender.isNotEmpty) {
            allowanceTarget = spender;
          }
        }
      }
    }

    // Gas: v2 may use 'gasLimit' or 'gas', also handle EIP-1559 fields
    final gas =
        transaction['gas']?.toString() ??
        transaction['gasLimit']?.toString() ??
        '200000'; // reasonable fallback

    // GasPrice: v2 supports EIP-1559 (maxFeePerGas) or legacy (gasPrice)
    final gasPrice =
        transaction['maxFeePerGas']?.toString() ??
        transaction['gasPrice']?.toString() ??
        '0';

    // Parse permit2.eip712 if it exists
    Map<String, dynamic>? permit2Eip712;
    final permit2 = json['permit2'] as Map<String, dynamic>?;
    if (permit2 != null) {
      permit2Eip712 = permit2['eip712'] as Map<String, dynamic>?;
    }

    return SwapQuoteModel(
      to: transaction['to'] as String,
      data: transaction['data'] as String,
      value: transaction['value']?.toString() ?? '0',
      gas: gas,
      gasPrice: gasPrice,
      allowanceTarget: allowanceTarget,
      buyAmount: json['buyAmount'] as String,
      sellAmount: json['sellAmount'] as String,
      minBuyAmount: json['minBuyAmount'] as String?,
      estimatedPriceImpact: json['estimatedPriceImpact'] as String?,
      permit2Eip712: permit2Eip712,
    );
  }

  /// Parse from v1 API response format (legacy flat structure).
  static SwapQuoteModel _parseV1Format(Map<String, dynamic> json) {
    final requiredFields = [
      'to',
      'data',
      'value',
      'gas',
      'gasPrice',
      'allowanceTarget',
      'buyAmount',
      'sellAmount',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw ArgumentError('Missing required field: $field');
      }
    }

    return SwapQuoteModel(
      to: json['to'] as String,
      data: json['data'] as String,
      value: json['value'] as String,
      gas: json['gas'] as String,
      gasPrice: json['gasPrice'] as String,
      allowanceTarget: json['allowanceTarget'] as String,
      buyAmount: json['buyAmount'] as String,
      sellAmount: json['sellAmount'] as String,
      estimatedPriceImpact: json['estimatedPriceImpact'] as String?,
    );
  }

  /// Converts model to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'data': data,
      'value': value,
      'gas': gas,
      'gasPrice': gasPrice,
      'allowanceTarget': allowanceTarget,
      'buyAmount': buyAmount,
      'sellAmount': sellAmount,
      if (minBuyAmount != null) 'minBuyAmount': minBuyAmount,
      if (estimatedPriceImpact != null)
        'estimatedPriceImpact': estimatedPriceImpact,
    };
  }

  @override
  String toString() {
    return 'SwapQuoteModel(to: $to, buyAmount: $buyAmount, sellAmount: $sellAmount)';
  }
}
