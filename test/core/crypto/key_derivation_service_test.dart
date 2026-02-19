import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/crypto/key_derivation_service.dart';
import 'package:aimo_wallet/core/crypto/key_derivation_service_impl.dart';
import 'package:aimo_wallet/core/crypto/bip39_service.dart';
import 'package:aimo_wallet/core/crypto/bip39_service_impl.dart';
import 'package:aimo_wallet/core/crypto/bip32_service.dart';
import 'package:aimo_wallet/core/crypto/bip32_service_impl.dart';
import 'package:hex/hex.dart';

void main() {
  late KeyDerivationService keyDerivationService;
  late Bip39Service bip39Service;
  late Bip32Service bip32Service;

  setUp(() {
    bip39Service = Bip39ServiceImpl();
    bip32Service = Bip32ServiceImpl();
    keyDerivationService = KeyDerivationServiceImpl(bip39Service, bip32Service);
  });

  group('secp256k1 Public Key Derivation', () {
    test('derivePublicKey generates 64-byte uncompressed public key', () {
      // Test with a known private key
      final privateKey = Uint8List.fromList(
        HEX.decode('0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'),
      );

      final publicKey = keyDerivationService.derivePublicKey(privateKey);

      // Public key should be 64 bytes (x + y coordinates, no prefix)
      expect(publicKey.length, equals(64));
    });

    test('derivePublicKey produces consistent results', () {
      final privateKey = Uint8List.fromList(
        HEX.decode('1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'),
      );

      final publicKey1 = keyDerivationService.derivePublicKey(privateKey);
      final publicKey2 = keyDerivationService.derivePublicKey(privateKey);

      expect(publicKey1, equals(publicKey2));
    });

    test('derivePublicKey produces different keys for different private keys', () {
      final privateKey1 = Uint8List.fromList(
        HEX.decode('0000000000000000000000000000000000000000000000000000000000000001'),
      );
      final privateKey2 = Uint8List.fromList(
        HEX.decode('0000000000000000000000000000000000000000000000000000000000000002'),
      );

      final publicKey1 = keyDerivationService.derivePublicKey(privateKey1);
      final publicKey2 = keyDerivationService.derivePublicKey(privateKey2);

      expect(publicKey1, isNot(equals(publicKey2)));
    });
  });

  group('Ethereum Address Derivation', () {
    test('deriveAddress generates valid Ethereum address', () {
      // Generate a public key
      final privateKey = Uint8List.fromList(
        HEX.decode('1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'),
      );
      final publicKey = keyDerivationService.derivePublicKey(privateKey);

      final address = keyDerivationService.deriveAddress(publicKey);

      // Address should start with 0x and be 42 characters (0x + 40 hex chars)
      expect(address.startsWith('0x'), isTrue);
      expect(address.length, equals(42));
    });

    test('deriveAddress produces consistent results', () {
      final privateKey = Uint8List.fromList(
        HEX.decode('1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'),
      );
      final publicKey = keyDerivationService.derivePublicKey(privateKey);

      final address1 = keyDerivationService.deriveAddress(publicKey);
      final address2 = keyDerivationService.deriveAddress(publicKey);

      expect(address1, equals(address2));
    });

    test('deriveAddress produces different addresses for different public keys', () {
      final privateKey1 = Uint8List.fromList(
        HEX.decode('0000000000000000000000000000000000000000000000000000000000000001'),
      );
      final privateKey2 = Uint8List.fromList(
        HEX.decode('0000000000000000000000000000000000000000000000000000000000000002'),
      );

      final publicKey1 = keyDerivationService.derivePublicKey(privateKey1);
      final publicKey2 = keyDerivationService.derivePublicKey(privateKey2);

      final address1 = keyDerivationService.deriveAddress(publicKey1);
      final address2 = keyDerivationService.deriveAddress(publicKey2);

      expect(address1, isNot(equals(address2)));
    });
  });

  group('Complete Wallet Key Derivation', () {
    test('deriveWalletKeys generates complete wallet keys from mnemonic', () {
      // Use a test mnemonic
      final mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';

      final walletKeys = keyDerivationService.deriveWalletKeys(mnemonic);

      // Verify all components are present
      expect(walletKeys.privateKey.length, equals(32));
      expect(walletKeys.publicKey.length, equals(64));
      expect(walletKeys.address.startsWith('0x'), isTrue);
      expect(walletKeys.address.length, equals(42));
    });

    test('deriveWalletKeys produces consistent results for same mnemonic', () {
      final mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';

      final walletKeys1 = keyDerivationService.deriveWalletKeys(mnemonic);
      final walletKeys2 = keyDerivationService.deriveWalletKeys(mnemonic);

      expect(walletKeys1.privateKey, equals(walletKeys2.privateKey));
      expect(walletKeys1.publicKey, equals(walletKeys2.publicKey));
      expect(walletKeys1.address, equals(walletKeys2.address));
    });

    test('derivePrivateKey derives key using BIP44 Ethereum path', () {
      final mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';

      final privateKey = keyDerivationService.derivePrivateKey(mnemonic);

      expect(privateKey.length, equals(32));
    });
  });
}
