import '../repositories/transaction_repository.dart';

/// Send Transaction Use Case
/// 
/// Responsibility: Orchestrate transaction sending.
/// - Create transaction
/// - Estimate gas
/// - Sign transaction with private key
/// - Send to network
/// - Return transaction hash
/// 
/// Security: Private key never leaves device, only used for signing
class SendTransactionUseCase {
  final TransactionRepository repository;

  SendTransactionUseCase(this.repository);

  Future<String> call({
    required String from,
    required String to,
    required BigInt value,
    required String privateKey,
    String? data,
  }) async {
    // Create transaction
    // Estimate gas
    // Sign transaction
    // Send to network
    throw UnimplementedError();
  }
}
