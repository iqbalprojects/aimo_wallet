# Clean Architecture - Non-Custodial EVM Wallet

## Overview

This project implements a production-grade, non-custodial cryptocurrency wallet using Flutter with clean architecture principles. The architecture ensures security, testability, and maintainability through strict separation of concerns.

## Core Principles

1. **Security First**: All cryptographic operations follow BIP39/BIP32/BIP44 standards
2. **Zero Trust**: Private keys never leave the device, only encrypted mnemonics are stored
3. **Dependency Inversion**: High-level modules don't depend on low-level modules
4. **Single Responsibility**: Each component has one well-defined purpose
5. **Testability**: Pure functions and dependency injection enable comprehensive testing

## Architecture Layers

```
lib/
├── core/                    # Pure business logic, no Flutter dependencies
│   ├── crypto/             # Cryptographic primitives (BIP39/BIP32/BIP44)
│   ├── vault/              # Secure storage and encryption
│   ├── security/           # Security utilities (PIN, secure random)
│   ├── network/            # Network configuration and RPC client
│   └── di/                 # Dependency injection
│
└── features/               # Feature modules (Clean Architecture)
    ├── wallet/
    │   ├── data/          # Repository implementations, data sources
    │   ├── domain/        # Business logic, entities, use cases
    │   └── presentation/  # State management (GetX controllers)
    │
    ├── transaction/
    │   ├── domain/        # Transaction entities and signing logic
    │   └── presentation/  # Transaction state management
    │
    └── network_switch/
        ├── domain/        # Network configuration entities
        └── presentation/  # Network switching logic
```

## Layer Responsibilities

### Core Layer (`lib/core/`)

**Purpose**: Pure cryptographic and utility functions with no external dependencies.

**Modules**:

- **crypto/**: BIP39 mnemonic generation/validation, BIP32 HD key derivation, BIP44 path derivation, wallet engine
- **vault/**: AES-256 encryption, secure storage abstraction, secure memory utilities
- **security/**: PIN validation, secure random generation, memory sanitization
- **network/**: RPC client, network interceptors, configuration
- **di/**: Service locator, dependency injection setup

**Rules**:

- No Flutter dependencies
- No state management
- Pure functions only
- Fully unit testable

### Domain Layer (`lib/features/*/domain/`)

**Purpose**: Business logic and use cases. Defines contracts for external dependencies.

**Structure**:

```
domain/
├── entities/           # Domain models (Wallet, Transaction, Network)
├── repositories/       # Abstract repository interfaces
├── usecases/          # Business logic operations
└── services/          # Domain services (e.g., TransactionSigner)
```

**Rules**:

- No implementation details
- No platform-specific code
- Defines interfaces only
- Contains business rules

### Data Layer (`lib/features/*/data/`)

**Purpose**: Implements repository interfaces and handles platform-specific storage.

**Structure**:

```
data/
├── datasources/       # Data source interfaces and implementations
│   ├── local/        # Local storage (flutter_secure_storage)
│   └── remote/       # Remote APIs (if needed)
├── models/           # DTOs for serialization
└── repositories/     # Repository implementations
```

**Rules**:

- Implements domain interfaces
- Handles data transformation
- Manages platform-specific storage
- No business logic

### Presentation Layer (`lib/features/*/presentation/`)

**Purpose**: Manages UI state using GetX controllers.

**Structure**:

```
presentation/
└── controllers/       # GetX controllers for state management
```

**Rules**:

- No business logic
- Delegates to use cases
- Manages UI state only
- No direct repository access

## Data Flow

```
User Action
    ↓
Controller (Presentation)
    ↓
Use Case (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
Data Source (Data)
    ↓
Platform Storage / Core Services
```

## Security Architecture

### Key Management Flow

1. **Wallet Creation**:
    - Generate 24-word mnemonic (256-bit entropy)
    - Derive private key using BIP39/BIP32/BIP44
    - Encrypt mnemonic with PIN-derived key (PBKDF2)
    - Store encrypted mnemonic in flutter_secure_storage
    - Clear sensitive data from memory

2. **Wallet Unlock**:
    - Retrieve encrypted mnemonic
    - Derive decryption key from PIN
    - Decrypt mnemonic temporarily
    - Derive private key for signing
    - Clear decrypted mnemonic immediately

3. **Transaction Signing**:
    - Unlock wallet temporarily
    - Sign transaction with private key
    - Clear private key from memory
    - Lock wallet automatically

### Security Guarantees

- ✅ Private key NEVER stored on disk
- ✅ Only encrypted mnemonic persisted
- ✅ AES-256-GCM encryption
- ✅ PBKDF2 key derivation (100,000 iterations)
- ✅ Secure memory clearing
- ✅ No logging of sensitive data
- ✅ Platform-level secure storage

## Dependency Rules

1. **Core** depends on: Nothing (pure Dart)
2. **Domain** depends on: Core only
3. **Data** depends on: Domain, Core, Platform packages
4. **Presentation** depends on: Domain, GetX

**Critical**: Dependencies point inward. Outer layers depend on inner layers, never the reverse.

## Testing Strategy

```
test/
├── core/              # Unit tests for crypto and vault
├── features/
│   └── wallet/
│       ├── domain/    # Use case tests
│       ├── data/      # Repository tests with mocks
│       └── presentation/  # Controller tests
└── integration/       # End-to-end wallet flows
```

**Coverage Requirements**:

- Core crypto: 100%
- Domain use cases: 100%
- Data repositories: 90%+
- Presentation controllers: 80%+

## Key Components

### Core Components

- **WalletEngine**: Orchestrates BIP39/BIP32/BIP44 operations
- **SecureVault**: Manages encrypted storage with AES-256
- **EncryptionService**: Handles encryption/decryption operations
- **BIP39Service**: Mnemonic generation and validation
- **BIP32Service**: Hierarchical deterministic key derivation
- **KeyDerivationService**: PBKDF2 key derivation from PIN

### Domain Components

- **CreateWalletUseCase**: Wallet creation business logic
- **UnlockWalletUseCase**: Wallet unlock and authentication
- **SignTransactionUseCase**: Transaction signing workflow
- **ExportMnemonicUseCase**: Secure mnemonic export

### Data Components

- **SecureStorageRepository**: flutter_secure_storage wrapper
- **WalletRepository**: Wallet persistence implementation

### Presentation Components

- **WalletController**: Wallet state management
- **WalletLockController**: Lock/unlock state management
- **TransactionController**: Transaction state management
- **NetworkController**: Network switching

## Initialization Flow

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await AppInitializer.initialize();

  runApp(MyApp());
}
```

**AppInitializer** registers:

1. Core services (crypto, vault, security)
2. Repositories (data layer)
3. Use cases (domain layer)
4. Controllers (presentation layer)

## Best Practices

### Security

- Never log sensitive data (mnemonic, private key, PIN)
- Clear sensitive data from memory immediately after use
- Use secure random for all cryptographic operations
- Validate all inputs before cryptographic operations
- Fail securely - never expose error details

### Code Organization

- One class per file
- Use barrel files for exports
- Keep functions small and focused
- Prefer composition over inheritance
- Use dependency injection

### Testing

- Test all business logic
- Mock external dependencies
- Test error cases
- Test security boundaries
- Integration tests for critical flows

## Production Checklist

- [ ] All tests passing
- [ ] Security audit completed
- [ ] Code review completed
- [ ] No sensitive data in logs
- [ ] Error messages don't leak information
- [ ] Memory clearing verified
- [ ] Encryption verified
- [ ] Key derivation tested
- [ ] Platform storage tested
- [ ] Integration tests passing

## References

- [BIP39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [BIP32 Specification](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
- [BIP44 Specification](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
