import 'dart:typed_data';

/// Wallet Keys (Private Key, Public Key, Address)
class WalletKeys {
  final Uint8List privateKey;
  final Uint8List publicKey;
  final String address;

  WalletKeys({
    required this.privateKey,
    required this.publicKey,
    required this.address,
  });
}

/// Key Derivation Service for EVM Wallets
/// 
/// Responsibility: Derive EVM-compatible keys from mnemonics.
/// - Derive private key using BIP44 path m/44'/60'/0'/0/0
/// - Derive public key from private key using secp256k1
/// - Derive Ethereum address from public key using Keccak-256
/// 
/// Security: Private keys never stored, only held in memory during session
abstract class KeyDerivationService {
  /// Derive private key from mnemonic using BIP44 path m/44'/60'/0'/0/0
  Uint8List derivePrivateKey(String mnemonic);

  /// Derive public key from private key using secp256k1 curve
  Uint8List derivePublicKey(Uint8List privateKey);

  /// Derive Ethereum address from public key
  /// Takes Keccak-256 hash of public key, uses last 20 bytes, formats as 0x-prefixed hex
  String deriveAddress(Uint8List publicKey);

  /// Complete derivation: mnemonic -> private key -> public key -> address
  WalletKeys deriveWalletKeys(String mnemonic);
}
