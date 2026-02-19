import 'dart:typed_data';

/// Wallet Status
enum WalletStatus {
  notCreated,
  locked,
  unlocked,
}

/// Wallet Entity
/// 
/// Responsibility: Represent wallet state in the domain layer.
/// - Address: Ethereum address (0x-prefixed)
/// - Private key: Only present when unlocked (held in memory)
/// - Status: Current wallet state
/// 
/// Security: Private key only exists in memory during unlocked session
class Wallet {
  final String address;
  final Uint8List? privateKey; // Only present when unlocked
  final WalletStatus status;

  Wallet({
    required this.address,
    this.privateKey,
    required this.status,
  });

  bool get isLocked => status == WalletStatus.locked;
  bool get isUnlocked => status == WalletStatus.unlocked;
  bool get exists => status != WalletStatus.notCreated;

  Wallet copyWith({
    String? address,
    Uint8List? privateKey,
    WalletStatus? status,
  }) {
    return Wallet(
      address: address ?? this.address,
      privateKey: privateKey ?? this.privateKey,
      status: status ?? this.status,
    );
  }
}
