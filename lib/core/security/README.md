# Security Module

## Overview

The security module provides core security utilities for the wallet application, including PIN validation, secure random number generation, and secure memory management.

## Components

### PIN Validator (`pin_validator.dart`)

**Responsibility**: Validates PIN strength and format.

**Rules**:

- PIN must be 6 digits minimum
- No sequential patterns (123456, 654321)
- No repeated patterns (111111, 000000)
- No common PINs (123456, 000000, 111111)

**Usage**:

```dart
final validator = PinValidator();
final result = validator.validate('123456');
if (!result.isValid) {
  print(result.error);
}
```

### Secure Random (`secure_random.dart`)

**Responsibility**: Generates cryptographically secure random numbers.

**Rules**:

- Uses platform-specific secure random source
- Never use Dart's Random() for cryptographic operations
- Suitable for key generation and nonce creation

**Usage**:

```dart
final random = SecureRandom();
final bytes = random.nextBytes(32); // 256-bit random
```

### Secure Memory (`secure_memory.dart`)

**Responsibility**: Manages sensitive data in memory with automatic clearing.

**Rules**:

- Automatically clears sensitive data when disposed
- Overwrites memory with zeros
- Use for temporary storage of keys and mnemonics

**Usage**:

```dart
final memory = SecureMemory<String>('sensitive_data');
try {
  // Use memory.value
  print(memory.value);
} finally {
  memory.dispose(); // Clears memory
}
```

## Security Best Practices

1. **Never log sensitive data**: No mnemonic, private key, or PIN in logs
2. **Clear memory immediately**: Use SecureMemory for temporary sensitive data
3. **Validate all inputs**: Use PinValidator before cryptographic operations
4. **Use secure random**: Always use SecureRandom for cryptographic operations
5. **Fail securely**: Never expose error details that could aid attackers

## Testing

All security components must have 100% test coverage:

```
test/core/security/
├── pin_validator_test.dart
├── secure_random_test.dart
└── secure_memory_test.dart
```

## Security Audit Notes

- PIN validation prevents weak PINs
- Secure random uses platform-specific sources
- Memory clearing verified in tests
- No sensitive data exposure in error messages
