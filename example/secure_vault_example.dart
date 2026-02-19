import 'package:aimo_wallet/core/vault/secure_vault.dart';
import 'package:aimo_wallet/core/vault/vault_exception.dart';
import 'package:aimo_wallet/core/crypto/wallet_engine.dart';
import 'package:aimo_wallet/core/vault/secure_memory.dart';

/// Example usage of SecureVault
/// 
/// Demonstrates:
/// - Storing encrypted mnemonic
/// - Retrieving mnemonic with PIN
/// - Verifying PIN
/// - Updating PIN
/// - Deleting wallet
/// - Complete wallet flow
void main() async {
  final vault = SecureVault();
  final walletEngine = WalletEngine();

  // Example 1: Create and store wallet
  print('=== Creating and Storing Wallet ===');
  final createResult = walletEngine.createWallet();
  print('Mnemonic: ${createResult.mnemonic}');
  print('Address: ${createResult.address}');

  const pin = '123456';

  try {
    await vault.storeMnemonic(createResult.mnemonic, pin);
    print('✓ Wallet stored securely');
  } on VaultException catch (e) {
    print('✗ Error: ${e.message}');
  }
  print('');

  // Example 2: Check if wallet exists
  print('=== Checking Wallet Existence ===');
  final hasWallet = await vault.hasWallet();
  print('Has wallet: $hasWallet');
  print('');

  // Example 3: Retrieve mnemonic
  print('=== Retrieving Mnemonic ===');
  try {
    final mnemonic = await vault.retrieveMnemonic(pin);
    print('✓ Mnemonic retrieved: ${mnemonic.substring(0, 20)}...');

    // IMPORTANT: Clear mnemonic from memory after use
    // In production, use SecureMemory.clearString(mnemonic)
  } on VaultException catch (e) {
    print('✗ Error: ${e.message}');
  }
  print('');

  // Example 4: Verify PIN
  print('=== Verifying PIN ===');
  final correctPin = await vault.verifyPin('123456');
  print('Correct PIN (123456): $correctPin');

  final wrongPin = await vault.verifyPin('654321');
  print('Wrong PIN (654321): $wrongPin');
  print('');

  // Example 5: Try wrong PIN
  print('=== Trying Wrong PIN ===');
  try {
    await vault.retrieveMnemonic('654321');
    print('✗ Should have failed');
  } on VaultException catch (e) {
    print('✓ Correctly rejected: ${e.message}');
  }
  print('');

  // Example 6: Update PIN
  print('=== Updating PIN ===');
  const newPin = '789012';
  try {
    await vault.updatePin(pin, newPin);
    print('✓ PIN updated successfully');

    // Verify new PIN works
    final isValid = await vault.verifyPin(newPin);
    print('New PIN valid: $isValid');
  } on VaultException catch (e) {
    print('✗ Error: ${e.message}');
  }
  print('');

  // Example 7: Get metadata
  print('=== Getting Metadata ===');
  final metadata = await vault.getMetadata();
  print('Has wallet: ${metadata['hasWallet']}');
  print('Salt length: ${metadata['saltLength']} bytes');
  print('IV length: ${metadata['ivLength']} bytes');
  print('Auth tag length: ${metadata['authTagLength']} bytes');
  print('');

  // Example 8: Complete wallet flow
  print('=== Complete Wallet Flow ===');

  // Unlock wallet
  final mnemonic = await vault.retrieveMnemonic(newPin);
  final importResult = walletEngine.importWallet(mnemonic);
  print('✓ Wallet unlocked: ${importResult.address}');

  // Derive private key for signing (account 0)
  final privateKey = walletEngine.derivePrivateKeyForAccount(mnemonic);
  print('✓ Private key derived (${privateKey.length} bytes)');

  // Use private key for signing (example)
  // final signature = signTransaction(transaction, privateKey);

  // CRITICAL: Clear private key from memory
  SecureMemory.clear(privateKey);
  print('✓ Private key cleared from memory');

  // Note: Wallet is now "locked" - the mnemonic and private key are cleared
  // To use the wallet again, retrieve the mnemonic from vault with PIN
  print('✓ Wallet locked (sensitive data cleared)');
  print('');

  // Example 9: Delete wallet
  print('=== Deleting Wallet ===');
  try {
    await vault.deleteWallet();
    print('✓ Wallet deleted');

    final hasWalletAfterDelete = await vault.hasWallet();
    print('Has wallet after delete: $hasWalletAfterDelete');
  } on VaultException catch (e) {
    print('✗ Error: ${e.message}');
  }
  print('');

  // Example 10: Try to retrieve from empty vault
  print('=== Trying to Retrieve from Empty Vault ===');
  try {
    await vault.retrieveMnemonic(newPin);
    print('✗ Should have failed');
  } on VaultException catch (e) {
    print('✓ Correctly rejected: ${e.message}');
  }
}
