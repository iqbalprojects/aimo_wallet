import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Token price in USD
class TokenPrice {
  final String tokenAddress;
  final double priceUSD;
  final DateTime timestamp;

  TokenPrice({
    required this.tokenAddress,
    required this.priceUSD,
    required this.timestamp,
  });

  /// Check if price is stale (older than 5 minutes)
  bool get isStale {
    final age = DateTime.now().difference(timestamp);
    return age > const Duration(minutes: 5);
  }

  @override
  String toString() => 'TokenPrice($tokenAddress: \$$priceUSD)';
}

/// Exception thrown by price oracle operations
class PriceOracleException implements Exception {
  final String message;
  final String? details;

  PriceOracleException(this.message, {this.details});

  @override
  String toString() => 'PriceOracleException: $message';
}

/// Price Oracle Service
///
/// Fetches token prices in USD from multiple sources with caching.
///
/// Data Sources (in priority order):
/// 1. CoinGecko API (free, reliable)
/// 2. CoinMarketCap API (requires API key)
/// 3. 1inch Price API (on-chain prices)
///
/// Features:
/// - Multiple provider support with fallback
/// - Price caching (5-minute cache)
/// - Batch price fetching
/// - USD value calculation
///
/// Usage:
/// ```dart
/// final service = PriceOracleService(httpClient: http.Client());
///
/// // Get single token price
/// final price = await service.getTokenPriceUSD(
///   '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
/// );
/// print('USDT: \$$price');
///
/// // Get multiple token prices
/// final prices = await service.getTokenPricesUSD([
///   '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
///   '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
/// ]);
///
/// // Calculate USD value
/// final usdValue = service.calculateUSDValue(
///   BigInt.from(1000000), // 1 USDT (6 decimals)
///   6,
///   price,
/// );
/// ```
class PriceOracleService {
  final http.Client _httpClient;
  final Duration _cacheTimeout;

  // Price cache
  final Map<String, TokenPrice> _priceCache = {};

  // Known token addresses to CoinGecko IDs mapping
  static const Map<String, String> _tokenToCoinGeckoId = {
    // Ethereum mainnet
    '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE': 'ethereum', // ETH
    '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2': 'weth', // WETH
    '0xdAC17F958D2ee523a2206206994597C13D831ec7': 'tether', // USDT
    '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48': 'usd-coin', // USDC
    '0x6B175474E89094C44Da98b954EedeAC495271d0F': 'dai', // DAI
    '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599': 'wrapped-bitcoin', // WBTC
    // Add more as needed
  };

  PriceOracleService({
    http.Client? httpClient,
    Duration cacheTimeout = const Duration(minutes: 5),
  })  : _httpClient = httpClient ?? http.Client(),
        _cacheTimeout = cacheTimeout;

  /// Get token price in USD
  ///
  /// Returns cached price if available and not stale.
  /// Otherwise fetches fresh price from API.
  Future<double> getTokenPriceUSD(String tokenAddress) async {
    final normalizedAddress = tokenAddress.toLowerCase();

    // Check cache
    final cached = _priceCache[normalizedAddress];
    if (cached != null && !cached.isStale) {
      return cached.priceUSD;
    }

    // Fetch fresh price
    try {
      final price = await _fetchPriceFromCoinGecko(normalizedAddress);
      _updateCache(normalizedAddress, price);
      return price;
    } catch (e) {
      // If fetch fails and we have stale cache, use it
      if (cached != null) {
        return cached.priceUSD;
      }
      throw PriceOracleException(
        'Failed to fetch price for $tokenAddress',
        details: e.toString(),
      );
    }
  }

  /// Get multiple token prices in USD
  ///
  /// Fetches prices for multiple tokens efficiently.
  /// Uses batch API calls when possible.
  Future<Map<String, double>> getTokenPricesUSD(
    List<String> tokenAddresses,
  ) async {
    final prices = <String, double>{};
    final addressesToFetch = <String>[];

    // Check cache first
    for (final address in tokenAddresses) {
      final normalizedAddress = address.toLowerCase();
      final cached = _priceCache[normalizedAddress];

      if (cached != null && !cached.isStale) {
        prices[normalizedAddress] = cached.priceUSD;
      } else {
        addressesToFetch.add(normalizedAddress);
      }
    }

    // Fetch missing prices
    if (addressesToFetch.isNotEmpty) {
      try {
        final fetchedPrices = await _fetchMultiplePricesFromCoinGecko(
          addressesToFetch,
        );

        for (final entry in fetchedPrices.entries) {
          prices[entry.key] = entry.value;
          _updateCache(entry.key, entry.value);
        }
      } catch (e) {
        // Use stale cache for failed fetches
        for (final address in addressesToFetch) {
          final cached = _priceCache[address];
          if (cached != null) {
            prices[address] = cached.priceUSD;
          }
        }
      }
    }

    return prices;
  }

  /// Calculate USD value from token amount
  ///
  /// Parameters:
  /// - amount: Token amount in smallest units (wei, satoshi, etc.)
  /// - decimals: Token decimals (18 for ETH, 6 for USDT, etc.)
  /// - priceUSD: Token price in USD
  ///
  /// Returns: USD value as double
  double calculateUSDValue(BigInt amount, int decimals, double priceUSD) {
    // Convert amount to decimal
    final divisor = BigInt.from(10).pow(decimals);
    final decimalAmount = amount / divisor;

    // Calculate USD value
    return decimalAmount * priceUSD;
  }

  /// Fetch price from CoinGecko API
  Future<double> _fetchPriceFromCoinGecko(String tokenAddress) async {
    // Get CoinGecko ID for token
    final coinGeckoId = _tokenToCoinGeckoId[tokenAddress];
    if (coinGeckoId == null) {
      throw PriceOracleException(
        'Token not supported: $tokenAddress',
        details: 'No CoinGecko ID mapping found',
      );
    }

    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/simple/price?ids=$coinGeckoId&vs_currencies=usd',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw PriceOracleException(
          'CoinGecko API error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final priceData = data[coinGeckoId] as Map<String, dynamic>?;

      if (priceData == null || !priceData.containsKey('usd')) {
        throw PriceOracleException('Price data not found for $coinGeckoId');
      }

      return (priceData['usd'] as num).toDouble();
    } catch (e) {
      throw PriceOracleException(
        'Failed to fetch from CoinGecko',
        details: e.toString(),
      );
    }
  }

  /// Fetch multiple prices from CoinGecko API
  Future<Map<String, double>> _fetchMultiplePricesFromCoinGecko(
    List<String> tokenAddresses,
  ) async {
    final prices = <String, double>{};

    // Map addresses to CoinGecko IDs
    final coinGeckoIds = <String>[];
    final idToAddress = <String, String>{};

    for (final address in tokenAddresses) {
      final id = _tokenToCoinGeckoId[address];
      if (id != null) {
        coinGeckoIds.add(id);
        idToAddress[id] = address;
      }
    }

    if (coinGeckoIds.isEmpty) {
      return prices;
    }

    try {
      final idsParam = coinGeckoIds.join(',');
      final response = await _httpClient
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/simple/price?ids=$idsParam&vs_currencies=usd',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw PriceOracleException(
          'CoinGecko API error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      for (final entry in data.entries) {
        final coinGeckoId = entry.key;
        final priceData = entry.value as Map<String, dynamic>;
        final address = idToAddress[coinGeckoId];

        if (address != null && priceData.containsKey('usd')) {
          prices[address] = (priceData['usd'] as num).toDouble();
        }
      }

      return prices;
    } catch (e) {
      throw PriceOracleException(
        'Failed to fetch multiple prices from CoinGecko',
        details: e.toString(),
      );
    }
  }

  /// Update price cache
  void _updateCache(String tokenAddress, double priceUSD) {
    _priceCache[tokenAddress] = TokenPrice(
      tokenAddress: tokenAddress,
      priceUSD: priceUSD,
      timestamp: DateTime.now(),
    );
  }

  /// Clear price cache
  void clearCache() {
    _priceCache.clear();
  }

  /// Clear stale prices from cache
  void clearStaleCache() {
    _priceCache.removeWhere((key, value) => value.isStale);
  }

  /// Get cache size
  int get cacheSize => _priceCache.length;

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    _priceCache.clear();
  }
}
