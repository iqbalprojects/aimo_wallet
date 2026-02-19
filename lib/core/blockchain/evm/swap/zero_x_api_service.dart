import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../features/swap/data/models/swap_quote_model.dart';

/// Exception thrown by 0x API service operations.
class ZeroXApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  ZeroXApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ZeroXApiException: $message (status: $statusCode)';
    }
    return 'ZeroXApiException: $message';
  }
}

/// Service for interacting with the 0x Swap API.
///
/// Provides access to the 0x decentralized exchange aggregator for
/// finding the best swap routes across multiple DEXs.
///
/// API Documentation: https://0x.org/docs/api/swap/introduction
///
/// This service ONLY fetches swap quotes - it does NOT:
/// - Sign transactions
/// - Broadcast transactions
/// - Execute swaps
/// - Handle approvals
///
/// Swap Flow:
/// 1. Get quote from this service
/// 2. Check allowance (CheckAllowanceUseCase)
/// 3. Approve tokens if needed (ApproveTokenUseCase)
/// 4. Sign transaction (TransactionEngine)
/// 5. Broadcast transaction
///
/// Usage:
/// ```dart
/// final service = ZeroXApiService();
///
/// final quote = await service.getQuote(
///   sellToken: '0xUSDT...',    // Token to sell
///   buyToken: '0xWETH...',     // Token to buy
///   sellAmount: '100000000',   // Amount in smallest units
///   takerAddress: '0xUser...',  // User wallet address
///   slippagePercentage: 0.01,  // 1% slippage tolerance
/// );
///
/// // Use quote.to, quote.data, quote.value for transaction
/// ```
class ZeroXApiService {
  /// Base URL for 0x Swap API v1.
  static const String _baseUrl = 'https://api.0x.org/swap/v1';

  /// HTTP client for making requests.
  final http.Client _httpClient;

  /// Request timeout duration.
  final Duration timeout;

  /// Creates a 0x API service.
  ///
  /// Parameters:
  /// - httpClient: Optional HTTP client (defaults to new client)
  /// - timeout: Request timeout (defaults to 30 seconds)
  ZeroXApiService({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  /// Fetches a swap quote from the 0x API.
  ///
  /// Gets the best available swap route for the given token pair.
  /// The returned quote contains all data needed to build the transaction.
  ///
  /// Parameters:
  /// - sellToken: Address of the token to sell
  /// - buyToken: Address of the token to buy
  /// - sellAmount: Amount to sell (in smallest units, e.g., wei for ETH)
  /// - takerAddress: Address that will execute the swap (user wallet)
  /// - slippagePercentage: Maximum acceptable price movement (0.01 = 1%)
  ///
  /// Returns: SwapQuoteModel with transaction data
  ///
  /// Throws:
  /// - ZeroXApiException: If API call fails or returns error
  /// - ArgumentError: If parameters are invalid
  ///
  /// Security:
  /// - No private key handling
  /// - No transaction signing
  /// - Read-only operation
  Future<SwapQuoteModel> getQuote({
    required String sellToken,
    required String buyToken,
    required String sellAmount,
    required String takerAddress,
    required double slippagePercentage,
  }) async {
    // Validate parameters
    _validateAddress(sellToken, 'sellToken');
    _validateAddress(buyToken, 'buyToken');
    _validateAddress(takerAddress, 'takerAddress');
    _validateAmount(sellAmount, 'sellAmount');
    _validateSlippage(slippagePercentage);

    // Build query parameters
    final queryParams = {
      'sellToken': sellToken,
      'buyToken': buyToken,
      'sellAmount': sellAmount,
      'takerAddress': takerAddress,
      'slippagePercentage': slippagePercentage.toString(),
    };

    // Build URI
    final uri = Uri.parse(
      '$_baseUrl/quote',
    ).replace(queryParameters: queryParams);

    try {
      // Make HTTP GET request with timeout
      final response = await _httpClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout);

      // Check for HTTP errors
      if (response.statusCode != 200) {
        throw _parseErrorResponse(response);
      }

      // Parse JSON response
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // Create and return model
      return SwapQuoteModel.fromJson(jsonData);
    } on ZeroXApiException {
      rethrow;
    } on TimeoutException {
      throw ZeroXApiException(
        'Request timed out after ${timeout.inSeconds} seconds',
      );
    } on FormatException catch (e) {
      throw ZeroXApiException(
        'Failed to parse API response',
        details: e.toString(),
      );
    } catch (e) {
      throw ZeroXApiException(
        'Failed to fetch swap quote',
        details: e.toString(),
      );
    }
  }

  /// Validates an Ethereum address format.
  void _validateAddress(String address, String paramName) {
    if (address.isEmpty) {
      throw ArgumentError('$paramName cannot be empty');
    }

    if (!address.startsWith('0x')) {
      throw ArgumentError('$paramName must start with 0x');
    }

    if (address.length != 42) {
      throw ArgumentError('$paramName must be 42 characters (0x + 40 hex)');
    }

    // Validate hex characters
    final hexPart = address.substring(2);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexPart)) {
      throw ArgumentError('$paramName contains invalid hex characters');
    }
  }

  /// Validates a token amount string.
  void _validateAmount(String amount, String paramName) {
    if (amount.isEmpty) {
      throw ArgumentError('$paramName cannot be empty');
    }

    // Check if it's a valid positive integer string
    final parsed = int.tryParse(amount);
    if (parsed == null) {
      throw ArgumentError('$paramName must be a valid integer');
    }

    if (parsed < 0) {
      throw ArgumentError('$paramName cannot be negative');
    }
  }

  /// Validates slippage percentage.
  ///
  /// Slippage must be between 0.001 (0.1%) and 1.0 (100%).
  /// Too low slippage will cause transaction failures.
  /// Too high slippage exposes user to MEV attacks.
  void _validateSlippage(double slippage) {
    if (slippage < 0.001) {
      throw ArgumentError(
        'slippagePercentage too low. Minimum is 0.001 (0.1%). '
        'Lower values will cause transaction failures.',
      );
    }

    if (slippage > 1) {
      throw ArgumentError(
        'slippagePercentage cannot exceed 1 (100%). Use 0.01 for 1%.',
      );
    }
  }

  /// Parses error response from API.
  ///
  /// Security: Sanitizes error details to prevent sensitive data leakage.
  ZeroXApiException _parseErrorResponse(http.Response response) {
    String message;

    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      message =
          errorData['reason'] as String? ??
          errorData['message'] as String? ??
          'Unknown API error';
      // Don't include errorData['values'] in details - could contain sensitive info
    } catch (_) {
      message = 'API request failed';
    }

    return ZeroXApiException(
      message,
      statusCode: response.statusCode,
      // Don't include response body in details - could contain sensitive info
    );
  }

  /// Disposes the HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
