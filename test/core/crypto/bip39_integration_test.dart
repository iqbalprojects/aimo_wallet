import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/crypto/bip39_service_impl.dart';
import 'package:aimo_wallet/core/crypto/bip39_wordlist.dart';

void main() {
  group('BIP39 Integration Tests', () {
    late Bip39ServiceImpl bip39Service;

    setUp(() {
      bip39Service = Bip39ServiceImpl();
    });

    test('should generate, validate, and derive seed from mnemonic', () {
      // Generate a new mnemonic
      final mnemonic = bip39Service.generateMnemonic();
      
      // Verify it's 24 words
      expect(mnemonic.split(' ').length, equals(24));
      
      // Verify it validates
      expect(bip39Service.validateMnemonic(mnemonic), isTrue);
      
      // Derive seed
      final seed = bip39Service.mnemonicToSeed(mnemonic);
      
      // Verify seed is 512 bits (64 bytes)
      expect(seed.length, equals(64));
    });

    test('should validate known BIP39 test vector', () {
      // Known BIP39 test vector
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      
      // Should validate
      expect(bip39Service.validateMnemonic(mnemonic), isTrue);
      
      // Derive seed
      final seed = bip39Service.mnemonicToSeed(mnemonic);
      
      // Verify seed length
      expect(seed.length, equals(64));
    });

    test('should normalize and validate mnemonic', () {
      const mnemonic = '  ABANDON  abandon   ABANDON  abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon ART  ';
      
      // Normalize
      final normalized = bip39Service.normalizeMnemonic(mnemonic);
      
      // Should be lowercase with single spaces
      expect(normalized, equals(
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon art'
      ));
      
      // Should validate after normalization
      expect(bip39Service.validateMnemonic(normalized), isTrue);
    });

    test('BIP39 word list should have 2048 words', () {
      expect(Bip39WordList.length, equals(2048));
    });

    test('BIP39 word list should support lookup', () {
      // First word should be 'abandon'
      expect(Bip39WordList.getWord(0), equals('abandon'));
      
      // Get index of 'abandon'
      expect(Bip39WordList.getIndex('abandon'), equals(0));
      
      // Check if word exists
      expect(Bip39WordList.contains('abandon'), isTrue);
      expect(Bip39WordList.contains('invalid'), isFalse);
    });
  });
}
