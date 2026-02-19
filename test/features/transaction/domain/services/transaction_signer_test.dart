import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/features/transaction/domain/entities/transaction.dart';
import 'package:aimo_wallet/features/transaction/domain/services/transaction_signer.dart';

void main() {
  group('TransactionSigner', () {
    late TransactionSigner signer;

    setUp(() {
      signer = TransactionSigner();
    });

    group('signTransaction', () {
      test('should sign valid transaction successfully', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000), // 1 ETH
          gasPrice: BigInt.from(20000000000), // 20 Gwei
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1, // Ethereum mainnet
        );

        // Act
        final result = await signer.signTransaction(
          transaction: transaction,
          privateKey: privateKey,
        );

        // Assert
        expect(result.rawTransaction, startsWith('0x'));
        expect(result.transactionHash, startsWith('0x'));
        expect(result.transaction, equals(transaction));
        expect(result.rawTransaction.length, greaterThan(100));
      });

      test('should sign transaction with data payload', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.zero,
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(100000),
          nonce: 0,
          chainId: 1,
          data: '0xa9059cbb', // transfer function selector
        );

        // Act
        final result = await signer.signTransaction(
          transaction: transaction,
          privateKey: privateKey,
        );

        // Assert
        expect(result.rawTransaction, startsWith('0x'));
        expect(result.transactionHash, startsWith('0x'));
      });

      test('should throw exception for empty recipient address', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for negative value', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(-1),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for zero gas price', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.zero,
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for zero gas limit', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.zero,
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for negative nonce', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: -1,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for invalid chain ID', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 0,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for invalid address format (no 0x prefix)', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for invalid address length', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0b', // Too short
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should throw exception for non-hex address', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0xGGGd35Cc6634C0532925a3b844Bc9e7595f0bEb', // Invalid hex
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        expect(
          () => signer.signTransaction(
            transaction: transaction,
            privateKey: privateKey,
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('should sign transactions with different chain IDs (EIP-155)', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final mainnetTx = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1, // Mainnet
        );
        final goerliTx = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 5, // Goerli
        );

        // Act
        final mainnetResult = await signer.signTransaction(
          transaction: mainnetTx,
          privateKey: privateKey,
        );
        final goerliResult = await signer.signTransaction(
          transaction: goerliTx,
          privateKey: privateKey,
        );

        // Assert - Different chain IDs should produce different signatures
        expect(mainnetResult.rawTransaction, isNot(equals(goerliResult.rawTransaction)));
        expect(mainnetResult.transactionHash, isNot(equals(goerliResult.transactionHash)));
      });
    });

    group('signTransactionSecure', () {
      test('should clear private key after successful signing', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act
        final result = await signer.signTransactionSecure(
          transaction: transaction,
          privateKey: privateKey,
        );

        // Assert
        expect(result.rawTransaction, startsWith('0x'));
        // Private key should be cleared (all zeros)
        expect(privateKey.every((byte) => byte == 0), isTrue);
      });

      test('should clear private key even if signing fails', () async {
        // Arrange
        final privateKey = Uint8List.fromList(List.filled(32, 1));
        final invalidTransaction = EvmTransaction(
          to: '', // Invalid
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act & Assert
        try {
          await signer.signTransactionSecure(
            transaction: invalidTransaction,
            privateKey: privateKey,
          );
          fail('Should have thrown exception');
        } catch (e) {
          // Private key should still be cleared
          expect(privateKey.every((byte) => byte == 0), isTrue);
        }
      });
    });

    group('estimateTransactionSize', () {
      test('should estimate size for simple transaction', () {
        // Arrange
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act
        final size = signer.estimateTransactionSize(transaction);

        // Assert
        expect(size, equals(100)); // Base size
      });

      test('should estimate size for transaction with data', () {
        // Arrange
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.zero,
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(100000),
          nonce: 0,
          chainId: 1,
          data: '0xa9059cbb${'0' * 128}', // 68 bytes of data
        );

        // Act
        final size = signer.estimateTransactionSize(transaction);

        // Assert
        expect(size, greaterThan(100)); // Base + data size
      });
    });

    group('calculateTransactionFee', () {
      test('should calculate fee correctly', () {
        // Arrange
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000), // 20 Gwei
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act
        final fee = signer.calculateTransactionFee(transaction);

        // Assert
        // Fee = 20 Gwei * 21000 = 420000 Gwei = 0.00042 ETH
        expect(fee, equals(BigInt.from(420000000000000)));
      });
    });

    group('calculateTotalCost', () {
      test('should calculate total cost correctly', () {
        // Arrange
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000), // 1 ETH
          gasPrice: BigInt.from(20000000000), // 20 Gwei
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act
        final totalCost = signer.calculateTotalCost(transaction);

        // Assert
        // Total = 1 ETH + 0.00042 ETH = 1.00042 ETH
        expect(
          totalCost,
          equals(BigInt.from(1000420000000000000)),
        );
      });

      test('should calculate total cost for zero value transaction', () {
        // Arrange
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.zero,
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        // Act
        final totalCost = signer.calculateTotalCost(transaction);

        // Assert
        // Total = 0 + fee
        expect(totalCost, equals(BigInt.from(420000000000000)));
      });
    });
  });
}
