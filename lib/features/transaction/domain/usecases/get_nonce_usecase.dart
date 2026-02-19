import '../../../../core/network/rpc_client.dart';
import '../../../../core/network/rpc_exception.dart';

/// Get Nonce Use Case
/// 
/// DOMAIN LAYER - Business Logic
/// 
/// Responsibilities:
/// - Query transaction count (nonce) from blockchain
/// - Handle pending transactions
/// - Provide correct nonce for new transactions
/// 
/// Nonce Explanation:
/// - Nonce is a counter for transactions from an address
/// - Each transaction must have a unique, sequential nonce
/// - Nonce prevents replay attacks
/// - Nonce must be exactly: current transaction count
/// 
/// Usage:
/// ```dart
/// final useCase = GetNonceUseCase(rpcClient: client);
/// final nonce = await useCase.call(address: '0x...');
/// print('Next nonce: $nonce');
/// ```
class GetNonceUseCase {
  final RpcClient _rpcClient;

  GetNonceUseCase({
    required RpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  /// Execute use case
  /// 
  /// Parameters:
  /// - address: Ethereum address to query nonce for
  /// - pending: If true, includes pending transactions (default: true)
  /// 
  /// Returns: Next nonce to use for transaction
  /// 
  /// Throws:
  /// - RpcException: If RPC call fails
  /// - Exception: For other errors
  Future<int> call({
    required String address,
    bool pending = true,
  }) async {
    try {
      // Query transaction count from blockchain
      // This returns the next nonce to use
      final nonce = await _rpcClient.getTransactionCount(address);

      return nonce;
    } on RpcException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get nonce: $e');
    }
  }
}
