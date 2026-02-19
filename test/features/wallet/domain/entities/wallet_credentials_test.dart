import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/features/wallet/domain/entities/wallet_credentials.dart';

void main() {
  group('WalletCredentials', () {
    const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon art';
    const testAddress = '0x1234567890123456789012345678901234567890';

    test('should create WalletCredentials with mnemonic and address', () {
      // Arrange & Act
      final credentials = WalletCredentials(
        mnemonic: testMnemonic,
        address: testAddress,
      );

      // Assert
      expect(credentials.mnemonic, equals(testMnemonic));
      expect(credentials.address, equals(testAddress));
    });

    test('should create copy with modified mnemonic', () {
      // Arrange
      final original = WalletCredentials(
        mnemonic: testMnemonic,
        address: testAddress,
      );
      const newMnemonic = 'test test test test test test '
          'test test test test test test '
          'test test test test test test '
          'test test test test test jelly';

      // Act
      final copy = original.copyWith(mnemonic: newMnemonic);

      // Assert
      expect(copy.mnemonic, equals(newMnemonic));
      expect(copy.address, equals(testAddress));
      expect(original.mnemonic, equals(testMnemonic)); // Original unchanged
    });

    test('should create copy with modified address', () {
      // Arrange
      final original = WalletCredentials(
        mnemonic: testMnemonic,
        address: testAddress,
      );
      const newAddress = '0x9876543210987654321098765432109876543210';

      // Act
      final copy = original.copyWith(address: newAddress);

      // Assert
      expect(copy.mnemonic, equals(testMnemonic));
      expect(copy.address, equals(newAddress));
      expect(original.address, equals(testAddress)); // Original unchanged
    });

    test('should create copy with no changes when no parameters provided', () {
      // Arrange
      final original = WalletCredentials(
        mnemonic: testMnemonic,
        address: testAddress,
      );

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.mnemonic, equals(testMnemonic));
      expect(copy.address, equals(testAddress));
    });
  });
}
