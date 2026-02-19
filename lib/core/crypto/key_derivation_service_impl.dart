import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'key_derivation_service.dart';
import 'bip39_service.dart';
import 'bip32_service.dart';

/// Key Derivation Service Implementation for EVM Wallets
/// 
/// Derives EVM-compatible keys using BIP44 standard.
/// Derivation path: m/44'/60'/0'/0/0
/// - 44' = BIP44 purpose (hardened)
/// - 60' = Ethereum coin type (hardened)
/// - 0' = Account 0 (hardened)
/// - 0 = External chain (not hardened)
/// - 0 = Address index 0 (not hardened)
/// 
/// Cryptographic Flow:
/// 1. Mnemonic → Seed (BIP39)
/// 2. Seed → Master Key (BIP32)
/// 3. Master Key → Derived Key (BIP44 path)
/// 4. Private Key → Public Key (secp256k1)
/// 5. Public Key → Address (Keccak-256)
/// 
/// Security: Private keys never stored, only derived at runtime
class KeyDerivationServiceImpl implements KeyDerivationService {
  final Bip39Service _bip39Service;
  final Bip32Service _bip32Service;

  /// BIP44 derivation path for Ethereum
  /// m/44'/60'/0'/0/0
  static const String _ethereumPath = "m/44'/60'/0'/0";

  KeyDerivationServiceImpl(this._bip39Service, this._bip32Service);

  @override
  Uint8List derivePrivateKey(String mnemonic) {
    // Step 1: Convert mnemonic to seed (512 bits)
    final seed = _bip39Service.mnemonicToSeed(mnemonic);

    // Step 2: Derive private key using BIP44 path
    // Path: m/44'/60'/0'/0/0 (Ethereum account 0, address 0)
    final privateKey = _bip32Service.derivePrivateKey(seed, "$_ethereumPath/0");

    return privateKey;
  }

  @override
  Uint8List derivePublicKey(Uint8List privateKey) {
    // Derive public key from private key using secp256k1 elliptic curve
    // 1. Multiply private key by generator point G
    // 2. Get uncompressed public key (65 bytes: 0x04 + x + y)
    
    final params = ECCurve_secp256k1();
    final G = params.G;

    // Convert private key to BigInt
    final d = bytesToUnsignedInt(privateKey);

    // Calculate public key point: Q = d * G
    final Q = G * d;

    if (Q == null) {
      throw Exception('Failed to derive public key');
    }

    // Get uncompressed public key (remove 0x04 prefix for Ethereum)
    // Ethereum uses the 64-byte public key (x + y coordinates)
    final xBytes = unsignedIntToBytes(Q.x!.toBigInteger()!);
    final yBytes = unsignedIntToBytes(Q.y!.toBigInteger()!);

    // Pad to 32 bytes each
    final publicKey = Uint8List(64);
    publicKey.setRange(32 - xBytes.length, 32, xBytes);
    publicKey.setRange(64 - yBytes.length, 64, yBytes);

    return publicKey;
  }

  @override
  String deriveAddress(Uint8List publicKey) {
    // Derive Ethereum address from public key
    // 1. Take Keccak-256 hash of public key (64 bytes)
    // 2. Take last 20 bytes of hash
    // 3. Format as 0x-prefixed hex string with checksum

    // Keccak-256 hash
    final hash = keccak256(publicKey);

    // Take last 20 bytes
    final addressBytes = hash.sublist(hash.length - 20);

    // Convert to EthereumAddress for checksum formatting
    final address = EthereumAddress(addressBytes);

    return address.hexEip55;
  }

  @override
  WalletKeys deriveWalletKeys(String mnemonic) {
    // Complete derivation: mnemonic → private key → public key → address
    
    // Step 1: Derive private key
    final privateKey = derivePrivateKey(mnemonic);

    // Step 2: Derive public key
    final publicKey = derivePublicKey(privateKey);

    // Step 3: Derive address
    final address = deriveAddress(publicKey);

    return WalletKeys(
      privateKey: privateKey,
      publicKey: publicKey,
      address: address,
    );
  }

  /// Derive keys for specific account index
  /// Allows multiple accounts from same mnemonic
  WalletKeys deriveAccountKeys(String mnemonic, int accountIndex) {
    // Derive using path: m/44'/60'/0'/0/{accountIndex}
    final seed = _bip39Service.mnemonicToSeed(mnemonic);
    final privateKey = _bip32Service.derivePrivateKey(
      seed,
      "$_ethereumPath/$accountIndex",
    );

    final publicKey = derivePublicKey(privateKey);
    final address = deriveAddress(publicKey);

    return WalletKeys(
      privateKey: privateKey,
      publicKey: publicKey,
      address: address,
    );
  }
}
