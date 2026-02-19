import '../../../../core/network/rpc_client.dart';
import '../../../../core/network/rpc_exception.dart';

/// Get Balance Result
/// 
/// Contains balance information in different formats.
class BalanceResult {
  /// Balance in Wei (smallest unit)
  final BigInt balanceWei;

  /// Balance in ETH (human-readable)
  final String balanceEth;

  /// Balance in USD (if price available)
  final String? balanceUsd;

  BalanceResult({
    required this.balanceWei,
    required this.balanceEth,
    this.balanceUsd,
  });

  /// Convert Wei to ETH
  static String weiToEth(BigInt wei) {
    final eth = wei / BigInt.from(10).pow(18);
    return eth.toStringAsFixed(6);
  }
}

/// Get Balance Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Query balance from blockchain via RPC
/// - Convert Wei to ETH
/// - Handle errors gracefully
/// - Cache balance (optional)
/// 
/// Usage:
/// ```dart
/// final useCase = GetBalanceUseCase(rpcClient: client);
/// final balance = await useCase.call(address: '0x...');
/// print('Balance: ${balance.balanceEth} ETH');
/// ```
class GetBalanceUseCase {
  final RpcClient _rpcClient;

  GetBalanceUseCase({
    required RpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  /// Execute use case
  /// 
  /// Parameters:
  /// - address: Ethereum address to query
  /// 
  /// Returns: BalanceResult with balance in Wei and ETH
  /// 
  /// Throws:
  /// - RpcException: If RPC call fails
  /// - Exception: For other errors
  Future<BalanceResult> call({required String address}) async {
    try {
      // Query balance from blockchain
      final balanceWei = await _rpcClient.getBalance(address);

      // Convert to ETH
      final balanceEth = _weiToEth(balanceWei);

      return BalanceResult(
        balanceWei: balanceWei,
        balanceEth: balanceEth,
      );
    } on RpcException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  /// Convert Wei to ETH with proper decimal handling
  String _weiToEth(BigInt wei) {
    // 1 ETH = 10^18 Wei
    final ethValue = wei.toDouble() / 1e18;
    
    // Format with up to 6 decimal places, removing trailing zeros
    String formatted = ethValue.toStringAsFixed(6);
    
    // Remove trailing zeros
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    
    // If empty, return "0"
    if (formatted.isEmpty || formatted == '.') {
      return '0';
    }
    
    return formatted;
  }
}
