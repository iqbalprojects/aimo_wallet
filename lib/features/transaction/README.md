# Transaction Signing Module

Production-grade EVM transaction signing with security-first design.

## Overview

This module provides secure transaction signing for Ethereum and EVM-compatible chains. It implements EIP-155 (replay protection) and follows best practices for private key handling.

## Architecture

```
lib/features/transaction/
├── domain/
│   ├── entities/
│   │   └── transaction.dart          # Transaction data models
│   └── services/
│       └── transaction_signer.dart    # Transaction signing service
```

## Features

- ✅ EIP-155 replay protection (chain ID in signature)
- ✅ Offline transaction signing (no network required)
- ✅ Private key automatic cleanup
- ✅ Comprehensive validation
- ✅ Support for contract interactions (data payload)
- ✅ Transaction cost calculation
- ✅ Integration with WalletLockController

## Security Principles

### 1. Private Key Handling

- Private keys derived at runtime only
- Private keys cleared immediately after signing
- No private key storage (plaintext or encrypted)
- Automatic cleanup even on errors

### 2. Transaction Validation

- Recipient address format validation
- Parameter range validation
- Chain ID validation
- Gas price and limit validation

### 3. EIP-155 Compliance

- Chain ID included in signature
- Prevents replay attacks across chains
- Standard-compliant v, r, s values

## Usage

### Basic Transaction Signing

```dart
import 'package:aimo_wallet/features/transaction/domain/entities/transaction.dart';
import 'package:aimo_wallet/features/transaction/domain/services/transaction_signer.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_lock_controller.dart';

// Initialize services
final lockController = WalletLockController();
final signer = TransactionSigner();

// Unlock wallet
await lockController.unlock(pin);

// Create transaction
final transaction = EvmTransaction(
  to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  value: BigInt.from(1000000000000000000), // 1 ETH
  gasPrice: BigInt.from(20000000000), // 20 Gwei
  gasLimit: BigInt.from(21000),
  nonce: 0,
  chainId: 1, // Ethereum mainnet
);

// Sign transaction
final signedTx = await lockController.executeWithPrivateKey(
  (privateKey) async {
    return await signer.signTransactionSecure(
      transaction: transaction,
      privateKey: privateKey,
    );
  },
  pin: pin,
);

print('Raw TX: ${signedTx.rawTransaction}');
print('TX Hash: ${signedTx.transactionHash}');

// Lock wallet
lockController.lock();
```

### Contract Interaction

```dart
// Create transaction with data payload
final transaction = EvmTransaction(
  to: '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI contract
  value: BigInt.zero,
  gasPrice: BigInt.from(20000000000),
  gasLimit: BigInt.from(100000),
  nonce: 0,
  chainId: 1,
  data: '0xa9059cbb' // transfer(address,uint256)
      '000000000000000000000000742d35Cc6634C0532925a3b844Bc9e7595f0bEb'
      '0000000000000000000000000000000000000000000000000de0b6b3a7640000',
);

// Sign and broadcast
final signedTx = await lockController.executeWithPrivateKey(
  (privateKey) async {
    return await signer.signTransactionSecure(
      transaction: transaction,
      privateKey: privateKey,
    );
  },
  pin: pin,
);
```

### Transaction Cost Calculation

```dart
final signer = TransactionSigner();

// Calculate fee
final fee = signer.calculateTransactionFee(transaction);
print('Fee: $fee Wei');

// Calculate total cost (value + fee)
final totalCost = signer.calculateTotalCost(transaction);
print('Total: $totalCost Wei');

// Estimate transaction size
final size = signer.estimateTransactionSize(transaction);
print('Size: $size bytes');
```

## Transaction Entity

### EvmTransaction

Represents an Ethereum transaction with all required fields.

```dart
class EvmTransaction {
  final String to;           // Recipient address (0x-prefixed)
  final BigInt value;        // Amount in Wei
  final BigInt gasPrice;     // Gas price in Wei
  final BigInt gasLimit;     // Gas limit
  final int nonce;           // Transaction nonce
  final int chainId;         // Chain ID (EIP-155)
  final String? data;        // Optional data payload (0x-prefixed)
}
```

### SignedTransaction

Contains the signed transaction ready for broadcast.

```dart
class SignedTransaction {
  final String rawTransaction;    // Raw signed TX hex (0x-prefixed)
  final String transactionHash;   // Transaction hash (0x-prefixed)
  final EvmTransaction transaction; // Original transaction
}
```

## Transaction Signer Service

### Methods

#### signTransaction()

Signs a transaction with a private key.

```dart
Future<SignedTransaction> signTransaction({
  required EvmTransaction transaction,
  required Uint8List privateKey,
})
```

**Security**: Private key must be cleared manually after use.

#### signTransactionSecure()

Signs a transaction with automatic private key cleanup.

```dart
Future<SignedTransaction> signTransactionSecure({
  required EvmTransaction transaction,
  required Uint8List privateKey,
})
```

**Security**: Private key automatically cleared in finally block.

#### calculateTransactionFee()

Calculates transaction fee (gasPrice \* gasLimit).

```dart
BigInt calculateTransactionFee(EvmTransaction transaction)
```

#### calculateTotalCost()

Calculates total cost (value + fee).

```dart
BigInt calculateTotalCost(EvmTransaction transaction)
```

#### estimateTransactionSize()

Estimates transaction size in bytes.

```dart
int estimateTransactionSize(EvmTransaction transaction)
```

## Validation Rules

### Address Validation

- Must start with `0x`
- Must be 42 characters (0x + 40 hex)
- Must contain only hex characters
- Must be valid Ethereum address

### Transaction Validation

- Recipient address required
- Value >= 0
- Gas price > 0
- Gas limit > 0
- Nonce >= 0
- Chain ID > 0

## Chain IDs (EIP-155)

Common chain IDs:

- 1: Ethereum Mainnet
- 5: Goerli Testnet
- 11155111: Sepolia Testnet
- 137: Polygon Mainnet
- 80001: Polygon Mumbai Testnet
- 56: BSC Mainnet
- 97: BSC Testnet

## Error Handling

### TransactionSigningException

Thrown when transaction signing fails.

```dart
try {
  final signedTx = await signer.signTransaction(
    transaction: transaction,
    privateKey: privateKey,
  );
} on TransactionSigningException catch (e) {
  print('Signing failed: ${e.message}');
  print('Details: ${e.details}');
}
```

Common errors:

- Invalid recipient address
- Negative value
- Zero gas price/limit
- Invalid chain ID
- Malformed transaction

## Integration with WalletLockController

The transaction signer integrates seamlessly with the wallet lock controller:

```dart
// Unlock wallet
await lockController.unlock(pin);

// Sign transaction (private key derived and cleared automatically)
final signedTx = await lockController.executeWithPrivateKey(
  (privateKey) async {
    return await signer.signTransactionSecure(
      transaction: transaction,
      privateKey: privateKey,
    );
  },
  pin: pin,
);

// Lock wallet
lockController.lock();
```

**Security Flow**:

1. Wallet unlocked with PIN
2. Mnemonic retrieved from vault
3. Private key derived from mnemonic
4. Transaction signed with private key
5. Private key cleared from memory
6. Mnemonic cleared from memory
7. Wallet locked

## Testing

Comprehensive unit tests cover:

- Valid transaction signing
- Transaction with data payload
- Address validation
- Parameter validation
- Chain ID validation (EIP-155)
- Private key cleanup
- Error handling
- Cost calculation

Run tests:

```bash
flutter test test/features/transaction/domain/services/transaction_signer_test.dart
```

## Examples

See `example/transaction_signing_example.dart` for complete examples:

- Basic transaction signing
- Contract interaction
- Batch signing
- Error handling

## Security Audit Checklist

- [x] Private keys never stored
- [x] Private keys cleared after use
- [x] EIP-155 replay protection
- [x] Address validation
- [x] Parameter validation
- [x] Automatic cleanup on errors
- [x] No logging of sensitive data
- [x] Integration with secure vault
- [x] Comprehensive test coverage

## Future Enhancements

Potential improvements:

- EIP-1559 support (maxFeePerGas, maxPriorityFeePerGas)
- EIP-2930 support (access lists)
- Transaction builder utilities
- Gas estimation helpers
- Multi-signature support
- Hardware wallet integration

## References

- [EIP-155: Simple replay attack protection](https://eips.ethereum.org/EIPS/eip-155)
- [EIP-1559: Fee market change](https://eips.ethereum.org/EIPS/eip-1559)
- [Ethereum Transaction Structure](https://ethereum.org/en/developers/docs/transactions/)
- [web3dart Documentation](https://pub.dev/packages/web3dart)
