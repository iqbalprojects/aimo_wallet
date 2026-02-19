# Test Migration Guide

## Overview

This guide helps you update tests after the security refactoring that removed global state from `WalletEngine` and refactored controllers.

## WalletEngine Test Updates

### Removed Methods - Delete These Tests

```dart
// ❌ DELETE - Method removed
test('should get current address', () {
  final result = walletEngine.createWallet();
  final address = walletEngine.getCurrentAddress();
  expect(address, equals(result.address));
});

// ❌ DELETE - Method removed
test('should derive private key for current account', () {
  walletEngine.createWallet();
  final privateKey = walletEngine.derivePrivateKey();
  expect(privateKey.length, equals(32));
});

// ❌ DELETE - Method removed
test('should clear session', () {
  walletEngine.createWallet();
  walletEngine.clearSession();
  expect(() => walletEngine.getCurrentAddress(), throwsStateError);
});
```

### Updated Methods - Modify These Tests

```dart
// ✅ UPDATE - Now requires mnemonic parameter
test('should derive account at index 0', () {
  final result = walletEngine.createWallet();
  final mnemonic = result.mnemonic;

  // OLD: final account = walletEngine.deriveAccount(mnemonic, 0);
  // NEW: Same, but mnemonic must be from createWallet result
  final account = walletEngine.deriveAccount(mnemonic, 0);

  expect(account.address, equals(result.address));
  expect(account.index, equals(0));
});

// ✅ UPDATE - Now requires mnemonic parameter
test('should derive private key for account', () {
  final result = walletEngine.createWallet();
  final mnemonic = result.mnemonic;

  // OLD: walletEngine.importWallet(mnemonic);
  //      final privateKey = walletEngine.derivePrivateKey();
  // NEW: Pass mnemonic directly
  final privateKey = walletEngine.derivePrivateKeyForAccount(mnemonic);

  expect(privateKey.length, equals(32));
});
```

## WalletLockController Test Updates

### Biometric Authentication

```dart
// ✅ UPDATE - Method renamed and behavior changed
test('should authenticate with biometric', () async {
  // Setup
  when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
  when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
  when(mockLocalAuth.authenticate(
    localizedReason: anyNamed('localizedReason'),
    options: anyNamed('options'),
  )).thenAnswer((_) async => true);

  await controller.enableBiometric();

  // OLD: final result = await controller.unlockWithBiometric();
  //      expect(controller.isUnlocked, isTrue);

  // NEW: Biometric auth doesn't unlock, just authenticates
  final result = await controller.authenticateWithBiometric();
  expect(result, isTrue);
  expect(controller.isLocked, isTrue);  // Still locked!

  // Must still call unlock with PIN
  await controller.unlock(testPin);
  expect(controller.isUnlocked, isTrue);
});
```

### Execute With Private Key

```dart
// ✅ UPDATE - Added accountIndex parameter
test('should execute operation with private key', () async {
  // Setup vault and unlock
  await setupVaultWithWallet();
  await controller.unlock(testPin);

  // OLD: final result = await controller.executeWithPrivateKey(
  //        (privateKey) async => privateKey.length,
  //        pin: testPin,
  //      );

  // NEW: Can specify account index
  final result = await controller.executeWithPrivateKey(
    (privateKey) async => privateKey.length,
    pin: testPin,
    accountIndex: 0,  // Optional, defaults to 0
  );

  expect(result, equals(32));
});
```

## SecureVault Test Updates

### Store Mnemonic with Address

```dart
// ✅ UPDATE - Added optional address parameter
test('should store mnemonic with address', () async {
  const mnemonic = 'test mnemonic...';
  const pin = '123456';
  const address = '0x1234...';

  // OLD: await vault.storeMnemonic(mnemonic, pin);

  // NEW: Can provide address for caching
  await vault.storeMnemonic(mnemonic, pin, address: address);

  // Verify address cached
  final cachedAddress = await vault.getWalletAddress();
  expect(cachedAddress, equals(address));
});
```

### Delete Wallet

```dart
// ✅ UPDATE - Now deletes cached address too
test('should delete wallet and cached address', () async {
  // Setup
  await vault.storeMnemonic(testMnemonic, testPin, address: testAddress);

  // Delete
  await vault.deleteWallet();

  // Verify both deleted
  expect(await vault.hasWallet(), isFalse);
  expect(await vault.getWalletAddress(), isNull);  // NEW: Check address deleted
});
```

### New Tests to Add

```dart
// ✅ ADD - Test address caching
test('should cache wallet address', () async {
  const address = '0x1234...';

  await vault.storeMnemonic(testMnemonic, testPin, address: address);

  final cachedAddress = await vault.getWalletAddress();
  expect(cachedAddress, equals(address));
});

test('should retrieve address without decryption', () async {
  await vault.storeMnemonic(testMnemonic, testPin, address: testAddress);

  // Should not require PIN
  final address = await vault.getWalletAddress();
  expect(address, equals(testAddress));
});
```

## WalletController Test Updates

### Complete Rewrite Required

The `WalletController` was completely refactored. Here's the new test structure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';

@GenerateMocks([SecureVault, WalletEngine])
void main() {
  late WalletController controller;
  late MockSecureVault mockVault;
  late MockWalletEngine mockWalletEngine;

  setUp(() {
    mockVault = MockSecureVault();
    mockWalletEngine = MockWalletEngine();
    controller = WalletController(
      vault: mockVault,
      walletEngine: mockWalletEngine,
    );
  });

  group('Initialization', () {
    test('should initialize with notCreated status when no wallet', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => false);

      await controller.onInit();

      expect(controller.status, equals(WalletStatus.notCreated));
      expect(controller.address, isNull);
    });

    test('should initialize with locked status when wallet exists', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => true);
      when(mockVault.getWalletAddress()).thenAnswer((_) async => '0x123...');

      await controller.onInit();

      expect(controller.status, equals(WalletStatus.locked));
      expect(controller.address, equals('0x123...'));
    });
  });

  group('Create Wallet', () {
    test('should create wallet and return mnemonic', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => false);
      when(mockWalletEngine.createWallet()).thenReturn(
        WalletCreationResult(
          mnemonic: 'test mnemonic...',
          address: '0x123...',
        ),
      );
      when(mockVault.storeMnemonic(any, any, address: anyNamed('address')))
          .thenAnswer((_) async => {});

      final mnemonic = await controller.createWallet('123456');

      expect(mnemonic, equals('test mnemonic...'));
      expect(controller.status, equals(WalletStatus.locked));
      expect(controller.address, equals('0x123...'));

      verify(mockVault.storeMnemonic(
        'test mnemonic...',
        '123456',
        address: '0x123...',
      )).called(1);
    });

    test('should enforce single wallet constraint', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => true);

      final mnemonic = await controller.createWallet('123456');

      expect(mnemonic, isNull);
      expect(controller.errorMessage, contains('already exists'));
      verifyNever(mockWalletEngine.createWallet());
    });
  });

  group('Import Wallet', () {
    test('should import valid wallet', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => false);
      when(mockWalletEngine.importWallet(any)).thenReturn(
        WalletImportResult(
          address: '0x123...',
          isValid: true,
        ),
      );
      when(mockVault.storeMnemonic(any, any, address: anyNamed('address')))
          .thenAnswer((_) async => {});

      final success = await controller.importWallet('test mnemonic...', '123456');

      expect(success, isTrue);
      expect(controller.status, equals(WalletStatus.locked));
      expect(controller.address, equals('0x123...'));
    });

    test('should reject invalid mnemonic', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => false);
      when(mockWalletEngine.importWallet(any)).thenReturn(
        WalletImportResult(
          address: '',
          isValid: false,
          error: 'Invalid mnemonic',
        ),
      );

      final success = await controller.importWallet('invalid', '123456');

      expect(success, isFalse);
      expect(controller.errorMessage, contains('Invalid'));
      verifyNever(mockVault.storeMnemonic(any, any, address: anyNamed('address')));
    });

    test('should enforce single wallet constraint', () async {
      when(mockVault.hasWallet()).thenAnswer((_) async => true);

      final success = await controller.importWallet('test mnemonic...', '123456');

      expect(success, isFalse);
      expect(controller.errorMessage, contains('already exists'));
    });
  });

  group('Delete Wallet', () {
    test('should delete wallet', () async {
      when(mockVault.deleteWallet()).thenAnswer((_) async => {});

      final success = await controller.deleteWallet();

      expect(success, isTrue);
      expect(controller.status, equals(WalletStatus.notCreated));
      expect(controller.address, isNull);
      verify(mockVault.deleteWallet()).called(1);
    });
  });
}
```

## Integration Test Updates

### Wallet Creation Flow

```dart
// ✅ UPDATE - Use new WalletController API
test('complete wallet creation flow', () async {
  final walletController = WalletController();
  final lockController = WalletLockController();

  // Create wallet
  final mnemonic = await walletController.createWallet('123456');
  expect(mnemonic, isNotNull);
  expect(walletController.status, equals(WalletStatus.locked));

  // Unlock wallet
  await lockController.unlock('123456');
  expect(lockController.isUnlocked, isTrue);

  // Sign transaction
  final signature = await lockController.executeWithPrivateKey(
    (privateKey) async {
      // Sign with private key
      return signTransaction(transaction, privateKey);
    },
    pin: '123456',
  );

  expect(signature, isNotNull);
});
```

## Quick Reference: API Changes

### WalletEngine

| Old API                          | New API                                | Notes             |
| -------------------------------- | -------------------------------------- | ----------------- |
| `getCurrentAddress()`            | `deriveAccount(mnemonic, 0).address`   | Requires mnemonic |
| `derivePrivateKey()`             | `derivePrivateKeyForAccount(mnemonic)` | Requires mnemonic |
| `clearSession()`                 | _(removed)_                            | No longer needed  |
| `deriveAccount(mnemonic, index)` | _(same)_                               | No change         |

### SecureVault

| Old API                 | New API                            | Notes                   |
| ----------------------- | ---------------------------------- | ----------------------- |
| `storeMnemonic(m, pin)` | `storeMnemonic(m, pin, {address})` | Optional address        |
| _(none)_                | `getWalletAddress()`               | New method              |
| `deleteWallet()`        | _(same)_                           | Now deletes address too |

### WalletLockController

| Old API                            | New API                                          | Notes              |
| ---------------------------------- | ------------------------------------------------ | ------------------ |
| `unlockWithBiometric()`            | `authenticateWithBiometric()`                    | Doesn't unlock     |
| `executeWithPrivateKey(op, {pin})` | `executeWithPrivateKey(op, {pin, accountIndex})` | Added accountIndex |

### WalletController

| Old API                     | New API                       | Notes                    |
| --------------------------- | ----------------------------- | ------------------------ |
| `updateWalletState(wallet)` | `updateStatus(status)`        | Simplified               |
| `lockWallet()`              | _(removed)_                   | Use WalletLockController |
| _(none)_                    | `createWallet(pin)`           | New method               |
| _(none)_                    | `importWallet(mnemonic, pin)` | New method               |
| _(none)_                    | `deleteWallet()`              | New method               |

## Running Tests

After updating tests, run:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/crypto/wallet_engine_test.dart

# Run with coverage
flutter test --coverage

# Generate mocks (if using mockito)
flutter pub run build_runner build
```

## Common Issues

### Issue: StateError when calling removed methods

**Solution**: Update code to pass mnemonic as parameter instead of relying on stored state.

### Issue: Biometric tests failing

**Solution**: Update tests to expect `authenticateWithBiometric()` to NOT unlock wallet. Add separate `unlock(pin)` call.

### Issue: Missing address in vault tests

**Solution**: Add `address` parameter when calling `storeMnemonic()`.

### Issue: WalletController tests failing

**Solution**: Complete rewrite required. Use new test structure from this guide.

## Need Help?

If you encounter issues not covered in this guide:

1. Check `SECURITY_REFACTORING_SUMMARY.md` for detailed API changes
2. Review the updated implementation files
3. Look at example code in `example/` directory
4. Check integration tests for usage patterns
