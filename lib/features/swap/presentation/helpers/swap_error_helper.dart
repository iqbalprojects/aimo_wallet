import 'package:flutter/foundation.dart';

/// Swap Error Types
///
/// Classification of swap-related errors for user-friendly messaging.
enum SwapErrorType {
  insufficientBalance,
  slippageError,
  rpcTimeout,
  userRejected,
  gasEstimationFailed,
  allowanceError,
  networkError,
  signingError,
  broadcastError,
  liquidityError,
  unknown,
}

/// Swap Error Helper
///
/// Classifies errors and provides user-friendly messages.
/// Never exposes raw RPC errors to users.
/// Logs internal errors safely (no sensitive data).
class SwapErrorHelper {
  /// Classify error from exception
  static SwapErrorType classify(Object error) {
    final errorString = error.toString().toLowerCase();

    // Insufficient balance patterns
    if (_matchesPatterns(errorString, [
      'insufficient balance',
      'insufficient funds',
      'gas required exceeds',
      'not enough balance',
    ])) {
      return SwapErrorType.insufficientBalance;
    }

    // Slippage error patterns
    if (_matchesPatterns(errorString, [
      'slippage',
      'price impact too high',
      'insufficient output amount',
      'excessive price impact',
    ])) {
      return SwapErrorType.slippageError;
    }

    // RPC timeout patterns
    if (_matchesPatterns(errorString, [
      'timeout',
      'timed out',
      'connection timeout',
      'socketexception',
      'connection refused',
    ])) {
      return SwapErrorType.rpcTimeout;
    }

    // User rejected patterns
    if (_matchesPatterns(errorString, [
      'user rejected',
      'user denied',
      'user cancelled',
      'user canceled',
      'rejected by user',
    ])) {
      return SwapErrorType.userRejected;
    }

    // Gas estimation failure patterns
    if (_matchesPatterns(errorString, [
      'gas estimation failed',
      'gas too low',
      'out of gas',
      'intrinsic gas',
      'execution reverted',
      'cannot estimate gas',
    ])) {
      return SwapErrorType.gasEstimationFailed;
    }

    // Allowance error patterns
    if (_matchesPatterns(errorString, [
      'allowance',
      'not approved',
      'insufficient allowance',
      'approve required',
    ])) {
      return SwapErrorType.allowanceError;
    }

    // Network error patterns
    if (_matchesPatterns(errorString, [
      'network',
      'no network',
      'chain id',
      'wrong network',
      'network mismatch',
    ])) {
      return SwapErrorType.networkError;
    }

    // Signing error patterns
    if (_matchesPatterns(errorString, [
      'sign',
      'invalid signature',
      'signature',
      'private key',
      'pin',
    ])) {
      return SwapErrorType.signingError;
    }

    // Broadcast error patterns
    if (_matchesPatterns(errorString, [
      'broadcast',
      'nonce too low',
      'nonce too high',
      'replacement transaction',
      'already known',
      'transaction underpriced',
    ])) {
      return SwapErrorType.broadcastError;
    }

    if (_matchesPatterns(errorString, ['liquidity'])) {
      return SwapErrorType.liquidityError;
    }

    return SwapErrorType.unknown;
  }

  /// Check if error string matches any pattern
  static bool _matchesPatterns(String error, List<String> patterns) {
    return patterns.any((pattern) => error.contains(pattern));
  }

  /// Get user-friendly message for error type
  static String getUserMessage(SwapErrorType type) {
    switch (type) {
      case SwapErrorType.insufficientBalance:
        return 'Insufficient balance. Please check your token balance and try again.';

      case SwapErrorType.slippageError:
        return 'Price moved too much. Try increasing slippage tolerance or try again later.';

      case SwapErrorType.rpcTimeout:
        return 'Network connection timed out. Please check your internet and try again.';

      case SwapErrorType.userRejected:
        return 'Transaction was cancelled.';

      case SwapErrorType.gasEstimationFailed:
        return 'Could not estimate gas fees. The transaction may fail. Please try again.';

      case SwapErrorType.allowanceError:
        return 'Token approval required. Please approve the token first.';

      case SwapErrorType.networkError:
        return 'Network error. Please check your connection and try again.';

      case SwapErrorType.signingError:
        return 'Failed to sign transaction. Please verify your PIN and try again.';

      case SwapErrorType.broadcastError:
        return 'Failed to submit transaction. Please try again.';

      case SwapErrorType.liquidityError:
        return 'No liquidity available for this trade pair/amount.';

      case SwapErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Log error safely (no sensitive data)
  static void logError(
    String operation,
    Object error, {
    StackTrace? stackTrace,
  }) {
    // Only log in debug mode
    if (!kDebugMode) return;

    // Sanitize error - remove potential sensitive data
    final sanitizedError = _sanitizeError(error.toString());

    debugPrint('========================================');
    debugPrint('Swap Error: $operation');
    debugPrint('Type: ${classify(error).name}');
    debugPrint('Details: $sanitizedError');
    if (stackTrace != null) {
      debugPrint(
        'Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}',
      );
    }
    debugPrint('========================================');
  }

  /// Sanitize error string - remove sensitive data patterns
  static String _sanitizeError(String error) {
    // Remove potential private keys (64+ hex chars)
    var sanitized = error.replaceAll(
      RegExp(r'0x[a-fA-F0-9]{64,}'),
      '[REDACTED_KEY]',
    );

    // Remove potential mnemonics (12-24 words)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(\w+\s+){11,23}\w+\b'),
      '[REDACTED_MNEMONIC]',
    );

    // Remove potential addresses (keep first/last 6 chars)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'0x[a-fA-F0-9]{40}'),
      (match) =>
          '${match.group(0)!.substring(0, 8)}...${match.group(0)!.substring(38)}',
    );

    return sanitized;
  }

  /// Handle error with classification, logging, and user message
  static String handleError(
    String operation,
    Object error, {
    StackTrace? stackTrace,
  }) {
    // Log safely
    logError(operation, error, stackTrace: stackTrace);

    // Classify and return user message
    final type = classify(error);
    return getUserMessage(type);
  }
}
