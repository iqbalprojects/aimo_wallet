# Wallet Data Layer

## Overview

The data layer implements repository interfaces defined in the domain layer. It handles platform-specific storage operations and data transformation.

## Structure

```
data/
├── datasources/
│   ├── local/
│   │   └── secure_storage_datasource.dart
│   └── remote/
│       └── (future: cloud backup)
├── models/
│   ├── wallet_model.dart
│   └── encrypted_mnemonic_model.dart
└── repositories/
    ├── secure_storage_repository_impl.dart
    └── wallet_repository_impl.dart
```

## Components

### Data Sources

**SecureStorageDataSource** (`datasources/local/secure_storage_datasource.dart`)

**Responsibility**: Abstracts flutter_secure_storage operations.

**Methods**:

- `write(key, value)`: Store encrypted data
- `read(key)`: Retrieve encrypted data
- `delete(key)`: Remove data
- `containsKey(key)`: Check if key exists
- `deleteAll()`: Clear all data

**Rules**:

- Only store encrypted data
- Never store plaintext sensitive data
- Use consistent key naming convention

### Models

**WalletModel** (`models/wallet_model.dart`)

**Responsibility**: Data transfer object for wallet serialization.

**Structure**:

```dart
class WalletModel {
  final String address;
  final String encryptedMnemonic;
  final DateTime createdAt;

  Map<String, dynamic> toJson();
  factory WalletModel.fromJson(Map<String, dynamic> json);
}
```

**EncryptedMnemonicModel** (`models/encrypted_mnemonic_model.dart`)

**Responsibility**: Encapsulates encrypted mnemonic with metadata.

**Structure**:

```dart
class EncryptedMnemonicModel {
  final String ciphertext;
  final String iv;
  final String salt;
  final int iterations;

  Map<String, dynamic> toJson();
  factory EncryptedMnemonicModel.fromJson(Map<String, dynamic> json);
}
```

### Repositories

**SecureStorageRepositoryImpl** (`repositories/secure_storage_repository_impl.dart`)

**Responsibility**: Implements SecureStorageRepository interface.

**Methods**:

- `saveEncryptedMnemonic(encrypted)`: Store encrypted mnemonic
- `getEncryptedMnemonic()`: Retrieve encrypted mnemonic
- `deleteWallet()`: Remove all wallet data
- `hasWallet()`: Check if wallet exists

**WalletRepositoryImpl** (`repositories/wallet_repository_impl.dart`)

**Responsibility**: Implements WalletRepository interface.

**Methods**:

- `createWallet(credentials)`: Create and store new wallet
- `importWallet(mnemonic, pin)`: Import existing wallet
- `getWallet()`: Retrieve wallet data
- `deleteWallet()`: Remove wallet
- `updateWallet(wallet)`: Update wallet data

## Data Flow

```
Controller
    ↓
Use Case
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
Data Source
    ↓
flutter_secure_storage
```

## Security Rules

1. **Never store plaintext sensitive data**
    - Only encrypted mnemonic is stored
    - Private key is never persisted

2. **Validate before storage**
    - Verify encryption before storing
    - Validate data integrity on retrieval

3. **Handle errors securely**
    - Don't expose storage errors to users
    - Log errors without sensitive data

4. **Clear data on errors**
    - If storage fails, clear partial data
    - Ensure atomic operations

## Testing

Data layer tests use mocks for platform dependencies:

```
test/features/wallet/data/
├── datasources/
│   └── local/
│       └── secure_storage_datasource_test.dart
├── models/
│   ├── wallet_model_test.dart
│   └── encrypted_mnemonic_model_test.dart
└── repositories/
    ├── secure_storage_repository_impl_test.dart
    └── wallet_repository_impl_test.dart
```

**Test Coverage**:

- Data source operations
- Model serialization/deserialization
- Repository implementations
- Error handling
- Edge cases

## Storage Keys

Use consistent key naming:

```dart
class StorageKeys {
  static const encryptedMnemonic = 'encrypted_mnemonic';
  static const walletAddress = 'wallet_address';
  static const createdAt = 'created_at';
  static const lastUnlocked = 'last_unlocked';
}
```

## Production Checklist

- [ ] All sensitive data encrypted before storage
- [ ] Error handling doesn't expose sensitive data
- [ ] Storage operations are atomic
- [ ] Data integrity verified on retrieval
- [ ] All tests passing
- [ ] Mock tests for platform dependencies
