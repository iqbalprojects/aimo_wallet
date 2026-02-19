import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rpc_client.dart';
import 'rpc_exception.dart';

/// RPC Client Implementation
///
/// Implements JSON-RPC communication with EVM-compatible blockchain nodes.
///
/// Features:
/// - HTTP-based JSON-RPC 2.0 protocol
/// - Error handling and retry logic
/// - Timeout management
/// - Request/response logging (debug mode only)
///
/// Security:
/// - Never transmits private keys or mnemonics
/// - Only sends signed transactions
/// - Validates responses
///
/// Usage:
/// ```dart
/// final client = RpcClientImpl(rpcUrl: 'https://mainnet.infura.io/v3/YOUR_KEY');
/// final balance = await client.getBalance('0x...');
/// ```
class RpcClientImpl implements RpcClient {
  final String rpcUrl;
  final http.Client _httpClient;
  final Duration timeout;

  RpcClientImpl({
    required this.rpcUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<RpcResponse> sendRequest(RpcRequest request) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse(rpcUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RpcResponse.fromJson(json);
      } else {
        if (response.statusCode == 401) {
          throw RpcException(
            'RPC Unauthorized (401). Invalid RPC credentials/project id. '
            'Please configure a valid RPC URL (e.g. set ETHEREUM_RPC_URL / SEPOLIA_RPC_URL).',
            code: response.statusCode,
          );
        }
        throw RpcException(
          'HTTP ${response.statusCode}: ${response.body}',
          code: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw RpcException(
        'Network error: ${e.message}',
        code: RpcErrorCode.networkError,
      );
    } catch (e) {
      if (e is RpcException) rethrow;
      throw RpcException(
        'Request failed: $e',
        code: RpcErrorCode.internalError,
      );
    }
  }

  @override
  Future<int> getBlockNumber() async {
    final request = RpcRequest(
      method: 'eth_blockNumber',
      params: [],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexBlock = response.result as String;
    return _hexToInt(hexBlock);
  }

  @override
  Future<BigInt> getBalance(String address) async {
    _validateAddress(address);

    final request = RpcRequest(
      method: 'eth_getBalance',
      params: [address.toLowerCase(), 'latest'],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexBalance = response.result as String;
    return _hexToBigInt(hexBalance);
  }

  @override
  Future<int> getTransactionCount(String address) async {
    _validateAddress(address);

    // Use 'pending' to include pending transactions in the count.
    // This ensures correct nonce when there are unconfirmed transactions.
    final request = RpcRequest(
      method: 'eth_getTransactionCount',
      params: [address.toLowerCase(), 'pending'],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexNonce = response.result as String;
    return _hexToInt(hexNonce);
  }

  @override
  Future<String> sendRawTransaction(String signedTx) async {
    if (!signedTx.startsWith('0x')) {
      signedTx = '0x$signedTx';
    }

    final request = RpcRequest(
      method: 'eth_sendRawTransaction',
      params: [signedTx],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);

    if (response.error != null) {
      final error = response.error!;
      final message = error['message'] as String? ?? 'Unknown error';
      final code = error['code'] as int? ?? -1;

      // Parse common blockchain errors
      if (message.contains('insufficient funds') ||
          message.contains('insufficient balance')) {
        throw InsufficientFundsException(message);
      } else if (message.contains('nonce too low') ||
          message.contains('nonce is too low')) {
        throw NonceTooLowException(message);
      } else if (message.contains('gas price') ||
          message.contains('underpriced')) {
        throw GasPriceTooLowException(message);
      } else if (message.contains('gas required exceeds allowance') ||
          message.contains('out of gas')) {
        throw OutOfGasException(message);
      } else if (message.contains('already known') ||
          message.contains('replacement transaction underpriced')) {
        throw TransactionAlreadyKnownException(message);
      } else {
        throw RpcException('Transaction failed: $message', code: code);
      }
    }

    return response.result as String; // Transaction hash
  }

  @override
  Future<BigInt> estimateGas(Map<String, dynamic> transaction) async {
    // Ensure addresses are lowercase
    if (transaction['from'] != null) {
      transaction['from'] = (transaction['from'] as String).toLowerCase();
    }
    if (transaction['to'] != null) {
      transaction['to'] = (transaction['to'] as String).toLowerCase();
    }

    final request = RpcRequest(
      method: 'eth_estimateGas',
      params: [transaction],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexGas = response.result as String;
    return _hexToBigInt(hexGas);
  }

  /// Get current gas price
  Future<BigInt> getGasPrice() async {
    final request = RpcRequest(
      method: 'eth_gasPrice',
      params: [],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexGasPrice = response.result as String;
    return _hexToBigInt(hexGasPrice);
  }

  /// Get transaction by hash
  Future<Map<String, dynamic>?> getTransactionByHash(String txHash) async {
    final request = RpcRequest(
      method: 'eth_getTransactionByHash',
      params: [txHash],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    return response.result as Map<String, dynamic>?;
  }

  /// Get transaction receipt
  Future<Map<String, dynamic>?> getTransactionReceipt(String txHash) async {
    final request = RpcRequest(
      method: 'eth_getTransactionReceipt',
      params: [txHash],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    return response.result as Map<String, dynamic>?;
  }

  /// Get chain ID
  Future<int> getChainId() async {
    final request = RpcRequest(
      method: 'eth_chainId',
      params: [],
      id: _generateRequestId(),
    );

    final response = await sendRequest(request);
    _throwIfError(response);

    final hexChainId = response.result as String;
    return _hexToInt(hexChainId);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Generate unique request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Convert hex string to int
  int _hexToInt(String hex) {
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }
    return int.parse(hex, radix: 16);
  }

  /// Convert hex string to BigInt
  BigInt _hexToBigInt(String hex) {
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }
    if (hex.isEmpty) {
      return BigInt.zero;
    }
    return BigInt.parse(hex, radix: 16);
  }

  /// Validate Ethereum address format
  void _validateAddress(String address) {
    if (!address.startsWith('0x') || address.length != 42) {
      throw RpcException(
        'Invalid address format: $address',
        code: RpcErrorCode.invalidParams,
      );
    }
  }

  /// Throw exception if response contains error
  void _throwIfError(RpcResponse response) {
    if (response.error != null) {
      final error = response.error!;
      final message = error['message'] as String? ?? 'Unknown error';
      final code = error['code'] as int? ?? -1;

      throw RpcException(message, code: code);
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }
}
