import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/create_new_wallet_usecase.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';

@GenerateMocks([WalletEngine, SecureVault])
import 'create_new_wallet_usecase_test.mocks.dart';

/// Create New Wallet Use Case Tests
/// 
/// Tests the business logic for wallet creation.
/// 
/// Coverage:
/// - Successful wallet creation
/// - Wallet already exists error
/// - Invalid PIN error
/// - Encryption errors
/// - Storage errors
/// - Mnemonic generation
/// - Address derivation
void main() {
  group('CreateNewWalletUseCase', () {
    late CreateNewWalletUseCase useCase;
    late MockWalletEngine mockWalletEngine;
    late MockSecureVault mockSecureVault;

    setUp(() {
      mockWalletEngine = MockWalletEngine();
      mockSecureVault = MockSecureVault();

      useCase = CreateNewWalletUseCase(
        walletEngine: mockWalletEngine,
        secureVault: mockSecureVault,
      );
    });

    group('Successful Wallet Creation', () {
      test('should create wallet and return mnemonic and address', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon art';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert
        expect(result.mnemonic, equals(testMnemonic));
        expect(result.address, equals(testAddress));
      });

      test('should check if wallet exists before creating', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockSecureVault.hasWallet()).called(1);
      });

      test('should generate mnemonic via wallet engine', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockWalletEngine.createWallet()).called(1);
      });

      test('should store encrypted mnemonic in vault', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        await useCase.call(pin: testPin);

        // Assert
        verify(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).called(1);
      });
    });

    group('Wallet Already Exists', () {
      test('should throw VaultException.vaultNotEmpty if wallet exists', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.vaultNotEmpty,
          )),
        );
      });

      test('should not call wallet engine if wallet exists', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act
        try {
          await useCase.call(pin: testPin);
        } catch (e) {
          // Expected
        }

        // Assert
        verifyNever(mockWalletEngine.createWallet());
      });
    });

    group('Invalid PIN', () {
      test('should throw VaultException.invalidPin for empty PIN', () async {
        // Arrange
        const emptyPin = '';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

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
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

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

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          validPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act & Assert - should not throw
        await useCase.call(pin: validPin);
      });

      test('should accept 8-digit PIN', () async {
        // Arrange
        const validPin = '12345678';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          validPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act & Assert - should not throw
        await useCase.call(pin: validPin);
      });
    });

    group('Encryption Errors', () {
      test('should propagate encryption failed error', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenThrow(VaultException.encryptionFailed('Encryption error'));

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.encryptionFailed,
          )),
        );
      });
    });

    group('Storage Errors', () {
      test('should propagate storage failed error', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenThrow(VaultException.storageFailed('Storage error'));

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.storageFailed,
          )),
        );
      });
    });

    group('Mnemonic Generation', () {
      test('should return 24-word mnemonic', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon art';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert
        final words = result.mnemonic.trim().split(RegExp(r'\s+'));
        expect(words.length, equals(24));
      });

      test('should return valid Ethereum address', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);
        when(mockWalletEngine.createWallet()).thenReturn(WalletCreationResult(
          mnemonic: testMnemonic,
          address: testAddress,
        ));
        when(mockSecureVault.storeMnemonic(
          testMnemonic,
          testPin,
          address: testAddress,
        )).thenAnswer((_) async => {});

        // Act
        final result = await useCase.call(pin: testPin);

        // Assert
        expect(result.address, startsWith('0x'));
        expect(result.address.length, equals(42));
      });
    });

    group('Security Properties', () {
      test('should enforce single wallet constraint', () async {
        // Arrange
        const testPin = '123456';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => useCase.call(pin: testPin),
          throwsA(isA<VaultException>()),
        );
      });

      test('should validate PIN before creating wallet', () async {
        // Arrange
        const invalidPin = '123';
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => useCase.call(pin: invalidPin),
          throwsA(isA<VaultException>()),
        );

        // Wallet engine should not be called
        verifyNever(mockWalletEngine.createWallet());
      });
    });
  });
}
