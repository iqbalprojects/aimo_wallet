import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

/// EVM Transaction
///
/// Represents an Ethereum transaction with all required fields.
///
/// Security: Does not contain private key or signature
class EvmTransaction {
  /// Recipient address
  final String to;

  /// Amount to send in Wei
  final BigInt value;

  /// Gas price in Wei
  final BigInt gasPrice;

  /// Gas limit
  final BigInt gasLimit;

  /// Transaction nonce
  final int nonce;

  /// Chain ID (for EIP-155 replay protection)
  final int chainId;

  /// Optional data payload (for contract calls)
  final String? data;

  EvmTransaction({
    required this.to,
    required this.value,
    required this.gasPrice,
    required this.gasLimit,
    required this.nonce,
    required this.chainId,
    this.data,
  });

  /// Convert to web3dart Transaction
  Transaction toWeb3Transaction() {
    return Transaction(
      to: EthereumAddress.fromHex(to),
      value: EtherAmount.inWei(value),
      gasPrice: EtherAmount.inWei(gasPrice),
      maxGas: gasLimit.toInt(),
      nonce: nonce,
      data: data != null ? hexToBytes(data!) : Uint8List(0),
    );
  }

  /// Create from map
  factory EvmTransaction.fromMap(Map<String, dynamic> map) {
    return EvmTransaction(
      to: map['to'] as String,
      value: BigInt.parse(map['value'].toString()),
      gasPrice: BigInt.parse(map['gasPrice'].toString()),
      gasLimit: BigInt.parse(map['gasLimit'].toString()),
      nonce: map['nonce'] as int,
      chainId: map['chainId'] as int,
      data: map['data'] as String?,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'to': to,
      'value': value.toString(),
      'gasPrice': gasPrice.toString(),
      'gasLimit': gasLimit.toString(),
      'nonce': nonce,
      'chainId': chainId,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'EvmTransaction(to: $to, value: $value, gasPrice: $gasPrice, '
        'gasLimit: $gasLimit, nonce: $nonce, chainId: $chainId, data: $data)';
  }
}

/// Signed Transaction Result
///
/// Contains the raw signed transaction hex ready for broadcast.
///
/// Security: Does not contain private key
class SignedTransaction {
  /// Raw signed transaction hex (0x-prefixed)
  final String rawTransaction;

  /// Transaction hash (0x-prefixed)
  final String transactionHash;

  /// Original transaction
  final EvmTransaction transaction;

  SignedTransaction({
    required this.rawTransaction,
    required this.transactionHash,
    required this.transaction,
  });

  @override
  String toString() {
    return 'SignedTransaction(hash: $transactionHash, raw: ${rawTransaction.substring(0, 20)}...)';
  }
}
