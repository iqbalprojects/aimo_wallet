import '../entities/network.dart';

/// Network Repository Interface
/// 
/// Responsibility: Manage network configurations.
/// - Get available networks
/// - Get current network
/// - Switch networks
/// - Add custom networks
abstract class NetworkRepository {
  /// Get all available networks
  Future<List<Network>> getNetworks();

  /// Get current active network
  Future<Network> getCurrentNetwork();

  /// Switch to different network
  Future<void> switchNetwork(Network network);

  /// Add custom network
  Future<void> addCustomNetwork(Network network);

  /// Remove custom network
  Future<void> removeCustomNetwork(String chainId);
}
