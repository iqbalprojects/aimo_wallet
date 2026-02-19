/// Network Entity
/// 
/// Responsibility: Represent blockchain network configuration.
class Network {
  final String chainId;
  final String name;
  final String rpcUrl;
  final String symbol;
  final String explorerUrl;
  final bool isTestnet;

  Network({
    required this.chainId,
    required this.name,
    required this.rpcUrl,
    required this.symbol,
    required this.explorerUrl,
    this.isTestnet = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Network &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId;

  @override
  int get hashCode => chainId.hashCode;
}
