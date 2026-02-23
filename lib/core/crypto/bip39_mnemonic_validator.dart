import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'bip39_wordlist.dart';

/// BIP39 Mnemonic Validator
///
/// Implements BIP39 mnemonic validation from scratch according to the standard.
/// Validates word count, word list membership, and checksum.
///
/// Standard: BIP39 (Bitcoin Improvement Proposal 39)
/// Reference: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
class Bip39MnemonicValidator {
  /// Validate a mnemonic against BIP39 rules
  ///
  /// Checks:
  /// 1. Word count (must be 24 words for 256-bit entropy)
  /// 2. All words exist in BIP39 word list
  /// 3. Checksum is valid
  ///
  /// Returns: true if mnemonic is valid, false otherwise
  bool validateMnemonic(String mnemonic) {
    // Normalize the mnemonic first
    final normalized = normalizeMnemonic(mnemonic);
    final words = normalized.split(' ');

    // Check 1: Word count (12 to 24 words allowable in BIP39)
    if (![12, 15, 18, 21, 24].contains(words.length)) {
      return false;
    }

    // Check 2: All words must be in BIP39 word list
    for (final word in words) {
      if (!Bip39WordList.contains(word)) {
        return false;
      }
    }

    // Check 3: Validate checksum
    return _validateChecksum(words);
  }

  /// Normalize mnemonic for consistent processing
  ///
  /// Normalization:
  /// 1. Trim leading/trailing whitespace
  /// 2. Convert to lowercase
  /// 3. Collapse multiple spaces to single space
  ///
  /// Returns: Normalized mnemonic string
  String normalizeMnemonic(String mnemonic) {
    return mnemonic.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validate the checksum of a mnemonic
  ///
  /// Process:
  /// 1. Convert words to indices (11 bits each)
  /// 2. Combine all bits (264 bits total for 24 words)
  /// 3. Split into entropy (256 bits) and checksum (8 bits)
  /// Calculate expected checksum from entropy
  /// 5. Compare with actual checksum
  bool _validateChecksum(List<String> words) {
    // Convert words to bit array
    final bits = _wordsToBits(words);

    // Calculate lengths
    final totalBits = words.length * 11;
    final checksumBitsLen = totalBits ~/ 33;
    final entropyBitsLen = totalBits - checksumBitsLen;

    // Split into entropy and checksum
    final entropyBits = bits.sublist(0, entropyBitsLen);
    final checksumBits = bits.sublist(entropyBitsLen, totalBits);

    // Convert entropy bits to bytes
    final entropy = _bitsToBytes(entropyBits);

    // Calculate expected checksum
    final expectedChecksum = _calculateChecksum(entropy, checksumBitsLen);

    // Convert checksum bits to integer
    int actualChecksum = 0;
    for (int i = 0; i < checksumBits.length; i++) {
      actualChecksum = (actualChecksum << 1) | checksumBits[i];
    }

    return expectedChecksum == actualChecksum;
  }

  /// Convert words to bit array
  ///
  /// Each word represents an 11-bit index in the BIP39 word list.
  List<int> _wordsToBits(List<String> words) {
    final bits = <int>[];

    for (final word in words) {
      final index = Bip39WordList.getIndex(word);

      // Convert index to 11 bits
      for (int i = 10; i >= 0; i--) {
        bits.add((index >> i) & 1);
      }
    }

    return bits;
  }

  /// Convert bit array to bytes
  Uint8List _bitsToBytes(List<int> bits) {
    final byteCount = (bits.length + 7) ~/ 8;
    final bytes = Uint8List(byteCount);

    for (int i = 0; i < bits.length; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = 7 - (i % 8);
      if (bits[i] == 1) {
        bytes[byteIndex] |= (1 << bitIndex);
      }
    }

    return bytes;
  }

  /// Calculate checksum using SHA-256
  ///
  /// Takes the first `checksumBits` bits of SHA-256(entropy).
  int _calculateChecksum(Uint8List entropy, int checksumBits) {
    // Calculate SHA-256 hash
    final hash = sha256.convert(entropy);
    final hashBytes = Uint8List.fromList(hash.bytes);

    // Extract first checksumBits bits
    int checksum = 0;
    for (int i = 0; i < checksumBits; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = 7 - (i % 8);
      final bit = (hashBytes[byteIndex] >> bitIndex) & 1;
      checksum = (checksum << 1) | bit;
    }

    return checksum;
  }
}
