/// Wallet Credentials Entity
/// 
/// Responsibility: Temporary holder for mnemonic during wallet operations.
/// - Used during wallet creation and import flows
/// - Holds mnemonic and derived address before encryption
/// - Should be cleared from memory after use
/// 
/// Security: This is a temporary entity - mnemonic must be cleared after use
class WalletCredentials {
  final String mnemonic;
  final String address;

  WalletCredentials({
    required this.mnemonic,
    required this.address,
  });

  WalletCredentials copyWith({
    String? mnemonic,
    String? address,
  }) {
    return WalletCredentials(
      mnemonic: mnemonic ?? this.mnemonic,
      address: address ?? this.address,
    );
  }
}
