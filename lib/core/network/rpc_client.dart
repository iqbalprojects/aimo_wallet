/// JSON-RPC Request
class RpcRequest {
  final String method;
  final List<dynamic> params;
  final String id;

  RpcRequest({
    required this.method,
    required this.params,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'jsonrpc': '2.0',
    'method': method,
    'params': params,
    'id': id,
  };
}

/// JSON-RPC Response
class RpcResponse {
  final dynamic result;
  final Map<String, dynamic>? error;
  final String id;

  RpcResponse({
    this.result,
    this.error,
    required this.id,
  });

  factory RpcResponse.fromJson(Map<String, dynamic> json) {
    return RpcResponse(
      result: json['result'],
      error: json['error'],
      id: json['id'],
    );
  }
}

/// RPC Client for EVM Networks
/// 
/// Responsibility: Communicate with EVM-compatible blockchain nodes.
/// - Send JSON-RPC requests to blockchain nodes
/// - Handle responses and errors
/// - Support multiple network endpoints
/// 
/// Security: Never transmits private keys or mnemonics
abstract class RpcClient {
  /// Send JSON-RPC request to blockchain node
  Future<RpcResponse> sendRequest(RpcRequest request);

  /// Get current block number
  Future<int> getBlockNumber();

  /// Get balance for address
  Future<BigInt> getBalance(String address);

  /// Get transaction count (nonce) for address
  Future<int> getTransactionCount(String address);

  /// Send raw signed transaction
  Future<String> sendRawTransaction(String signedTx);

  /// Estimate gas for transaction
  Future<BigInt> estimateGas(Map<String, dynamic> transaction);
}
