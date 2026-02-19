import 'package:aimo_wallet/features/transaction/domain/entities/transaction.dart';
import 'package:aimo_wallet/features/transaction/domain/services/transaction_signer.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_lock_controller.dart';

/// Transaction Signing Example
/// 
/// Demonstrates complete flow for signing EVM transactions:
/// 1. Create transaction
/// 2. Unlock wallet
/// 3. Sign transaction with private key
/// 4. Broadcast signed transaction (not implemented here)
/// 
/// Security:
/// - Private key derived at runtime only
/// - Private key cleared after signing
/// - Wallet must be unlocked before signing
/// - Mnemonic never stored globally
void main() async {
  // Initialize services
  final lockController = WalletLockController();
  final signer = TransactionSigner();

  // User's PIN (in production, get from secure input)
  const pin = '123456';

  print('=== Transaction Signing Example ===\n');

  // Step 1: Check if wallet exists
  final hasWallet = await lockController.hasWallet();
  if (!hasWallet) {
    print('Error: No wallet found. Create wallet first.');
    return;
  }

  // Step 2: Unlock wallet
  print('Unlocking wallet...');
  final unlocked = await lockController.unlock(pin);
  if (!unlocked) {
    print('Error: Failed to unlock wallet');
    return;
  }
  print('✓ Wallet unlocked\n');

  // Step 3: Create transaction
  print('Creating transaction...');
  final transaction = EvmTransaction(
    to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    value: BigInt.from(1000000000000000000), // 1 ETH
    gasPrice: BigInt.from(20000000000), // 20 Gwei
    gasLimit: BigInt.from(21000),
    nonce: 0,
    chainId: 1, // Ethereum mainnet
  );

  print('Transaction details:');
  print('  To: ${transaction.to}');
  print('  Value: ${transaction.value} Wei (1 ETH)');
  print('  Gas Price: ${transaction.gasPrice} Wei (20 Gwei)');
  print('  Gas Limit: ${transaction.gasLimit}');
  print('  Nonce: ${transaction.nonce}');
  print('  Chain ID: ${transaction.chainId}');
  print('');

  // Step 4: Calculate transaction cost
  final fee = signer.calculateTransactionFee(transaction);
  final totalCost = signer.calculateTotalCost(transaction);
  print('Transaction cost:');
  print('  Fee: $fee Wei');
  print('  Total: $totalCost Wei');
  print('');

  // Step 5: Sign transaction with private key
  print('Signing transaction...');
  try {
    final signedTx = await lockController.executeWithPrivateKey(
      (privateKey) async {
        // Sign transaction with private key
        // Private key will be automatically cleared after this operation
        return await signer.signTransactionSecure(
          transaction: transaction,
          privateKey: privateKey,
        );
      },
      pin: pin,
    );

    print('✓ Transaction signed successfully\n');
    print('Signed transaction:');
    print('  Raw TX: ${signedTx.rawTransaction.substring(0, 66)}...');
    print('  TX Hash: ${signedTx.transactionHash}');
    print('');

    // Step 6: Broadcast transaction (not implemented)
    print('Next step: Broadcast transaction to network');
    print('  Use Web3 provider to send raw transaction');
    print('  Example: web3.eth.sendRawTransaction(rawTransaction)');
  } catch (e) {
    print('Error signing transaction: $e');
  }

  // Step 7: Lock wallet
  print('\nLocking wallet...');
  lockController.lock();
  print('✓ Wallet locked');

  print('\n=== Example Complete ===');
}

/// Example: Sign transaction with contract interaction
void exampleContractInteraction() async {
  final lockController = WalletLockController();
  final signer = TransactionSigner();
  const pin = '123456';

  // Unlock wallet
  await lockController.unlock(pin);

  // Create transaction with data (contract call)
  final transaction = EvmTransaction(
    to: '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI contract
    value: BigInt.zero,
    gasPrice: BigInt.from(20000000000),
    gasLimit: BigInt.from(100000),
    nonce: 0,
    chainId: 1,
    data: '0xa9059cbb' // transfer(address,uint256) function selector
        '000000000000000000000000742d35Cc6634C0532925a3b844Bc9e7595f0bEb' // recipient
        '0000000000000000000000000000000000000000000000000de0b6b3a7640000', // amount (1 DAI)
  );

  // Sign transaction
  final signedTx = await lockController.executeWithPrivateKey(
    (privateKey) async {
      return await signer.signTransactionSecure(
        transaction: transaction,
        privateKey: privateKey,
      );
    },
    pin: pin,
  );

  print('Contract interaction signed: ${signedTx.transactionHash}');

  // Lock wallet
  lockController.lock();
}

/// Example: Sign multiple transactions in sequence
void exampleBatchSigning() async {
  final lockController = WalletLockController();
  final signer = TransactionSigner();
  const pin = '123456';

  // Unlock wallet once
  await lockController.unlock(pin);

  // Sign multiple transactions
  final transactions = [
    EvmTransaction(
      to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
      value: BigInt.from(1000000000000000000),
      gasPrice: BigInt.from(20000000000),
      gasLimit: BigInt.from(21000),
      nonce: 0,
      chainId: 1,
    ),
    EvmTransaction(
      to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
      value: BigInt.from(2000000000000000000),
      gasPrice: BigInt.from(20000000000),
      gasLimit: BigInt.from(21000),
      nonce: 1, // Increment nonce
      chainId: 1,
    ),
  ];

  for (var i = 0; i < transactions.length; i++) {
    final signedTx = await lockController.executeWithPrivateKey(
      (privateKey) async {
        return await signer.signTransactionSecure(
          transaction: transactions[i],
          privateKey: privateKey,
        );
      },
      pin: pin,
    );

    print('Transaction ${i + 1} signed: ${signedTx.transactionHash}');
  }

  // Lock wallet
  lockController.lock();
}

/// Example: Error handling
void exampleErrorHandling() async {
  final lockController = WalletLockController();
  final signer = TransactionSigner();
  const pin = '123456';

  try {
    // Attempt to sign without unlocking
    await lockController.executeWithPrivateKey(
      (privateKey) async {
        final transaction = EvmTransaction(
          to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        return await signer.signTransactionSecure(
          transaction: transaction,
          privateKey: privateKey,
        );
      },
      pin: pin,
    );
  } catch (e) {
    print('Expected error: $e');
    // Error: Wallet is locked
  }

  // Unlock wallet
  await lockController.unlock(pin);

  try {
    // Attempt to sign invalid transaction
    await lockController.executeWithPrivateKey(
      (privateKey) async {
        final invalidTransaction = EvmTransaction(
          to: '', // Invalid address
          value: BigInt.from(1000000000000000000),
          gasPrice: BigInt.from(20000000000),
          gasLimit: BigInt.from(21000),
          nonce: 0,
          chainId: 1,
        );

        return await signer.signTransactionSecure(
          transaction: invalidTransaction,
          privateKey: privateKey,
        );
      },
      pin: pin,
    );
  } catch (e) {
    print('Expected error: $e');
    // Error: Invalid transaction
  }

  // Lock wallet
  lockController.lock();
}
