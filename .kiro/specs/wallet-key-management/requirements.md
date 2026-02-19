# Requirements Document: Wallet Key Management System

## Introduction

This document specifies the requirements for a secure, production-grade wallet key management system for a Flutter mobile application. The system provides cryptographic key generation, secure storage, and key derivation for an EVM-compatible, non-custodial cryptocurrency wallet. The design prioritizes security, auditability, and compliance with industry standards (BIP39, BIP32, BIP44).

## Glossary

- **Wallet_System**: The complete wallet key management system
- **Key_Generator**: Component responsible for generating cryptographic keys and mnemonics
- **Storage_Manager**: Component responsible for secure storage operations using flutter_secure_storage
- **Encryption_Service**: Component responsible for encrypting and decrypting sensitive data
- **Derivation_Service**: Component responsible for deriving keys according to BIP32/BIP44 standards
- **Authentication_Service**: Component responsible for PIN validation and user authentication
- **Mnemonic**: A 24-word phrase (256-bit entropy) representing the wallet seed according to BIP39
- **Private_Key**: The cryptographic private key derived from the mnemonic, never stored in plaintext
- **Encrypted_Mnemonic**: The mnemonic encrypted with AES-256 using a PIN-derived key
- **PIN**: User-chosen numeric code used to derive encryption keys via PBKDF2
- **Derivation_Path**: The BIP44 path m/44'/60'/0'/0/0 for EVM wallet key derivation
- **Salt**: Random data used in PBKDF2 key derivation
- **EVM**: Ethereum Virtual Machine, the target blockchain compatibility

## Requirements

### Requirement 1: Mnemonic Generation

**User Story:** As a new user, I want to create a new wallet with a secure mnemonic, so that I can safely store and recover my cryptocurrency assets.

#### Acceptance Criteria

1. WHEN a user initiates wallet creation, THE Key_Generator SHALL generate a 24-word mnemonic using 256 bits of cryptographically secure random entropy
2. WHEN generating entropy, THE Key_Generator SHALL use a cryptographically secure random number generator appropriate for the platform
3. WHEN converting entropy to mnemonic, THE Key_Generator SHALL follow the BIP39 standard specification exactly
4. WHEN a mnemonic is generated, THE Key_Generator SHALL validate that the mnemonic is valid according to BIP39 checksum rules
5. THE Key_Generator SHALL never log or persist the mnemonic in plaintext during generation

### Requirement 2: Mnemonic Import

**User Story:** As a user with an existing wallet, I want to import my wallet using my 24-word mnemonic, so that I can access my assets on this device.

#### Acceptance Criteria

1. WHEN a user provides a mnemonic for import, THE Wallet_System SHALL accept exactly 24 words as input
2. WHEN validating an imported mnemonic, THE Wallet_System SHALL verify the mnemonic against BIP39 word list and checksum rules
3. IF an imported mnemonic fails validation, THEN THE Wallet_System SHALL reject the import and return a descriptive error without storing any data
4. WHEN a valid mnemonic is imported, THE Wallet_System SHALL normalize the mnemonic (lowercase, single spaces) before processing
5. THE Wallet_System SHALL never log or persist the imported mnemonic in plaintext

### Requirement 3: PIN-Based Encryption

**User Story:** As a user, I want to protect my wallet with a PIN, so that my mnemonic is encrypted and cannot be accessed without my PIN.

#### Acceptance Criteria

1. WHEN a user sets a PIN, THE Wallet_System SHALL require the PIN to be between 4 and 8 digits
2. WHEN encrypting a mnemonic, THE Encryption_Service SHALL generate a cryptographically secure random salt of at least 16 bytes
3. WHEN deriving an encryption key from a PIN, THE Encryption_Service SHALL use PBKDF2 with at least 100,000 iterations
4. WHEN deriving an encryption key, THE Encryption_Service SHALL use SHA-256 as the PBKDF2 hash function
5. WHEN encrypting a mnemonic, THE Encryption_Service SHALL use AES-256 in CBC or GCM mode
6. WHEN encrypting a mnemonic, THE Encryption_Service SHALL generate a unique initialization vector (IV) for each encryption operation
7. THE Encryption_Service SHALL store the salt and IV alongside the encrypted mnemonic for decryption

### Requirement 4: Secure Storage

**User Story:** As a user, I want my encrypted wallet data stored securely on my device, so that it cannot be accessed by other applications or unauthorized parties.

#### Acceptance Criteria

1. WHEN storing encrypted data, THE Storage_Manager SHALL use flutter_secure_storage exclusively
2. WHEN storing the encrypted mnemonic, THE Storage_Manager SHALL store it with a unique, non-guessable key identifier
3. WHEN storing encryption metadata, THE Storage_Manager SHALL store the salt and IV separately from the encrypted mnemonic
4. THE Storage_Manager SHALL never store the PIN, private key, or plaintext mnemonic
5. WHEN the wallet is deleted, THE Storage_Manager SHALL securely remove all stored data including encrypted mnemonic, salt, and IV
6. THE Storage_Manager SHALL provide atomic operations to prevent partial writes during storage failures

### Requirement 5: Key Derivation

**User Story:** As a developer, I want to derive EVM-compatible private keys from the mnemonic, so that the wallet can sign transactions on EVM chains.

#### Acceptance Criteria

1. WHEN deriving a seed from a mnemonic, THE Derivation_Service SHALL use BIP39 seed derivation with an empty passphrase
2. WHEN deriving keys from a seed, THE Derivation_Service SHALL follow the BIP32 hierarchical deterministic key derivation specification
3. WHEN deriving the wallet private key, THE Derivation_Service SHALL use the BIP44 derivation path m/44'/60'/0'/0/0 exactly
4. WHEN a private key is derived, THE Derivation_Service SHALL hold it in memory only for the duration of the operation
5. WHEN key derivation is complete, THE Derivation_Service SHALL securely clear the mnemonic and seed from memory
6. THE Derivation_Service SHALL derive the corresponding public key and Ethereum address from the private key

### Requirement 6: Wallet Authentication

**User Story:** As a user, I want to unlock my wallet with my PIN, so that I can access my wallet and sign transactions.

#### Acceptance Criteria

1. WHEN a user enters a PIN to unlock the wallet, THE Authentication_Service SHALL retrieve the encrypted mnemonic, salt, and IV from storage
2. WHEN authenticating, THE Authentication_Service SHALL derive the decryption key using the provided PIN and stored salt with identical PBKDF2 parameters used during encryption
3. WHEN decrypting the mnemonic, THE Encryption_Service SHALL attempt decryption and validate the result
4. IF decryption fails or produces invalid data, THEN THE Authentication_Service SHALL reject the authentication attempt and return an error
5. WHEN authentication succeeds, THE Wallet_System SHALL derive the private key and make it available for the current session only
6. WHEN the session ends, THE Wallet_System SHALL securely clear all decrypted sensitive data from memory

### Requirement 7: Single Wallet Constraint

**User Story:** As a user, I want the system to enforce a single wallet per device, so that the security model remains simple and auditable.

#### Acceptance Criteria

1. WHEN checking wallet existence, THE Wallet_System SHALL determine if an encrypted mnemonic already exists in storage
2. WHEN a wallet already exists, THE Wallet_System SHALL prevent creation of a new wallet without explicit deletion of the existing wallet
3. WHEN a wallet already exists, THE Wallet_System SHALL prevent import of a different wallet without explicit deletion of the existing wallet
4. WHEN deleting a wallet, THE Wallet_System SHALL require explicit user confirmation
5. THE Wallet_System SHALL provide a clear status indicating whether a wallet exists on the device

### Requirement 8: Security Constraints

**User Story:** As a security auditor, I want the system to enforce strict security constraints, so that the wallet is resistant to common attack vectors.

#### Acceptance Criteria

1. THE Wallet_System SHALL never store the private key in any form (plaintext or encrypted)
2. THE Wallet_System SHALL never store the mnemonic in plaintext
3. THE Wallet_System SHALL never log the mnemonic, private key, or PIN to any logging system
4. THE Wallet_System SHALL never transmit the mnemonic or private key over any network
5. WHEN sensitive data is no longer needed, THE Wallet_System SHALL overwrite the memory containing that data before deallocation
6. THE Wallet_System SHALL validate all cryptographic operations and handle errors securely without leaking sensitive information
7. THE Wallet_System SHALL use constant-time comparison for PIN validation to prevent timing attacks

### Requirement 9: Error Handling

**User Story:** As a user, I want clear error messages when operations fail, so that I understand what went wrong without exposing sensitive information.

#### Acceptance Criteria

1. WHEN a cryptographic operation fails, THE Wallet_System SHALL return a descriptive error code without exposing sensitive data
2. WHEN validation fails, THE Wallet_System SHALL provide user-friendly error messages indicating what validation failed
3. WHEN storage operations fail, THE Wallet_System SHALL handle errors gracefully and maintain data consistency
4. IF the encrypted mnemonic is corrupted, THEN THE Wallet_System SHALL detect this during decryption and inform the user
5. THE Wallet_System SHALL distinguish between authentication failures (wrong PIN) and system errors (storage failure, corruption)

### Requirement 10: Architecture and Testability

**User Story:** As a developer, I want the system to follow clean architecture principles, so that the code is maintainable, testable, and auditable.

#### Acceptance Criteria

1. THE Wallet_System SHALL separate concerns into distinct layers: core, domain, data, and presentation
2. THE Wallet_System SHALL implement all cryptographic operations as pure functions where possible for testability
3. THE Wallet_System SHALL use dependency injection to allow mocking of platform-specific components during testing
4. THE Wallet_System SHALL provide interfaces for all external dependencies (storage, random number generation)
5. THE Wallet_System SHALL implement the domain layer without dependencies on Flutter framework or external packages
6. WHERE GetX state management is used, THE Wallet_System SHALL isolate state management in the presentation layer only

### Requirement 11: Mnemonic Display and Backup

**User Story:** As a user, I want to view my mnemonic after wallet creation, so that I can write it down and store it safely offline.

#### Acceptance Criteria

1. WHEN a wallet is created, THE Wallet_System SHALL display the generated mnemonic to the user exactly once
2. WHEN displaying the mnemonic, THE Wallet_System SHALL present all 24 words in order with clear numbering
3. WHEN the user confirms they have backed up the mnemonic, THE Wallet_System SHALL proceed to encrypt and store it
4. THE Wallet_System SHALL provide a mechanism to re-display the mnemonic only after successful PIN authentication
5. WHEN displaying the mnemonic for backup, THE Wallet_System SHALL warn the user about security risks of screenshots or digital copies

### Requirement 12: Wallet Recovery Verification

**User Story:** As a user, I want to verify my mnemonic backup, so that I can ensure I have correctly recorded my recovery phrase.

#### Acceptance Criteria

1. WHEN a user initiates backup verification, THE Wallet_System SHALL prompt the user to enter their mnemonic
2. WHEN verifying a mnemonic, THE Wallet_System SHALL compare the entered mnemonic with the stored encrypted mnemonic after decryption
3. IF the entered mnemonic matches, THEN THE Wallet_System SHALL confirm successful verification
4. IF the entered mnemonic does not match, THEN THE Wallet_System SHALL inform the user and allow retry
5. THE Wallet_System SHALL require PIN authentication before allowing mnemonic verification

### Requirement 13: Cryptographic Standards Compliance

**User Story:** As a security auditor, I want the system to strictly comply with BIP39, BIP32, and BIP44 standards, so that the wallet is interoperable and follows industry best practices.

#### Acceptance Criteria

1. THE Key_Generator SHALL implement BIP39 mnemonic generation exactly as specified in the standard
2. THE Derivation_Service SHALL implement BIP32 hierarchical deterministic key derivation exactly as specified in the standard
3. THE Derivation_Service SHALL implement BIP44 multi-account hierarchy exactly as specified in the standard
4. THE Wallet_System SHALL use the BIP39 English word list without modifications
5. THE Wallet_System SHALL generate mnemonics that are compatible with other BIP39-compliant wallets
6. THE Wallet_System SHALL derive keys that produce identical addresses as other BIP44-compliant EVM wallets using the same mnemonic
