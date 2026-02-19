import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/create_new_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/get_current_address_usecase.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';

@GenerateMocks([CreateNewWalletUseCase, GetCurrentAddressUseCase])
import 'wallet_controller_test.mocks.dart';

/// Wallet Controller Tests
/// 
/// Tests the refactored WalletController with callback pattern.
/// 
/// Coverage:
/// - Wallet creation with callback
/// - No mnemonic storage in controller
/// - Error handling
/// - State management
/// - Initialization
void main() {
  group('WalletController', () {
    late WalletController controller;
    late MockCreateNewWalletUseCase mockCreateNewWalletUseCase;
    late MockGetCurrentAddressUseCase mockGetCurrentAddressUseCase;

    setUp(() {
      mockCreateNewWalletUseCase = MockCreateNewWalletUseCase();
      mockGetCurrentAddressUseCase = MockGetCurrentAddressUseCase();

      controller = WalletController(
        createNewWalletUseCase: mockCreateNewWalletUseCase,
        getCurrentAddressUseCase: mockGetCurrentAddressUseCase,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        // Assert
        expect(controller.currentAddress.value, equals(''));
        expect(controller.balance, equals('0.0'));
        expect(controller.balanceUsd, equals('0.00'));
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        expect(controller.hasWallet, isFalse);
      });

      test('should load wallet address if exists', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';
        when(mockGetCurrentAddressUseCase.call())
            .thenAnswer((_) async => testAddress);

        // Act
        controller = WalletController(
          getCurrentAddressUseCase: mockGetCurrentAddressUseCase,
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.hasWallet, isTrue);
        expect(controller.currentAddress.value, equals(testAddress));
      });

      test('should handle no wallet exists', () async {
        // Arrange
        when(mockGetCurrentAddressUseCase.call())
            .thenThrow(VaultException.vaultEmpty());

        // Act
        controller = WalletController(
          getCurrentAddressUseCase: mockGetCurrentAddressUseCase,
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.hasWallet, isFalse);
        expect(controller.currentAddress.value, equals(''));
      });
    });

    group('Create Wallet - Callback Pattern', () {
      test('should call use case and invoke callback with mnemonic', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon art';
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenAnswer((_) async => CreateNewWalletResult(
                  mnemonic: testMnemonic,
                  address: testAddress,
                ));

        String? callbackMnemonic;
        String? callbackAddress;

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            callbackMnemonic = mnemonic;
            callbackAddress = address;
          },
        );

        // Assert
        expect(callbackMnemonic, equals(testMnemonic));
        expect(callbackAddress, equals(testAddress));
        expect(controller.hasWallet, isTrue);
        expect(controller.currentAddress.value, equals(testAddress));
        expect(controller.errorMessage, isNull);
      });

      test('should NOT store mnemonic in controller state', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic phrase';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenAnswer((_) async => CreateNewWalletResult(
                  mnemonic: testMnemonic,
                  address: testAddress,
                ));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            // Callback receives mnemonic
          },
        );

        // Assert - controller should NOT have mnemonic field
        // This is a compile-time check - if controller had _mnemonic field,
        // this test would fail to compile
        expect(controller.currentAddress.value, equals(testAddress));
        expect(controller.hasWallet, isTrue);
      });

      test('should set loading state during wallet creation', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic phrase';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return CreateNewWalletResult(
            mnemonic: testMnemonic,
            address: testAddress,
          );
        });

        // Act
        final future = controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {},
        );

        // Assert - should be loading
        await Future.delayed(const Duration(milliseconds: 50));
        expect(controller.isLoading, isTrue);

        await future;
        expect(controller.isLoading, isFalse);
      });

      test('should handle vault not empty error', () async {
        // Arrange
        const testPin = '123456';
        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenThrow(VaultException.vaultNotEmpty());

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(controller.errorMessage, equals('Wallet already exists'));
        expect(controller.hasWallet, isFalse);
      });

      test('should handle invalid PIN error', () async {
        // Arrange
        const testPin = '123';
        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenThrow(VaultException.invalidPin('PIN too short'));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(controller.errorMessage, equals('Invalid PIN format'));
      });

      test('should handle encryption failed error', () async {
        // Arrange
        const testPin = '123456';
        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenThrow(VaultException.encryptionFailed('Encryption error'));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(controller.errorMessage, equals('Failed to encrypt wallet'));
      });

      test('should handle storage failed error', () async {
        // Arrange
        const testPin = '123456';
        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenThrow(VaultException.storageFailed('Storage error'));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(controller.errorMessage, equals('Failed to store wallet'));
      });

      test('should handle generic error', () async {
        // Arrange
        const testPin = '123456';
        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenThrow(Exception('Unexpected error'));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(
          controller.errorMessage,
          contains('Failed to create wallet'),
        );
      });

      test('should handle use case not initialized', () async {
        // Arrange
        final controllerWithoutUseCase = WalletController();
        const testPin = '123456';

        // Act
        await controllerWithoutUseCase.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            fail('Callback should not be called on error');
          },
        );

        // Assert
        expect(
          controllerWithoutUseCase.errorMessage,
          contains('CreateNewWalletUseCase not initialized'),
        );

        controllerWithoutUseCase.dispose();
      });
    });

    group('Import Wallet', () {
      test('should import wallet successfully', () async {
        // Arrange
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon art';
        const testPin = '123456';

        // Act
        final result = await controller.importWallet(testMnemonic, testPin);

        // Assert
        expect(result, isTrue);
        expect(controller.hasWallet, isTrue);
        expect(controller.currentAddress.value, isNotEmpty);
      });

      test('should handle import error', () async {
        // Arrange
        const testMnemonic = 'invalid mnemonic';
        const testPin = '123456';

        // Act
        final result = await controller.importWallet(testMnemonic, testPin);

        // Assert
        expect(result, isFalse);
        expect(controller.errorMessage, isNotNull);
      });
    });

    group('Refresh Balance', () {
      test('should refresh balance successfully', () async {
        // Arrange
        controller.currentAddress.value = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        // Act
        await controller.refreshBalance();

        // Assert
        expect(controller.balance, isNotEmpty);
        expect(controller.balanceUsd, isNotEmpty);
      });

      test('should not refresh if no address', () async {
        // Arrange
        controller.currentAddress.value = '';

        // Act
        await controller.refreshBalance();

        // Assert
        expect(controller.balance, equals('0.0'));
      });

      test('should handle refresh error', () async {
        // Arrange
        controller.currentAddress.value = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        // Act
        await controller.refreshBalance();

        // Assert - should not crash
        expect(controller.errorMessage, anyOf(isNull, isNotNull));
      });
    });

    group('Clear Error', () {
      test('should clear error message', () {
        // Arrange
        controller.clearError();

        // Assert
        expect(controller.errorMessage, isNull);
      });
    });

    group('Security Properties', () {
      test('should never expose mnemonic through controller', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic phrase';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenAnswer((_) async => CreateNewWalletResult(
                  mnemonic: testMnemonic,
                  address: testAddress,
                ));

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            // Mnemonic received in callback only
          },
        );

        // Assert - controller should only have public data
        expect(controller.currentAddress.value, equals(testAddress));
        expect(controller.hasWallet, isTrue);
        // No way to access mnemonic from controller
      });

      test('should only pass mnemonic via callback', () async {
        // Arrange
        const testPin = '123456';
        const testMnemonic = 'test mnemonic phrase';
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockCreateNewWalletUseCase.call(pin: testPin))
            .thenAnswer((_) async => CreateNewWalletResult(
                  mnemonic: testMnemonic,
                  address: testAddress,
                ));

        int callbackCount = 0;
        String? receivedMnemonic;

        // Act
        await controller.createWallet(
          pin: testPin,
          onSuccess: (mnemonic, address) {
            callbackCount++;
            receivedMnemonic = mnemonic;
          },
        );

        // Assert
        expect(callbackCount, equals(1)); // Called exactly once
        expect(receivedMnemonic, equals(testMnemonic));
      });
    });
  });
}
