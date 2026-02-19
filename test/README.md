# Test Suite README

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Mock Files

The test suite uses Mockito for mocking. Generate mock files with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:

- `test/integration/wallet_integration_test.mocks.dart`
- `test/core/vault/secure_vault_test.mocks.dart`
- `test/features/wallet/presentation/controllers/wallet_lock_controller_test.mocks.dart`

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test Files

```bash
# Integration tests
flutter test test/integration/wallet_integration_test.dart

# Core crypto tests
flutter test test/core/crypto/wallet_engine_test.dart
flutter test test/core/crypto/bip39_service_test.dart

# Vault tests
flutter test test/core/vault/encryption_service_test.dart
flutter test test/core/vault/secure_vault_test.dart

# Transaction tests
flutter test test/features/transaction/domain/services/transaction_signer_test.dart

# Wallet lock tests
flutter test test/features/wallet/presentation/controllers/wallet_lock_controller_test.dart
```

### Run Tests by Category

```bash
# All unit tests
flutter test test/core/ test/features/

# All integration tests
flutter test test/integration/
```

### Run with Coverage

```bash
flutter test --coverage
```

### View Coverage Report

```bash
# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser (macOS)
open coverage/html/index.html

# Open in browser (Linux)
xdg-open coverage/html/index.html
```

## Test Structure

```
test/
├── core/
│   ├── crypto/
│   │   ├── wallet_engine_test.dart
│   │   └── bip39_service_test.dart
│   └── vault/
│       ├── encryption_service_test.dart
│       └── secure_vault_test.dart
├── features/
│   ├── transaction/
│   │   └── domain/
│   │       └── services/
│   │           └── transaction_signer_test.dart
│   └── wallet/
│       └── presentation/
│           └── controllers/
│               └── wallet_lock_controller_test.dart
├── integration/
│   └── wallet_integration_test.dart
└── README.md
```

## Test Categories

### Unit Tests (180+ tests)

- Core crypto functionality
- Encryption/decryption
- Transaction signing
- Wallet lock management

### Integration Tests (20+ tests)

- End-to-end wallet flows
- MetaMask compatibility
- BIP44 compliance
- Security properties

## Key Test Scenarios

### 1. Mnemonic Generation

- Generates 24-word mnemonics
- All mnemonics are unique
- All mnemonics pass validation

### 2. MetaMask Compatibility

- Import produces same addresses as MetaMask
- Derivation path: `m/44'/60'/0'/0/index`
- Known test vector verified

### 3. Encryption Security

- AES-256-GCM encryption
- PBKDF2 key derivation (100k iterations)
- Round-trip preserves data
- Wrong PIN rejected

### 4. Transaction Signing

- EIP-155 replay protection
- Deterministic signatures
- Private key cleanup
- Address validation

## Troubleshooting

### Mock Files Not Found

If you see errors about missing `.mocks.dart` files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Runner Issues

If build_runner fails:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test Failures

If tests fail:

1. Check Flutter version: `flutter --version`
2. Update dependencies: `flutter pub upgrade`
3. Clean build: `flutter clean && flutter pub get`
4. Regenerate mocks: `flutter pub run build_runner build --delete-conflicting-outputs`

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
    test:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v2
            - uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.8.1"
            - run: flutter pub get
            - run: flutter pub run build_runner build --delete-conflicting-outputs
            - run: flutter test --coverage
            - run: flutter analyze
```

## Test Coverage Goals

- Overall: > 85%
- Core Crypto: > 95%
- Vault: > 95%
- Transaction: > 90%
- Wallet Lock: > 85%

## Writing New Tests

### Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Name', () {
    late YourClass instance;

    setUp(() {
      instance = YourClass();
    });

    tearDown(() {
      // Cleanup
    });

    test('should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = instance.doSomething(input);

      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Mock Template

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([YourDependency])
import 'your_test.mocks.dart';

void main() {
  late MockYourDependency mockDependency;

  setUp(() {
    mockDependency = MockYourDependency();
  });

  test('should use mock', () {
    // Setup mock behavior
    when(mockDependency.method(any)).thenReturn('mocked');

    // Use mock
    final result = mockDependency.method('input');

    // Verify
    expect(result, equals('mocked'));
    verify(mockDependency.method('input')).called(1);
  });
}
```

## Best Practices

1. **Test Naming**: Use descriptive names that explain what is being tested
2. **Arrange-Act-Assert**: Follow AAA pattern for clarity
3. **One Assertion**: Focus each test on one specific behavior
4. **Mock External Dependencies**: Use mocks for external services
5. **Test Edge Cases**: Include boundary values and error conditions
6. **Clean Up**: Use tearDown to clean up resources
7. **Deterministic**: Tests should produce same results every time

## Security Testing

### Critical Security Tests

- Private key never stored
- Private key cleared after use
- Mnemonic encrypted before storage
- PIN validation enforced
- Wrong PIN rejected
- EIP-155 replay protection

### Running Security Tests

```bash
# Run all security-related tests
flutter test --tags security

# Run specific security test
flutter test test/integration/wallet_integration_test.dart --name "Private key cleanup"
```

## Performance Testing

### Benchmarking

```bash
# Run with profiling
flutter test --profile

# Measure specific operations
flutter test test/core/crypto/ --name "performance"
```

## Documentation

- [Test Coverage Summary](../TEST_COVERAGE_SUMMARY.md)
- [Implementation Summary](../IMPLEMENTATION_SUMMARY.md)
- [Vault Implementation](../VAULT_IMPLEMENTATION_SUMMARY.md)
- [Transaction Signing](../TRANSACTION_SIGNING_IMPLEMENTATION_SUMMARY.md)

## Support

For issues or questions:

1. Check existing test files for examples
2. Review test documentation
3. Check Flutter test documentation: https://docs.flutter.dev/testing
4. Check Mockito documentation: https://pub.dev/packages/mockito
