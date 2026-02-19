import '../../../../core/network/rpc_client.dart';
import '../../../../core/network/rpc_exception.dart';

/// Gas Estimate Result
/// 
/// Contains gas estimation information.
class GasEstimate {
  /// Estimated gas limit
  final BigInt gasLimit;

  /// Current gas price in Wei
  final BigInt gasPrice;

  /// Total fee in Wei (gasLimit * gasPrice)
  final BigInt totalFeeWei;

  /// Total fee in ETH (human-readable)
  final String totalFeeEth;

  /// Gas price in Gwei (human-readable)
  final String gasPriceGwei;

  GasEstimate({
    required this.gasLimit,
    required this.gasPrice,
    required this.totalFeeWei,
    required this.totalFeeEth,
    required this.gasPriceGwei,
  });
}

/// Estimate Gas Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Estimate gas limit for transaction
/// - Get current gas price
/// - Calculate total transaction fee
/// - Add safety buffer to gas limit
/// 
/// Gas Explanation:
/// - Gas Limit: Maximum gas units transaction can use
/// - Gas Price: Price per gas unit (in Wei)
/// - Total Fee: gasLimit * gasPrice
/// 
/// Usage:
/// ```dart
/// final useCase = EstimateGasUseCase(rpcClient: client);
/// final estimate = await useCase.call(
///   from: '0x...',
///   to: '0x...',
///   value: BigInt.from(1000000000000000000), // 1 ETH
/// );
/// print('Estimated fee: ${estimate.totalFeeEth} ETH');
/// ```
class EstimateGasUseCase {
  final RpcClient _rpcClient;

  /// Safety buffer percentage (10% = 1.1x)
  static const double safetyBuffer = 1.1;

  EstimateGasUseCase({
    required RpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  /// Execute use case
  /// 
  /// Parameters:
  /// - from: Sender address
  /// - to: Recipient address
  /// - value: Amount in Wei
  /// - data: Transaction data (optional, for contract calls)
  /// 
  /// Returns: GasEstimate with gas limit, price, and total fee
  /// 
  /// Throws:
  /// - RpcException: If RPC call fails
  /// - Exception: For other errors
  Future<GasEstimate> call({
    required String from,
    required String to,
    required BigInt value,
    String? data,
  }) async {
    try {
      // Build transaction object for estimation
      final transaction = {
        'from': from.toLowerCase(),
        'to': to.toLowerCase(),
        'value': '0x${value.toRadixString(16)}',
      };

      if (data != null && data.isNotEmpty) {
        transaction['data'] = data;
      }

      // Estimate gas limit
      BigInt estimatedGasLimit = await _rpcClient.estimateGas(transaction);

      // Add safety buffer (10% extra)
      estimatedGasLimit = BigInt.from(
        (estimatedGasLimit.toDouble() * safetyBuffer).ceil(),
      );

      // Get current gas price
      final gasPrice = await (_rpcClient as dynamic).getGasPrice() as BigInt;

      // Calculate total fee
      final totalFeeWei = estimatedGasLimit * gasPrice;

      // Convert to human-readable formats
      final totalFeeEth = _weiToEth(totalFeeWei);
      final gasPriceGwei = _weiToGwei(gasPrice);

      return GasEstimate(
        gasLimit: estimatedGasLimit,
        gasPrice: gasPrice,
        totalFeeWei: totalFeeWei,
        totalFeeEth: totalFeeEth,
        gasPriceGwei: gasPriceGwei,
      );
    } on RpcException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to estimate gas: $e');
    }
  }

  /// Convert Wei to ETH
  String _weiToEth(BigInt wei) {
    final ethValue = wei.toDouble() / 1e18;
    String formatted = ethValue.toStringAsFixed(6);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted.isEmpty || formatted == '.' ? '0' : formatted;
  }

  /// Convert Wei to Gwei
  String _weiToGwei(BigInt wei) {
    final gweiValue = wei.toDouble() / 1e9;
    String formatted = gweiValue.toStringAsFixed(2);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted.isEmpty || formatted == '.' ? '0' : formatted;
  }
}
