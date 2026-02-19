import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([FlutterSecureStorage])
import 'secure_vault_test.mocks.dart';

void main() {
  late SecureVault vault;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    vault = SecureVault(storage: mockStorage);
  });

  group('SecureVault - Store Mnemonic', () {
    test('should store mnemonic successfully', () async {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      const pin = '123456';

      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      // Mock: write succeeds
      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

      verify(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).called(1);
    });

    test('should throw error if vault already has wallet', () async {
      const mnemonic = 'test mnemonic';
      const pin = '123456';

      // Mock: vault has wallet
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => '{"ciphertext":"test"}');

      expect(
        () => vault.storeMnemonic(mnemonic, pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should reject invalid PIN', () async {
      const mnemonic = 'test mnemonic';
      const pin = '12'; // Too short

      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      expect(
        () => vault.storeMnemonic(mnemonic, pin),
        throwsA(isA<VaultException>()),
      );
    });
  });

  group('SecureVault - Retrieve Mnemonic', () {
    test('should retrieve mnemonic successfully', () async {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      const pin = '123456';

      // First store mnemonic
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

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

      // Retrieve mnemonic
      final retrieved = await vault.retrieveMnemonic(pin);

      expect(retrieved, equals(mnemonic));
    });

    test('should throw error if vault is empty', () async {
      const pin = '123456';

      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      expect(
        () => vault.retrieveMnemonic(pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should throw error with wrong PIN', () async {
      const mnemonic = 'test mnemonic';
      const pin = '123456';
      const wrongPin = '654321';

      // Store with correct PIN
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

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

      // Try to retrieve with wrong PIN
      expect(
        () => vault.retrieveMnemonic(wrongPin),
        throwsA(isA<VaultException>()),
      );
    });
  });

  group('SecureVault - Has Wallet', () {
    test('should return true if wallet exists', () async {
      // Mock: vault has wallet
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => '{"ciphertext":"test"}');

      final hasWallet = await vault.hasWallet();

      expect(hasWallet, isTrue);
    });

    test('should return false if vault is empty', () async {
      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      final hasWallet = await vault.hasWallet();

      expect(hasWallet, isFalse);
    });
  });

  group('SecureVault - Delete Wallet', () {
    test('should delete wallet successfully', () async {
      // Mock: delete succeeds
      when(mockStorage.delete(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.deleteWallet();

      // Should delete both wallet and address keys
      verify(mockStorage.delete(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).called(2); // Deletes both wallet and address
    });
  });

  group('SecureVault - Verify PIN', () {
    test('should verify correct PIN', () async {
      const mnemonic = 'test mnemonic';
      const pin = '123456';

      // Store mnemonic
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

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

      // Verify PIN
      final isValid = await vault.verifyPin(pin);

      expect(isValid, isTrue);
    });

    test('should reject wrong PIN', () async {
      const mnemonic = 'test mnemonic';
      const pin = '123456';
      const wrongPin = '654321';

      // Store mnemonic
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

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

      // Verify wrong PIN
      final isValid = await vault.verifyPin(wrongPin);

      expect(isValid, isFalse);
    });
  });

  group('SecureVault - Update PIN', () {
    test('should update PIN successfully', () async {
      const mnemonic = 'test mnemonic';
      const oldPin = '123456';
      const newPin = '654321';

      // Store with old PIN
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      when(mockStorage.delete(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, oldPin);

      // Capture stored value
      final captured1 = verify(mockStorage.write(
        key: anyNamed('key'),
        value: captureAnyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).captured;

      final storedValue1 = captured1.first as String;

      // Mock: read returns stored value for retrieval
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => storedValue1);

      // Update PIN - this will:
      // 1. Read the encrypted data (returns storedValue1)
      // 2. Delete the wallet
      // 3. Store with new PIN
      // After delete, we need to return null for hasWallet check
      var callCount = 0;
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return storedValue1; // First call for retrieveMnemonic
        } else {
          return null; // After delete, vault is empty
        }
      });

      await vault.updatePin(oldPin, newPin);

      // Capture new stored value
      final captured2 = verify(mockStorage.write(
        key: anyNamed('key'),
        value: captureAnyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).captured;

      final storedValue2 = captured2.last as String;

      // Mock: read returns new stored value
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => storedValue2);

      // Verify new PIN works
      final retrieved = await vault.retrieveMnemonic(newPin);
      expect(retrieved, equals(mnemonic));
    });
  });

  group('SecureVault - Get Metadata', () {
    test('should return metadata for stored wallet', () async {
      const mnemonic = 'test mnemonic';
      const pin = '123456';

      // Store mnemonic
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => {});

      await vault.storeMnemonic(mnemonic, pin);

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

      // Get metadata
      final metadata = await vault.getMetadata();

      expect(metadata['hasWallet'], isTrue);
      expect(metadata['saltLength'], equals(32));
      expect(metadata['ivLength'], equals(12));
      expect(metadata['authTagLength'], equals(16));
    });

    test('should return empty metadata for empty vault', () async {
      // Mock: vault is empty
      when(mockStorage.read(
        key: anyNamed('key'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async => null);

      final metadata = await vault.getMetadata();

      expect(metadata['hasWallet'], isFalse);
    });
  });
}
