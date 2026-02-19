/// Network Configuration
class NetworkConfig {
  final String chainId;
  final String name;
  final String rpcUrl;
  final String symbol;
  final String explorerUrl;

  NetworkConfig({
    required this.chainId,
    required this.name,
    required this.rpcUrl,
    required this.symbol,
    required this.explorerUrl,
  });
}

/// Predefined EVM Networks
/// 
/// Responsibility: Provide configuration for supported EVM networks.
/// - Ethereum Mainnet
/// - Polygon
/// - BSC
/// - Arbitrum
/// - Optimism
class NetworkConfigs {
  static final ethereum = NetworkConfig(
    chainId: '1',
    name: 'Ethereum Mainnet',
    rpcUrl: 'https://eth.llamarpc.com',
    symbol: 'ETH',
    explorerUrl: 'https://etherscan.io',
  );

  static final polygon = NetworkConfig(
    chainId: '137',
    name: 'Polygon',
    rpcUrl: 'https://polygon-rpc.com',
    symbol: 'MATIC',
    explorerUrl: 'https://polygonscan.com',
  );

  static final bsc = NetworkConfig(
    chainId: '56',
    name: 'BNB Smart Chain',
    rpcUrl: 'https://bsc-dataseed.binance.org',
    symbol: 'BNB',
    explorerUrl: 'https://bscscan.com',
  );

  static List<NetworkConfig> get all => [ethereum, polygon, bsc];
}
