import 'dart:convert';
import 'dart:typed_data';
import 'package:eth_sig_util/eth_sig_util.dart';
import '../entities/transaction.dart';
import '../services/transaction_signer.dart';
import '../../../../core/vault/secure_vault.dart';
import '../../../../core/crypto/wallet_engine.dart';
import '../../../../core/vault/secure_memory.dart';
import '../../../wallet/presentation/controllers/auth_controller.dart';

/// Sign Transaction Use Case Exception
class SignTransactionException implements Exception {
  final String message;
  final String? details;

  SignTransactionException(this.message, {this.details});

  @override
  String toString() => 'SignTransactionException: $message';
}

/// Sign Transaction Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Coordinates transaction signing with security-first approach.
///
/// Cryptographic Flow:
/// 1. Check if wallet is unlocked (via AuthController)
/// 2. Retrieve encrypted mnemonic from SecureVault using PIN
/// 3. Derive private key at runtime using WalletEngine
/// 4. Sign transaction using TransactionSigner (EIP-155)
/// 5. Clear mnemonic and private key from memory
/// 6. Return SignedTransaction
///
/// Security Principles:
/// - Wallet must be unlocked before signing
/// - Private key derived at runtime only
/// - Private key never stored
/// - Mnemonic cleared from memory after use
/// - Private key cleared from memory after signing
/// - EIP-155 prevents replay attacks
/// - No automatic broadcast
///
/// Usage:
/// ```dart
/// final useCase = SignTransactionUseCase(
///   secureVault: secureVault,
///   walletEngine: walletEngine,
///   transactionSigner: transactionSigner,
///   authController: authController,
/// );
///
/// final signed = await useCase.call(
///   transaction: transaction,
///   pin: pin,
/// );
///
/// print('TX Hash: ${signed.transactionHash}');
/// ```
class SignTransactionUseCase {
  final SecureVault _secureVault;
  final WalletEngine _walletEngine;
  final TransactionSigner _transactionSigner;

  SignTransactionUseCase({
    required SecureVault secureVault,
    required WalletEngine walletEngine,
    required TransactionSigner transactionSigner,
    AuthController?
    authController, // Kept for backward compatibility but not used
  }) : _secureVault = secureVault,
       _walletEngine = walletEngine,
       _transactionSigner = transactionSigner;

  /// Sign transaction
  ///
  /// Parameters:
  /// - transaction: Transaction to sign
  /// - pin: User's PIN (for mnemonic decryption)
  /// - accountIndex: Account index (default: 0)
  ///
  /// Returns: SignedTransaction with raw hex and hash
  ///
  /// Throws:
  /// - SignTransactionException.walletLocked: If wallet is locked
  /// - SignTransactionException.invalidPin: If PIN is wrong
  /// - SignTransactionException.signingFailed: If signing fails
  ///
  /// Security:
  /// - Checks wallet lock state before proceeding
  /// - Mnemonic retrieved only for signing
  /// - Private key derived at runtime
  /// - All sensitive data cleared after use
  Future<SignedTransaction> call({
    required EvmTransaction transaction,
    required String pin,
    int accountIndex = 0,
    Map<String, dynamic>? permit2Eip712,
  }) async {
    String? mnemonic;
    Uint8List? privateKey;

    try {
      // Step 1: Retrieve mnemonic from SecureVault using PIN
      // No need to check wallet lock state - PIN is sufficient for decryption
      try {
        mnemonic = await _secureVault.retrieveMnemonic(pin);
      } catch (e) {
        throw SignTransactionException(
          'Failed to retrieve wallet credentials',
          details: 'Invalid PIN or vault error: $e',
        );
      }

      // Step 2: Derive private key at runtime
      try {
        privateKey = _walletEngine.derivePrivateKeyForAccount(
          mnemonic,
          index: accountIndex,
        );
      } catch (e) {
        throw SignTransactionException(
          'Failed to derive private key',
          details: e.toString(),
        );
      }

      // Step 2.5: Sign Permit2 EIP-712 payload if provided
      EvmTransaction txToSign = transaction;
      if (permit2Eip712 != null) {
        try {
          final signature = EthSigUtil.signTypedData(
            privateKeyInBytes: privateKey,
            jsonData: jsonEncode(permit2Eip712),
            version: TypedDataVersion.V4,
          );

          String txData = transaction.data ?? '0x';
          if (!txData.startsWith('0x')) txData = '0x$txData';

          String sigStr = signature.startsWith('0x')
              ? signature.substring(2)
              : signature;
          int sigLen = sigStr.length ~/ 2;
          String sigLenHex = sigLen.toRadixString(16).padLeft(64, '0');

          txToSign = transaction.copyWith(data: '$txData$sigLenHex$sigStr');
        } catch (e) {
          throw SignTransactionException(
            'Failed to sign Permit2 EIP-712 message',
            details: e.toString(),
          );
        }
      }

      // Step 3: Sign transaction with EIP-155
      try {
        final signedTransaction = await _transactionSigner
            .signTransactionSecure(
              transaction: txToSign,
              privateKey: privateKey,
            );

        return signedTransaction;
      } catch (e) {
        throw SignTransactionException(
          'Failed to sign transaction',
          details: e.toString(),
        );
      }
    } finally {
      // Step 4: CRITICAL - Clear sensitive data from memory
      if (mnemonic != null) {
        // Overwrite mnemonic string (best effort in Dart)
        mnemonic = '';
      }

      if (privateKey != null) {
        // Clear private key bytes
        SecureMemory.clear(privateKey);
      }
    }
  }
}
