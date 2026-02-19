import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/features/wallet/data/models/encrypted_wallet_data.dart';

void main() {
  group('EncryptedWalletData', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final data = EncryptedWalletData(
        encryptedMnemonic: 'base64EncodedCiphertext',
        iv: 'base64EncodedIV',
        salt: 'base64EncodedSalt',
        authTag: 'base64EncodedAuthTag',
        address: '0x1234567890123456789012345678901234567890',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      // Act
      final json = data.toJson();

      // Assert
      expect(json['encryptedMnemonic'], 'base64EncodedCiphertext');
      expect(json['iv'], 'base64EncodedIV');
      expect(json['salt'], 'base64EncodedSalt');
      expect(json['authTag'], 'base64EncodedAuthTag');
      expect(json['address'], '0x1234567890123456789012345678901234567890');
      expect(json['createdAt'], '2024-01-01T12:00:00.000');
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'encryptedMnemonic': 'base64EncodedCiphertext',
        'iv': 'base64EncodedIV',
        'salt': 'base64EncodedSalt',
        'authTag': 'base64EncodedAuthTag',
        'address': '0x1234567890123456789012345678901234567890',
        'createdAt': '2024-01-01T12:00:00.000',
      };

      // Act
      final data = EncryptedWalletData.fromJson(json);

      // Assert
      expect(data.encryptedMnemonic, 'base64EncodedCiphertext');
      expect(data.iv, 'base64EncodedIV');
      expect(data.salt, 'base64EncodedSalt');
      expect(data.authTag, 'base64EncodedAuthTag');
      expect(data.address, '0x1234567890123456789012345678901234567890');
      expect(data.createdAt, DateTime(2024, 1, 1, 12, 0, 0));
    });

    test('should handle null authTag', () {
      // Arrange
      final json = {
        'encryptedMnemonic': 'base64EncodedCiphertext',
        'iv': 'base64EncodedIV',
        'salt': 'base64EncodedSalt',
        'authTag': null,
        'address': '0x1234567890123456789012345678901234567890',
        'createdAt': '2024-01-01T12:00:00.000',
      };

      // Act
      final data = EncryptedWalletData.fromJson(json);

      // Assert
      expect(data.authTag, isNull);
    });

    test('should serialize and deserialize JSON string correctly', () {
      // Arrange
      final original = EncryptedWalletData(
        encryptedMnemonic: 'base64EncodedCiphertext',
        iv: 'base64EncodedIV',
        salt: 'base64EncodedSalt',
        authTag: 'base64EncodedAuthTag',
        address: '0x1234567890123456789012345678901234567890',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      // Act
      final jsonString = original.toJsonString();
      final deserialized = EncryptedWalletData.fromJsonString(jsonString);

      // Assert
      expect(deserialized.encryptedMnemonic, original.encryptedMnemonic);
      expect(deserialized.iv, original.iv);
      expect(deserialized.salt, original.salt);
      expect(deserialized.authTag, original.authTag);
      expect(deserialized.address, original.address);
      expect(deserialized.createdAt, original.createdAt);
    });
  });
}
