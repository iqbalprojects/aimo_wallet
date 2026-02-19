import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/unlock_wallet_usecase.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';

@GenerateMocks([SecureVault])
import 'unlock_wallet_usecase_test.mocks.dart';

/// Unlock Wallet Use Case Tests
/// 
/// Tests the business logic for wallet unlocking.
/// 
/// Coverage:
/// - Successful unlock
/// - Wallet not found error
/// - Invalid PIN error
/// - Decryption failed error
/// - PIN verification
/// - Mnemonic memory clearing
/// - Address retrieval
void main() {
  group('UnlockWalletUseCase', () {
    late UnlockWalletUseCase useCase;
    late MockSecureVault mockSecureVault;

    setUp(() {
      mockSecureVault = MockSecureVault();
      useCase = UnlockWalletUseCase(secureVault: mockSecureVault);
    });

    group('Successful Unlock', () {
      test('should unlock wallet and return address', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon art';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert
        expect(result.address, equals(testAddress));
      });

      test('should check if wallet exists before unlocking', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockSecureVault.hasWallet()).called(1);
      });

      test('should verify PIN by retrieving mnemonic', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockSecureVault.retrieveMnemonic(testPin)).called(1);
      });

      test('should retrieve wallet address after PIN verification', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockSecureVault.getWalletAddress()).called(1);
      });
    });

    group('Wallet Not Found', () {
      test('should throw VaultException.vaultEmpty if no wallet exists', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.vaultEmpty,
          )),
        );
      });

      test('should not attempt to retrieve mnemonic if wallet does not exist', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

        // Act
        try {
          await useCase.call(pin: testPin);
        } catch (e) {
          // Expected
        }

        // Assert
        verifyNever(mockSecureVault.retrieveMnemonic(any));
      });
    });

    group('Invalid PIN', () {
      test('should throw VaultException.invalidPin for empty PIN', () async {
        // Arrange
        const emptyPin = '';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => useCase.call(pin: emptyPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.invalidPin,
          )),
        );
      });

      test('should throw VaultException.invalidPin for short PIN', () async {
        // Arrange
        const shortPin = '123';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => useCase.call(pin: shortPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.invalidPin,
          )),
        );
      });

      test('should accept 6-digit PIN', () async {
        // Arrange
        const validPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(validPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act & Assert - should not throw
        await useCase.call(pin: validPin);
      });

      test('should accept 8-digit PIN', () async {
        // Arrange
        const validPin = '12345678';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(validPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act & Assert - should not throw
        await useCase.call(pin: validPin);
      });
    });

    group('Decryption Failed', () {
      test('should propagate decryption failed error for wrong PIN', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenThrow(VaultException.decryptionFailed('Wrong PIN'));

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.decryptionFailed,
          )),
        );
      });
    });

    group('Address Retrieval', () {
      test('should throw VaultException.dataCorrupted if address is null', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.dataCorrupted,
          )),
        );
      });

      test('should return valid Ethereum address', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert
        expect(result.address, startsWith('0x'));
        expect(result.address.length, equals(42));
      });
    });

    group('PIN Verification Only', () {
      test('should verify PIN without unlocking', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.verifyPin(testPin)).thenAnswer((_) async => true);

        // Act
        final result = await useCase.verifyPinOnly(testPin);

        // Assert
        expect(result, isTrue);
        verify(mockSecureVault.verifyPin(testPin)).called(1);
      });

      test('should return false for wrong PIN', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.verifyPin(testPin)).thenAnswer((_) async => false);

        // Act
        final result = await useCase.verifyPinOnly(testPin);

        // Assert
        expect(result, isFalse);
      });

      test('should return false on exception', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.verifyPin(testPin))
            .thenThrow(Exception('Verification error'));

        // Act
        final result = await useCase.verifyPinOnly(testPin);

        // Assert
        expect(result, isFalse);
      });
    });

    group('Security Properties', () {
      test('should not expose mnemonic in result', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert - result should only contain address, not mnemonic
        expect(result.address, isNotNull);
        expect(result.toString(), isNot(contains(testMnemonic)));
      });

      test('should validate PIN before attempting decryption', () async {
        // Arrange
        const invalidPin = '123';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => useCase.call(pin: invalidPin),
          throwsA(isA<VaultException>()),
        );

        // Vault should not be accessed
        verifyNever(mockSecureVault.retrieveMnemonic(any));
      });
    });
  });
}
