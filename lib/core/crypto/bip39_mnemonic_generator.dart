import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'bip39_wordlist.dart';

/// BIP39 Mnemonic Generator
/// 
/// Implements BIP39 mnemonic generation from scratch according to the standard.
/// Generates 24-word mnemonics from 256 bits of cryptographically secure entropy.
/// 
/// Standard: BIP39 (Bitcoin Improvement Proposal 39)
/// Reference: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
class Bip39MnemonicGenerator {
  final Random _random;

  /// Create a new mnemonic generator
  /// 
  /// Uses Random.secure() by default for cryptographically secure random generation.
  /// A custom Random instance can be provided for testing purposes.
  Bip39MnemonicGenerator({Random? random}) 
      : _random = random ?? Random.secure();

  /// Generate a 24-word mnemonic from 256 bits of entropy
  /// 
  /// Process:
  /// 1. Generate 256 bits (32 bytes) of cryptographically secure random entropy
  /// 2. Calculate checksum: first 8 bits of SHA-256(entropy)
  /// 3. Combine entropy + checksum = 264 bits
  /// 4. Split into 24 groups of 11 bits each
  /// 5. Convert each 11-bit group to a word from the BIP39 word list
  /// 
  /// Returns: A 24-word mnemonic phrase separated by spaces
  String generateMnemonic() {
    // Step 1: Generate 256 bits (32 bytes) of entropy
    final entropy = _generateEntropy(32);

    // Step 2: Calculate checksum (first 8 bits of SHA-256)
    final checksum = _calculateChecksum(entropy, 8);

    // Step 3: Combine entropy + checksum
    final combined = _combineEntropyAndChecksum(entropy, checksum, 8);

    // Step 4 & 5: Convert to mnemonic words
    final mnemonic = _convertToMnemonic(combined, 24);

    return mnemonic;
  }

  /// Generate cryptographically secure random entropy
  /// 
  /// Uses Random.secure() to generate the specified number of random bytes.
  Uint8List _generateEntropy(int byteCount) {
    final entropy = Uint8List(byteCount);
    for (int i = 0; i < byteCount; i++) {
      entropy[i] = _random.nextInt(256);
    }
    return entropy;
  }

  /// Calculate checksum using SHA-256
  /// 
  /// Takes the first `checksumBits` bits of SHA-256(entropy).
  /// For 256-bit entropy, checksum is 8 bits (256/32).
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

  /// Combine entropy and checksum into a single bit array
  /// 
  /// Appends the checksum bits to the entropy bits.
  List<int> _combineEntropyAndChecksum(
    Uint8List entropy,
    int checksum,
    int checksumBits,
  ) {
    final totalBits = (entropy.length * 8) + checksumBits;
    final bits = List<int>.filled(totalBits, 0);

    // Add entropy bits
    for (int i = 0; i < entropy.length * 8; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = 7 - (i % 8);
      bits[i] = (entropy[byteIndex] >> bitIndex) & 1;
    }

    // Add checksum bits
    for (int i = 0; i < checksumBits; i++) {
      final bitIndex = (entropy.length * 8) + i;
      final checksumBitIndex = checksumBits - 1 - i;
      bits[bitIndex] = (checksum >> checksumBitIndex) & 1;
    }

    return bits;
  }

  /// Convert bit array to mnemonic words
  /// 
  /// Splits the bit array into 11-bit groups and converts each to a word.
  /// Each 11-bit group represents an index (0-2047) in the BIP39 word list.
  String _convertToMnemonic(List<int> bits, int wordCount) {
    final words = <String>[];

    for (int i = 0; i < wordCount; i++) {
      // Extract 11 bits for this word
      int index = 0;
      for (int j = 0; j < 11; j++) {
        final bitIndex = (i * 11) + j;
        index = (index << 1) | bits[bitIndex];
      }

      // Get word from word list
      words.add(Bip39WordList.getWord(index));
    }

    return words.join(' ');
  }
}
