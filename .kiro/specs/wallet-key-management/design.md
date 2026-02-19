# Design Document: Wallet Key Management System

## Overview

This design document specifies the architecture and implementation details for a secure, production-grade wallet key management system for Flutter. The system implements a non-custodial cryptocurrency wallet with EVM compatibility, following clean architecture principles and industry-standard cryptographic protocols (BIP39, BIP32, BIP44).

The design prioritizes security above all else: private keys never leave the device, mnemonics are stored only in encrypted form, and all sensitive data is cleared from memory after use. The architecture separates concerns into distinct layers (core, domain, data, presentation) to ensure testability, maintainability, and auditability.

### Key Design Principles

1. **Security First**: All cryptographic operations follow industry standards and best practices
2. **Zero Trust**: Never store or transmit sensitive data in plaintext
3. **Clean Architecture**: Clear separation of concerns with dependency inversion
4. **Testability**: Pure functions and dependency injection enable comprehensive testing
5. **Single Responsibility**: Each component has one well-defined purpose
6. **Fail Secure**: Errors never expose sensitive information

## Architecture

The system follows clean architecture with four distinct layers:

### Layer Structure

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  (GetX Controllers, UI State Management)                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  (Use Cases, Business Logic, Entities)                   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  (Repositories, Data Sources, Models)                    │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      Core Layer                          │
│  (Cryptographic Primitives, Utilities)                   │
└─────────────────────────────────────────────────────────┘
```

### Core Layer

The core layer contains pure cryptographic functions and utilities with no dependencies on Flutter or external packages. This layer is the foundation of security.

**Components:**

- **BIP39 Implementation**: Mnemonic generation and validation
- **BIP32 Implementation**: Hierarchical deterministic key derivation
- **BIP44 Implementation**: Multi-account hierarchy for EVM
- **Encryption Utilities**: AES-256 encryption/decryption
- **Key Derivation**: PBKDF2 implementation
- **Secure Memory**: Memory clearing utilities

### Domain Layer

The domain layer contains business logic and use cases. It defines interfaces for external dependencies and orchestrates cryptographic operations.

**Use Cases:**

- `CreateWalletUseCase`: Orchestrates wallet creation flow
- `ImportWalletUseCase`: Orchestrates wallet import flow
- `UnlockWalletUseCase`: Handles authentication and decryption
- `GetWalletAddressUseCase`: Derives and returns wallet address
- `DeleteWalletUseCase`: Securely removes wallet data
- `VerifyBackupUseCase`: Validates mnemonic backup
- `ExportMnemonicUseCase`: Retrieves decrypted mnemonic for display

**Entities:**

- `Wallet`: Represents wallet state (address, locked status)
- `EncryptedWallet`: Represents encrypted wallet data
- `WalletCredentials`: Temporary holder for mnemonic during operations

**Repository Interfaces:**

- `WalletRepository`: Abstract interface for wallet storage operations
- `SecureStorageRepository`: Abstract interface for secure storage

### Data Layer

The data layer implements repository interfaces and handles platform-specific storage.

**Implementations:**

- `WalletRepositoryImpl`: Implements wallet storage using secure storage
- `SecureStorageDataSource`: Wraps flutter_secure_storage
- `WalletModel`: Data transfer object for serialization

### Presentation Layer

The presentation layer manages UI state using GetX controllers.

**Controllers:**

- `WalletCreationController`: Manages wallet creation flow
- `WalletImportController`: Manages wallet import flow
- `WalletUnlockController`: Manages authentication
- `WalletController`: Manages wallet state and operations

## Components and Interfaces

### 1. BIP39 Mnemonic Service

**Purpose**: Generate and validate BIP39 mnemonics

**Interface:**

```dart
abstract class Bip39Service {
  /// Generate a 24-word mnemonic from 256 bits of entropy
  String generateMnemonic();

  /// Validate a mnemonic against BIP39 rules
  bool validateMnemonic(String mnemonic);

  /// Convert mnemonic to seed bytes (512 bits)
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''});

  /// Normalize mnemonic (lowercase, single spaces)
  String normalizeMnemonic(String mnemonic);
}
```

**Implementation Details:**

- Use platform-specific secure random number generator (dart:math Random.secure())
- Implement BIP39 word list (2048 English words)
- Calculate checksum: SHA-256 of entropy, take first entropy_length/32 bits
- Validate checksum on import
- Normalize: trim, lowercase, collapse multiple spaces
- PBKDF2 for seed derivation: 2048 iterations, HMAC-SHA512, salt="mnemonic" + passphrase

### 2. BIP32 HD Key Derivation Service

**Purpose**: Derive hierarchical deterministic keys according to BIP32

**Interface:**

```dart
abstract class Bip32Service {
  /// Derive master key from seed
  ExtendedKey deriveMasterKey(Uint8List seed);

  /// Derive child key from parent using derivation path
  ExtendedKey deriveKey(ExtendedKey parent, String path);

  /// Derive private key at specific path
  Uint8List derivePrivateKey(Uint8List seed, String path);
}

class ExtendedKey {
  final Uint8List key;
  final Uint8List chainCode;
  final int depth;
  final int index;
  final Uint8List parentFingerprint;
}
```

**Implementation Details:**

- Master key derivation: HMAC-SHA512(key="Bitcoin seed", data=seed)
- Split result: first 32 bytes = private key, last 32 bytes = chain code
- Hardened derivation (index >= 2^31): HMAC-SHA512(key=chainCode, data=0x00 || privateKey || index)
- Normal derivation (index < 2^31): HMAC-SHA512(key=chainCode, data=publicKey || index)
- Path format: m/44'/60'/0'/0/0 (all hardened except last two)

### 3. Encryption Service

**Purpose**: Encrypt and decrypt sensitive data using AES-256

**Interface:**

```dart
abstract class EncryptionService {
  /// Encrypt plaintext using AES-256-GCM
  EncryptedData encrypt(String plaintext, Uint8List key);

  /// Decrypt ciphertext using AES-256-GCM
  String decrypt(EncryptedData encrypted, Uint8List key);

  /// Derive encryption key from PIN using PBKDF2
  Uint8List deriveKeyFromPin(String pin, Uint8List salt, {int iterations = 100000});

  /// Generate cryptographically secure random salt
  Uint8List generateSalt({int length = 32});

  /// Generate cryptographically secure random IV
  Uint8List generateIV({int length = 16});
}

class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List? authTag; // For GCM mode
}
```

**Implementation Details:**

- Use AES-256-GCM for authenticated encryption (preferred) or AES-256-CBC with HMAC
- PBKDF2 parameters: 100,000 iterations minimum, SHA-256, 32-byte output
- Salt: 32 bytes of secure random data
- IV: 16 bytes for CBC, 12 bytes for GCM
- GCM provides authentication, eliminating need for separate HMAC
- Use pointycastle or cryptography package for implementation

### 4. Secure Storage Service

**Purpose**: Store and retrieve encrypted data using flutter_secure_storage

**Interface:**

```dart
abstract class SecureStorageService {
  /// Store encrypted mnemonic
  Future<void> storeEncryptedMnemonic(EncryptedData encrypted);

  /// Store encryption salt
  Future<void> storeSalt(Uint8List salt);

  /// Retrieve encrypted mnemonic
  Future<EncryptedData?> getEncryptedMnemonic();

  /// Retrieve encryption salt
  Future<Uint8List?> getSalt();

  /// Check if wallet exists
  Future<bool> hasWallet();

  /// Delete all wallet data
  Future<void> deleteWallet();
}
```

**Implementation Details:**

- Use flutter_secure_storage with platform-specific secure storage (Keychain on iOS, KeyStore on Android)
- Storage keys: "encrypted_mnemonic", "encryption_salt", "encryption_iv"
- Serialize EncryptedData as JSON with base64-encoded bytes
- Atomic operations: use transactions or verify writes
- Error handling: catch platform exceptions, return null on missing data

### 5. Wallet Repository

**Purpose**: High-level wallet operations coordinating storage and cryptography

**Interface:**

```dart
abstract class WalletRepository {
  /// Create new wallet with mnemonic and PIN
  Future<Wallet> createWallet(String mnemonic, String pin);

  /// Import existing wallet with mnemonic and PIN
  Future<Wallet> importWallet(String mnemonic, String pin);

  /// Unlock wallet with PIN
  Future<Wallet> unlockWallet(String pin);

  /// Get wallet address without unlocking
  Future<String?> getWalletAddress();

  /// Check if wallet exists
  Future<bool> hasWallet();

  /// Delete wallet
  Future<void> deleteWallet();

  /// Export mnemonic (requires prior unlock)
  Future<String> exportMnemonic(String pin);
}

class Wallet {
  final String address;
  final Uint8List privateKey; // Held in memory only during session
  final bool isLocked;
}
```

**Implementation Details:**

- Coordinate encryption service and storage service
- Validate PIN format (4-8 digits)
- Derive Ethereum address from private key (Keccak-256 hash of public key, take last 20 bytes)
- Clear sensitive data from memory after operations
- Cache wallet address separately for quick access without decryption

### 6. Key Derivation Service

**Purpose**: Derive EVM-compatible keys from mnemonic

**Interface:**

```dart
abstract class KeyDerivationService {
  /// Derive private key from mnemonic using BIP44 path m/44'/60'/0'/0/0
  Uint8List derivePrivateKey(String mnemonic);

  /// Derive public key from private key
  Uint8List derivePublicKey(Uint8List privateKey);

  /// Derive Ethereum address from public key
  String deriveAddress(Uint8List publicKey);

  /// Complete derivation: mnemonic -> address
  WalletKeys deriveWalletKeys(String mnemonic);
}

class WalletKeys {
  final Uint8List privateKey;
  final Uint8List publicKey;
  final String address;
}
```

**Implementation Details:**

- Use secp256k1 elliptic curve for EVM compatibility
- Derivation path: m/44'/60'/0'/0/0 (BIP44 standard for Ethereum)
    - 44' = BIP44 purpose (hardened)
    - 60' = Ethereum coin type (hardened)
    - 0' = Account 0 (hardened)
    - 0 = External chain (not hardened)
    - 0 = Address index 0 (not hardened)
- Public key derivation: secp256k1 point multiplication
- Address derivation: Keccak-256(publicKey)[12:] (last 20 bytes), format as 0x-prefixed hex
- Use web3dart or pointycastle for secp256k1 operations

### 7. Memory Security Utilities

**Purpose**: Securely clear sensitive data from memory

**Interface:**

```dart
abstract class SecureMemory {
  /// Overwrite Uint8List with zeros
  void clear(Uint8List data);

  /// Overwrite String in memory (best effort)
  void clearString(String data);

  /// Execute function with automatic cleanup
  T withSecureData<T>(Uint8List data, T Function(Uint8List) operation);
}
```

**Implementation Details:**

- Overwrite byte arrays with zeros before deallocation
- For strings: convert to bytes, overwrite, then clear reference
- Dart's garbage collector makes complete memory clearing difficult, but overwriting reduces exposure window
- Use try-finally blocks to ensure cleanup even on exceptions
- Consider using ffi for more control over memory if needed

## Data Models

### EncryptedWalletData

```dart
class EncryptedWalletData {
  final String encryptedMnemonic; // Base64-encoded ciphertext
  final String iv; // Base64-encoded IV
  final String salt; // Base64-encoded salt
  final String? authTag; // Base64-encoded auth tag (for GCM)
  final String address; // Cached Ethereum address
  final DateTime createdAt;

  Map<String, dynamic> toJson();
  factory EncryptedWalletData.fromJson(Map<String, dynamic> json);
}
```

### WalletState

```dart
enum WalletStatus {
  notCreated,
  locked,
  unlocked,
}

class WalletState {
  final WalletStatus status;
  final String? address;
  final DateTime? createdAt;
  final Uint8List? privateKey; // Only present when unlocked
}
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property Reflection

After analyzing all acceptance criteria, I've identified several areas where properties can be consolidated:

**Consolidations:**

1. Properties 1.3, 1.4, 13.1, 13.4, 13.5 all relate to BIP39 compliance - can be combined into comprehensive BIP39 standard compliance property
2. Properties 5.1, 5.2, 5.3, 13.2, 13.3, 13.6 all relate to BIP32/BIP44 compliance - can be combined into comprehensive key derivation standard compliance property
3. Properties 3.2, 3.6, 3.7 all relate to encryption metadata generation - can be combined into encryption data completeness property
4. Properties 6.2, 6.3, 6.4 all relate to encryption/decryption round-trip - can be combined into single round-trip property
5. Properties 8.1, 8.2, 4.4 all relate to storage security constraints - can be combined into storage security property
6. Properties 9.1, 9.2, 9.5 all relate to error handling - can be combined into comprehensive error handling property
7. Properties 12.2, 12.3, 12.4 all relate to mnemonic verification - can be combined into verification correctness property

**Unique Properties to Keep:**

- Mnemonic generation (24 words, 256-bit entropy)
- Entropy randomness quality
- PIN validation (4-8 digits)
- PBKDF2 parameters (100k iterations, SHA-256)
- AES-256 encryption algorithm
- Storage structure (separate salt/IV)
- Wallet deletion completeness
- Storage atomicity
- Public key and address derivation
- Authentication data retrieval
- Wallet existence checking
- Single wallet constraint enforcement
- Error information security
- Constant-time PIN comparison
- Storage failure recovery
- Corruption detection
- Mnemonic export authentication
- Backup confirmation workflow

### Correctness Properties

Property 1: BIP39 Standard Compliance
_For any_ generated or imported mnemonic, it must be exactly 24 words from the BIP39 English word list, have a valid checksum, and produce the same seed as reference BIP39 implementations when converted
**Validates: Requirements 1.1, 1.3, 1.4, 2.2, 13.1, 13.4, 13.5**

Property 2: Entropy Randomness Quality
_For any_ sequence of generated mnemonics, the entropy must pass statistical randomness tests (chi-square, runs test) indicating cryptographically secure random generation
**Validates: Requirements 1.2**

Property 3: Mnemonic Word Count Validation
_For any_ mnemonic import attempt, the system must accept input with exactly 24 words and reject input with any other word count
**Validates: Requirements 2.1**

Property 4: Mnemonic Normalization Consistency
_For any_ valid mnemonic with varying whitespace and casing, normalization must produce identical lowercase output with single spaces between words
**Validates: Requirements 2.4**

Property 5: Import Rejection on Invalid Mnemonic
_For any_ invalid mnemonic (wrong checksum, invalid words, wrong length), the import must fail with an error and no data must be stored
**Validates: Requirements 2.3**

Property 6: PIN Format Validation
_For any_ PIN input, the system must accept PINs with 4-8 digits and reject PINs outside this range or containing non-digit characters
**Validates: Requirements 3.1**

Property 7: Encryption Metadata Completeness
_For any_ encryption operation, the output must include ciphertext, a unique IV (different from all previous IVs), and a cryptographically secure salt of at least 16 bytes
**Validates: Requirements 3.2, 3.6, 3.7**

Property 8: PBKDF2 Parameter Compliance
_For any_ PIN-to-key derivation, the system must use PBKDF2 with SHA-256, at least 100,000 iterations, and produce a 32-byte key
**Validates: Requirements 3.3, 3.4**

Property 9: AES-256 Encryption Algorithm
_For any_ encryption operation, the system must use AES-256 in GCM or CBC mode, verifiable by comparing outputs with reference implementations using the same key and IV
**Validates: Requirements 3.5**

Property 10: Encryption Round-Trip Integrity
_For any_ mnemonic and PIN, encrypting then decrypting with the same PIN must recover the original mnemonic exactly
**Validates: Requirements 6.2, 6.3**

Property 11: Wrong PIN Rejection
_For any_ encrypted mnemonic, attempting to decrypt with an incorrect PIN must fail and return an authentication error
**Validates: Requirements 6.4**

Property 12: Storage Structure Separation
_For any_ stored wallet, the encrypted mnemonic, salt, and IV must be retrievable as separate values from storage
**Validates: Requirements 4.3**

Property 13: Storage Security Constraints
_For any_ wallet storage operation, the storage must never contain the plaintext mnemonic, private key, or PIN at any time
**Validates: Requirements 4.4, 8.1, 8.2**

Property 14: Wallet Deletion Completeness
_For any_ wallet, after deletion, all wallet data (encrypted mnemonic, salt, IV, address) must be absent from storage
**Validates: Requirements 4.5**

Property 15: Storage Atomicity
_For any_ storage operation that fails mid-write, the storage must either contain the complete new data or remain in the previous consistent state (no partial writes)
**Validates: Requirements 4.6**

Property 16: BIP32/BIP44 Key Derivation Compliance
_For any_ mnemonic, deriving keys using path m/44'/60'/0'/0/0 must produce identical private keys, public keys, and Ethereum addresses as reference BIP32/BIP44 implementations
**Validates: Requirements 5.1, 5.2, 5.3, 13.2, 13.3, 13.6**

Property 17: Public Key and Address Derivation
_For any_ private key, the derived public key and Ethereum address must match reference secp256k1 and Keccak-256 implementations
**Validates: Requirements 5.6**

Property 18: Authentication Data Retrieval
_For any_ unlock attempt, the system must retrieve all required data (encrypted mnemonic, salt, IV) from storage before attempting decryption
**Validates: Requirements 6.1**

Property 19: Session Private Key Availability
_For any_ successful authentication, the private key must be derivable and available for use during the session
**Validates: Requirements 6.5**

Property 20: Wallet Existence Detection
_For any_ system state, the wallet existence check must return true if and only if an encrypted mnemonic exists in storage
**Validates: Requirements 7.1, 7.5**

Property 21: Single Wallet Creation Constraint
_For any_ system with an existing wallet, attempts to create or import a new wallet must fail with an error until the existing wallet is deleted
**Validates: Requirements 7.2, 7.3**

Property 22: Error Information Security
_For any_ error from cryptographic operations, the error message must not contain any portion of the mnemonic, private key, or PIN
**Validates: Requirements 8.6, 9.1**

Property 23: Constant-Time PIN Comparison
_For any_ two different incorrect PINs of the same length, the authentication time must not vary by more than a negligible threshold (< 1ms), preventing timing attacks
**Validates: Requirements 8.7**

Property 24: Error Message Descriptiveness
_For any_ validation failure, the error message must indicate which validation failed (e.g., "invalid word count", "invalid checksum", "wrong PIN")
**Validates: Requirements 9.2**

Property 25: Storage Failure Recovery
_For any_ storage operation failure, the system must remain in a consistent state and subsequent operations must not be affected by the failed operation
**Validates: Requirements 9.3**

Property 26: Corruption Detection
_For any_ corrupted encrypted mnemonic (modified ciphertext or auth tag), decryption must fail and return a corruption error
**Validates: Requirements 9.4**

Property 27: Mnemonic Display Format
_For any_ mnemonic display operation, the output must contain all 24 words in order with sequential numbering from 1 to 24
**Validates: Requirements 11.2**

Property 28: Backup Confirmation Workflow
_For any_ wallet creation, after the user confirms backup, the mnemonic must be encrypted and stored
**Validates: Requirements 11.3**

Property 29: Mnemonic Export Authentication
_For any_ mnemonic export attempt, the operation must fail unless preceded by successful PIN authentication
**Validates: Requirements 11.4, 12.5**

Property 30: Mnemonic Verification Correctness
_For any_ stored wallet and entered mnemonic, verification must return success if and only if the entered mnemonic matches the stored mnemonic (after decryption and normalization)
**Validates: Requirements 12.2, 12.3, 12.4**

## Error Handling

### Error Types

The system defines distinct error types for different failure scenarios:

```dart
enum WalletErrorType {
  // Validation Errors
  invalidMnemonicLength,
  invalidMnemonicWords,
  invalidMnemonicChecksum,
  invalidPinFormat,

  // Authentication Errors
  wrongPin,
  walletLocked,
  authenticationRequired,

  // Storage Errors
  storageReadFailure,
  storageWriteFailure,
  storageDeleteFailure,
  dataCorrupted,

  // Constraint Errors
  walletAlreadyExists,
  walletNotFound,

  // Cryptographic Errors
  encryptionFailure,
  decryptionFailure,
  keyDerivationFailure,

  // System Errors
  insufficientEntropy,
  platformNotSupported,
}

class WalletError implements Exception {
  final WalletErrorType type;
  final String message;
  final String? details;

  WalletError(this.type, this.message, {this.details});
}
```

### Error Handling Principles

1. **Fail Secure**: Errors never expose sensitive information
2. **Clear Classification**: Each error has a specific type for proper handling
3. **User-Friendly Messages**: Error messages are descriptive but safe
4. **Consistent State**: Failed operations leave the system in a consistent state
5. **Audit Trail**: Errors are logged (without sensitive data) for debugging

### Error Handling Patterns

**Validation Errors:**

- Occur during input validation (mnemonic, PIN)
- Return immediately without side effects
- Provide specific feedback about what failed

**Authentication Errors:**

- Occur during unlock or authentication
- Use constant-time comparison to prevent timing attacks
- Don't distinguish between "wrong PIN" and "corrupted data" to external observers (both fail authentication)

**Storage Errors:**

- Occur during read/write operations
- Implement retry logic for transient failures
- Maintain data consistency through atomic operations

**Cryptographic Errors:**

- Occur during encryption/decryption/derivation
- Clear sensitive data from memory before returning error
- Log error type but never log inputs or outputs

## Testing Strategy

### Dual Testing Approach

The system requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests:**

- Specific examples demonstrating correct behavior
- Edge cases (empty input, boundary values, special characters)
- Error conditions (invalid input, storage failures, corruption)
- Integration points between components
- Platform-specific behavior

**Property-Based Tests:**

- Universal properties that hold for all inputs
- Cryptographic correctness across random inputs
- Standard compliance verification
- Security constraints validation
- Comprehensive input coverage through randomization

Both testing approaches are complementary and necessary. Unit tests catch concrete bugs and verify specific scenarios, while property tests verify general correctness and find edge cases through randomization.

### Property-Based Testing Configuration

**Library Selection:**

- Use `test` package with custom property testing utilities, or
- Use `dart_check` or similar property-based testing library for Dart

**Test Configuration:**

- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `@Tags(['feature:wallet-key-management', 'property:N'])`
- Each correctness property must be implemented by a single property-based test

**Example Property Test Structure:**

```dart
// Feature: wallet-key-management, Property 1: BIP39 Standard Compliance
test('generated mnemonics comply with BIP39 standard', () {
  final generator = Bip39Service();

  for (int i = 0; i < 100; i++) {
    final mnemonic = generator.generateMnemonic();

    // Must be exactly 24 words
    expect(mnemonic.split(' ').length, equals(24));

    // Must pass BIP39 validation
    expect(generator.validateMnemonic(mnemonic), isTrue);

    // Must produce same seed as reference implementation
    final ourSeed = generator.mnemonicToSeed(mnemonic);
    final referenceSeed = referenceBip39.mnemonicToSeed(mnemonic);
    expect(ourSeed, equals(referenceSeed));
  }
});
```

### Test Coverage Requirements

**Core Layer:**

- 100% coverage of cryptographic functions
- Test against reference implementations (BIP39, BIP32, BIP44)
- Test with known test vectors from standards
- Property tests for all cryptographic operations

**Domain Layer:**

- Test all use cases with valid and invalid inputs
- Test error handling and edge cases
- Mock repository interfaces for isolation
- Property tests for business logic invariants

**Data Layer:**

- Test storage operations with mock secure storage
- Test serialization/deserialization
- Test error recovery and consistency
- Integration tests with real flutter_secure_storage

**Security Testing:**

- Verify sensitive data is never logged
- Verify sensitive data is cleared from memory
- Verify constant-time operations
- Verify error messages don't leak information
- Test with corrupted data
- Test with malicious inputs

### Test Data

**Known Test Vectors:**
Use official BIP39/BIP32/BIP44 test vectors for validation:

- BIP39 test vectors from the specification
- BIP32 test vectors from the specification
- Known Ethereum addresses for specific mnemonics

**Random Test Data:**

- Generate random mnemonics for property tests
- Generate random PINs for encryption tests
- Generate random invalid inputs for validation tests

### Continuous Testing

- Run unit tests on every commit
- Run property tests on every pull request
- Run security tests before releases
- Perform manual security audits periodically

## Dependencies

### Required Packages

```yaml
dependencies:
    flutter:
        sdk: flutter
    flutter_secure_storage: ^9.0.0 # Secure storage
    pointycastle: ^3.7.3 # Cryptographic primitives
    hex: ^0.2.0 # Hex encoding/decoding
    get: ^4.6.6 # State management

dev_dependencies:
    flutter_test:
        sdk: flutter
    mockito: ^5.4.4 # Mocking for tests
    build_runner: ^2.4.8 # Code generation
```

### Package Justification

**flutter_secure_storage:**

- Platform-specific secure storage (Keychain/KeyStore)
- Required for encrypted mnemonic storage
- Industry standard for Flutter secure storage

**pointycastle:**

- Pure Dart cryptographic library
- Implements AES, PBKDF2, SHA-256, secp256k1
- No native dependencies, fully auditable
- Implements BIP32 HMAC-SHA512

**hex:**

- Hex encoding/decoding for addresses and keys
- Lightweight, no dependencies

**get:**

- State management as specified in requirements
- Dependency injection support
- Reactive state updates

## Security Considerations

### Threat Model

**In Scope:**

- Device compromise while app is not running (encrypted storage protects mnemonic)
- Malicious apps on same device (secure storage isolation)
- Physical device theft (PIN protection)
- Memory dumps while app is running (minimize exposure window)
- Timing attacks on PIN validation (constant-time comparison)
- Data corruption (detection and error handling)

**Out of Scope:**

- Device compromise while app is running and unlocked (attacker has full access)
- Compromised operating system (secure storage may be bypassed)
- Hardware attacks (side-channel, fault injection)
- Social engineering (user reveals PIN or mnemonic)
- Clipboard monitoring (user copies mnemonic)

### Security Best Practices

1. **Minimize Exposure Window**: Hold decrypted mnemonic and private key in memory only as long as necessary
2. **Clear Sensitive Data**: Overwrite memory containing sensitive data before deallocation
3. **Validate All Inputs**: Never trust user input, always validate
4. **Fail Secure**: Errors never expose sensitive information
5. **Constant-Time Operations**: Use constant-time comparison for PIN validation
6. **No Logging**: Never log sensitive data (mnemonic, private key, PIN)
7. **No Network**: Never transmit sensitive data over network
8. **Audit Trail**: Log security-relevant events (without sensitive data)
9. **Defense in Depth**: Multiple layers of security (encryption, secure storage, validation)
10. **Standard Compliance**: Follow industry standards (BIP39, BIP32, BIP44, AES-256, PBKDF2)

### Secure Coding Guidelines

**DO:**

- Use cryptographically secure random number generators
- Use established cryptographic libraries (pointycastle)
- Validate all inputs before processing
- Clear sensitive data from memory after use
- Use constant-time comparison for secrets
- Handle errors securely without leaking information
- Follow clean architecture for testability
- Write comprehensive tests including security tests

**DON'T:**

- Store private keys (even encrypted)
- Store PINs (even hashed)
- Log sensitive data
- Transmit sensitive data over network
- Use weak encryption (< AES-256)
- Use weak key derivation (< 100k iterations)
- Trust user input without validation
- Expose sensitive data in error messages
- Use variable-time comparison for secrets

## Implementation Notes

### Platform-Specific Considerations

**iOS:**

- flutter_secure_storage uses Keychain
- Keychain data persists across app reinstalls (may need explicit deletion)
- Biometric authentication can be added later using local_auth

**Android:**

- flutter_secure_storage uses KeyStore
- KeyStore data is deleted on app uninstall
- Biometric authentication can be added later using local_auth

### Performance Considerations

**PBKDF2 Iterations:**

- 100,000 iterations provides good security/performance balance
- Takes ~100-200ms on modern mobile devices
- Consider increasing to 200,000+ for higher security (with user testing)

**Memory Management:**

- Dart's garbage collector makes complete memory clearing difficult
- Overwrite sensitive data to reduce exposure window
- Consider using ffi for more control if needed

**Storage Performance:**

- flutter_secure_storage is relatively slow (platform calls)
- Cache wallet address separately for quick access
- Minimize storage operations

### Future Enhancements

**Potential Additions (Out of Scope for Current Spec):**

- Biometric authentication (fingerprint, face ID)
- Multiple accounts (BIP44 account index)
- Hardware wallet integration
- Backup encryption with cloud storage
- Social recovery mechanisms
- Multi-signature support
- Transaction signing
- Balance queries
- Transaction history

These enhancements would require separate specifications and security analysis.

## Glossary Reference

For complete definitions of all terms used in this document, refer to the Glossary section in the Requirements Document.

## Appendix: BIP Standards Summary

### BIP39: Mnemonic Code for Generating Deterministic Keys

- **Purpose**: Convert random entropy into human-readable mnemonic phrases
- **Entropy**: 256 bits for 24-word mnemonic
- **Checksum**: First entropy_length/32 bits of SHA-256(entropy)
- **Word List**: 2048 English words
- **Seed Derivation**: PBKDF2(password=mnemonic, salt="mnemonic"+passphrase, iterations=2048, hash=SHA-512)

### BIP32: Hierarchical Deterministic Wallets

- **Purpose**: Derive multiple keys from a single seed
- **Master Key**: HMAC-SHA512(key="Bitcoin seed", data=seed)
- **Child Derivation**: HMAC-SHA512(key=chainCode, data=parentKey||index)
- **Hardened Keys**: Index >= 2^31, uses private key in derivation
- **Normal Keys**: Index < 2^31, uses public key in derivation

### BIP44: Multi-Account Hierarchy for Deterministic Wallets

- **Purpose**: Standard derivation path structure
- **Path Format**: m / purpose' / coin_type' / account' / change / address_index
- **Ethereum Path**: m / 44' / 60' / 0' / 0 / 0
    - 44' = BIP44 purpose (hardened)
    - 60' = Ethereum coin type (hardened)
    - 0' = Account 0 (hardened)
    - 0 = External chain (receiving addresses)
    - 0 = First address

## Appendix: Cryptographic Algorithms

### AES-256-GCM

- **Algorithm**: Advanced Encryption Standard
- **Key Size**: 256 bits
- **Mode**: Galois/Counter Mode (authenticated encryption)
- **IV Size**: 12 bytes (96 bits) for GCM
- **Authentication**: Built-in authentication tag
- **Security**: Industry standard, NIST approved

### PBKDF2

- **Algorithm**: Password-Based Key Derivation Function 2
- **Hash**: SHA-256
- **Iterations**: 100,000 minimum
- **Salt**: 32 bytes
- **Output**: 32 bytes (256 bits)
- **Purpose**: Derive encryption key from PIN

### secp256k1

- **Algorithm**: Elliptic Curve Digital Signature Algorithm
- **Curve**: secp256k1 (used by Bitcoin and Ethereum)
- **Key Size**: 256 bits
- **Purpose**: Derive public key from private key

### Keccak-256

- **Algorithm**: SHA-3 variant used by Ethereum
- **Output**: 256 bits (32 bytes)
- **Purpose**: Hash public key to derive Ethereum address
- **Address Format**: Last 20 bytes of Keccak-256(publicKey)
