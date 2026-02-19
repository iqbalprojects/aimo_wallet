# Network Switch Data Layer

## Overview

The network switch data layer handles network configuration persistence and management. It stores user's selected network and provides network switching functionality.

## Structure

```
data/
├── datasources/
│   └── local/
│       └── network_preferences_datasource.dart
├── models/
│   └── network_config_model.dart
└── repositories/
    └── network_repository_impl.dart
```

## Components

### Data Source

**NetworkPreferencesDataSource** (`datasources/local/network_preferences_datasource.dart`)

**Responsibility**: Manages network preferences in local storage.

**Methods**:

- `saveSelectedNetwork(networkId)`: Save user's network selection
- `getSelectedNetwork()`: Get current network selection
- `saveCustomNetwork(config)`: Save custom network configuration
- `getCustomNetworks()`: Get all custom networks
- `deleteCustomNetwork(networkId)`: Remove custom network

**Storage**:

- Uses SharedPreferences for non-sensitive network data
- Stores network ID, RPC URL, chain ID, symbol

### Model

**NetworkConfigModel** (`models/network_config_model.dart`)

**Responsibility**: Data transfer object for network configuration.

**Structure**:

```dart
class NetworkConfigModel {
  final String id;
  final String name;
  final String rpcUrl;
  final int chainId;
  final String symbol;
  final String explorerUrl;
  final bool isCustom;

  Map<String, dynamic> toJson();
  factory NetworkConfigModel.fromJson(Map<String, dynamic> json);
  NetworkConfig toDomain();
}
```

**Predefined Networks**:

```dart
class PredefinedNetworks {
  static final ethereum = NetworkConfigModel(
    id: 'ethereum',
    name: 'Ethereum Mainnet',
    rpcUrl: 'https://mainnet.infura.io/v3/YOUR_KEY',
    chainId: 1,
    symbol: 'ETH',
    explorerUrl: 'https://etherscan.io',
    isCustom: false,
  );

  static final polygon = NetworkConfigModel(
    id: 'polygon',
    name: 'Polygon',
    rpcUrl: 'https://polygon-rpc.com',
    chainId: 137,
    symbol: 'MATIC',
    explorerUrl: 'https://polygonscan.com',
    isCustom: false,
  );

  // Add more networks...
}
```

### Repository

**NetworkRepositoryImpl** (`repositories/network_repository_impl.dart`)

**Responsibility**: Implements NetworkRepository interface.

**Methods**:

- `getAvailableNetworks()`: Get all available networks
- `getCurrentNetwork()`: Get currently selected network
- `switchNetwork(networkId)`: Switch to different network
- `addCustomNetwork(config)`: Add custom network
- `removeCustomNetwork(networkId)`: Remove custom network
- `validateNetwork(config)`: Validate network configuration

## Data Flow

```
NetworkController
    ↓
SwitchNetworkUseCase
    ↓
NetworkRepository Interface (Domain)
    ↓
NetworkRepositoryImpl (Data)
    ↓
NetworkPreferencesDataSource
    ↓
SharedPreferences
```

## Network Validation

Before adding custom networks, validate:

1. **RPC URL**: Must be valid HTTPS URL
2. **Chain ID**: Must be positive integer
3. **Connectivity**: Test RPC connection
4. **Response**: Verify JSON-RPC response format

```dart
Future<bool> validateNetwork(NetworkConfig config) async {
  // Validate URL format
  if (!config.rpcUrl.startsWith('https://')) {
    return false;
  }

  // Test connectivity
  try {
    final client = RpcClient(config);
    final chainId = await client.getChainId();
    return chainId == config.chainId;
  } catch (e) {
    return false;
  }
}
```

## Security Rules

1. **Validate RPC URLs**
    - Only allow HTTPS URLs
    - Validate URL format before saving

2. **Test connectivity**
    - Verify network is reachable before switching
    - Handle connection failures gracefully

3. **Sanitize inputs**
    - Validate all network configuration inputs
    - Prevent injection attacks

4. **Handle errors**
    - Don't expose internal errors
    - Provide user-friendly messages

## Testing

Network switch data layer tests:

```
test/features/network_switch/data/
├── datasources/
│   └── local/
│       └── network_preferences_datasource_test.dart
├── models/
│   └── network_config_model_test.dart
└── repositories/
    └── network_repository_impl_test.dart
```

**Test Coverage**:

- Network configuration validation
- Network switching logic
- Custom network management
- Model serialization
- Error handling
- Connectivity testing

## Storage Keys

```dart
class NetworkStorageKeys {
  static const selectedNetwork = 'selected_network';
  static const customNetworks = 'custom_networks';
}
```

## Production Checklist

- [ ] Network validation implemented
- [ ] HTTPS-only enforcement
- [ ] Connectivity testing working
- [ ] Custom network management tested
- [ ] Network switching tested
- [ ] Error handling implemented
- [ ] All tests passing
