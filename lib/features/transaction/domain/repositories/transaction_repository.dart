import 'package:web3dart/web3dart.dart';


/// Transaction Repository Interface
/// 
/// Responsibility: Define contract for transaction operations.
/// - Create and sign transactions
/// - Send transactions to network
/// - Query transaction status
/// - Estimate gas
abstract class TransactionRepository {
  /// Create unsigned transaction
  Future<Transaction> createTransaction({
    required String from,
    required String to,
    required BigInt value,
    BigInt? gasLimit,
    BigInt? gasPrice,
    String? data,
  });

  /// Sign transaction with private key
  Future<String> signTransaction(Transaction transaction, String privateKey);

  /// Send signed transaction to network
  Future<String> sendTransaction(String signedTx);

  /// Get transaction by hash
  Future<Transaction?> getTransaction(String hash);

  /// Estimate gas for transaction
  Future<BigInt> estimateGas(Transaction transaction);
}
