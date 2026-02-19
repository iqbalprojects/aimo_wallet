import 'dart:typed_data';
import 'bip39_service.dart';
import 'bip39_mnemonic_generator.dart';
import 'bip39_mnemonic_validator.dart';
import 'bip39_seed_derivation.dart';

/// BIP39 Mnemonic Service Implementation
/// 
/// Implements BIP39 standard for mnemonic generation, validation, and seed derivation.
/// Uses custom implementations for all BIP39 operations.
/// 
/// Security: Never logs or persists mnemonics in plaintext
class Bip39ServiceImpl implements Bip39Service {
  final Bip39MnemonicGenerator _generator;
  final Bip39MnemonicValidator _validator;
  final Bip39SeedDerivation _seedDerivation;

  Bip39ServiceImpl({
    Bip39MnemonicGenerator? generator,
    Bip39MnemonicValidator? validator,
    Bip39SeedDerivation? seedDerivation,
  })  : _generator = generator ?? Bip39MnemonicGenerator(),
        _validator = validator ?? Bip39MnemonicValidator(),
        _seedDerivation = seedDerivation ?? Bip39SeedDerivation();

  @override
  String generateMnemonic() {
    // Generate 256 bits (32 bytes) of entropy for 24-word mnemonic
    // BIP39 standard: 24 words = 256 bits entropy + 8 bits checksum
    // Uses our custom implementation
    return _generator.generateMnemonic();
  }

  @override
  bool validateMnemonic(String mnemonic) {
    // Validates:
    // 1. Word count (24 words for 256-bit entropy)
    // 2. All words exist in BIP39 word list
    // 3. Checksum is valid
    // Uses our custom implementation
    return _validator.validateMnemonic(mnemonic);
  }

  @override
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    // Convert mnemonic to 512-bit seed using PBKDF2-HMAC-SHA512
    // - 2048 iterations (BIP39 standard)
    // - Salt: "mnemonic" + passphrase
    // - Output: 64 bytes (512 bits)
    // Uses our custom implementation
    return _seedDerivation.mnemonicToSeed(mnemonic, passphrase: passphrase);
  }

  @override
  String normalizeMnemonic(String mnemonic) {
    // Normalize mnemonic:
    // 1. Trim whitespace
    // 2. Convert to lowercase
    // 3. Collapse multiple spaces to single space
    // Uses our custom implementation
    return _validator.normalizeMnemonic(mnemonic);
  }
}
