import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/get_current_address_usecase.dart';
import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';

@GenerateMocks([SecureVault])
import 'get_current_address_usecase_test.mocks.dart';

/// Get Current Address Use Case Tests
/// 
/// Tests the business logic for retrieving wallet address.
/// 
/// Coverage:
/// - Successful address retrieval
/// - Wallet not found error
/// - Address not found error
/// - No decryption required
/// - Fast operation (cached value)
void main() {
  group('GetCurrentAddressUseCase', () {
    late GetCurrentAddressUseCase useCase;
    late MockSecureVault mockSecureVault;

    setUp(() {
      mockSecureVault = MockSecureVault();
      useCase = GetCurrentAddressUseCase(secureVault: mockSecureVault);
    });

    group('Successful Address Retrieval', () {
      test('should retrieve wallet address', () async {
        // Arrange
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result = await useCase.call();

        // Assert
        expect(result, equals(testAddress));
      });

      test('should check if wallet exists before retrieving address', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call();

        // Assert
        verify(mockSecureVault.hasWallet()).called(1);
      });

      test('should retrieve cached address from vault', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call();

        // Assert
        verify(mockSecureVault.getWalletAddress()).called(1);
      });

      test('should return valid Ethereum address', () async {
        // Arrange
        const testAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result = await useCase.call();

        // Assert
        expect(result, startsWith('0x'));
        expect(result.length, equals(42));
      });
    });

    group('Wallet Not Found', () {
      test('should throw VaultException.vaultEmpty if no wallet exists', () async {
        // Arrange
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => useCase.call(),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.vaultEmpty,
          )),
        );
      });

      test('should not attempt to retrieve address if wallet does not exist', () async {
        // Arrange
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => false);

        // Act
        try {
          await useCase.call();
        } catch (e) {
          // Expected
        }

        // Assert
        verifyNever(mockSecureVault.getWalletAddress());
      });
    });

    group('Address Not Found', () {
      test('should throw VaultException.dataCorrupted if address is null', () async {
        // Arrange
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => useCase.call(),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.dataCorrupted,
          )),
        );
      });

      test('should throw VaultException.dataCorrupted if address is empty', () async {
        // Arrange
        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress()).thenAnswer((_) async => '');

        // Act & Assert
        expect(
          () => useCase.call(),
          throwsA(isA<VaultException>().having(
            (e) => e.type,
            'type',
            VaultExceptionType.dataCorrupted,
          )),
        );
      });
    });

    group('Security Properties', () {
      test('should not require PIN for address retrieval', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call();

        // Assert - should not call retrieveMnemonic (no PIN required)
        verifyNever(mockSecureVault.retrieveMnemonic(any));
      });

      test('should not perform decryption', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        await useCase.call();

        // Assert - address is public info, no decryption needed
        verify(mockSecureVault.getWalletAddress()).called(1);
        verifyNever(mockSecureVault.retrieveMnemonic(any));
      });

      test('should be fast operation (no crypto)', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final stopwatch = Stopwatch()..start();
        await useCase.call();
        stopwatch.stop();

        // Assert - should complete quickly (no crypto operations)
        // This is a cached value, so it should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Multiple Calls', () {
      test('should return same address on multiple calls', () async {
        // Arrange
        const testAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

        when(mockSecureVault.hasWallet()).thenAnswer((_) async => true);
        when(mockSecureVault.getWalletAddress())
            .thenAnswer((_) async => testAddress);

        // Act
        final result1 = await useCase.call();
        final result2 = await useCase.call();
        final result3 = await useCase.call();

        // Assert
        expect(result1, equals(testAddress));
        expect(result2, equals(testAddress));
        expect(result3, equals(testAddress));
        expect(result1, equals(result2));
        expect(result2, equals(result3));
      });
    });
  });
}
