# Clean Architecture - Non-Custodial EVM Wallet

## Overview

This project follows Clean Architecture principles with clear separation of concerns across four layers: Core, Domain, Data, and Presentation.

## Architecture Layers

### 1. Core Layer (`lib/core/`)

Pure business logic and utilities with no dependencies on Flutter or external packages.

#### Crypto (`lib/core/crypto/`)

- `bip39_service.dart` - BIP39 mnemonic generation and validation
- `bip32_service.dart` - BIP32 hierarchical deterministic key derivation
- `key_derivation_service.dart` - EVM key derivation (BIP44 path m/44'/60'/0'/0/0)
- `encryption_service.dart` - AES-256-GCM encryption/decryption
- `transaction_signer.dart` - Transaction signing with secp256k1
- `bip39_wordlist.dart` - BIP39 English word list (2048 words)

#### Vault (`lib/core/vault/`)

- `secure_memory.dart` - Memory clearing utilities for sensitive data
- `keychain_service.dart` - Platform keychain abstraction

#### Security (`lib/core/security/`)

- `pin_validator.dart` - PIN validation and constant-time comparison
- `secure_random.dart` - Cryptographically secure random generation

#### Network (`lib/core/network/`)

- `rpc_client.dart` - JSON-RPC client for EVM networks
- `network_config.dart` - Network configurations (Ethereum, Polygon, BSC)
- `network_interceptor.dart` - Request/response interceptor

#### Dependency Injection (`lib/core/di/`)

- `service_locator.dart` - GetX dependency injection setup

### 2. Domain Layer (`lib/features/*/domain/`)

Business logic and use cases. No dependencies on external packages or Flutter.

#### Wallet Feature (`lib/features/wallet/domain/`)

**Entities:**

- `wallet.dart` - Wallet entity (address, private key, status)
- `wallet_error.dart` - Error types and exceptions

**Repositories (Interfaces):**

- `wallet_repository.dart` - Wallet operations contract

**Use Cases:**

- `create_wallet_usecase.dart` - Create new wallet
- `import_wallet_usecase.dart` - Import existing wallet
- `unlock_wallet_usecase.dart` - Unlock wallet with PIN
- `export_mnemonic_usecase.dart` - Export mnemonic for backup
- `verify_backup_usecase.dart` - Verify mnemonic backup
- `delete_wallet_usecase.dart` - Delete wallet from device
- `get_wallet_address_usecase.dart` - Get cached address

#### Transaction Feature (`lib/features/transaction/domain/`)

**Entities:**

- `transaction.dart` - Transaction entity

**Repositories:**

- `transaction_repository.dart` - Transaction operations contract

**Use Cases:**

- `send_transaction_usecase.dart` - Send transaction

#### Network Switch Feature (`lib/features/network_switch/domain/`)

**Entities:**

- `network.dart` - Network configuration entity

**Repositories:**

- `network_repository.dart` - Network management contract

### 3. Data Layer (`lib/features/*/data/`)

Implementation of repositories and data sources.

#### Wallet Feature (`lib/features/wallet/data/`)

**Models:**

- `encrypted_wallet_data.dart` - Encrypted wallet data model with JSON serialization

**Data Sources:**

- `secure_storage_datasource.dart` - Secure storage interface
- `secure_storage_datasource_impl.dart` - flutter_secure_storage implementation

**Repositories:**

- `wallet_repository_impl.dart` - Wallet repository implementation

### 4. Presentation Layer (`lib/features/*/presentation/`)

UI state management using GetX controllers. No UI code included.

#### Wallet Feature (`lib/features/wallet/presentation/controllers/`)

- `wallet_controller.dart` - Global wallet state management
- `wallet_creation_controller.dart` - Wallet creation flow
- `wallet_import_controller.dart` - Wallet import flow
- `wallet_unlock_controller.dart` - Wallet unlock/authentication
- `wallet_settings_controller.dart` - Settings and backup management

#### Transaction Feature (`lib/features/transaction/presentation/controllers/`)

- `transaction_controller.dart` - Transaction state management

#### Network Switch Feature (`lib/features/network_switch/presentation/controllers/`)

- `network_controller.dart` - Network switching state management

## Security Principles

### 1. Private Key Management

- Private keys NEVER stored (plaintext or encrypted)
- Only held in memory during unlocked session
- Cleared from memory when session ends

### 2. Mnemonic Storage

- Only encrypted mnemonic stored
- AES-256-GCM authenticated encryption
- PIN-derived keys using PBKDF2 (100k+ iterations)

### 3. Memory Security

- Sensitive data cleared after use
- Secure memory utilities for overwriting
- Minimal exposure window

### 4. Constant-Time Operations

- PIN comparison uses constant-time algorithm
- Prevents timing attacks

### 5. Error Handling

- Errors never contain sensitive data
- No logging of mnemonics, private keys, or PINs

## Data Flow

### Wallet Creation Flow

```
User → WalletCreationController → CreateWalletUseCase → Bip39Service (generate)
                                                      → KeyDerivationService (derive address)
                                                      → EncryptionService (encrypt)
                                                      → WalletRepository → SecureStorage
```

### Wallet Unlock Flow

```
User (PIN) → WalletUnlockController → UnlockWalletUseCase → WalletRepository
                                                           → SecureStorage (retrieve encrypted)
                                                           → EncryptionService (decrypt)
                                                           → KeyDerivationService (derive keys)
                                                           → Wallet (with private key in memory)
```

### Transaction Flow

```
User → TransactionController → SendTransactionUseCase → TransactionRepository
                                                      → TransactionSigner (sign with private key)
                                                      → RpcClient (broadcast)
```

## Testing Structure

Tests mirror the lib structure:

- `test/core/` - Core layer tests
- `test/features/*/domain/` - Use case tests
- `test/features/*/data/` - Repository tests
- `test/features/*/presentation/` - Controller tests

## Dependencies

Required packages (to be added to pubspec.yaml):

- `flutter_secure_storage` - Secure storage (Keychain/KeyStore)
- `pointycastle` - Cryptographic primitives
- `hex` - Hex encoding/decoding
- `get` - State management and dependency injection

## Next Steps

1. Add dependencies to `pubspec.yaml`
2. Implement core cryptographic services (BIP39, BIP32, encryption)
3. Implement domain use cases
4. Implement data repositories
5. Implement presentation controllers
6. Write comprehensive tests
7. Security audit

## Notes

- No UI code included - focus on business logic and state management
- All cryptographic operations follow industry standards (BIP39, BIP32, BIP44)
- Single wallet per device constraint enforced
- Production-ready, auditable code
