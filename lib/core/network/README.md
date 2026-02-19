# Network Module

## Overview

The network module provides RPC client functionality for interacting with EVM-compatible blockchains. It handles network configuration, request/response management, and error handling.

## Components

### Network Config (`network_config.dart`)

**Responsibility**: Defines EVM network configurations.

**Structure**:

```dart
class NetworkConfig {
  final String name;
  final String rpcUrl;
  final int chainId;
  final String symbol;
  final String explorerUrl;
}
```

**Supported Networks**:

- Ethereum Mainnet (chainId: 1)
- Polygon (chainId: 137)
- BSC (chainId: 56)
- Arbitrum (chainId: 42161)
- Optimism (chainId: 10)

### RPC Client (`rpc_client.dart`)

**Responsibility**: Handles JSON-RPC communication with blockchain nodes.

**Methods**:

- `getBalance(address)`: Get account balance
- `getTransactionCount(address)`: Get nonce for transactions
- `sendRawTransaction(signedTx)`: Broadcast signed transaction
- `estimateGas(transaction)`: Estimate gas for transaction
- `getGasPrice()`: Get current gas price
- `call(transaction)`: Execute read-only contract call

**Usage**:

```dart
final client = RpcClient(networkConfig);
final balance = await client.getBalance(address);
final nonce = await client.getTransactionCount(address);
```

### Network Interceptor (`network_interceptor.dart`)

**Responsibility**: Intercepts and logs network requests/responses.

**Features**:

- Request/response logging (non-sensitive data only)
- Error handling and retry logic
- Rate limiting
- Timeout management

**Rules**:

- Never log sensitive data (private keys, mnemonics)
- Log only request IDs and status codes
- Implement exponential backoff for retries

## Network Security

### Best Practices

1. **Use HTTPS only**: All RPC endpoints must use HTTPS
2. **Validate responses**: Always validate JSON-RPC responses
3. **Handle errors gracefully**: Never expose internal errors to users
4. **Rate limiting**: Implement rate limiting to prevent abuse
5. **Timeout management**: Set reasonable timeouts for all requests

### Error Handling

```dart
try {
  final balance = await client.getBalance(address);
} on NetworkException catch (e) {
  // Handle network errors
} on RpcException catch (e) {
  // Handle RPC errors
}
```

## Testing

Network components should be tested with mocks:

```
test/core/network/
├── network_config_test.dart
├── rpc_client_test.dart
└── network_interceptor_test.dart
```

**Test Coverage**:

- Network configuration validation
- RPC request/response handling
- Error handling and retries
- Timeout management

## Configuration

Network configurations should be stored in a separate config file:

```dart
class Networks {
  static final ethereum = NetworkConfig(
    name: 'Ethereum',
    rpcUrl: 'https://mainnet.infura.io/v3/YOUR_KEY',
    chainId: 1,
    symbol: 'ETH',
    explorerUrl: 'https://etherscan.io',
  );

  // Add more networks...
}
```

## Production Checklist

- [ ] All RPC endpoints use HTTPS
- [ ] Error messages don't expose sensitive data
- [ ] Rate limiting implemented
- [ ] Timeout management configured
- [ ] Retry logic tested
- [ ] Network switching tested
- [ ] All tests passing
