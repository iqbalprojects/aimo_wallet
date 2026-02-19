import '../repositories/wallet_repository.dart';

/// Get Wallet Address Use Case
/// 
/// Responsibility: Retrieve wallet address without unlocking.
/// - Get cached address from storage
/// - No decryption required
/// 
/// Requirements: 7.1
/// 
/// Security: Address is public information, safe to retrieve without authentication
class GetWalletAddressUseCase {
  final WalletRepository repository;

  GetWalletAddressUseCase({required this.repository});

  /// Get wallet address without unlocking
  /// 
  /// Returns cached address from storage without decryption.
  /// Returns null if no wallet exists.
  /// 
  /// Requirements: 7.1
  Future<String?> call() async {
    return await repository.getWalletAddress();
  }
}
