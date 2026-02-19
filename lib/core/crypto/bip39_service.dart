import 'dart:typed_data';

/// BIP39 Mnemonic Service
/// 
/// Responsibility: Generate and validate BIP39 mnemonics according to the standard.
/// - Generate 24-word mnemonics from 256-bit entropy
/// - Validate mnemonics (word count, word list, checksum)
/// - Convert mnemonics to seeds using PBKDF2
/// - Normalize mnemonics (lowercase, whitespace)
/// 
/// Security: Never logs or persists mnemonics in plaintext
abstract class Bip39Service {
  /// Generate a 24-word mnemonic from 256 bits of cryptographically secure entropy
  String generateMnemonic();

  /// Validate a mnemonic against BIP39 rules (word count, word list, checksum)
  bool validateMnemonic(String mnemonic);

  /// Convert mnemonic to 512-bit seed using PBKDF2-HMAC-SHA512
  /// Uses 2048 iterations with salt "mnemonic" + passphrase
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''});

  /// Normalize mnemonic: trim, lowercase, collapse multiple spaces
  String normalizeMnemonic(String mnemonic);
}
