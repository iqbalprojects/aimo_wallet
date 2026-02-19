import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/crypto/bip39_service_impl.dart';

void main() {
  late Bip39ServiceImpl bip39Service;

  setUp(() {
    bip39Service = Bip39ServiceImpl();
  });

  group('Bip39Service - Generate Mnemonic', () {
    test('should generate 24-word mnemonic', () {
      final mnemonic = bip39Service.generateMnemonic();
      final words = mnemonic.split(' ');

      expect(words.length, equals(24));
    });

    test('should generate different mnemonics', () {
      final mnemonic1 = bip39Service.generateMnemonic();
      final mnemonic2 = bip39Service.generateMnemonic();

      expect(mnemonic1, isNot(equals(mnemonic2)));
    });

    test('should generate valid mnemonics', () {
      for (int i = 0; i < 10; i++) {
        final mnemonic = bip39Service.generateMnemonic();
        expect(bip39Service.validateMnemonic(mnemonic), isTrue);
      }
    });
  });

  group('Bip39Service - Validate Mnemonic', () {
    test('should validate correct mnemonic', () {
      const validMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      expect(bip39Service.validateMnemonic(validMnemonic), isTrue);
    });

    test('should reject mnemonic with wrong word count', () {
      const invalidMnemonic = 'abandon abandon abandon';

      expect(bip39Service.validateMnemonic(invalidMnemonic), isFalse);
    });

    test('should reject mnemonic with invalid checksum', () {
      const invalidMnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon'; // Wrong last word

      expect(bip39Service.validateMnemonic(invalidMnemonic), isFalse);
    });

    test('should reject mnemonic with invalid words', () {
      const invalidMnemonic = 'invalid words that are not in bip39 wordlist '
          'more invalid words to make twenty four words total '
          'even more words here to reach the count needed';

      expect(bip39Service.validateMnemonic(invalidMnemonic), isFalse);
    });
  });

  group('Bip39Service - Normalize Mnemonic', () {
    test('should convert to lowercase', () {
      const mnemonic = 'ABANDON ABANDON ABANDON';
      final normalized = bip39Service.normalizeMnemonic(mnemonic);

      expect(normalized, equals('abandon abandon abandon'));
    });

    test('should trim whitespace', () {
      const mnemonic = '  abandon abandon abandon  ';
      final normalized = bip39Service.normalizeMnemonic(mnemonic);

      expect(normalized, equals('abandon abandon abandon'));
    });

    test('should collapse multiple spaces', () {
      const mnemonic = 'abandon  abandon   abandon';
      final normalized = bip39Service.normalizeMnemonic(mnemonic);

      expect(normalized, equals('abandon abandon abandon'));
    });

    test('should handle mixed case and spacing', () {
      const mnemonic = '  ABANDON  abandon   ABANDON  ';
      final normalized = bip39Service.normalizeMnemonic(mnemonic);

      expect(normalized, equals('abandon abandon abandon'));
    });
  });

  group('Bip39Service - Mnemonic to Seed', () {
    test('should convert mnemonic to 512-bit seed', () {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final seed = bip39Service.mnemonicToSeed(mnemonic);

      expect(seed.length, equals(64)); // 64 bytes = 512 bits
    });

    test('should generate same seed for same mnemonic', () {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final seed1 = bip39Service.mnemonicToSeed(mnemonic);
      final seed2 = bip39Service.mnemonicToSeed(mnemonic);

      expect(seed1, equals(seed2));
    });

    test('should generate different seeds for different mnemonics', () {
      const mnemonic1 = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final generatedMnemonic = bip39Service.generateMnemonic();

      final seed1 = bip39Service.mnemonicToSeed(mnemonic1);
      final seed2 = bip39Service.mnemonicToSeed(generatedMnemonic);

      expect(seed1, isNot(equals(seed2)));
    });

    test('should support passphrase', () {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';

      final seedNoPassphrase = bip39Service.mnemonicToSeed(mnemonic);
      final seedWithPassphrase = bip39Service.mnemonicToSeed(
        mnemonic,
        passphrase: 'test',
      );

      expect(seedNoPassphrase, isNot(equals(seedWithPassphrase)));
    });
  });
}
