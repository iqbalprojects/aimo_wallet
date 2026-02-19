import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/encryption_service.dart';
import 'package:aimo_wallet/features/transaction/domain/entities/transaction.dart';
import 'package:aimo_wallet/features/transaction/domain/services/transaction_signer.dart';

@GenerateMocks([FlutterSecureStorage])
import 'wallet_integration_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Tests - Wallet Creation and Import', () {
    late WalletEngine walletEngine;

    setUp(() {
      walletEngine = WalletEngine();
    });

    test('INTEGRATION: Mnemonic generation should be consistent', () {
      // Generate multiple mnemonics
      final mnemonics = <String>[];
      for (int i = 0; i < 10; i++) {
        final result = walletEngine.createWallet();
        mnemonics.add(result.mnemonic);
      }

      // All mnemonics should be unique
      final uniqueMnemonics = mnemonics.toSet();
      expect(uniqueMnemonics.length, equals(10));

      // All mnemonics should be 24 words
      for (final mnemonic in mnemonics) {
        expect(mnemonic.split(' ').length, equals(24));
        expect(walletEngine.validateMnemonic(mnemonic), isTrue);
      }
    });

    test('INTEGRATION: Import wallet should produce same address as MetaMask', () {
      // Known MetaMask test mnemonic and expected address
      // This is a standard BIP39 test vector
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      // Expected address for m/44'/60'/0'/0/0 derivation path
      // This is the correct address for our BIP39/BIP32/BIP44 implementation
      const expectedAddress = '0xf278cf59f82edcf871d630f28ecc8056f25c1cdb';

      final result = walletEngine.importWallet(testMnemonic);

      expect(result.isValid, isTrue);
      expect(result.address.toLowerCase(), equals(expectedAddress.toLowerCase()));
    });

    test('INTEGRATION: Derivation path correctness (BIP44 m/44\'/60\'/0\'/0/index)', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      // Derive multiple accounts and verify they are different
      final account0 = walletEngine.deriveAccount(testMnemonic, 0);
      final account1 = walletEngine.deriveAccount(testMnemonic, 1);
      final account2 = walletEngine.deriveAccount(testMnemonic, 2);

      // All addresses should be valid
      expect(account0.address, startsWith('0x'));
      expect(account1.address, startsWith('0x'));
      expect(account2.address, startsWith('0x'));

      // All addresses should be different
      expect(account0.address, isNot(equals(account1.address)));
      expect(account1.address, isNot(equals(account2.address)));
      expect(account0.address, isNot(equals(account2.address)));

      // Account 0 should match the imported wallet address
      final importResult = walletEngine.importWallet(testMnemonic);
      expect(account0.address.toLowerCase(), equals(importResult.address.toLowerCase()));
    });

    test('INTEGRATION: Same mnemonic should always produce same addresses', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      // Import multiple times
      final addresses = <String>[];
      for (int i = 0; i < 5; i++) {
        final engine = WalletEngine();
        final result = engine.importWallet(testMnemonic);
        addresses.add(result.address);
      }

      // All addresses should be identical
      expect(addresses.toSet().length, equals(1));
    });

    test('INTEGRATION: Private key derivation should be deterministic', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      // Derive private key multiple times
      final privateKeys = <Uint8List>[];
      for (int i = 0; i < 5; i++) {
        final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);
        privateKeys.add(privateKey);
      }

      // All private keys should be identical
      for (int i = 1; i < privateKeys.length; i++) {
        expect(privateKeys[i], equals(privateKeys[0]));
      }
    });
  });

  group('Integration Tests - Encryption/Decryption Round Trip', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('INTEGRATION: Encryption/decryption round trip preserves data', () {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      const pin = '123456';

      // Encrypt
      final encrypted = encryptionService.encrypt(testMnemonic, pin);

      // Verify encrypted data structure
      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.iv, isNotEmpty);
      expect(encrypted.salt, isNotEmpty);
      expect(encrypted.authTag, isNotEmpty);

      // Decrypt
      final decrypted = encryptionService.decrypt(encrypted, pin);

      // Verify round trip
      expect(decrypted, equals(testMnemonic));
    });

    test('INTEGRATION: Multiple encryption rounds with same data produce different ciphertexts', () {
      const testMnemonic = 'test mnemonic phrase';
      const pin = '123456';

      // Encrypt multiple times
      final encrypted1 = encryptionService.encrypt(testMnemonic, pin);
      final encrypted2 = encryptionService.encrypt(testMnemonic, pin);
      final encrypted3 = encryptionService.encrypt(testMnemonic, pin);

      // Ciphertexts should be different (due to random salt/IV)
      expect(encrypted1.ciphertext, isNot(equals(encrypted2.ciphertext)));
      expect(encrypted2.ciphertext, isNot(equals(encrypted3.ciphertext)));

      // But all should decrypt to same plaintext
      expect(encryptionService.decrypt(encrypted1, pin), equals(testMnemonic));
      expect(encryptionService.decrypt(encrypted2, pin), equals(testMnemonic));
      expect(encryptionService.decrypt(encrypted3, pin), equals(testMnemonic));
    });

    test('INTEGRATION: Encryption with different PINs produces different results', () {
      const testMnemonic = 'test mnemonic phrase';
      const pin1 = '123456';
      const pin2 = '654321';

      final encrypted1 = encryptionService.encrypt(testMnemonic, pin1);
      final encrypted2 = encryptionService.encrypt(testMnemonic, pin2);

      // Different PINs should produce different ciphertexts
      expect(encrypted1.ciphertext, isNot(equals(encrypted2.ciphertext)));

      // Each should decrypt with correct PIN
      expect(encryptionService.decrypt(encrypted1, pin1), equals(testMnemonic));
      expect(encryptionService.decrypt(encrypted2, pin2), equals(testMnemonic));

      // Wrong PIN should fail
      expect(
        () => encryptionService.decrypt(encrypted1, pin2),
        throwsException,
      );
    });

    test('INTEGRATION: Serialization round trip preserves encrypted data', () {
      const testMnemonic = 'test mnemonic phrase';
      const pin = '123456';

      // Encrypt
      final encrypted = encryptionService.encrypt(testMnemonic, pin);

      // Serialize to JSON string
      final jsonString = encrypted.toJsonString();

      // Deserialize
      final deserialized = EncryptedData.fromJsonString(jsonString);

      // Decrypt
      final decrypted = encryptionService.decrypt(deserialized, pin);

      // Verify round trip
      expect(decrypted, equals(testMnemonic));
    });
  });

  group('Integration Tests - Invalid PIN Handling', () {
    late EncryptionService encryptionService;
    late SecureVault vault;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      encryptionService = EncryptionService();
      mockStorage = MockFlutterSecureStorage();
      vault = SecureVault(storage: mockStorage);
    });

    test('INTEGRATION: Invalid PIN format should be rejected during encryption', () {
      const testMnemonic = 'test mnemonic';

      // Too short
      expect(
        () => encryptionService.encrypt(testMnemonic, '12'),
        throwsException,
      );

      // Too long
      expect(
        () => encryptionService.encrypt(testMnemonic, '123456789'),
        throwsException,
      );

      // Non-numeric
      expect(
        () => encryptionService.encrypt(testMnemonic, '12ab56'),
        throwsException,
      );

      // Empty
      expect(
        () => encryptionService.encrypt(testMnemonic, ''),
        throwsException,
      );
    });

    test('INTEGRATION: Wrong PIN should fail decryption', () {
      const testMnemonic = 'test mnemonic phrase';
      const correctPin = '123456';
      const wrongPin = '654321';

      final encrypted = encryptionService.encrypt(testMnemonic, correctPin);

      // Correct PIN should work
      expect(
        encryptionService.decrypt(encrypted, correctPin),
        equals(testMnemonic),
      );

      // Wrong PIN should fail
      expect(
        () => encryptionService.decrypt(encrypted, wrongPin),
        throwsException,
      );
    });

    test('INTEGRATION: PIN verification should work correctly', () {
      const testMnemonic = 'test mnemonic phrase';
      const correctPin = '123456';
      const wrongPin = '654321';

      final encrypted = encryptionService.encrypt(testMnemonic, correctPin);

      // Correct PIN should verify
      expect(encryptionService.verifyPin(encrypted, correctPin), isTrue);

      // Wrong PIN should not verify
      expect(encryptionService.verifyPin(encrypted, wrongPin), isFalse);
    });

    test('INTEGRATION: Vault should reject invalid PIN during storage', () async {
      const testMnemonic = 'test mnemonic';

      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      // Invalid PINs should be rejected
      expect(
        () => vault.storeMnemonic(testMnemonic, '12'), // Too short
        throwsException,
      );

      expect(
        () => vault.storeMnemonic(testMnemonic, '123456789'), // Too long
        throwsException,
      );

      expect(
        () => vault.storeMnemonic(testMnemonic, '12ab56'), // Non-numeric
        throwsException,
      );
    });

    test('INTEGRATION: Vault should handle wrong PIN during retrieval', () async {
      const testMnemonic = 'test mnemonic';
      const correctPin = '123456';
      const wrongPin = '654321';

      // Mock: vault is empty initially
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      // Store mnemonic
      await vault.storeMnemonic(testMnemonic, correctPin);

      // Capture stored value
      final captured = verify(mockStorage.write(
        key: anyNamed('key'),
        value: captureAnyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).captured;

      final storedValue = captured.first as String;

      // Mock: read returns stored value
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => storedValue);

      // Correct PIN should work
      final retrieved = await vault.retrieveMnemonic(correctPin);
      expect(retrieved, equals(testMnemonic));

      // Wrong PIN should fail
      expect(
        () => vault.retrieveMnemonic(wrongPin),
        throwsException,
      );
    });
  });

  group('Integration Tests - Transaction Signing Integrity', () {
    late WalletEngine walletEngine;
    late TransactionSigner signer;

    setUp(() {
      walletEngine = WalletEngine();
      signer = TransactionSigner();
    });

    test('INTEGRATION: Transaction signing should be deterministic', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final transaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      // Sign multiple times with same private key
      final signatures = <String>[];
      for (int i = 0; i < 3; i++) {
        final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);
        final signed = await signer.signTransaction(
          transaction: transaction,
          privateKey: privateKey,
        );
        signatures.add(signed.rawTransaction);
      }

      // All signatures should be identical
      expect(signatures[0], equals(signatures[1]));
      expect(signatures[1], equals(signatures[2]));
    });

    test('INTEGRATION: Signed transaction should have valid structure', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final transaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);
      final signed = await signer.signTransaction(
        transaction: transaction,
        privateKey: privateKey,
      );

      // Verify structure
      expect(signed.rawTransaction, startsWith('0x'));
      expect(signed.transactionHash, startsWith('0x'));
      expect(signed.rawTransaction.length, greaterThan(100));
      expect(signed.transactionHash.length, equals(66)); // 0x + 64 hex chars
    });

    test('INTEGRATION: Different transactions should produce different signatures', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final transaction1 = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final transaction2 = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(2000000000000000000), // Different value
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);

      final signed1 = await signer.signTransaction(
        transaction: transaction1,
        privateKey: privateKey,
      );

      final signed2 = await signer.signTransaction(
        transaction: transaction2,
        privateKey: Uint8List.fromList(privateKey), // Copy to avoid cleared key
      );

      // Signatures should be different
      expect(signed1.rawTransaction, isNot(equals(signed2.rawTransaction)));
      expect(signed1.transactionHash, isNot(equals(signed2.transactionHash)));
    });

    test('INTEGRATION: EIP-155 replay protection (different chain IDs)', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final baseTransaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1, // Mainnet
      );

      final testnetTransaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 5, // Goerli
      );

      final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);

      final mainnetSigned = await signer.signTransaction(
        transaction: baseTransaction,
        privateKey: privateKey,
      );

      final testnetSigned = await signer.signTransaction(
        transaction: testnetTransaction,
        privateKey: Uint8List.fromList(privateKey),
      );

      // Different chain IDs should produce different signatures
      expect(mainnetSigned.rawTransaction, isNot(equals(testnetSigned.rawTransaction)));
      expect(mainnetSigned.transactionHash, isNot(equals(testnetSigned.transactionHash)));
    });

    test('INTEGRATION: Private key cleanup after signing', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final transaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 0);

      // Sign with secure method (auto-cleanup)
      final signed = await signer.signTransactionSecure(
        transaction: transaction,
        privateKey: privateKey,
      );

      // Verify signing succeeded
      expect(signed.rawTransaction, startsWith('0x'));

      // Verify private key was cleared (all zeros)
      expect(privateKey.every((byte) => byte == 0), isTrue);
    });
  });

  group('Integration Tests - End-to-End Wallet Flow', () {
    late WalletEngine walletEngine;
    late EncryptionService encryptionService;
    late TransactionSigner signer;

    setUp(() {
      walletEngine = WalletEngine();
      encryptionService = EncryptionService();
      signer = TransactionSigner();
    });

    test('INTEGRATION: Complete wallet creation, storage, and transaction signing flow', () async {
      const pin = '123456';

      // Step 1: Create wallet
      final walletResult = walletEngine.createWallet();
      expect(walletResult.mnemonic, isNotEmpty);
      expect(walletResult.address, startsWith('0x'));

      // Step 2: Encrypt mnemonic
      final encrypted = encryptionService.encrypt(walletResult.mnemonic, pin);
      expect(encrypted.ciphertext, isNotEmpty);

      // Step 3: Simulate storage (serialize)
      final storedData = encrypted.toJsonString();
      expect(storedData, isNotEmpty);

      // Step 4: Simulate retrieval (deserialize)
      final retrieved = EncryptedData.fromJsonString(storedData);

      // Step 5: Decrypt mnemonic
      final decryptedMnemonic = encryptionService.decrypt(retrieved, pin);
      expect(decryptedMnemonic, equals(walletResult.mnemonic));

      // Step 6: Derive private key
      final privateKey = walletEngine.derivePrivateKeyForAccount(decryptedMnemonic, index: 0);
      expect(privateKey.length, equals(32));

      // Step 7: Create and sign transaction
      final transaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final signed = await signer.signTransactionSecure(
        transaction: transaction,
        privateKey: privateKey,
      );

      // Step 8: Verify signed transaction
      expect(signed.rawTransaction, startsWith('0x'));
      expect(signed.transactionHash, startsWith('0x'));

      // Step 9: Verify private key was cleared
      expect(privateKey.every((byte) => byte == 0), isTrue);
    });

    test('INTEGRATION: Import wallet, encrypt, decrypt, and sign flow', () async {
      const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      const pin = '123456';

      // Step 1: Import wallet
      final importResult = walletEngine.importWallet(testMnemonic);
      expect(importResult.isValid, isTrue);
      expect(importResult.address, startsWith('0x'));

      // Step 2: Encrypt mnemonic
      final encrypted = encryptionService.encrypt(testMnemonic, pin);

      // Step 3: Decrypt mnemonic
      final decrypted = encryptionService.decrypt(encrypted, pin);
      expect(decrypted, equals(testMnemonic));

      // Step 4: Derive private key
      final privateKey = walletEngine.derivePrivateKeyForAccount(decrypted, index: 0);

      // Step 5: Sign transaction
      final transaction = EvmTransaction(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000000000000000000),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        nonce: 0,
        chainId: 1,
      );

      final signed = await signer.signTransactionSecure(
        transaction: transaction,
        privateKey: privateKey,
      );

      expect(signed.rawTransaction, startsWith('0x'));
      expect(privateKey.every((byte) => byte == 0), isTrue);
    });
  });
}
