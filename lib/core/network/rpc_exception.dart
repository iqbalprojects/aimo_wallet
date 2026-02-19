/// RPC Exception
/// 
/// Base exception for all RPC-related errors.
class RpcException implements Exception {
  final String message;
  final int code;
  final dynamic data;

  RpcException(
    this.message, {
    this.code = -1,
    this.data,
  });

  @override
  String toString() => 'RpcException($code): $message';
}

/// RPC Error Codes
/// 
/// Standard JSON-RPC 2.0 error codes plus custom codes.
class RpcErrorCode {
  // JSON-RPC 2.0 standard errors
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  // Custom errors
  static const int networkError = -1;
  static const int timeout = -2;
  static const int unknownError = -3;
}

/// Insufficient Funds Exception
/// 
/// Thrown when account doesn't have enough balance for transaction.
class InsufficientFundsException implements Exception {
  final String message;

  InsufficientFundsException([this.message = 'Insufficient funds for transaction']);

  @override
  String toString() => 'InsufficientFundsException: $message';
}

/// Nonce Too Low Exception
/// 
/// Thrown when transaction nonce is lower than expected.
class NonceTooLowException implements Exception {
  final String message;

  NonceTooLowException([this.message = 'Transaction nonce too low']);

  @override
  String toString() => 'NonceTooLowException: $message';
}

/// Gas Price Too Low Exception
/// 
/// Thrown when gas price is too low for network conditions.
class GasPriceTooLowException implements Exception {
  final String message;

  GasPriceTooLowException([this.message = 'Gas price too low']);

  @override
  String toString() => 'GasPriceTooLowException: $message';
}

/// Out of Gas Exception
/// 
/// Thrown when transaction runs out of gas.
class OutOfGasException implements Exception {
  final String message;

  OutOfGasException([this.message = 'Transaction out of gas']);

  @override
  String toString() => 'OutOfGasException: $message';
}

/// Transaction Already Known Exception
/// 
/// Thrown when transaction is already in mempool.
class TransactionAlreadyKnownException implements Exception {
  final String message;

  TransactionAlreadyKnownException([this.message = 'Transaction already known']);

  @override
  String toString() => 'TransactionAlreadyKnownException: $message';
}
