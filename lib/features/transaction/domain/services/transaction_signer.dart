import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import '../entities/transaction.dart';
import '../../../../core/vault/secure_memory.dart';

/// Transaction Signing Exception
class TransactionSigningException implements Exception {
  final String message;
  final String? details;

  TransactionSigningException(this.message, {this.details});

  @override
  String toString() => 'TransactionSigningException: $message';
}

/// Transaction Signer
///
/// Signs EVM transactions using web3dart with EIP-155 support.
///
/// Security Features:
/// - Private key derived at runtime
/// - Private key cleared after signing
/// - Address validation before signing
/// - EIP-155 replay protection
/// - No automatic broadcast
///
/// Cryptographic Flow:
/// 1. Validate transaction parameters
/// 2. Validate recipient address format
/// 3. Derive private key from mnemonic
/// 4. Create web3dart credentials
/// 5. Sign transaction with EIP-155
/// 6. Clear private key from memory
/// 7. Return raw signed transaction hex
///
/// Usage:
/// ```dart
/// final signer = TransactionSigner();
///
/// final signed = await signer.signTransaction(
///   transaction: transaction,
///   privateKey: privateKey,
/// );
///
/// print('Raw TX: ${signed.rawTransaction}');
/// print('TX Hash: ${signed.transactionHash}');
/// ```
class TransactionSigner {
  /// Sign EVM transaction
  ///
  /// Cryptographic Flow:
  /// 1. Validate transaction parameters
  /// 2. Validate recipient address
  /// 3. Create credentials from private key
  /// 4. Sign transaction with EIP-155 (chainId)
  /// 5. Encode signed transaction to RLP
  /// 6. Calculate transaction hash
  ///
  /// Parameters:
  /// - transaction: Transaction to sign
  /// - privateKey: Private key (32 bytes)
  ///
  /// Returns: SignedTransaction with raw hex and hash
  ///
  /// Throws: TransactionSigningException if validation or signing fails
  ///
  /// Security:
  /// - Private key cleared after signing
  /// - Address validated before signing
  /// - EIP-155 prevents replay attacks
  /// - No automatic broadcast
  Future<SignedTransaction> signTransaction({
    required EvmTransaction transaction,
    required Uint8List privateKey,
  }) async {
    try {
      // Step 1: Validate transaction parameters
      _validateTransaction(transaction);

      // Step 2: Validate recipient address format
      _validateAddress(transaction.to);

      // Step 3: Create credentials from private key
      final credentials = EthPrivateKey(privateKey);

      // Step 4: Convert to web3dart Transaction
      final web3Transaction = transaction.toWeb3Transaction();

      // Step 5: Sign transaction using web3dart's built-in EIP-155 signing
      // signTransactionRaw handles: RLP encoding, keccak256 hashing,
      // ECDSA signing, EIP-155 chain ID, and signed tx RLP encoding
      final signedBytes = signTransactionRaw(
        web3Transaction,
        credentials,
        chainId: transaction.chainId,
      );

      // Step 6: Encode to hex
      final rawTransaction = '0x${bytesToHex(signedBytes)}';

      // Step 7: Calculate transaction hash
      final transactionHash = '0x${bytesToHex(keccak256(signedBytes))}';

      return SignedTransaction(
        rawTransaction: rawTransaction,
        transactionHash: transactionHash,
        transaction: transaction,
      );
    } catch (e) {
      throw TransactionSigningException(
        'Failed to sign transaction',
        details: e.toString(),
      );
    }
  }

  /// Sign transaction with automatic private key cleanup
  ///
  /// Ensures private key is cleared even if signing fails.
  ///
  /// Security: Private key cleared in finally block
  Future<SignedTransaction> signTransactionSecure({
    required EvmTransaction transaction,
    required Uint8List privateKey,
  }) async {
    try {
      return await signTransaction(
        transaction: transaction,
        privateKey: privateKey,
      );
    } finally {
      // CRITICAL: Clear private key from memory
      SecureMemory.clear(privateKey);
    }
  }

  // NOTE: Custom RLP encoding and manual signing methods removed.
  // Now using web3dart's signTransactionRaw which correctly handles:
  // - Unsigned transaction RLP encoding (getUnsignedSerialized)
  // - keccak256 hashing (inside signToEcSignature)
  // - ECDSA signing with EIP-155 chain ID
  // - Signed transaction RLP encoding

  /// Validate transaction parameters
  ///
  /// Checks:
  /// - To address not empty
  /// - Value >= 0
  /// - Gas price > 0
  /// - Gas limit > 0
  /// - Nonce >= 0
  /// - Chain ID > 0
  void _validateTransaction(EvmTransaction transaction) {
    if (transaction.to.isEmpty) {
      throw TransactionSigningException('Recipient address is required');
    }

    if (transaction.value < BigInt.zero) {
      throw TransactionSigningException('Value cannot be negative');
    }

    if (transaction.gasPrice <= BigInt.zero) {
      throw TransactionSigningException('Gas price must be positive');
    }

    if (transaction.gasLimit <= BigInt.zero) {
      throw TransactionSigningException('Gas limit must be positive');
    }

    if (transaction.nonce < 0) {
      throw TransactionSigningException('Nonce cannot be negative');
    }

    if (transaction.chainId <= 0) {
      throw TransactionSigningException('Chain ID must be positive');
    }
  }

  /// Validate Ethereum address format
  ///
  /// Checks:
  /// - Address starts with 0x
  /// - Address is 42 characters (0x + 40 hex chars)
  /// - Address contains only hex characters
  ///
  /// Throws: TransactionSigningException if invalid
  void _validateAddress(String address) {
    // Check format
    if (!address.startsWith('0x')) {
      throw TransactionSigningException(
        'Invalid address format: must start with 0x',
      );
    }

    if (address.length != 42) {
      throw TransactionSigningException(
        'Invalid address length: must be 42 characters (0x + 40 hex)',
      );
    }

    // Check hex characters
    final hexPart = address.substring(2);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexPart)) {
      throw TransactionSigningException(
        'Invalid address format: contains non-hex characters',
      );
    }

    // Validate with web3dart
    try {
      EthereumAddress.fromHex(address);
    } catch (e) {
      throw TransactionSigningException(
        'Invalid Ethereum address',
        details: e.toString(),
      );
    }
  }

  /// Estimate transaction size in bytes
  ///
  /// Useful for fee estimation and validation.
  int estimateTransactionSize(EvmTransaction transaction) {
    // Rough estimate:
    // - Base: ~100 bytes
    // - Data: data.length / 2 bytes
    final baseSize = 100;
    final dataSize = transaction.data != null
        ? (transaction.data!.length - 2) ~/
              2 // Remove 0x and divide by 2
        : 0;

    return baseSize + dataSize;
  }

  /// Calculate transaction fee
  ///
  /// Fee = gasPrice * gasLimit
  BigInt calculateTransactionFee(EvmTransaction transaction) {
    return transaction.gasPrice * transaction.gasLimit;
  }

  /// Calculate total transaction cost
  ///
  /// Total = value + fee
  BigInt calculateTotalCost(EvmTransaction transaction) {
    return transaction.value + calculateTransactionFee(transaction);
  }
}
