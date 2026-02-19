import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/crypto/bip32_service.dart';
import 'package:aimo_wallet/core/crypto/bip32_service_impl.dart';
import 'package:hex/hex.dart';

void main() {
  late Bip32Service bip32Service;

  setUp(() {
    bip32Service = Bip32ServiceImpl();
  });

  group('BIP32 Master Key Derivation', () {
    test('deriveMasterKey generates correct master key from seed', () {
      // Test vector from BIP32 specification
      // Seed: 000102030405060708090a0b0c0d0e0f
      final seed = Uint8List.fromList(HEX.decode('000102030405060708090a0b0c0d0e0f'));

      final masterKey = bip32Service.deriveMasterKey(seed);

      // Expected master private key from BIP32 test vectors
      final expectedKey = HEX.decode('e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35');
      final expectedChainCode = HEX.decode('873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508');

      expect(masterKey.key, equals(expectedKey));
      expect(masterKey.chainCode, equals(expectedChainCode));
      expect(masterKey.depth, equals(0));
      expect(masterKey.index, equals(0));
      expect(masterKey.parentFingerprint, equals(Uint8List(4)));
    });

    test('deriveMasterKey returns 32-byte key and chain code', () {
      final seed = Uint8List(64); // 512-bit seed

      final masterKey = bip32Service.deriveMasterKey(seed);

      expect(masterKey.key.length, equals(32));
      expect(masterKey.chainCode.length, equals(32));
    });

    test('deriveMasterKey produces different keys for different seeds', () {
      final seed1 = Uint8List.fromList(List.generate(64, (i) => i));
      final seed2 = Uint8List.fromList(List.generate(64, (i) => i + 1));

      final masterKey1 = bip32Service.deriveMasterKey(seed1);
      final masterKey2 = bip32Service.deriveMasterKey(seed2);

      expect(masterKey1.key, isNot(equals(masterKey2.key)));
      expect(masterKey1.chainCode, isNot(equals(masterKey2.chainCode)));
    });
  });

  group('BIP32 Child Key Derivation', () {
    test('deriveKey derives hardened child keys correctly', () {
      // Test vector from BIP32 specification
      final seed = Uint8List.fromList(HEX.decode('000102030405060708090a0b0c0d0e0f'));
      final masterKey = bip32Service.deriveMasterKey(seed);

      // Derive m/0' (first hardened child)
      final child = bip32Service.deriveKey(masterKey, "0'");

      // Expected values from BIP32 test vectors
      final expectedKey = HEX.decode('edb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea');
      final expectedChainCode = HEX.decode('47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141');

      expect(child.key, equals(expectedKey));
      expect(child.chainCode, equals(expectedChainCode));
      expect(child.depth, equals(1));
    });

    test('deriveKey parses BIP44 Ethereum path correctly', () {
      final seed = Uint8List(64);
      final masterKey = bip32Service.deriveMasterKey(seed);

      // Should not throw for valid BIP44 Ethereum path
      expect(
        () => bip32Service.deriveKey(masterKey, "m/44'/60'/0'/0/0"),
        returnsNormally,
      );
    });

    test('deriveKey handles path without m/ prefix', () {
      final seed = Uint8List(64);
      final masterKey = bip32Service.deriveMasterKey(seed);

      // Should handle path with or without m/ prefix
      final withPrefix = bip32Service.deriveKey(masterKey, "m/44'/60'/0'/0/0");
      final withoutPrefix = bip32Service.deriveKey(masterKey, "44'/60'/0'/0/0");

      expect(withPrefix.key, equals(withoutPrefix.key));
      expect(withPrefix.chainCode, equals(withoutPrefix.chainCode));
    });

    test('derivePrivateKey derives complete path from seed', () {
      final seed = Uint8List(64);

      // Should derive private key at specific path
      final privateKey = bip32Service.derivePrivateKey(seed, "m/44'/60'/0'/0/0");

      expect(privateKey.length, equals(32));
    });

    test('deriveKey increments depth correctly', () {
      final seed = Uint8List(64);
      final masterKey = bip32Service.deriveMasterKey(seed);

      final child1 = bip32Service.deriveKey(masterKey, "0'");
      expect(child1.depth, equals(1));

      final child2 = bip32Service.deriveKey(child1, "0");
      expect(child2.depth, equals(2));
    });
  });
}
