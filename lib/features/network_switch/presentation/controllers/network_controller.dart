import 'package:get/get.dart';
import '../../../../core/network/rpc_client.dart';
import '../../../transaction/domain/usecases/get_nonce_usecase.dart';
import '../../../transaction/domain/usecases/estimate_gas_usecase.dart';
import '../../../transaction/domain/usecases/broadcast_transaction_usecase.dart';
import '../../../wallet/domain/usecases/get_balance_usecase.dart';
import '../../data/network_storage_service.dart';

/// Network Controller
///
/// PRESENTATION LAYER - GetX Controller
///
/// Responsibilities:
/// - Manage network state (reactive)
/// - Provide network switching
/// - Manage custom networks
/// - Persist network selection locally
///
/// SEPARATION OF CONCERNS:
/// - NO blockchain logic (delegated to domain layer)
/// - NO RPC implementation (uses network service)
/// - Uses NetworkStorageService for persistence
/// - UI observes reactive state (Rx)
///
/// Storage:
/// - Uses SharedPreferences (non-secure storage OK)
/// - Network config is public information
/// - Does NOT affect wallet derivation
///
/// Usage:
/// ```dart
/// final controller = Get.find<NetworkController>();
///
/// // Get current network (reactive)
/// Obx(() => Text(controller.currentNetwork?.name ?? 'No network'));
///
/// // Switch network
/// await controller.switchNetwork(network);
///
/// // Get available networks
/// Obx(() => ListView(children: controller.networks));
/// ```
class NetworkController extends GetxController {
  final NetworkStorageService _storageService;

  NetworkController({NetworkStorageService? storageService})
    : _storageService = storageService ?? NetworkStorageService();

  // ============================================================================
  // REACTIVE STATE (Observable by UI)
  // ============================================================================

  /// Current network
  final Rxn<Network> _currentNetwork = Rxn<Network>();

  /// Available networks
  final RxList<Network> _networks = <Network>[].obs;

  /// Loading state
  final RxBool _isLoading = false.obs;

  /// Error message
  final RxnString _errorMessage = RxnString();

  // ============================================================================
  // GETTERS (UI reads these)
  // ============================================================================

  Network? get currentNetwork => _currentNetwork.value;
  List<Network> get networks => _networks;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _loadNetworks();
    _loadCurrentNetwork();
  }

  /// Load available networks
  ///
  /// Loads default networks + custom networks from storage.
  ///
  /// SEPARATION OF CONCERNS:
  /// - Default networks hardcoded
  /// - Custom networks loaded from NetworkStorageService
  /// - Controller updates reactive state
  Future<void> _loadNetworks() async {
    try {
      // Default networks (always available)
      final defaultNetworks = [
        Network(
          id: 'ethereum-mainnet',
          name: 'Ethereum Mainnet',
          chainId: 1,
          rpcUrl: const String.fromEnvironment(
            'ETHEREUM_RPC_URL',
            defaultValue:
                'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
          ),
          symbol: 'ETH',
          explorerUrl: 'https://etherscan.io',
          isTestnet: false,
        ),
        Network(
          id: 'ethereum-sepolia',
          name: 'Sepolia Testnet',
          chainId: 11155111,
          rpcUrl: const String.fromEnvironment(
            'SEPOLIA_RPC_URL',
            defaultValue:
                'https://sepolia.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
          ),
          symbol: 'ETH',
          explorerUrl: 'https://sepolia.etherscan.io',
          isTestnet: true,
        ),
        Network(
          id: 'polygon-mainnet',
          name: 'Polygon Mainnet',
          chainId: 137,
          rpcUrl: 'https://polygon-rpc.com',
          symbol: 'MATIC',
          explorerUrl: 'https://polygonscan.com',
          isTestnet: false,
        ),
        Network(
          id: 'bsc-mainnet',
          name: 'BNB Smart Chain',
          chainId: 56,
          rpcUrl: 'https://bsc-dataseed.binance.org',
          symbol: 'BNB',
          explorerUrl: 'https://bscscan.com',
          isTestnet: false,
        ),
        Network(
          id: 'arbitrum-mainnet',
          name: 'Arbitrum One',
          chainId: 42161,
          rpcUrl: 'https://arb1.arbitrum.io/rpc',
          symbol: 'ETH',
          explorerUrl: 'https://arbiscan.io',
          isTestnet: false,
        ),
        Network(
          id: 'base-mainnet',
          name: 'Base',
          chainId: 8453,
          rpcUrl: 'https://mainnet.base.org',
          symbol: 'ETH',
          explorerUrl: 'https://basescan.org',
          isTestnet: false,
        ),
        Network(
          id: 'optimism-mainnet',
          name: 'Optimism',
          chainId: 10,
          rpcUrl: 'https://mainnet.optimism.io',
          symbol: 'ETH',
          explorerUrl: 'https://optimistic.etherscan.io',
          isTestnet: false,
        ),
      ];

      // Load custom networks from storage
      final customNetworks = await _storageService.getCustomNetworks();

      // Combine default + custom networks
      _networks.value = [...defaultNetworks, ...customNetworks];
    } catch (e) {
      _errorMessage.value = 'Failed to load networks';
    }
  }

  /// Load current network from storage
  ///
  /// Loads saved network ID from storage and finds matching network.
  /// Falls back to Sepolia Testnet for testing.
  Future<void> _loadCurrentNetwork() async {
    try {
      // Load saved network ID from storage
      final savedNetworkId = await _storageService.getCurrentNetwork();

      if (savedNetworkId != null) {
        // Find network by ID
        final network = _networks.firstWhereOrNull(
          (n) => n.id == savedNetworkId,
        );
        if (network != null) {
          _currentNetwork.value = network;
          return;
        }
      }

      // Fallback: Default to Sepolia Testnet for testing
      // Find Sepolia network
      final sepoliaNetwork = _networks.firstWhereOrNull(
        (n) => n.id == 'ethereum-sepolia',
      );
      if (sepoliaNetwork != null) {
        _currentNetwork.value = sepoliaNetwork;
        // Save as default
        await _storageService.saveCurrentNetwork(sepoliaNetwork.id);
      } else {
        // Ultimate fallback: First network
        _currentNetwork.value = _networks.isNotEmpty ? _networks.first : null;
      }
    } catch (e) {
      // Fallback on error: Try Sepolia first
      final sepoliaNetwork = _networks.firstWhereOrNull(
        (n) => n.id == 'ethereum-sepolia',
      );
      _currentNetwork.value =
          sepoliaNetwork ?? (_networks.isNotEmpty ? _networks.first : null);
    }
  }

  // ============================================================================
  // NETWORK OPERATIONS (Call use cases, NO blockchain logic)
  // ============================================================================

  /// Switch to different network
  ///
  /// Updates current network and saves to storage.
  ///
  /// IMPORTANT: Network switching does NOT affect wallet derivation.
  /// Wallet keys are derived from mnemonic only, independent of network.
  ///
  /// Parameters:
  /// - network: Network to switch to
  Future<bool> switchNetwork(Network network) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Update current network (reactive)
      _currentNetwork.value = network;

      // Save to storage for persistence
      await _storageService.saveCurrentNetwork(network.id);

      // CRITICAL: Refresh RPC Client to use new network
      // This ensures transactions are sent to the correct blockchain
      _refreshRpcClient();

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to switch network: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh RPC Client after network change
  ///
  /// CRITICAL: This ensures RpcClient uses the new network's RPC URL.
  /// Without this, transactions would be sent to the wrong blockchain!
  void _refreshRpcClient() {
    try {
      // Delete old RPC client instance
      Get.delete<RpcClient>(force: true);

      // Delete all use cases that hold a reference to the old RpcClient
      // They will be lazily recreated with the new RpcClient on next access
      // (all registered with fenix: true in service_locator.dart)
      try {
        Get.delete<GetBalanceUseCase>(force: true);
      } catch (_) {}
      try {
        Get.delete<GetNonceUseCase>(force: true);
      } catch (_) {}
      try {
        Get.delete<EstimateGasUseCase>(force: true);
      } catch (_) {}
      try {
        Get.delete<BroadcastTransactionUseCase>(force: true);
      } catch (_) {}

      print('RPC client and dependent use cases refreshed for network switch');
    } catch (e) {
      print('Warning: Failed to refresh RPC client: $e');
    }
  }

  /// Add custom network
  ///
  /// Validates and adds custom network to list and storage.
  ///
  /// Parameters:
  /// - network: Custom network to add
  Future<bool> addCustomNetwork(Network network) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Validate network
      if (network.name.isEmpty || network.rpcUrl.isEmpty) {
        _errorMessage.value = 'Invalid network configuration';
        return false;
      }

      // Check for duplicates
      if (_networks.any((n) => n.chainId == network.chainId)) {
        _errorMessage.value = 'Network with this chain ID already exists';
        return false;
      }

      // Mark as custom
      final customNetwork = network.copyWith(isCustom: true);

      // Add to list
      _networks.add(customNetwork);

      // Save custom networks to storage
      final customNetworks = _networks.where((n) => n.isCustom).toList();
      await _storageService.saveCustomNetworks(customNetworks);

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add network: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Remove custom network
  ///
  /// Only custom networks can be removed (not default networks).
  ///
  /// Parameters:
  /// - networkId: ID of network to remove
  Future<bool> removeCustomNetwork(String networkId) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      // Find network
      final network = _networks.firstWhereOrNull((n) => n.id == networkId);
      if (network == null) {
        _errorMessage.value = 'Network not found';
        return false;
      }

      // Don't allow removing default networks
      if (!network.isCustom) {
        _errorMessage.value = 'Cannot remove default network';
        return false;
      }

      // Remove from list
      _networks.removeWhere((n) => n.id == networkId);

      // Save updated custom networks to storage
      final customNetworks = _networks.where((n) => n.isCustom).toList();
      await _storageService.saveCustomNetworks(customNetworks);

      // Switch to default if current network was removed
      if (_currentNetwork.value?.id == networkId) {
        await switchNetwork(_networks.first);
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to remove network: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get network by chain ID
  Network? getNetworkByChainId(int chainId) {
    return _networks.firstWhereOrNull((n) => n.chainId == chainId);
  }

  /// Refresh networks
  Future<void> refreshNetworks() async {
    await _loadNetworks();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }
}

// ============================================================================
// MODELS (UI-friendly data structures)
// ============================================================================

/// Network model
class Network {
  final String id;
  final String name;
  final int chainId;
  final String rpcUrl;
  final String symbol;
  final String explorerUrl;
  final bool isTestnet;
  final bool isCustom;

  Network({
    required this.id,
    required this.name,
    required this.chainId,
    required this.rpcUrl,
    required this.symbol,
    required this.explorerUrl,
    required this.isTestnet,
    this.isCustom = false,
  });

  Network copyWith({
    String? id,
    String? name,
    int? chainId,
    String? rpcUrl,
    String? symbol,
    String? explorerUrl,
    bool? isTestnet,
    bool? isCustom,
  }) {
    return Network(
      id: id ?? this.id,
      name: name ?? this.name,
      chainId: chainId ?? this.chainId,
      rpcUrl: rpcUrl ?? this.rpcUrl,
      symbol: symbol ?? this.symbol,
      explorerUrl: explorerUrl ?? this.explorerUrl,
      isTestnet: isTestnet ?? this.isTestnet,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
