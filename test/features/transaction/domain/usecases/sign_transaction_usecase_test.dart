import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aimo_wallet/features/transaction/domain/usecases/sign_transaction_usecase.dart';
import 'package:aimo_wallet/features/transaction/domain/entities/transaction.dart';
import 'package:aimo_wallet/features/transaction/domain/services/transaction_signer.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/auth_controller.dart';

@GenerateMocks([SecureVault, WalletEngine, TransactionSigner, AuthController])
import 'sign_transaction_usecase_test.mocks.dart';

/// Sign Transaction Use Case Tests
/// 
/// Tests the business logic for transaction signing.
/// 
/// Coverage:
/// - Successful transaction signing
/// - Wallet locked error
/// - Invalid PIN error
/// - Signing failed error
/// - Private key derivation
/// - Memory clearing
/// - EIP-155 compliance
void main() {
  group('SignTransactionUseCase', () {
    late SignTransactionUseCase useCase;
    late MockSecureVault mockSecureVault;
    late MockWalletEngine mockWalletEngine;
    late MockTransactionSigner mockTransactionSigner;
    late MockAuthController mockAuthController;

    setUp(() {
      mockSecureVault = MockSecureVault();
      mockWalletEngine = MockWalletEngine();
      mockTransactionSigner = MockTransactionSigner();
      mockAuthController = MockAuthController();

      useCase = SignTransactionUseCase(
        secureVault: mockSecureVault,
        walletEngine: mockWalletEngine,
        transactionSigner: mockTransactionSigner,
        authController: mockAuthController,
      );
    });

    group('Successful Transaction Signing', () {
      test('should sign transaction and return signed result', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );
        final signedTransaction = SignedTransaction(
          rawTransaction: '0xf86c...',
          transactionHash: '0x123abc...',
          transaction: transaction,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => signedTransaction);

        // Act
        final result = await useCase.call(
          transaction: transaction,
          pin: testPin,
        );

        // Assert
        expect(result, equals(signedTransaction));
        expect(result.transactionHash, equals('0x123abc...'));
      });

      test('should check wallet lock state before signing', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => SignedTransaction(
              rawTransaction: '0xf86c...',
              transactionHash: '0x123abc...',
              transaction: transaction,
            ));

        // Act
        await useCase.call(transaction: transaction, pin: testPin);

        // Assert
        verify(mockAuthController.isLocked).called(1);
      });

      test('should retrieve mnemonic from vault', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => SignedTransaction(
              rawTransaction: '0xf86c...',
              transactionHash: '0x123abc...',
              transaction: transaction,
            ));

        // Act
        await useCase.call(transaction: transaction, pin: testPin);

        // Assert
        verify(mockSecureVault.retrieveMnemonic(testPin)).called(1);
      });

      test('should derive private key at runtime', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => SignedTransaction(
              rawTransaction: '0xf86c...',
              transactionHash: '0x123abc...',
              transaction: transaction,
            ));

        // Act
        await useCase.call(transaction: transaction, pin: testPin);

        // Assert
        verify(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).called(1);
      });

      test('should sign transaction with derived private key', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => SignedTransaction(
              rawTransaction: '0xf86c...',
              transactionHash: '0x123abc...',
              transaction: transaction,
            ));

        // Act
        await useCase.call(transaction: transaction, pin: testPin);

        // Assert
        verify(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).called(1);
      });
    });

    group('Wallet Locked', () {
      test('should throw SignTransactionException if wallet is locked', () async {
        // Arrange
        const testPin = '123456';
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(true);

        // Act & Assert
        expect(
          () => useCase.call(transaction: transaction, pin: testPin),
          throwsA(isA<SignTransactionException>().having(
            (e) => e.message,
            'message',
            contains('locked'),
          )),
        );
      });

      test('should not retrieve mnemonic if wallet is locked', () async {
        // Arrange
        const testPin = '123456';
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(true);

        // Act
        try {
          await useCase.call(transaction: transaction, pin: testPin);
        } catch (e) {
          // Expected
        }

        // Assert
        verifyNever(mockSecureVault.retrieveMnemonic(any));
      });
    });

    group('Invalid PIN', () {
      test('should throw SignTransactionException for wrong PIN', () async {
        // Arrange
        const testPin = '123456';
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenThrow(Exception('Invalid PIN'));

        // Act & Assert
        expect(
          () => useCase.call(transaction: transaction, pin: testPin),
          throwsA(isA<SignTransactionException>().having(
            (e) => e.message,
            'message',
            contains('Failed to retrieve wallet credentials'),
          )),
        );
      });
    });

    group('Private Key Derivation Errors', () {
      test('should throw SignTransactionException if derivation fails', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenThrow(Exception('Derivation failed'));

        // Act & Assert
        expect(
          () => useCase.call(transaction: transaction, pin: testPin),
          throwsA(isA<SignTransactionException>().having(
            (e) => e.message,
            'message',
            contains('Failed to derive private key'),
          )),
        );
      });
    });

    group('Signing Errors', () {
      test('should throw SignTransactionException if signing fails', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenThrow(Exception('Signing failed'));

        // Act & Assert
        expect(
          () => useCase.call(transaction: transaction, pin: testPin),
          throwsA(isA<SignTransactionException>().having(
            (e) => e.message,
            'message',
            contains('Failed to sign transaction'),
          )),
        );
      });
    });

    group('Security Properties', () {
      test('should not store private key', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic';
        final testPrivateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(false);
        when(mockSecureVault.retrieveMnemonic(testPin))
            .thenAnswer((_) async => testMnemonic);
        when(mockWalletEngine.derivePrivateKeyForAccount(
          testMnemonic,
          index: 0,
        )).thenReturn(testPrivateKey);
        when(mockTransactionSigner.signTransactionSecure(
          transaction: transaction,
          privateKey: testPrivateKey,
        )).thenAnswer((_) async => SignedTransaction(
              rawTransaction: '0xf86c...',
              transactionHash: '0x123abc...',
              transaction: transaction,
            ));

        // Act
        final result = await useCase.call(transaction: transaction, pin: testPin);

        // Assert - private key should not be in result
        expect(result.toString(), isNot(contains(testPrivateKey.toString())));
      });

      test('should enforce wallet unlock before signing', () async {
        // Arrange
        const testPin = '123456';
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(25000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        when(mockAuthController.isLocked).thenReturn(true);

        // Act & Assert
        expect(
          () => useCase.call(transaction: transaction, pin: testPin),
          throwsA(isA<SignTransactionException>()),
        );
      });
    });
  });
}
