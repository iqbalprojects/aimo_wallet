import 'package:aimo_wallet/core/crypto/wallet_engine.dart';

/// Example usage of WalletEngine
/// 
/// Demonstrates:
/// - Creating new wallet
/// - Importing existing wallet
/// - Deriving multiple accounts
/// - Getting current address
/// - Deriving private keys (for signing)
void main() {
  final walletEngine = WalletEngine();

  // Example 1: Create new wallet
  print('=== Creating New Wallet ===');
  final createResult = walletEngine.createWallet();
  print('Mnemonic: ${createResult.mnemonic}');
  print('Address: ${createResult.address}');
  print('');

  // IMPORTANT: In production, encrypt mnemonic before storage
  // Never store mnemonic in plaintext!

  // Example 2: Import existing wallet
  print('=== Importing Wallet ===');
  const testMnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon art';

  final importResult = walletEngine.importWallet(testMnemonic);
  if (importResult.isValid) {
    print('Import successful!');
    print('Address: ${importResult.address}');
  } else {
    print('Import failed: ${importResult.error}');
  }
  print('');

  // Example 3: Derive multiple accounts
  print('=== Deriving Multiple Accounts ===');
  for (int i = 0; i < 3; i++) {
    final account = walletEngine.deriveAccount(testMnemonic, i);
    print('Account $i: ${account.address}');
  }
  print('');

  // Example 4: Derive private key for signing (account 0)
  print('=== Deriving Private Key ===');
  final privateKey = walletEngine.derivePrivateKeyForAccount(testMnemonic);
  print('Private Key Length: ${privateKey.length} bytes');
  print('Private Key (first 8 bytes): ${privateKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
  print('');

  // IMPORTANT: Clear private key from memory after use
  // In production, use SecureMemory.clear(privateKey)

  // Example 5: Derive private key for different account
  print('=== Deriving Private Key for Account 1 ===');
  final privateKey1 = walletEngine.derivePrivateKeyForAccount(testMnemonic, index: 1);
  print('Account 1 Private Key Length: ${privateKey1.length} bytes');
  print('Account 1 Private Key (first 8 bytes): ${privateKey1.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
  print('');

  // Example 6: Validate mnemonic
  print('=== Validating Mnemonic ===');
  const validMnemonic = testMnemonic;
  const invalidMnemonic = 'invalid mnemonic phrase';

  print('Valid mnemonic: ${walletEngine.validateMnemonic(validMnemonic)}');
  print('Invalid mnemonic: ${walletEngine.validateMnemonic(invalidMnemonic)}');
  print('');

  // Note: WalletEngine is stateless - it doesn't maintain session state
  // To "lock" the wallet, simply clear sensitive data from memory
  // To "unlock", retrieve the mnemonic from secure storage and derive keys again
}
