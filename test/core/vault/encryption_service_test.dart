import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/vault/encryption_service.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';

void main() {
  late EncryptionService encryptionService;

  setUp(() {
    encryptionService = EncryptionService();
  });

  group('EncryptionService - Encrypt', () {
    test('should encrypt plaintext successfully', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.iv, isNotEmpty);
      expect(encrypted.salt, isNotEmpty);
      expect(encrypted.authTag, isNotEmpty);
    });

    test('should generate unique salt for each encryption', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted1 = encryptionService.encrypt(plaintext, pin);
      final encrypted2 = encryptionService.encrypt(plaintext, pin);

      expect(encrypted1.salt, isNot(equals(encrypted2.salt)));
    });

    test('should generate unique IV for each encryption', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted1 = encryptionService.encrypt(plaintext, pin);
      final encrypted2 = encryptionService.encrypt(plaintext, pin);

      expect(encrypted1.iv, isNot(equals(encrypted2.iv)));
    });

    test('should generate different ciphertext for same plaintext', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted1 = encryptionService.encrypt(plaintext, pin);
      final encrypted2 = encryptionService.encrypt(plaintext, pin);

      // Different salt/IV should produce different ciphertext
      expect(encrypted1.ciphertext, isNot(equals(encrypted2.ciphertext)));
    });

    test('should use 32-byte salt', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      expect(encrypted.salt.length, equals(32));
    });

    test('should use 12-byte IV for GCM mode', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      expect(encrypted.iv.length, equals(12));
    });

    test('should use 16-byte authentication tag', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      expect(encrypted.authTag.length, equals(16));
    });

    test('should reject PIN shorter than 4 digits', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123';

      expect(
        () => encryptionService.encrypt(plaintext, pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should reject PIN longer than 8 digits', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456789';

      expect(
        () => encryptionService.encrypt(plaintext, pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should reject non-numeric PIN', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '12ab56';

      expect(
        () => encryptionService.encrypt(plaintext, pin),
        throwsA(isA<VaultException>()),
      );
    });
  });

  group('EncryptionService - Decrypt', () {
    test('should decrypt ciphertext successfully', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final decrypted = encryptionService.decrypt(encrypted, pin);

      expect(decrypted, equals(plaintext));
    });

    test('should fail with wrong PIN', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';
      const wrongPin = '654321';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      expect(
        () => encryptionService.decrypt(encrypted, wrongPin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should fail with corrupted ciphertext', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      // Corrupt ciphertext
      encrypted.ciphertext[0] ^= 0xFF;

      expect(
        () => encryptionService.decrypt(encrypted, pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should fail with corrupted authentication tag', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);

      // Corrupt auth tag
      encrypted.authTag[0] ^= 0xFF;

      expect(
        () => encryptionService.decrypt(encrypted, pin),
        throwsA(isA<VaultException>()),
      );
    });

    test('should handle long plaintext', () {
      final plaintext = 'word ' * 100; // 500 characters
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final decrypted = encryptionService.decrypt(encrypted, pin);

      expect(decrypted, equals(plaintext));
    });

    test('should handle special characters', () {
      const plaintext = 'test 测试 тест 🔐 @#\$%^&*()';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final decrypted = encryptionService.decrypt(encrypted, pin);

      expect(decrypted, equals(plaintext));
    });
  });

  group('EncryptionService - Round-Trip', () {
    test('should preserve plaintext through encrypt/decrypt cycle', () {
      const plaintext = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon art';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final decrypted = encryptionService.decrypt(encrypted, pin);

      expect(decrypted, equals(plaintext));
    });

    test('should work with different PIN lengths', () {
      const plaintext = 'test mnemonic phrase';

      for (int length = 4; length <= 8; length++) {
        final pin = '1' * length;

        final encrypted = encryptionService.encrypt(plaintext, pin);
        final decrypted = encryptionService.decrypt(encrypted, pin);

        expect(decrypted, equals(plaintext));
      }
    });

    test('should work with different plaintexts', () {
      const pin = '123456';
      final plaintexts = [
        'short',
        'medium length plaintext',
        'very long plaintext ' * 50,
        'special chars: 测试 тест 🔐',
        '',
      ];

      for (final plaintext in plaintexts) {
        final encrypted = encryptionService.encrypt(plaintext, pin);
        final decrypted = encryptionService.decrypt(encrypted, pin);

        expect(decrypted, equals(plaintext));
      }
    });
  });

  group('EncryptionService - Verify PIN', () {
    test('should verify correct PIN', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final isValid = encryptionService.verifyPin(encrypted, pin);

      expect(isValid, isTrue);
    });

    test('should reject wrong PIN', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';
      const wrongPin = '654321';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final isValid = encryptionService.verifyPin(encrypted, wrongPin);

      expect(isValid, isFalse);
    });
  });

  group('EncryptionService - Serialization', () {
    test('should serialize to JSON', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final json = encrypted.toJson();

      expect(json, containsPair('ciphertext', isA<String>()));
      expect(json, containsPair('iv', isA<String>()));
      expect(json, containsPair('salt', isA<String>()));
      expect(json, containsPair('authTag', isA<String>()));
    });

    test('should deserialize from JSON', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final json = encrypted.toJson();
      final deserialized = EncryptedData.fromJson(json);

      expect(deserialized.ciphertext, equals(encrypted.ciphertext));
      expect(deserialized.iv, equals(encrypted.iv));
      expect(deserialized.salt, equals(encrypted.salt));
      expect(deserialized.authTag, equals(encrypted.authTag));
    });

    test('should serialize to JSON string', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final jsonString = encrypted.toJsonString();

      expect(jsonString, isA<String>());
      expect(jsonString, contains('ciphertext'));
      expect(jsonString, contains('iv'));
      expect(jsonString, contains('salt'));
      expect(jsonString, contains('authTag'));
    });

    test('should deserialize from JSON string', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final jsonString = encrypted.toJsonString();
      final deserialized = EncryptedData.fromJsonString(jsonString);

      final decrypted = encryptionService.decrypt(deserialized, pin);
      expect(decrypted, equals(plaintext));
    });

    test('should handle round-trip through JSON', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final jsonString = encrypted.toJsonString();
      final deserialized = EncryptedData.fromJsonString(jsonString);
      final decrypted = encryptionService.decrypt(deserialized, pin);

      expect(decrypted, equals(plaintext));
    });
  });

  group('EncryptionService - Security', () {
    test('should use PBKDF2 with 100k iterations', () {
      // This is verified by the implementation
      expect(EncryptionService.pbkdf2Iterations, equals(100000));
    });

    test('should use 32-byte salt', () {
      expect(EncryptionService.saltLength, equals(32));
    });

    test('should use 12-byte IV for GCM', () {
      expect(EncryptionService.ivLength, equals(12));
    });

    test('should use 32-byte key for AES-256', () {
      expect(EncryptionService.keyLength, equals(32));
    });

    test('should not expose plaintext in encrypted data', () {
      const plaintext = 'secret mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final jsonString = encrypted.toJsonString();

      // Plaintext should not appear in encrypted data
      expect(jsonString.toLowerCase(), isNot(contains('secret')));
      expect(jsonString.toLowerCase(), isNot(contains('mnemonic')));
    });

    test('should not expose PIN in encrypted data', () {
      const plaintext = 'test mnemonic phrase';
      const pin = '123456';

      final encrypted = encryptionService.encrypt(plaintext, pin);
      final jsonString = encrypted.toJsonString();

      // PIN should not appear in encrypted data
      expect(jsonString, isNot(contains(pin)));
    });
  });
}
