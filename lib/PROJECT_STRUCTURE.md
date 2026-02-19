# Project Structure

This document describes the clean architecture structure of the Aimo Wallet project.

## Architecture Layers

The project follows clean architecture principles with four distinct layers:

### 1. Core Layer (`lib/core/`)

Contains pure cryptographic functions and utilities with no dependencies on Flutter or external packages.

**Modules:**

- `crypto/` - BIP39, BIP32, BIP44 implementations, key derivation, wallet engine
- `vault/` - Encryption service, secure vault, secure memory utilities
- `security/` - PIN validation, secure random number generation
- `network/` - Network configuration, RPC client, interceptors
- `di/` - Dependency injection and service locator

**Exports:** `lib/core/core_exports.dart`

### 2. Domain Layer (`lib/features/*/domain/`)

Contains business logic and use cases. Defines interfaces for external dependencies.

**Structure per feature:**

- `entities/` - Domain entities (Wallet, WalletError, WalletLockState)
- `repositories/` - Abstract repository interfaces
- `usecases/` - Business logic use cases

**Exports:** `lib/features/wallet/domain/domain_exports.dart`

### 3. Data Layer (`lib/features/*/data/`)

Implements repository interfaces and handles platform-specific storage.

**Structure per feature:**

- `datasources/` - Data source interfaces and implementations
- `models/` - Data transfer objects for serialization
- `repositories/` - Repository implementations

**Exports:** `lib/features/wallet/data/data_exports.dart`

### 4. Presentation Layer (`lib/features/*/presentation/`)

Manages UI state using GetX controllers.

**Structure per feature:**

- `controllers/` - GetX controllers for state management

**Exports:** `lib/features/wallet/presentation/presentation_exports.dart`

## Features

### Wallet Feature (`lib/features/wallet/`)

Complete wallet key management system with:

- Wallet creation and import
- PIN-based encryption
- Secure storage
- Key derivation (BIP39/BIP32/BIP44)
- Wallet unlock and authentication
- Mnemonic export and backup verification

**Main Export:** `lib/features/wallet/wallet_exports.dart`

### Transaction Feature (`lib/features/transaction/`)

Transaction signing and management.

### Network Switch Feature (`lib/features/network_switch/`)

Network configuration and switching.

## Test Structure

The test directory (`test/`) mirrors the lib structure:

```
test/
├── core/
│   ├── crypto/
│   ├── vault/
│   ├── security/
│   ├── network/
│   └── di/
├── features/
│   ├── wallet/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       └── controllers/
│   ├── transaction/
│   └── network_switch/
└── integration/
```

## Dependencies

### Production Dependencies

- `flutter` - Flutter SDK
- `pointycastle: ^3.9.1` - Cryptographic primitives
- `flutter_secure_storage: ^9.2.2` - Secure platform storage
- `get: ^4.6.6` - State management
- `hex: ^0.2.0` - Hex encoding/decoding
- `web3dart: ^2.7.3` - Ethereum utilities
- `bip39: ^1.0.6` - BIP39 mnemonic utilities
- `ed25519_hd_key: ^2.2.0` - HD key derivation
- `crypto: ^3.0.3` - Cryptographic utilities
- `local_auth: ^2.3.0` - Biometric authentication

### Development Dependencies

- `flutter_test` - Flutter testing framework
- `flutter_lints: ^5.0.0` - Linting rules
- `mockito: ^5.4.4` - Mocking for tests
- `build_runner: ^2.4.6` - Code generation

## Barrel Files

Barrel files (exports) are provided at each layer for convenient imports:

- `lib/core/core_exports.dart` - All core modules
- `lib/core/crypto/crypto_exports.dart` - Crypto module
- `lib/core/vault/vault_exports.dart` - Vault module
- `lib/features/wallet/wallet_exports.dart` - Complete wallet feature
- `lib/features/wallet/domain/domain_exports.dart` - Wallet domain layer
- `lib/features/wallet/data/data_exports.dart` - Wallet data layer
- `lib/features/wallet/presentation/presentation_exports.dart` - Wallet presentation layer

## Usage

Import entire layers using barrel files:

```dart
// Import all core utilities
import 'package:aimo_wallet/core/core_exports.dart';

// Import wallet feature
import 'package:aimo_wallet/features/wallet/wallet_exports.dart';

// Import specific layer
import 'package:aimo_wallet/features/wallet/domain/domain_exports.dart';
```

## Design Principles

1. **Security First** - All cryptographic operations follow industry standards
2. **Zero Trust** - Never store or transmit sensitive data in plaintext
3. **Clean Architecture** - Clear separation of concerns with dependency inversion
4. **Testability** - Pure functions and dependency injection enable comprehensive testing
5. **Single Responsibility** - Each component has one well-defined purpose
6. **Fail Secure** - Errors never expose sensitive information
