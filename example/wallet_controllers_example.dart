/// Example usage of Wallet Presentation Controllers
/// 
/// This example demonstrates the controller interfaces and flow.
/// Note: Full implementation requires completed use cases and repository.
/// 
/// Demonstrates complete wallet lifecycle:
/// 1. Create new wallet
/// 2. Display mnemonic for backup
/// 3. Save wallet with PIN
/// 4. Lock wallet
/// 5. Unlock wallet
/// 6. Export mnemonic
/// 7. Verify backup
/// 8. Delete wallet
/// 9. Import existing wallet
void main() async {
  print('=== Wallet Controllers Example ===\n');
  print('This example demonstrates the controller interfaces.');
  print('Full implementation requires completed repository methods.\n');

  // Example 1: Wallet Creation Flow
  print('=== 1. Wallet Creation Flow ===');
  print('');
  print('// Step 1: Generate mnemonic');
  print('await creationController.generateMnemonic();');
  print('');
  print('// Step 2: Display mnemonic with numbering (Requirement 11.2)');
  print('final words = creationController.getMnemonicWords();');
  print('for (int i = 0; i < words.length; i++) {');
  print('  print("\${(i + 1).toString().padLeft(2)}. \${words[i]}");');
  print('}');
  print('');
  print('// Step 3: User confirms backup');
  print('creationController.confirmBackup();');
  print('');
  print('// Step 4: Save wallet with PIN');
  print('const pin = "123456";');
  print('final saved = await creationController.saveWallet(pin);');
  print('');
  print('if (saved) {');
  print('  print("✓ Wallet created and saved");');
  print('  print("Status: \${walletController.status}");');
  print('  print("Address: \${walletController.address}");');
  print('}');
  print('');

  // Example 2: Wallet Import Flow
  print('=== 2. Wallet Import Flow ===');
  print('');
  print('// Step 1: Validate mnemonic and derive address');
  print('const mnemonic = "abandon abandon ... art";');
  print('final validated = await importController.validateAndDeriveAddress(mnemonic);');
  print('');
  print('if (validated) {');
  print('  print("Derived address: \${importController.derivedAddress}");');
  print('  ');
  print('  // Step 2: User confirms address');
  print('  importController.confirmAddress();');
  print('  ');
  print('  // Step 3: Import wallet with PIN');
  print('  const pin = "654321";');
  print('  final imported = await importController.importWallet(mnemonic, pin);');
  print('  ');
  print('  if (imported) {');
  print('    print("✓ Wallet imported successfully");');
  print('  }');
  print('}');
  print('');

  // Example 3: Wallet Unlock Flow
  print('=== 3. Wallet Unlock Flow ===');
  print('');
  print('// Unlock wallet with PIN');
  print('const pin = "123456";');
  print('final unlocked = await unlockController.unlockWallet(pin);');
  print('');
  print('if (unlocked) {');
  print('  print("✓ Wallet unlocked");');
  print('  print("Status: \${walletController.status}");');
  print('} else {');
  print('  print("✗ Failed: \${unlockController.errorMessage}");');
  print('  print("Error type: \${unlockController.errorType}");');
  print('  print("Is auth error: \${unlockController.isAuthenticationError}");');
  print('  print("Is system error: \${unlockController.isSystemError}");');
  print('}');
  print('');

  // Example 4: Export Mnemonic
  print('=== 4. Export Mnemonic (Requires Authentication) ===');
  print('');
  print('// Export mnemonic with PIN authentication');
  print('const pin = "123456";');
  print('final exported = await settingsController.exportMnemonic(pin);');
  print('');
  print('if (exported) {');
  print('  // Display mnemonic with numbering');
  print('  final words = settingsController.getExportedMnemonicWords();');
  print('  for (int i = 0; i < words.length; i++) {');
  print('    print("\${(i + 1).toString().padLeft(2)}. \${words[i]}");');
  print('  }');
  print('  ');
  print('  // Clear from memory after display');
  print('  settingsController.clearExportedMnemonic();');
  print('}');
  print('');

  // Example 5: Verify Backup
  print('=== 5. Verify Backup (Requires Authentication) ===');
  print('');
  print('// Verify backup with PIN authentication');
  print('const enteredMnemonic = "user entered mnemonic...";');
  print('const pin = "123456";');
  print('final verified = await settingsController.verifyBackup(');
  print('  enteredMnemonic,');
  print('  pin,');
  print(');');
  print('');
  print('if (verified) {');
  print('  print("✓ Backup verified successfully");');
  print('} else {');
  print('  print("✗ Backup does not match");');
  print('}');
  print('');

  // Example 6: Delete Wallet
  print('=== 6. Delete Wallet ===');
  print('');
  print('// Delete wallet (requires user confirmation)');
  print('final deleted = await settingsController.deleteWallet();');
  print('');
  print('if (deleted) {');
  print('  print("✓ Wallet deleted");');
  print('  print("Status: \${walletController.status}");');
  print('  print("Has wallet: \${walletController.hasWallet}");');
  print('}');
  print('');

  // Example 7: Error Handling
  print('=== 7. Error Handling ===');
  print('');
  print('// Import controller provides specific error messages');
  print('final validated = await importController.validateAndDeriveAddress(');
  print('  "invalid mnemonic",');
  print(');');
  print('');
  print('if (!validated) {');
  print('  // Error messages distinguish between:');
  print('  // - Invalid length (not 24 words)');
  print('  // - Invalid words (not in BIP39 word list)');
  print('  // - Invalid checksum (checksum verification failed)');
  print('  print("Error: \${importController.errorMessage}");');
  print('}');
  print('');
  print('// Unlock controller distinguishes error types');
  print('final unlocked = await unlockController.unlockWallet("wrong_pin");');
  print('');
  print('if (!unlocked) {');
  print('  if (unlockController.isAuthenticationError) {');
  print('    print("Authentication failed: wrong PIN");');
  print('  } else if (unlockController.isSystemError) {');
  print('    print("System error: corrupted data or storage failure");');
  print('  }');
  print('}');
  print('');

  // Example 8: Controller State Management
  print('=== 8. Controller State Management ===');
  print('');
  print('// WalletController manages global wallet state');
  print('print("Status: \${walletController.status}");');
  print('print("Has wallet: \${walletController.hasWallet}");');
  print('print("Is locked: \${walletController.isLocked}");');
  print('print("Is unlocked: \${walletController.isUnlocked}");');
  print('print("Address: \${walletController.address}");');
  print('');
  print('// Other controllers update WalletController state');
  print('// - Creation/Import: Update to locked with address');
  print('// - Unlock: Update to unlocked');
  print('// - Delete: Update to notCreated');
  print('');

  // Example 9: Security Best Practices
  print('=== 9. Security Best Practices ===');
  print('✓ Mnemonic displayed once during creation (Requirement 11.1)');
  print('✓ Mnemonic shown with numbering 1-24 (Requirement 11.2)');
  print('✓ Mnemonic encrypted before storage (Requirement 11.3)');
  print('✓ PIN required for all sensitive operations (Requirements 11.4, 12.5)');
  print('✓ Mnemonic cleared from memory after use');
  print('✓ Single wallet per device enforced (Requirement 7.2, 7.3)');
  print('✓ Specific error messages for user feedback (Requirement 9.5)');
  print('✓ Authentication errors distinguished from system errors (Requirement 9.5)');
  print('✓ No global mnemonic or private key storage (Requirement 7.5)');
  print('');

  print('=== Example Complete ===');
}
