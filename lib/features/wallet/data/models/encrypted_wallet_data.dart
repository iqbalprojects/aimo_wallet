import 'dart:convert';

/// Encrypted Wallet Data Model
/// 
/// Responsibility: Data transfer object for encrypted wallet storage.
/// - Encrypted mnemonic (base64-encoded ciphertext)
/// - Encryption metadata (IV, salt, auth tag)
/// - Cached address for quick access
/// - Creation timestamp
/// 
/// Security: Only encrypted data stored, never plaintext
class EncryptedWalletData {
  final String encryptedMnemonic; // Base64-encoded ciphertext
  final String iv; // Base64-encoded IV
  final String salt; // Base64-encoded salt
  final String? authTag; // Base64-encoded auth tag (for GCM)
  final String address; // Cached Ethereum address
  final DateTime createdAt;

  EncryptedWalletData({
    required this.encryptedMnemonic,
    required this.iv,
    required this.salt,
    this.authTag,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'encryptedMnemonic': encryptedMnemonic,
    'iv': iv,
    'salt': salt,
    'authTag': authTag,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EncryptedWalletData.fromJson(Map<String, dynamic> json) {
    return EncryptedWalletData(
      encryptedMnemonic: json['encryptedMnemonic'],
      iv: json['iv'],
      salt: json['salt'],
      authTag: json['authTag'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory EncryptedWalletData.fromJsonString(String jsonString) {
    return EncryptedWalletData.fromJson(jsonDecode(jsonString));
  }
}
