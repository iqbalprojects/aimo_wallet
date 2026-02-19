# Transaction Data Layer

## Overview

The transaction data layer handles transaction persistence, caching, and remote blockchain interactions. It implements repository interfaces defined in the domain layer.

## Structure

```
data/
├── datasources/
│   ├── local/
│   │   └── transaction_cache_datasource.dart
│   └── remote/
│       └── blockchain_datasource.dart
├── models/
│   ├── transaction_model.dart
│   └── transaction_receipt_model.dart
└── repositories/
    └── transaction_repository_impl.dart
```

## Components

### Data Sources

**TransactionCacheDataSource** (`datasources/local/transaction_cache_datasource.dart`)

**Responsibility**: Caches transaction history locally.

**Methods**:

- `saveTransaction(tx)`: Cache transaction
- `getTransactions(address)`: Get cached transactions
- `updateTransactionStatus(txHash, status)`: Update transaction status
- `clearCache()`: Clear all cached transactions

**BlockchainDataSource** (`datasources/remote/blockchain_datasource.dart`)

**Responsibility**: Interacts with blockchain via RPC.

**Methods**:

- `sendRawTransaction(signedTx)`: Broadcast transaction
- `getTransactionReceipt(txHash)`: Get transaction receipt
- `estimateGas(tx)`: Estimate gas for transaction
- `getGasPrice()`: Get current gas price
- `getNonce(address)`: Get transaction count

### Models

**TransactionModel** (`models/transaction_model.dart`)

**Responsibility**: Data transfer object for transactions.

**Structure**:

```dart
class TransactionModel {
  final String from;
  final String to;
  final BigInt value;
  final BigInt gasLimit;
  final BigInt gasPrice;
  final int nonce;
  final String? data;
  final int chainId;

  Map<String, dynamic> toJson();
  factory TransactionModel.fromJson(Map<String, dynamic> json);
  Transaction toDomain();
}
```

**TransactionReceiptModel** (`models/transaction_receipt_model.dart`)

**Responsibility**: Data transfer object for transaction receipts.

**Structure**:

```dart
class TransactionReceiptModel {
  final String transactionHash;
  final String blockHash;
  final int blockNumber;
  final String status;
  final BigInt gasUsed;

  Map<String, dynamic> toJson();
  factory TransactionReceiptModel.fromJson(Map<String, dynamic> json);
}
```

### Repository

**TransactionRepositoryImpl** (`repositories/transaction_repository_impl.dart`)

**Responsibility**: Implements TransactionRepository interface.

**Methods**:

- `sendTransaction(signedTx)`: Broadcast transaction to blockchain
- `getTransactionHistory(address)`: Get transaction history
- `getTransactionStatus(txHash)`: Check transaction status
- `estimateGas(tx)`: Estimate gas for transaction
- `getGasPrice()`: Get current gas price

## Data Flow

```
TransactionController
    ↓
SignTransactionUseCase
    ↓
TransactionRepository Interface (Domain)
    ↓
TransactionRepositoryImpl (Data)
    ↓
BlockchainDataSource → RPC Client → Blockchain
    ↓
TransactionCacheDataSource → Local Storage
```

## Security Rules

1. **Never log transaction details**
    - Don't log amounts or addresses
    - Log only transaction hashes

2. **Validate before broadcasting**
    - Verify signature before sending
    - Validate gas parameters

3. **Handle errors securely**
    - Don't expose RPC errors to users
    - Provide user-friendly error messages

4. **Cache responsibly**
    - Only cache non-sensitive data
    - Clear cache on wallet deletion

## Testing

Transaction data layer tests:

```
test/features/transaction/data/
├── datasources/
│   ├── local/
│   │   └── transaction_cache_datasource_test.dart
│   └── remote/
│       └── blockchain_datasource_test.dart
├── models/
│   ├── transaction_model_test.dart
│   └── transaction_receipt_model_test.dart
└── repositories/
    └── transaction_repository_impl_test.dart
```

**Test Coverage**:

- Data source operations with mocks
- Model serialization/deserialization
- Repository implementation
- Error handling
- Network failures
- Cache management

## Error Handling

```dart
try {
  final txHash = await repository.sendTransaction(signedTx);
} on NetworkException catch (e) {
  // Handle network errors
} on InsufficientFundsException catch (e) {
  // Handle insufficient balance
} on GasEstimationException catch (e) {
  // Handle gas estimation errors
}
```

## Production Checklist

- [ ] Transaction signing verified
- [ ] Gas estimation tested
- [ ] Network error handling implemented
- [ ] Transaction caching working
- [ ] Status polling implemented
- [ ] All tests passing
- [ ] No sensitive data in logs
