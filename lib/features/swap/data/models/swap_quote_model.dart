/// Swap quote response model from 0x API.
///
/// Contains the essential data needed to execute a swap transaction.
/// This model only includes fields necessary for transaction building
/// and user display.
class SwapQuoteModel {
  /// Target contract address for the swap transaction.
  /// This is typically the 0x router contract.
  final String to;

  /// Encoded transaction data for the swap.
  /// This should be used as the `data` field in the transaction.
  final String data;

  /// Amount of ETH to send with the transaction (in wei).
  /// For token-to-token swaps, this is typically "0".
  /// For ETH buys, this contains the ETH amount.
  final String value;

  /// Estimated gas limit for the swap transaction.
  final String gas;

  /// Suggested gas price for the transaction (in wei).
  final String gasPrice;

  /// Address that needs token approval before swap.
  /// The user must approve this address to spend their tokens.
  /// This is typically the 0x allowance target contract.
  final String allowanceTarget;

  /// Amount of tokens the user will receive (in smallest units).
  final String buyAmount;

  /// Amount of tokens the user is selling (in smallest units).
  final String sellAmount;

  SwapQuoteModel({
    required this.to,
    required this.data,
    required this.value,
    required this.gas,
    required this.gasPrice,
    required this.allowanceTarget,
    required this.buyAmount,
    required this.sellAmount,
  });

  /// Parses SwapQuoteModel from JSON response.
  ///
  /// Expected JSON structure from 0x API:
  /// ```json
  /// {
  ///   "to": "0x...",
  ///   "data": "0x...",
  ///   "value": "0",
  ///   "gas": "150000",
  ///   "gasPrice": "20000000000",
  ///   "allowanceTarget": "0x...",
  ///   "buyAmount": "1000000000000000000",
  ///   "sellAmount": "500000000"
  /// }
  /// ```
  ///
  /// Throws: ArgumentError if required fields are missing
  factory SwapQuoteModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
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
    };
  }

  @override
  String toString() {
    return 'SwapQuoteModel(to: $to, buyAmount: $buyAmount, sellAmount: $sellAmount)';
  }
}
