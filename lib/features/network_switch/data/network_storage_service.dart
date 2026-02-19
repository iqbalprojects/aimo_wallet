import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/controllers/network_controller.dart';

/// Network Storage Service
/// 
/// DATA LAYER - Local Storage
/// 
/// Provides persistent storage for network configuration using SharedPreferences.
/// 
/// Storage Keys:
/// - 'current_network_id': ID of currently selected network
/// - 'custom_networks': JSON array of custom networks
/// 
/// Security:
/// - Non-secure storage (SharedPreferences) is OK for network config
/// - Network config is public information
/// - Does NOT store private keys or sensitive data
/// 
/// Usage:
/// ```dart
/// final storage = NetworkStorageService();
/// 
/// // Save current network
/// await storage.saveCurrentNetwork('ethereum-mainnet');
/// 
/// // Load current network
/// final networkId = await storage.getCurrentNetwork();
/// 
/// // Save custom networks
/// await storage.saveCustomNetworks(networks);
/// ```
class NetworkStorageService {
  static const String _currentNetworkKey = 'current_network_id';
  static const String _customNetworksKey = 'custom_networks';

  /// Save current network ID
  /// 
  /// Parameters:
  /// - networkId: ID of network to save as current
  Future<void> saveCurrentNetwork(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentNetworkKey, networkId);
  }

  /// Get current network ID
  /// 
  /// Returns: Network ID or null if not set
  Future<String?> getCurrentNetwork() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentNetworkKey);
  }

  /// Save custom networks
  /// 
  /// Parameters:
  /// - networks: List of custom networks to save
  Future<void> saveCustomNetworks(List<Network> networks) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert networks to JSON
    final networksJson = networks.map((n) => _networkToJson(n)).toList();
    final jsonString = jsonEncode(networksJson);
    
    await prefs.setString(_customNetworksKey, jsonString);
  }

  /// Load custom networks
  /// 
  /// Returns: List of custom networks or empty list if none saved
  Future<List<Network>> getCustomNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customNetworksKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _networkFromJson(json)).toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Clear all network storage
  /// 
  /// Useful for testing or reset functionality
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentNetworkKey);
    await prefs.remove(_customNetworksKey);
  }

  /// Convert Network to JSON map
  Map<String, dynamic> _networkToJson(Network network) {
    return {
      'id': network.id,
      'name': network.name,
      'chainId': network.chainId,
      'rpcUrl': network.rpcUrl,
      'symbol': network.symbol,
      'explorerUrl': network.explorerUrl,
      'isTestnet': network.isTestnet,
      'isCustom': network.isCustom,
    };
  }

  /// Convert JSON map to Network
  Network _networkFromJson(Map<String, dynamic> json) {
    return Network(
      id: json['id'] as String,
      name: json['name'] as String,
      chainId: json['chainId'] as int,
      rpcUrl: json['rpcUrl'] as String,
      symbol: json['symbol'] as String,
      explorerUrl: json['explorerUrl'] as String,
      isTestnet: json['isTestnet'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
