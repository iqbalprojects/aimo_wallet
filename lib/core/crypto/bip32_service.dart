import 'dart:typed_data';

/// Extended Key for BIP32 Hierarchical Deterministic Key Derivation
class ExtendedKey {
  final Uint8List key;
  final Uint8List chainCode;
  final int depth;
  final int index;
  final Uint8List parentFingerprint;

  ExtendedKey({
    required this.key,
    required this.chainCode,
    required this.depth,
    required this.index,
    required this.parentFingerprint,
  });
}

/// BIP32 Hierarchical Deterministic Key Derivation Service
/// 
/// Responsibility: Derive keys according to BIP32 specification.
/// - Derive master key from seed using HMAC-SHA512
/// - Derive child keys using hardened and normal derivation
/// - Parse and validate derivation paths (e.g., m/44'/60'/0'/0/0)
/// 
/// Security: Keys held in memory only during derivation, cleared after use
abstract class Bip32Service {
  /// Derive master key from seed using HMAC-SHA512 with key "Bitcoin seed"
  ExtendedKey deriveMasterKey(Uint8List seed);

  /// Derive child key from parent using derivation path
  /// Path format: m/44'/60'/0'/0/0 (hardened indices marked with ')
  ExtendedKey deriveKey(ExtendedKey parent, String path);

  /// Derive private key at specific path from seed
  Uint8List derivePrivateKey(Uint8List seed, String path);
}
