import 'dart:typed_data';

/// Transaction Signer
/// 
/// Responsibility: Sign transactions using secp256k1.
/// - Sign transaction data with private key
/// - Generate v, r, s signature components
/// - Encode signed transaction for broadcast
/// 
/// Security: Private key never stored, only used for signing
abstract class TransactionSigner {
  /// Sign transaction hash with private key
  /// Returns signature (v, r, s)
  Signature sign(Uint8List messageHash, Uint8List privateKey);

  /// Encode signed transaction for broadcast
  String encodeSignedTransaction(
    Map<String, dynamic> transaction,
    Signature signature,
  );
}

/// ECDSA Signature
class Signature {
  final int v;
  final Uint8List r;
  final Uint8List s;

  Signature({
    required this.v,
    required this.r,
    required this.s,
  });
}
