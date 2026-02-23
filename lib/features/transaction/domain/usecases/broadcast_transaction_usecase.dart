import '../../../../core/network/rpc_client.dart';
import '../../../../core/network/rpc_exception.dart';
import '../entities/transaction.dart';

/// Broadcast Transaction Result
///
/// Contains information about broadcasted transaction.
class BroadcastResult {
  /// Transaction hash
  final String transactionHash;

  /// Timestamp when broadcasted
  final DateTime timestamp;

  BroadcastResult({required this.transactionHash, required this.timestamp});
}

/// Broadcast Transaction Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Broadcast signed transaction to blockchain network
/// - Handle broadcast errors
/// - Return transaction hash
/// - Track broadcast status
///
/// Security:
/// - Only broadcasts already-signed transactions
/// - Never accesses private keys
/// - Validates transaction format before broadcast
///
/// Usage:
/// ```dart
/// final useCase = BroadcastTransactionUseCase(rpcClient: client);
/// final result = await useCase.call(signedTransaction: signedTx);
/// print('Transaction hash: ${result.transactionHash}');
/// ```
class BroadcastTransactionUseCase {
  final RpcClient _rpcClient;

  BroadcastTransactionUseCase({required RpcClient rpcClient})
    : _rpcClient = rpcClient;

  /// Execute use case
  ///
  /// Parameters:
  /// - signedTransaction: Signed transaction to broadcast
  ///
  /// Returns: BroadcastResult with transaction hash
  ///
  /// Throws:
  /// - InsufficientFundsException: If account has insufficient balance
  /// - NonceTooLowException: If nonce is too low
  /// - GasPriceTooLowException: If gas price is too low
  /// - OutOfGasException: If transaction runs out of gas
  /// - RpcException: For other RPC errors
  /// - Exception: For other errors
  Future<BroadcastResult> call({
    required SignedTransaction signedTransaction,
  }) async {
    try {
      // Validate signed transaction
      if (signedTransaction.rawTransaction.isEmpty) {
        throw Exception('Invalid signed transaction: empty raw transaction');
      }

      print('');
      print('📡 Broadcasting transaction to network...');
      print(
        '   Raw TX: ${signedTransaction.rawTransaction.substring(0, 20)}...',
      );
      print('   Expected Hash: ${signedTransaction.transactionHash}');

      // Broadcast to network
      final txHash = await _rpcClient.sendRawTransaction(
        signedTransaction.rawTransaction,
      );

      print('   Received Hash: $txHash');

      // Verify transaction hash matches (warning only - tx is already broadcast)
      if (txHash.toLowerCase() !=
          signedTransaction.transactionHash.toLowerCase()) {
        print('   ⚠️  WARNING: Transaction hash mismatch!');
        print('   ⚠️  Expected: ${signedTransaction.transactionHash}');
        print('   ⚠️  Received: $txHash');
        print(
          '   ⚠️  Using blockchain hash (authoritative). Transaction IS broadcast.',
        );
      }

      print('   ✅ Transaction broadcast successful!');
      print('');

      return BroadcastResult(
        transactionHash: txHash,
        timestamp: DateTime.now(),
      );
    } on InsufficientFundsException catch (e) {
      print('   ❌ ERROR: Insufficient funds - $e');
      rethrow;
    } on NonceTooLowException catch (e) {
      print('   ❌ ERROR: Nonce too low - $e');
      rethrow;
    } on GasPriceTooLowException catch (e) {
      print('   ❌ ERROR: Gas price too low - $e');
      rethrow;
    } on OutOfGasException catch (e) {
      print('   ❌ ERROR: Out of gas - $e');
      rethrow;
    } on TransactionAlreadyKnownException {
      // Transaction already in mempool, return existing hash
      print('   ⚠️  Transaction already known (already in mempool)');
      return BroadcastResult(
        transactionHash: signedTransaction.transactionHash,
        timestamp: DateTime.now(),
      );
    } on RpcException catch (e) {
      print('   ❌ RPC ERROR: $e');
      rethrow;
    } catch (e) {
      print('   ❌ UNEXPECTED ERROR: $e');
      throw Exception('Failed to broadcast transaction: $e');
    }
  }
}
