# HD Wallet Core - Cryptographic Implementation

## Overview

This directory contains the core cryptographic implementation for a production-grade, non-custodial HD (Hierarchical Deterministic) wallet following BIP39, BIP32, and BIP44 standards.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    WalletEngine                          │
│  High-level wallet operations (create, import, derive)   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              KeyDerivationService                        │
│  EVM key derivation (BIP44 path: m/44'/60'/0'/0/0)      │
└─────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
┌───────────────────────┐   ┌───────────────────────┐
│   Bip39Service        │   │   Bip32Service        │
│  Mnemonic generation  │   │  HD key derivation    │
│  Seed derivation      │   │  BIP32 standard       │
└───────────────────────┘   └───────────────────────┘
```

## Components

### 1. WalletEngine

**File:** `wallet_engine.dart`

High-level API for wallet operations.

**Features:**

- Create new wallet (24-word mnemonic)
- Import existing wallet
- Derive multiple accounts from single mnemonic
- Get current address
- Derive private keys for signing

**Usage:**

```dart
final engine = WalletEngine();

// Create wallet
final result = engine.createWallet();
print('Mnemonic: ${result.mnemonic}');
print('Address: ${result.address}');

// Import wallet
final importResult = engine.importWallet(mnemonic);

// Derive accounts
final account1 = engine.deriveAccount(mnemonic, 1);
```

### 2. Bip39Service

**Files:** `bip39_service.dart`, `bip39_service_impl.dart`

BIP39 mnemonic generation and validation.

**Features:**

- Generate 24-word mnemonics (256-bit entropy)
- Validate mnemonics (word count, word list, checksum)
- Convert mnemonic to seed (PBKDF2-HMAC-SHA512)
- Normalize mnemonics (lowercase, trim, collapse spaces)

**Cryptographic Flow:**

```
Random Entropy (256 bits)
    ↓
Checksum (SHA-256, first 8 bits)
    ↓
Entropy + Checksum (264 bits)
    ↓
24 Words (11 bits each)
    ↓
PBKDF2-HMAC-SHA512 (2048 iterations)
    ↓
Seed (512 bits)
```

### 3. Bip32Service

**Files:** `bip32_service.dart`, `bip32_service_impl.dart`

BIP32 hierarchical deterministic key derivation.

**Features:**

- Derive master key from seed
- Derive child keys using derivation paths
- Support hardened and normal derivation
- Parse derivation paths (e.g., m/44'/60'/0'/0/0)

**Cryptographic Flow:**

```
Seed (512 bits)
    ↓
HMAC-SHA512(key="Bitcoin seed", data=seed)
    ↓
Master Key (256 bits) + Chain Code (256 bits)
    ↓
Child Key Derivation (HMAC-SHA512)
    ↓
Derived Private Key
```

**Derivation Types:**

- **Hardened:** Index >= 2^31 (marked with ')
    - Uses private key in derivation
    - More secure, cannot derive public key without private key
- **Normal:** Index < 2^31
    - Uses public key in derivation
    - Can derive public key without private key

### 4. KeyDerivationService

**Files:** `key_derivation_service.dart`, `key_derivation_service_impl.dart`

EVM-specific key derivation using BIP44 standard.

**Features:**

- Derive private key from mnemonic
- Derive public key from private key (secp256k1)
- Derive Ethereum address from public key (Keccak-256)
- Support multiple accounts

**BIP44 Derivation Path:**

```
m / 44' / 60' / 0' / 0 / 0
│   │     │     │    │   │
│   │     │     │    │   └─ Address Index
│   │     │     │    └───── External Chain (0) / Internal Chain (1)
│   │     │     └────────── Account Index
│   │     └──────────────── Coin Type (60 = Ethereum)
│   └────────────────────── Purpose (44 = BIP44)
└────────────────────────── Master Key
```

**Cryptographic Flow:**

```
Mnemonic
    ↓
Seed (BIP39)
    ↓
Master Key (BIP32)
    ↓
Derived Private Key (BIP44 path: m/44'/60'/0'/0/0)
    ↓
Public Key (secp256k1 point multiplication)
    ↓
Keccak-256 Hash
    ↓
Ethereum Address (last 20 bytes, EIP-55 checksum)
```

## Security Principles

### 1. Private Key Management

**NEVER STORED:**

- Private keys are NEVER stored on device
- Private keys are derived at runtime only
- Private keys exist in memory only during signing

**BEST PRACTICES:**

```dart
// ✅ CORRECT: Derive at runtime
final privateKey = engine.derivePrivateKey();
// Use for signing
signTransaction(privateKey);
// Clear from memory
SecureMemory.clear(privateKey);

// ❌ WRONG: Never store
await storage.write('private_key', privateKey); // NEVER DO THIS
```

### 2. Mnemonic Storage

**ENCRYPTION REQUIRED:**

- Mnemonics must be encrypted before storage
- Use AES-256-GCM with PIN-derived key (PBKDF2)
- Store only encrypted mnemonic, never plaintext

**BEST PRACTICES:**

```dart
// ✅ CORRECT: Encrypt before storage
final encrypted = encryptionService.encrypt(mnemonic, pinDerivedKey);
await storage.write('encrypted_mnemonic', encrypted);

// ❌ WRONG: Never store plaintext
await storage.write('mnemonic', mnemonic); // NEVER DO THIS
```

### 3. Memory Security

**CLEAR SENSITIVE DATA:**

- Clear mnemonics from memory after use
- Clear private keys immediately after signing
- Clear seeds after key derivation

**BEST PRACTICES:**

```dart
// Use try-finally to ensure cleanup
Uint8List? privateKey;
try {
  privateKey = engine.derivePrivateKey();
  signTransaction(privateKey);
} finally {
  if (privateKey != null) {
    SecureMemory.clear(privateKey);
  }
}
```

### 4. Session Management

**LOCK WALLET:**

- Clear mnemonic from memory when locking wallet
- Require re-authentication to unlock
- Never keep wallet unlocked indefinitely

**BEST PRACTICES:**

```dart
// Lock wallet
engine.clearSession();

// Unlock wallet (requires PIN)
final decryptedMnemonic = decryptMnemonic(pin);
engine.importWallet(decryptedMnemonic);
```

## Standards Compliance

### BIP39 (Mnemonic Code)

- **Entropy:** 256 bits (24 words)
- **Checksum:** SHA-256, first 8 bits
- **Word List:** English (2048 words)
- **Seed Derivation:** PBKDF2-HMAC-SHA512, 2048 iterations
- **Salt:** "mnemonic" + passphrase (empty by default)

### BIP32 (HD Wallets)

- **Master Key:** HMAC-SHA512(key="Bitcoin seed", data=seed)
- **Child Derivation:** HMAC-SHA512(key=chainCode, data=parentKey || index)
- **Hardened Derivation:** Index >= 2^31 (0x80000000)
- **Key Size:** 256 bits (32 bytes)

### BIP44 (Multi-Account Hierarchy)

- **Purpose:** 44' (hardened)
- **Coin Type:** 60' (Ethereum, hardened)
- **Account:** 0' (hardened)
- **Change:** 0 (external), 1 (internal)
- **Address Index:** 0, 1, 2, ... (not hardened)

### EVM Compatibility

- **Curve:** secp256k1
- **Public Key:** Uncompressed (64 bytes: x + y coordinates)
- **Address:** Keccak-256(publicKey)[12:] (last 20 bytes)
- **Format:** 0x-prefixed hex with EIP-55 checksum

## Testing

### Unit Tests

**Location:** `test/core/crypto/`

**Coverage:**

- BIP39 mnemonic generation and validation
- BIP32 key derivation
- EVM address derivation
- Wallet engine operations
- Error handling

**Run Tests:**

```bash
flutter test test/core/crypto/
```

### Test Vectors

Uses official BIP39/BIP32/BIP44 test vectors for validation:

- Known mnemonics produce expected addresses
- Deterministic derivation (same input → same output)
- Cross-wallet compatibility

## Dependencies

```yaml
dependencies:
    pointycastle: ^3.9.1 # Cryptographic primitives
    hex: ^0.2.0 # Hex encoding/decoding
    web3dart: ^2.7.3 # Ethereum utilities
    bip39: ^1.0.6 # BIP39 implementation
    ed25519_hd_key: ^2.2.0 # HD key derivation
```

## Usage Examples

### Example 1: Create New Wallet

```dart
final engine = WalletEngine();
final result = engine.createWallet();

print('Mnemonic: ${result.mnemonic}');
print('Address: ${result.address}');

// IMPORTANT: Encrypt mnemonic before storage
final encrypted = encryptMnemonic(result.mnemonic, pin);
await storage.write('wallet', encrypted);
```

### Example 2: Import Existing Wallet

```dart
final engine = WalletEngine();
const mnemonic = 'your 24 word mnemonic phrase here...';

final result = engine.importWallet(mnemonic);
if (result.isValid) {
  print('Address: ${result.address}');
} else {
  print('Error: ${result.error}');
}
```

### Example 3: Multiple Accounts

```dart
final engine = WalletEngine();
const mnemonic = 'your 24 word mnemonic phrase here...';

// Derive multiple accounts
for (int i = 0; i < 5; i++) {
  final account = engine.deriveAccount(mnemonic, i);
  print('Account $i: ${account.address}');
}
```

### Example 4: Sign Transaction

```dart
final engine = WalletEngine();
engine.importWallet(mnemonic);

Uint8List? privateKey;
try {
  // Derive private key
  privateKey = engine.derivePrivateKey();

  // Sign transaction
  final signature = signTransaction(transaction, privateKey);

  // Broadcast transaction
  await sendTransaction(signature);
} finally {
  // CRITICAL: Clear private key from memory
  if (privateKey != null) {
    SecureMemory.clear(privateKey);
  }
}
```

## Security Audit Checklist

- [x] Private keys never stored
- [x] Private keys derived at runtime only
- [x] Mnemonics encrypted before storage
- [x] Sensitive data cleared from memory
- [x] BIP39/BIP32/BIP44 standards compliance
- [x] Cryptographically secure random generation
- [x] Deterministic key derivation
- [x] EVM address compatibility
- [x] Comprehensive unit tests
- [x] Error handling without data leakage

## Future Enhancements

1. **Hardware Wallet Support:** Integrate with Ledger/Trezor
2. **Multi-Signature:** Support multi-sig wallets
3. **Social Recovery:** Implement Shamir's Secret Sharing
4. **Biometric Auth:** Add fingerprint/face unlock
5. **Account Discovery:** Auto-discover used accounts
6. **Custom Derivation Paths:** Support non-standard paths

## References

- [BIP39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [BIP32 Specification](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
- [BIP44 Specification](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)
- [EIP-55: Mixed-case checksum address encoding](https://eips.ethereum.org/EIPS/eip-55)
- [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf)
