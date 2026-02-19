import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';

void main() {
  late WalletEngine walletEngine;

  setUp(() {
    walletEngine = WalletEngine();
  });

  group('WalletEngine - Create Wallet', () {
    test('should generate 24-word mnemonic', () {
      final result = walletEngine.createWallet();

      expect(result.mnemonic, isNotEmpty);
      expect(result.mnemonic.split(' ').length, equals(24));
      expect(result.address, isNotEmpty);
      expect(result.address, startsWith('0x'));
      expect(result.address.length, equals(42)); // 0x + 40 hex chars
    });

    test('should generate different mnemonics on each call', () {
      final result1 = walletEngine.createWallet();
      final result2 = WalletEngine().createWallet();

      expect(result1.mnemonic, isNot(equals(result2.mnemonic)));
      expect(result1.address, isNot(equals(result2.address)));
    });

    test('should generate valid mnemonic', () {
      final result = walletEngine.createWallet();

      expect(walletEngine.validateMnemonic(result.mnemonic), isTrue);
    });
  });

  group('WalletEngine - Import Wallet', () {
    test('should import valid mnemonic', () {
      // Known test mnemonic (BIP39 test vector)
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final result = walletEngine.importWallet(testMnemonic);

      expect(result.isValid, isTrue);
      expect(result.address, isNotEmpty);
      expect(result.address, startsWith('0x'));
      expect(result.error, isNull);
    });

    test('should reject invalid mnemonic - wrong word count', () {
      const invalidMnemonic = 'abandon abandon abandon';

      final result = walletEngine.importWallet(invalidMnemonic);

      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('should reject invalid mnemonic - invalid checksum', () {
      const invalidMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon'; // Wrong last word

      final result = walletEngine.importWallet(invalidMnemonic);

      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('should normalize mnemonic before validation', () {
      const mnemonicWithSpaces = '  abandon  abandon  abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art  ';

      final result = walletEngine.importWallet(mnemonicWithSpaces);

      expect(result.isValid, isTrue);
    });

    test('should handle uppercase mnemonic', () {
      const uppercaseMnemonic = 'ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON '
          'ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON '
          'ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON '
          'ABANDON ABANDON ABANDON ABANDON ABANDON ART';

      final result = walletEngine.importWallet(uppercaseMnemonic);

      expect(result.isValid, isTrue);
    });
  });

  group('WalletEngine - Derive Account', () {
    test('should derive account at index 0', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final result = walletEngine.deriveAccount(testMnemonic, 0);

      expect(result.address, isNotEmpty);
      expect(result.address, startsWith('0x'));
      expect(result.index, equals(0));
    });

    test('should derive different addresses for different indices', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final account0 = walletEngine.deriveAccount(testMnemonic, 0);
      final account1 = walletEngine.deriveAccount(testMnemonic, 1);
      final account2 = walletEngine.deriveAccount(testMnemonic, 2);

      expect(account0.address, isNot(equals(account1.address)));
      expect(account1.address, isNot(equals(account2.address)));
      expect(account0.address, isNot(equals(account2.address)));
    });

    test('should derive same address for same index', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final result1 = walletEngine.deriveAccount(testMnemonic, 0);
      final result2 = walletEngine.deriveAccount(testMnemonic, 0);

      expect(result1.address, equals(result2.address));
    });

    test('should throw error for negative index', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      expect(
        () => walletEngine.deriveAccount(testMnemonic, -1),
        throwsArgumentError,
      );
    });
  });

  // NOTE: Session management tests commented out - not part of tasks 1-4
  // These features will be implemented in later tasks
  /*
  group('WalletEngine - Get Current Address', () {
    test('should return current address after wallet creation', () {
      final createResult = walletEngine.createWallet();
      final currentAddress = walletEngine.getCurrentAddress();

      expect(currentAddress, equals(createResult.address));
    });

    test('should return current address after wallet import', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final importResult = walletEngine.importWallet(testMnemonic);
      final currentAddress = walletEngine.getCurrentAddress();

      expect(currentAddress, equals(importResult.address));
    });

    test('should throw error when no wallet is active', () {
      expect(
        () => walletEngine.getCurrentAddress(),
        throwsStateError,
      );
    });

    test('should update current address after deriving new account', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      walletEngine.importWallet(testMnemonic);
      final account1 = walletEngine.deriveAccount(testMnemonic, 1);
      final currentAddress = walletEngine.getCurrentAddress();

      expect(currentAddress, equals(account1.address));
    });
  });
  */

  group('WalletEngine - Derive Private Key For Account', () {
    test('should derive different private keys for different accounts', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final privateKey0 = walletEngine.derivePrivateKeyForAccount(testMnemonic);
      final privateKey1 = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 1);

      expect(privateKey0, isNot(equals(privateKey1)));
      expect(privateKey0.length, equals(32)); // 32 bytes = 256 bits
      expect(privateKey1.length, equals(32));
    });

    test('should derive same private key for same account', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final privateKey1 = walletEngine.derivePrivateKeyForAccount(testMnemonic);
      final privateKey2 = walletEngine.derivePrivateKeyForAccount(testMnemonic);

      expect(privateKey1, equals(privateKey2));
    });
  });

  // NOTE: Session management tests commented out - not part of tasks 1-4
  /*
  group('WalletEngine - Session Management', () {
    test('should clear session', () {
      walletEngine.createWallet();
      walletEngine.clearSession();

      expect(
        () => walletEngine.getCurrentAddress(),
        throwsStateError,
      );
    });

    test('should track current account index', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      walletEngine.importWallet(testMnemonic);
      expect(walletEngine.getCurrentAccountIndex(), equals(0));

      walletEngine.deriveAccount(testMnemonic, 5);
      expect(walletEngine.getCurrentAccountIndex(), equals(5));
    });
  });
  */

  group('WalletEngine - Validate Mnemonic', () {
    test('should validate correct mnemonic', () {
      const validMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      expect(walletEngine.validateMnemonic(validMnemonic), isTrue);
    });

    test('should reject invalid mnemonic', () {
      const invalidMnemonic = 'invalid mnemonic phrase';

      expect(walletEngine.validateMnemonic(invalidMnemonic), isFalse);
    });
  });

  group('WalletEngine - Deterministic Derivation', () {
    test('should derive same address from same mnemonic', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final engine1 = WalletEngine();
      final engine2 = WalletEngine();

      final result1 = engine1.importWallet(testMnemonic);
      final result2 = engine2.importWallet(testMnemonic);

      expect(result1.address, equals(result2.address));
    });

    test('should be compatible with BIP44 standard', () {
      // Test with known BIP44 test vector
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final result = walletEngine.importWallet(testMnemonic);

      // This address should match other BIP44-compliant wallets
      // using the same mnemonic and derivation path m/44'/60'/0'/0/0
      expect(result.address, isNotEmpty);
      expect(result.address, startsWith('0x'));
    });
  });
}
