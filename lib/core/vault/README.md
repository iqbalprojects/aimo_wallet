# Secure Vault - Encrypted Mnemonic Storage

## Overview

The Secure Vault provides production-grade encrypted storage for wallet mnemonics using AES-256-GCM encryption with PBKDF2 key derivation. All sensitive data is stored in platform secure storage (iOS Keychain / Android KeyStore).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SecureVault                           │
│  High-level API for encrypted mnemonic storage          │
└─────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
┌───────────────────────┐   ┌───────────────────────┐
│  EncryptionService    │   │ FlutterSecureStorage  │
│  AES-256-GCM + PBKDF2 │   │ Keychain/KeyStore     │
└───────────────────────┘   └───────────────────────┘
```

## Components

### 1. SecureVault

**File:** `secure_vault.dart`

High-level API for secure mnemonic storage.

**Features:**

- Store encrypted mnemonic
- Retrieve mnemonic with PIN
- Verify PIN without decryption
- Update PIN (re-encrypt)
- Delete wallet
- Single wallet per device

**Usage:**

```dart
final vault = SecureVault();

// Store mnemonic
await vault.storeMnemonic(mnemonic, pin);

// Retrieve mnemonic
final mnemonic = await vault.retrieveMnemonic(pin);

// Verify PIN
final isValid = await vault.verifyPin(pin);

// Update PIN
await vault.updatePin(oldPin, newPin);

// Delete wallet
await vault.deleteWallet();
```

### 2. EncryptionService

**File:** `encryption_service.dart`

AES-256-GCM encryption with PBKDF2 key derivation.

**Features:**

- AES-256-GCM authenticated encryption
- PBKDF2 key derivation (100k iterations)
- Random salt generation (32 bytes)
- Random IV generation (12 bytes)
- Authentication tag (16 bytes)
- Memory clearing after use

**Cryptographic Flow:**

```
PIN + Salt
    ↓
PBKDF2-SHA256 (100k iterations)
    ↓
Encryption Key (32 bytes)
    ↓
AES-256-GCM (with random IV)
    ↓
Ciphertext + Auth Tag
```

### 3. VaultException

**File:** `vault_exception.dart`

Exception types for vault operations.

**Types:**

- `encryptionFailed` - Encryption operation failed
- `decryptionFailed` - Wrong PIN or corrupted data
- `storageFailed` - Storage read/write error
- `vaultEmpty` - No wallet stored
- `vaultNotEmpty` - Wallet already exists
- `invalidPin` - Invalid PIN format
- `dataCorrupted` - Data corruption detected
- `keyDerivationFailed` - Key derivation failed

## Security Features

### 1. Encryption

**AES-256-GCM:**

- 256-bit key (AES-256)
- GCM mode (authenticated encryption)
- Prevents tampering (authentication tag)
- Industry standard

**PBKDF2:**

- 100,000 iterations (slows brute-force)
- SHA-256 hash function
- 32-byte salt (prevents rainbow tables)
- 32-byte output (256-bit key)

### 2. Storage

**flutter_secure_storage:**

- iOS: Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android: EncryptedSharedPreferences with AES-256-GCM
- Platform-level encryption
- Secure by default

### 3. Memory Security

**Sensitive Data Clearing:**

- Encryption keys cleared after use
- Plaintext cleared after encryption
- Decrypted data cleared by caller
- Reduces exposure window

### 4. Single Wallet Constraint

**Enforcement:**

- Single storage key
- Check before store
- Prevents multiple wallets
- Simplifies security model

## Security Decisions

### Why AES-256-GCM?

1. **Authenticated Encryption:** Provides both confidentiality and authenticity
2. **Tamper Detection:** Authentication tag prevents data modification
3. **Industry Standard:** Widely used and audited
4. **Performance:** Hardware acceleration on modern devices

### Why PBKDF2 with 100k Iterations?

1. **Slows Brute-Force:** Each PIN attempt takes ~100ms
2. **NIST Recommended:** Meets NIST SP 800-132 guidelines
3. **Balance:** Good security without excessive delay
4. **Compatibility:** Widely supported

### Why 32-Byte Salt?

1. **Rainbow Table Protection:** Makes precomputed attacks impractical
2. **NIST Recommended:** Exceeds minimum 16-byte requirement
3. **Unique Per Wallet:** Each wallet has unique salt

### Why 12-Byte IV?

1. **GCM Standard:** 96-bit IV is standard for GCM mode
2. **Collision Resistance:** 2^96 unique IVs before collision risk
3. **Performance:** Optimal for GCM mode

### Why Not Store PIN?

1. **Security:** PIN only used for key derivation
2. **Zero Knowledge:** Server/storage never sees PIN
3. **Brute-Force Protection:** Attacker must try each PIN

### Why Not Store Encryption Key?

1. **Security:** Key derived on-demand from PIN
2. **Memory Safety:** Key exists only during encryption/decryption
3. **Compromise Resistance:** Stolen storage doesn't reveal key

## Storage Structure

### Encrypted Wallet Data (JSON)

```json
{
    "ciphertext": "base64_encoded_ciphertext",
    "iv": "base64_encoded_iv",
    "salt": "base64_encoded_salt",
    "authTag": "base64_encoded_auth_tag"
}
```

### Storage Location

- **Key:** `encrypted_wallet`
- **Platform:**
    - iOS: Keychain
    - Android: EncryptedSharedPreferences

## Usage Examples

### Example 1: Store Mnemonic

```dart
final vault = SecureVault();
const mnemonic = 'abandon abandon abandon...';
const pin = '123456';

try {
  await vault.storeMnemonic(mnemonic, pin);
  print('Mnemonic stored successfully');
} on VaultException catch (e) {
  print('Error: ${e.message}');
}
```

### Example 2: Retrieve Mnemonic

```dart
final vault = SecureVault();
const pin = '123456';

try {
  final mnemonic = await vault.retrieveMnemonic(pin);
  print('Mnemonic: $mnemonic');

  // IMPORTANT: Clear mnemonic from memory after use
  // Use for key derivation, then clear
} on VaultException catch (e) {
  if (e.type == VaultExceptionType.decryptionFailed) {
    print('Wrong PIN');
  } else {
    print('Error: ${e.message}');
  }
}
```

### Example 3: Verify PIN

```dart
final vault = SecureVault();
const pin = '123456';

final isValid = await vault.verifyPin(pin);
if (isValid) {
  print('PIN correct');
} else {
  print('PIN incorrect');
}
```

### Example 4: Update PIN

```dart
final vault = SecureVault();
const oldPin = '123456';
const newPin = '654321';

try {
  await vault.updatePin(oldPin, newPin);
  print('PIN updated successfully');
} on VaultException catch (e) {
  print('Error: ${e.message}');
}
```

### Example 5: Complete Wallet Flow

```dart
final vault = SecureVault();
final walletEngine = WalletEngine();

// Create wallet
final createResult = walletEngine.createWallet();
print('Mnemonic: ${createResult.mnemonic}');
print('Address: ${createResult.address}');

// User confirms backup
const pin = '123456';

// Store encrypted mnemonic
await vault.storeMnemonic(createResult.mnemonic, pin);
print('Wallet stored securely');

// Later: Unlock wallet
final mnemonic = await vault.retrieveMnemonic(pin);
final importResult = walletEngine.importWallet(mnemonic);
print('Wallet unlocked: ${importResult.address}');

// Use wallet for signing
final privateKey = walletEngine.derivePrivateKey();
try {
  // Sign transaction
  final signature = signTransaction(privateKey);
} finally {
  // Clear private key
  SecureMemory.clear(privateKey);
}

// Lock wallet
walletEngine.clearSession();
```

## Testing

### Unit Tests

**Location:** `test/core/vault/`

**Coverage:**

- Encryption/decryption (AES-256-GCM)
- Key derivation (PBKDF2)
- PIN validation
- Storage operations
- Error handling
- Serialization
- Security properties

**Run Tests:**

```bash
flutter test test/core/vault/
```

### Test Scenarios

✅ Encrypt/decrypt round-trip
✅ Wrong PIN rejection
✅ Data corruption detection
✅ PIN format validation
✅ Salt/IV uniqueness
✅ Authentication tag verification
✅ JSON serialization
✅ Storage operations
✅ Single wallet constraint
✅ PIN update
✅ Memory clearing

## Security Audit Checklist

- [x] AES-256-GCM encryption
- [x] PBKDF2 key derivation (100k iterations)
- [x] Random salt (32 bytes)
- [x] Random IV (12 bytes)
- [x] Authentication tag (16 bytes)
- [x] PIN never stored
- [x] Encryption key never stored
- [x] Memory clearing after use
- [x] Platform secure storage
- [x] Single wallet constraint
- [x] Error handling without data leakage
- [x] Comprehensive unit tests

## Performance

### Encryption

- **Time:** ~100ms (PBKDF2 dominates)
- **Memory:** ~1KB (temporary buffers)
- **Storage:** ~500 bytes (encrypted data)

### Decryption

- **Time:** ~100ms (PBKDF2 dominates)
- **Memory:** ~1KB (temporary buffers)

### PBKDF2 Iterations

- **100k iterations:** ~100ms on modern devices
- **Trade-off:** Security vs. user experience
- **Acceptable:** <200ms for authentication

## Dependencies

```yaml
dependencies:
    flutter_secure_storage: ^9.2.2 # Platform secure storage
    pointycastle: ^3.9.1 # Cryptographic primitives
    crypto: ^3.0.3 # Hash functions
```

## Future Enhancements

1. **Biometric Authentication:** Add fingerprint/face unlock
2. **Hardware Security Module:** Use device HSM if available
3. **Key Rotation:** Periodic re-encryption with new keys
4. **Backup Encryption:** Encrypt backup files
5. **Multi-Device Sync:** Secure sync across devices
6. **Rate Limiting:** Limit PIN attempts
7. **Audit Logging:** Log security events

## References

- [NIST SP 800-132: PBKDF](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-132.pdf)
- [NIST SP 800-38D: GCM](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38d.pdf)
- [RFC 5869: HKDF](https://tools.ietf.org/html/rfc5869)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
