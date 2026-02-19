import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aimo_wallet/features/wallet/data/datasources/secure_storage_datasource.dart';
import 'package:aimo_wallet/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:aimo_wallet/features/wallet/domain/entities/wallet_error.dart';
import 'package:aimo_wallet/core/vault/encryption_service.dart';
import 'package:aimo_wallet/core/crypto/bip39_service.dart';
import 'package:aimo_wallet/core/crypto/key_derivation_service.dart';

@GenerateMocks([
  SecureStorageDataSource,
  EncryptionService,
  Bip39Service,
  KeyDerivationService,
])
import 'wallet_repository_impl_test.mocks.dart';

void main() {
  late WalletRepositoryImpl repository;
  late MockSecureStorageDataSource mockStorage;
  late MockEncryptionService mockEncryption;
  late MockBip39Service mockBip39;
  late MockKeyDerivationService mockKeyDerivation;

  setUp(() {
    mockStorage = MockSecureStorageDataSource();
    mockEncryption = MockEncryptionService();
    mockBip39 = MockBip39Service();
    mockKeyDerivation = MockKeyDerivationService();

    repository = WalletRepositoryImpl(
      storage: mockStorage,
      encryptionService: mockEncryption,
      keyDerivationService: mockKeyDerivation,
      bip39Service: mockBip39,
    );
  });

  group('WalletRepositoryImpl - Storage Operations', () {
    group('hasWallet', () {
      test('should return true when wallet exists', () async {
        // Arrange
        when(mockStorage.containsKey(SecureStorageDataSource.walletDataKey))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.hasWallet();

        // Assert
        expect(result, isTrue);
        verify(mockStorage.containsKey(SecureStorageDataSource.walletDataKey))
            .called(1);
      });

      test('should return false when wallet does not exist', () async {
        // Arrange
        when(mockStorage.containsKey(SecureStorageDataSource.walletDataKey))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.hasWallet();

        // Assert
        expect(result, isFalse);
      });

      test('should throw WalletError on storage failure', () async {
        // Arrange
        when(mockStorage.containsKey(SecureStorageDataSource.walletDataKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => repository.hasWallet(),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageReadFailure,
          )),
        );
      });
    });

    group('deleteWallet', () {
      test('should delete wallet data from storage', () async {
        // Arrange
        when(mockStorage.delete(SecureStorageDataSource.walletDataKey))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteWallet();

        // Assert
        verify(mockStorage.delete(SecureStorageDataSource.walletDataKey))
            .called(1);
      });

      test('should throw WalletError on delete failure', () async {
        // Arrange
        when(mockStorage.delete(SecureStorageDataSource.walletDataKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => repository.deleteWallet(),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageDeleteFailure,
          )),
        );
      });
    });

    group('getWalletAddress', () {
      test('should return wallet address when wallet exists', () async {
        // Arrange
        const testAddress = '0x1234567890123456789012345678901234567890';
        final walletJson = '''
        {
          "encryptedMnemonic": "base64Ciphertext",
          "iv": "base64IV",
          "salt": "base64Salt",
          "authTag": "base64AuthTag",
          "address": "$testAddress",
          "createdAt": "2024-01-01T12:00:00.000"
        }
        ''';

        when(mockStorage.read(SecureStorageDataSource.walletDataKey))
            .thenAnswer((_) async => walletJson);

        // Act
        final result = await repository.getWalletAddress();

        // Assert
        expect(result, testAddress);
      });

      test('should return null when wallet does not exist', () async {
        // Arrange
        when(mockStorage.read(SecureStorageDataSource.walletDataKey))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getWalletAddress();

        // Assert
        expect(result, isNull);
      });

      test('should throw WalletError on storage read failure', () async {
        // Arrange
        when(mockStorage.read(SecureStorageDataSource.walletDataKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => repository.getWalletAddress(),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageReadFailure,
          )),
        );
      });
    });
  });
}
