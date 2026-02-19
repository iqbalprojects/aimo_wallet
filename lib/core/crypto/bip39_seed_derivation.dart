import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// BIP39 Seed Derivation
/// 
/// Implements BIP39 seed derivation from mnemonic using PBKDF2-HMAC-SHA512.
/// Converts a mnemonic phrase to a 512-bit seed for key derivation.
/// 
/// Standard: BIP39 (Bitcoin Improvement Proposal 39)
/// Reference: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
class Bip39SeedDerivation {
  /// Convert mnemonic to 512-bit seed using PBKDF2-HMAC-SHA512
  /// 
  /// Parameters:
  /// - mnemonic: The BIP39 mnemonic phrase
  /// - passphrase: Optional passphrase (default: empty string)
  /// 
  /// Process:
  /// 1. Password: mnemonic (UTF-8 encoded)
  /// 2. Salt: "mnemonic" + passphrase (UTF-8 encoded)
  /// 3. Iterations: 2048 (BIP39 standard)
  /// 4. Hash: HMAC-SHA512
  /// 5. Output: 64 bytes (512 bits)
  /// 
  /// Returns: 512-bit seed as Uint8List (64 bytes)
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    // Prepare password (mnemonic as UTF-8 bytes)
    final password = Uint8List.fromList(utf8.encode(mnemonic));

    // Prepare salt ("mnemonic" + passphrase as UTF-8 bytes)
    final saltString = 'mnemonic$passphrase';
    final salt = Uint8List.fromList(utf8.encode(saltString));

    // Configure PBKDF2 with HMAC-SHA512
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    
    // Initialize with parameters:
    // - 2048 iterations (BIP39 standard)
    // - 64 bytes output (512 bits)
    pbkdf2.init(Pbkdf2Parameters(salt, 2048, 64));

    // Derive seed
    final seed = pbkdf2.process(password);

    return seed;
  }
}
