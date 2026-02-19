import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aimo_wallet/features/wallet/data/datasources/secure_storage_datasource_impl.dart';
import 'package:aimo_wallet/features/wallet/domain/entities/wallet_error.dart';

@GenerateMocks([FlutterSecureStorage])
import 'secure_storage_datasource_test.mocks.dart';

void main() {
  late SecureStorageDataSourceImpl dataSource;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    dataSource = SecureStorageDataSourceImpl(mockStorage);
  });

  group('SecureStorageDataSourceImpl', () {
    const testKey = 'test_key';
    const testValue = 'test_value';

    group('write', () {
      test('should write data to secure storage', () async {
        // Arrange
        when(mockStorage.write(key: testKey, value: testValue))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.write(testKey, testValue);

        // Assert
        verify(mockStorage.write(key: testKey, value: testValue)).called(1);
      });

      test('should throw WalletError on write failure', () async {
        // Arrange
        when(mockStorage.write(key: testKey, value: testValue))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.write(testKey, testValue),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageWriteFailure,
          )),
        );
      });
    });

    group('read', () {
      test('should read data from secure storage', () async {
        // Arrange
        when(mockStorage.read(key: testKey))
            .thenAnswer((_) async => testValue);

        // Act
        final result = await dataSource.read(testKey);

        // Assert
        expect(result, testValue);
        verify(mockStorage.read(key: testKey)).called(1);
      });

      test('should return null when key does not exist', () async {
        // Arrange
        when(mockStorage.read(key: testKey)).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.read(testKey);

        // Assert
        expect(result, isNull);
      });

      test('should throw WalletError on read failure', () async {
        // Arrange
        when(mockStorage.read(key: testKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.read(testKey),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageReadFailure,
          )),
        );
      });
    });

    group('containsKey', () {
      test('should return true when key exists', () async {
        // Arrange
        when(mockStorage.containsKey(key: testKey))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.containsKey(testKey);

        // Assert
        expect(result, isTrue);
        verify(mockStorage.containsKey(key: testKey)).called(1);
      });

      test('should return false when key does not exist', () async {
        // Arrange
        when(mockStorage.containsKey(key: testKey))
            .thenAnswer((_) async => false);

        // Act
        final result = await dataSource.containsKey(testKey);

        // Assert
        expect(result, isFalse);
      });

      test('should throw WalletError on containsKey failure', () async {
        // Arrange
        when(mockStorage.containsKey(key: testKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.containsKey(testKey),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageReadFailure,
          )),
        );
      });
    });

    group('delete', () {
      test('should delete data from secure storage', () async {
        // Arrange
        when(mockStorage.delete(key: testKey)).thenAnswer((_) async => {});

        // Act
        await dataSource.delete(testKey);

        // Assert
        verify(mockStorage.delete(key: testKey)).called(1);
      });

      test('should throw WalletError on delete failure', () async {
        // Arrange
        when(mockStorage.delete(key: testKey))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.delete(testKey),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageDeleteFailure,
          )),
        );
      });
    });

    group('deleteAll', () {
      test('should delete all data from secure storage', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenAnswer((_) async => {});

        // Act
        await dataSource.deleteAll();

        // Assert
        verify(mockStorage.deleteAll()).called(1);
      });

      test('should throw WalletError on deleteAll failure', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.deleteAll(),
          throwsA(isA<WalletError>().having(
            (e) => e.type,
            'type',
            WalletErrorType.storageDeleteFailure,
          )),
        );
      });
    });
  });
}
