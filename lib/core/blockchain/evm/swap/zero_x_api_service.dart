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

/// Service for interacting with the 0x Swap API v2 (permit2).
///
/// Provides access to the 0x decentralized exchange aggregator for
/// finding the best swap routes across multiple DEXs.
///
/// ⚠️ MIGRATION NOTE: Updated from v1 (deprecated) to v2 (permit2).
///    0x API v1 at https://api.0x.org/swap/v1 is no longer supported on mainnet.
///    v2 uses permit2 for more efficient and secure token approvals.
///
/// API Documentation: https://0x.org/docs/api/swap/v2/introduction
///
/// Supported Networks (0x API v2):
/// - Ethereum: chainId 1
/// - Polygon: chainId 137
/// - BSC: chainId 56
/// - Base: chainId 8453
/// - Arbitrum: chainId 42161
/// - Optimism: chainId 10
/// - Avalanche: chainId 43114
///
/// This service ONLY fetches swap quotes - it does NOT:
/// - Sign transactions
/// - Broadcast transactions
/// - Execute swaps
/// - Handle approvals
///
/// Swap Flow (v2/permit2):
/// 1. Get quote from this service
/// 2. Check allowance for permit2 contract
/// 3. Sign permit2 message (or approve tokens if needed)
/// 4. Submit swap transaction with signed permit2
///
/// Usage:
/// ```dart
/// final service = ZeroXApiService(chainId: 1); // Ethereum mainnet
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
  /// Base URL for 0x Swap API v2.
  /// Chain-specific endpoints are used for better routing.
  /// Using Allowance Holder endpoint as it supports standard ERC20 approvals.
  static const String _baseUrl = 'https://api.0x.org/swap/allowance-holder';

  /// 0x API key loaded from environment variable.
  /// Set ZERO_X_API_KEY in your build configuration.
  /// Get your key at: https://0x.org/docs/introduction/getting-started
  ///
  /// IMPORTANT: The default key below is for testing only and may not work.
  /// You MUST get your own API key from https://dashboard.0x.org/
  static const String _apiKey = String.fromEnvironment(
    'ZERO_X_API_KEY',
    defaultValue: '', // Empty default - forces user to set their own key
  );

  /// Networks supported by 0x API v2.
  /// Maps chainId → true (supported) or false (not supported).
  static const Map<int, bool> _supportedChains = {
    1: true, // Ethereum Mainnet
    137: true, // Polygon
    56: true, // BNB Smart Chain
    8453: true, // Base
    42161: true, // Arbitrum One
    10: true, // Optimism
    43114: true, // Avalanche
    // Testnets (limited support)
    11155111: true, // Sepolia (limited)
  };

  /// Chain ID for the current network.
  final int chainId;

  /// HTTP client for making requests.
  final http.Client _httpClient;

  /// Request timeout duration.
  final Duration timeout;

  /// Creates a 0x API service for a specific chain.
  ///
  /// Parameters:
  /// - chainId: Chain ID of the network to use
  /// - httpClient: Optional HTTP client (defaults to new client)
  /// - timeout: Request timeout (defaults to 30 seconds)
  ZeroXApiService({
    required this.chainId,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  /// Check if current chain is supported by 0x API.
  bool get isChainSupported => _supportedChains[chainId] ?? false;

  /// Fetches an indicative price from the 0x API v2.
  ///
  /// Gets a read-only price quote without creating a full order.
  /// Use this to show users potential prices before committing to a swap.
  /// This is the "price" endpoint - the read-only version of "quote".
  ///
  /// Parameters:
  /// - sellToken: Address of the token to sell
  /// - buyToken: Address of the token to buy
  /// - sellAmount: Amount to sell (in smallest units, e.g., wei for ETH)
  /// - takerAddress: Address that will execute the swap (user wallet)
  /// - slippagePercentage: Maximum acceptable price movement (0.01 = 1%)
  ///
  /// Returns: SwapQuoteModel with price information
  ///
  /// Throws:
  /// - ZeroXApiException: If API call fails or returns error
  /// - ArgumentError: If parameters are invalid
  Future<SwapQuoteModel> getPrice({
    required String sellToken,
    required String buyToken,
    required String sellAmount,
    required String takerAddress,
    required double slippagePercentage,
  }) async {
    // Validate chain support
    if (!isChainSupported) {
      throw ZeroXApiException(
        'Chain ID $chainId is not supported by 0x API. '
        'Supported chains: ${_supportedChains.keys.join(', ')}',
      );
    }

    // Validate API key is set
    if (_apiKey.isEmpty) {
      throw ZeroXApiException(
        'ZERO_X_API_KEY is not set. Please get your API key from https://dashboard.0x.org/ '
        'and add it to your .env file or build configuration.',
      );
    }

    // Validate parameters
    _validateAddress(sellToken, 'sellToken');
    _validateAddress(buyToken, 'buyToken');
    _validateAddress(takerAddress, 'takerAddress');
    _validateAmount(sellAmount, 'sellAmount');
    _validateSlippage(slippagePercentage);

    // Build query parameters for 0x API v2 allowance-holder endpoint
    final queryParams = {
      'chainId': chainId.toString(),
      'sellToken': sellToken,
      'buyToken': buyToken,
      'sellAmount': sellAmount,
      'taker': takerAddress,
      'slippageBps': (slippagePercentage * 10000).round().toString(),
    };

    // Build URI for v2 price endpoint
    final uri = Uri.parse(
      '$_baseUrl/price',
    ).replace(queryParameters: queryParams);

    // Log request for debugging (remove in production)
    print('[0x API] GET $uri');

    try {
      // Make HTTP GET request with timeout
      final response = await _httpClient
          .get(uri, headers: {'0x-api-key': _apiKey, '0x-version': 'v2'})
          .timeout(timeout);

      // Log response status for debugging
      print('[0x API] Response status: ${response.statusCode}');

      // Check for HTTP errors
      if (response.statusCode != 200) {
        print('[0x API] Error response: ${response.body}');
        throw _parseErrorResponse(response);
      }

      // Log successful response (truncated)
      print('[0x API] Success - received quote data');

      // Parse JSON response
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for lack of liquidity
      if (jsonData['liquidityAvailable'] == false) {
        throw ZeroXApiException(
          'No liquidity available for this trade pair/amount.',
        );
      }

      // Create and return model (v2 response format)
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
      print('[0x API] Exception: $e');
      throw ZeroXApiException('Failed to fetch price', details: e.toString());
    }
  }

  /// Fetches a swap quote from the 0x API v2.
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
    // Validate chain support
    if (!isChainSupported) {
      throw ZeroXApiException(
        'Chain ID $chainId is not supported by 0x API. '
        'Supported chains: ${_supportedChains.keys.join(', ')}',
      );
    }

    // Validate API key is set
    if (_apiKey.isEmpty) {
      throw ZeroXApiException(
        'ZERO_X_API_KEY is not set. Please get your API key from https://dashboard.0x.org/ '
        'and add it to your .env file or build configuration.',
      );
    }

    // Validate parameters
    _validateAddress(sellToken, 'sellToken');
    _validateAddress(buyToken, 'buyToken');
    _validateAddress(takerAddress, 'takerAddress');
    _validateAmount(sellAmount, 'sellAmount');
    _validateSlippage(slippagePercentage);

    // Build query parameters for 0x API v2 allowance-holder endpoint
    // According to docs: https://docs.0x.org/docs/introduction/quickstart/swap-tokens-with-0x-swap-api
    final queryParams = {
      'chainId': chainId.toString(),
      'sellToken': sellToken,
      'buyToken': buyToken,
      'sellAmount': sellAmount,
      'taker': takerAddress,
      'slippageBps': (slippagePercentage * 10000).round().toString(),
    };

    // Build URI for v2 quote endpoint
    final uri = Uri.parse(
      '$_baseUrl/quote',
    ).replace(queryParameters: queryParams);

    // Log request for debugging (remove in production)
    print('[0x API] GET $uri');

    try {
      // Make HTTP GET request with timeout
      // According to 0x docs, only need 0x-api-key header
      final response = await _httpClient
          .get(uri, headers: {'0x-api-key': _apiKey, '0x-version': 'v2'})
          .timeout(timeout);

      // Log response status for debugging
      print('[0x API] Response status: ${response.statusCode}');

      // Check for HTTP errors
      if (response.statusCode != 200) {
        print('[0x API] Error response: ${response.body}');
        throw _parseErrorResponse(response);
      }

      // Log successful response (truncated)
      print('[0x API] Success - received quote data');

      // Parse JSON response
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for lack of liquidity
      if (jsonData['liquidityAvailable'] == false) {
        throw ZeroXApiException(
          'No liquidity available for this trade pair/amount.',
        );
      }

      // Create and return model (v2 response format)
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
      print('[0x API] Exception: $e');
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

    // Use BigInt to handle large token amounts (e.g. 18-decimal tokens)
    final parsed = BigInt.tryParse(amount);
    if (parsed == null) {
      throw ArgumentError('$paramName must be a valid integer');
    }

    if (parsed < BigInt.zero) {
      throw ArgumentError('$paramName cannot be negative');
    }
  }

  /// Validates slippage percentage.
  ///
  /// Slippage must be between 0.001 (0.1%) and 0.5 (50%).
  /// Too low slippage will cause transaction failures.
  /// Too high slippage exposes user to MEV attacks.
  void _validateSlippage(double slippage) {
    if (slippage < 0.001) {
      throw ArgumentError(
        'slippagePercentage too low. Minimum is 0.001 (0.1%). '
        'Lower values will cause transaction failures.',
      );
    }

    if (slippage > 0.5) {
      throw ArgumentError(
        'slippagePercentage cannot exceed 0.5 (50%). Use 0.01 for 1%.',
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
      // v2 error format
      message =
          errorData['reason'] as String? ??
          errorData['message'] as String? ??
          errorData['error'] as String? ??
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
