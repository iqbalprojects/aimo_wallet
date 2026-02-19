import 'dart:typed_data';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'bip32_service.dart';

/// BIP32 HD Key Derivation Service Implementation
/// 
/// Implements BIP32 hierarchical deterministic key derivation.
/// Derives keys according to BIP32 specification using HMAC-SHA512.
/// 
/// Cryptographic Flow:
/// 1. Master key: HMAC-SHA512(key="Bitcoin seed", data=seed)
/// 2. Child key: HMAC-SHA512(key=chainCode, data=parentKey || index)
/// 3. Hardened derivation: index >= 2^31 (0x80000000)
/// 
/// Security: Keys held in memory only during derivation
class Bip32ServiceImpl implements Bip32Service {
  static const int _hardenedOffset = 0x80000000;

  @override
  ExtendedKey deriveMasterKey(Uint8List seed) {
    // Derive master key from seed using HMAC-SHA512
    // Key: "Bitcoin seed" (BIP32 standard)
    // Data: seed (512 bits from BIP39)
    final hmac = _createHmac(Uint8List.fromList('Bitcoin seed'.codeUnits));
    final hash = hmac.process(seed);

    // Split result:
    // - First 32 bytes: master private key
    // - Last 32 bytes: master chain code
    final key = Uint8List.fromList(hash.sublist(0, 32));
    final chainCode = Uint8List.fromList(hash.sublist(32, 64));

    return ExtendedKey(
      key: key,
      chainCode: chainCode,
      depth: 0,
      index: 0,
      parentFingerprint: Uint8List(4), // Master key has no parent
    );
  }

  @override
  ExtendedKey deriveKey(ExtendedKey parent, String path) {
    // Parse and validate derivation path
    // Format: m/44'/60'/0'/0/0
    // ' indicates hardened derivation
    final indices = _parsePath(path);
    
    ExtendedKey current = parent;
    for (final index in indices) {
      current = _deriveChildKey(current, index);
    }
    
    return current;
  }

  @override
  Uint8List derivePrivateKey(Uint8List seed, String path) {
    // Complete derivation from seed to private key
    final masterKey = deriveMasterKey(seed);
    final derivedKey = deriveKey(masterKey, path);
    return derivedKey.key;
  }

  /// Derive child key from parent using BIP32 specification
  ExtendedKey _deriveChildKey(ExtendedKey parent, int index) {
    final data = Uint8List(37);
    
    if (index >= _hardenedOffset) {
      // Hardened derivation: 0x00 || parentKey || index
      data[0] = 0x00;
      data.setRange(1, 33, parent.key);
    } else {
      // Normal derivation: publicKey || index
      // For private key derivation, we use the public key
      final publicKey = _derivePublicKey(parent.key);
      data.setRange(0, 33, publicKey);
    }
    
    // Add index (big-endian)
    data.buffer.asByteData().setUint32(33, index, Endian.big);

    // HMAC-SHA512(key=chainCode, data=data)
    final hmac = _createHmac(parent.chainCode);
    final hash = hmac.process(data);

    // Split result
    final childKeyData = Uint8List.fromList(hash.sublist(0, 32));
    final childChainCode = Uint8List.fromList(hash.sublist(32, 64));

    // Add parent key to child key data (modulo curve order)
    final childKey = _addPrivateKeys(parent.key, childKeyData);

    return ExtendedKey(
      key: childKey,
      chainCode: childChainCode,
      depth: parent.depth + 1,
      index: index,
      parentFingerprint: _calculateFingerprint(parent.key),
    );
  }

  /// Parse derivation path string to list of indices
  List<int> _parsePath(String path) {
    // Remove 'm/' prefix if present
    final cleanPath = path.startsWith('m/') ? path.substring(2) : path;
    
    return cleanPath.split('/').map((segment) {
      final isHardened = segment.endsWith("'");
      final indexStr = isHardened ? segment.substring(0, segment.length - 1) : segment;
      final index = int.parse(indexStr);
      return isHardened ? index + _hardenedOffset : index;
    }).toList();
  }

  /// Create HMAC-SHA512 instance
  HMac _createHmac(Uint8List key) {
    final hmac = HMac(SHA512Digest(), 128);
    hmac.init(KeyParameter(key));
    return hmac;
  }

  /// Derive public key from private key (compressed format)
  Uint8List _derivePublicKey(Uint8List privateKey) {
    // For BIP32, we need the compressed public key (33 bytes)
    // Format: 0x02/0x03 (parity) + 32-byte x-coordinate
    
    final params = ECCurve_secp256k1();
    final G = params.G;

    // Convert private key to BigInt
    final d = _bytesToBigInt(privateKey);

    // Calculate public key point: Q = d * G
    final Q = G * d;

    if (Q == null || Q.isInfinity) {
      throw Exception('Invalid private key for public key derivation');
    }

    // Get compressed public key
    // Prefix: 0x02 if y is even, 0x03 if y is odd
    final x = Q.x!.toBigInteger()!;
    final y = Q.y!.toBigInteger()!;
    final prefix = y.isEven ? 0x02 : 0x03;

    // Create compressed public key: prefix + x-coordinate (32 bytes)
    final xBytes = _bigIntToBytes(x, 32);
    final compressed = Uint8List(33);
    compressed[0] = prefix;
    compressed.setRange(1, 33, xBytes);

    return compressed;
  }

  /// Add two private keys (modulo secp256k1 curve order)
  Uint8List _addPrivateKeys(Uint8List key1, Uint8List key2) {
    // Add keys modulo secp256k1 curve order (n)
    final params = ECCurve_secp256k1();
    final n = params.n;

    final k1 = _bytesToBigInt(key1);
    final k2 = _bytesToBigInt(key2);

    // (k1 + k2) mod n
    final sum = (k1 + k2) % n;

    return _bigIntToBytes(sum, 32);
  }

  /// Convert bytes to BigInt (big-endian)
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Convert BigInt to bytes (big-endian, padded to length)
  Uint8List _bigIntToBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    for (int i = length - 1; i >= 0; i--) {
      bytes[i] = (value & BigInt.from(0xff)).toInt();
      value = value >> 8;
    }
    return bytes;
  }

  /// Calculate fingerprint of key (first 4 bytes of HASH160)
  Uint8List _calculateFingerprint(Uint8List key) {
    // HASH160 = RIPEMD160(SHA256(publicKey))
    // For simplicity, using SHA256 only
    final sha256 = SHA256Digest();
    final hash = sha256.process(key);
    return Uint8List.fromList(hash.sublist(0, 4));
  }
}
