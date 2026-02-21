import '../../../../core/blockchain/evm/erc20/erc20_service.dart';
import '../../../../core/network/rpc_client.dart';

/// Token balance result
class TokenBalance {
  /// Raw balance in smallest units (wei, satoshi, etc.)
  final BigInt raw;

  /// Token decimals
  final int decimals;

  /// Token symbol
  final String symbol;

  TokenBalance({
    required this.raw,
    required this.decimals,
    required this.symbol,
  });

  /// Get balance as decimal string
  ///
  /// Example: 1500000 with 6 decimals = "1.5"
  String toDecimalString({int maxDecimals = 6}) {
    if (raw == BigInt.zero) return '0';

    final str = raw.toString();
    if (str.length <= decimals) {
      // Less than 1 token
      final padded = str.padLeft(decimals, '0');
      final decimal = padded.substring(0, maxDecimals.clamp(0, decimals));
      return '0.$decimal'
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    // More than 1 token
    final integerPart = str.substring(0, str.length - decimals);
    final decimalPart = str.substring(str.length - decimals);
    final truncatedDecimal = decimalPart.substring(
      0,
      maxDecimals.clamp(0, decimals),
    );

    if (truncatedDecimal.isEmpty || truncatedDecimal == '0' * maxDecimals) {
      return integerPart;
    }

    return '$integerPart.$truncatedDecimal'
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Get formatted balance with symbol
  ///
  /// Example: "1.5 USDT"
  String toFormattedString({int maxDecimals = 6}) {
    return '${toDecimalString(maxDecimals: maxDecimals)} $symbol';
  }

  /// Check if balance is zero
  bool get isZero => raw == BigInt.zero;

  /// Check if balance is sufficient for amount
  bool isSufficient(BigInt amount) => raw >= amount;

  @override
  String toString() => toFormattedString();
}

/// Get Token Balance Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Fetch ERC20 token balance for a wallet
/// - Convert raw balance to readable format
/// - Provide balance information for UI display
///
/// This use case handles both:
/// - Native token balance (ETH, BNB, etc.)
/// - ERC20 token balance (USDT, USDC, etc.)
///
/// Usage:
/// ```dart
/// final useCase = GetTokenBalanceUseCase(erc20Service: service);
///
/// // Get ERC20 token balance
/// final balance = await useCase.call(
///   tokenAddress: '0xUSDT...',
///   walletAddress: '0xUser...',
///   decimals: 6,
///   symbol: 'USDT',
/// );
///
/// print(balance.toFormattedString()); // "100.5 USDT"
/// print(balance.raw); // BigInt: 100500000
/// ```
///
/// For native token (ETH):
/// ```dart
/// // Use special address for native token
/// final ethBalance = await useCase.call(
///   tokenAddress: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
///   walletAddress: '0xUser...',
///   decimals: 18,
///   symbol: 'ETH',
/// );
/// ```
class GetTokenBalanceUseCase {
  final Erc20Service _erc20Service;
  final RpcClient _rpcClient;

  /// Special address representing native token (ETH, BNB, etc.)
  static const String nativeTokenAddress =
      '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

  GetTokenBalanceUseCase({
    required Erc20Service erc20Service,
    required RpcClient rpcClient,
  }) : _erc20Service = erc20Service,
       _rpcClient = rpcClient;

  /// Execute use case
  ///
  /// Fetches token balance for the given wallet address.
  ///
  /// Parameters:
  /// - tokenAddress: ERC20 token contract address
  ///   (use nativeTokenAddress for native token)
  /// - walletAddress: User's wallet address
  /// - decimals: Token decimals (18 for ETH, 6 for USDT, etc.)
  /// - symbol: Token symbol for display
  ///
  /// Returns: TokenBalance with raw and formatted balance
  ///
  /// Throws:
  /// - Erc20Exception: If balance query fails
  /// - Exception: For other errors
  Future<TokenBalance> call({
    required String tokenAddress,
    required String walletAddress,
    required int decimals,
    required String symbol,
  }) async {
    try {
      // Check if this is native token
      final isNativeToken =
          tokenAddress.toLowerCase() == nativeTokenAddress.toLowerCase();

      BigInt balance;

      if (isNativeToken) {
        balance = await _rpcClient.getBalance(walletAddress);
      } else {
        // For ERC20 tokens, use Erc20Service
        balance = await _erc20Service.balanceOf(
          contractAddress: tokenAddress,
          walletAddress: walletAddress,
        );
      }

      return TokenBalance(raw: balance, decimals: decimals, symbol: symbol);
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch token balance: $e');
    }
  }

  /// Get multiple token balances at once
  ///
  /// Useful for fetching balances of multiple tokens efficiently.
  Future<Map<String, TokenBalance>> getMultipleBalances({
    required List<String> tokenAddresses,
    required String walletAddress,
    required Map<String, int> decimalsMap,
    required Map<String, String> symbolsMap,
  }) async {
    final balances = <String, TokenBalance>{};

    // Fetch all balances in parallel
    final futures = tokenAddresses.map((address) async {
      final balance = await call(
        tokenAddress: address,
        walletAddress: walletAddress,
        decimals: decimalsMap[address] ?? 18,
        symbol: symbolsMap[address] ?? 'UNKNOWN',
      );
      return MapEntry(address, balance);
    });

    final results = await Future.wait(futures);

    for (final entry in results) {
      balances[entry.key] = entry.value;
    }

    return balances;
  }
}
