import 'package:get/get.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_lock_controller.dart';
import 'package:aimo_wallet/features/wallet/domain/entities/wallet_lock_state.dart';

/// Example usage of WalletLockController
/// 
/// Demonstrates:
/// - Unlock wallet with PIN
/// - Execute secure operations
/// - Auto-lock configuration
/// - Biometric authentication
/// - Lock on background
void main() async {
  // Initialize GetX
  Get.testMode = true;

  // Create controller
  final controller = Get.put(WalletLockController());

  // Example 1: Check wallet state
  print('=== Wallet State ===');
  print('Is locked: ${controller.isLocked}');
  print('Is unlocked: ${controller.isUnlocked}');
  print('');

  // Example 2: Unlock wallet with PIN
  print('=== Unlocking Wallet ===');
  const pin = '123456';

  final unlocked = await controller.unlock(pin);
  if (unlocked) {
    print('✓ Wallet unlocked successfully');
    print('Lock state: ${controller.lockState}');
  } else {
    print('✗ Failed to unlock: ${controller.errorMessage}');
  }
  print('');

  // Example 3: Execute secure operation
  print('=== Executing Secure Operation ===');
  try {
    final result = await controller.executeSecureOperation(
      (mnemonic) async {
        print('✓ Mnemonic retrieved (length: ${mnemonic.length})');
        print('✓ Performing operation...');

        // Simulate transaction signing
        await Future.delayed(const Duration(milliseconds: 100));

        return 'transaction_signature_0x123...';
      },
      pin: pin,
    );

    print('✓ Operation completed: $result');
    print('✓ Mnemonic automatically cleared from memory');
  } catch (e) {
    print('✗ Operation failed: $e');
  }
  print('');

  // Example 4: Execute operation with private key
  print('=== Executing with Private Key ===');
  try {
    final signature = await controller.executeWithPrivateKey(
      (privateKey) async {
        print('✓ Private key derived (${privateKey.length} bytes)');
        print('✓ Signing transaction...');

        // Simulate signing
        await Future.delayed(const Duration(milliseconds: 100));

        return 'signature_0xabc...';
      },
      pin: pin,
    );

    print('✓ Transaction signed: $signature');
    print('✓ Private key automatically cleared from memory');
  } catch (e) {
    print('✗ Signing failed: $e');
  }
  print('');

  // Example 5: Configure auto-lock
  print('=== Configuring Auto-Lock ===');
  final newConfig = WalletLockConfig(
    autoLockTimeoutSeconds: 600, // 10 minutes
    lockOnBackground: true,
    biometricEnabled: false,
  );

  controller.updateConfig(newConfig);
  print('✓ Auto-lock timeout: ${controller.config.autoLockTimeoutSeconds}s');
  print('✓ Lock on background: ${controller.config.lockOnBackground}');
  print('✓ Biometric enabled: ${controller.config.biometricEnabled}');
  print('');

  // Example 6: Check time until auto-lock
  print('=== Auto-Lock Status ===');
  final timeUntilLock = controller.getTimeUntilAutoLock();
  if (timeUntilLock != null) {
    print('Time until auto-lock: ${timeUntilLock}s');
  } else {
    print('Auto-lock not active (wallet locked or no activity)');
  }
  print('');

  // Example 7: Enable biometric authentication
  print('=== Biometric Authentication ===');
  print('Biometric available: ${controller.biometricAvailable}');

  if (controller.biometricAvailable) {
    final enabled = await controller.enableBiometric();
    if (enabled) {
      print('✓ Biometric authentication enabled');
    } else {
      print('✗ Failed to enable biometric');
    }
  } else {
    print('Biometric not available on this device');
  }
  print('');

  // Example 8: Lock wallet manually
  print('=== Locking Wallet ===');
  controller.lock();
  print('✓ Wallet locked');
  print('Lock state: ${controller.lockState}');
  print('');

  // Example 9: Try operation when locked
  print('=== Trying Operation When Locked ===');
  try {
    await controller.executeSecureOperation(
      (mnemonic) async => 'result',
      pin: pin,
    );
    print('✗ Should have thrown error');
  } catch (e) {
    print('✓ Correctly prevented: $e');
  }
  print('');

  // Example 10: Authenticate with biometric
  if (controller.biometricAvailable && controller.config.biometricEnabled) {
    print('=== Authenticating with Biometric ===');
    final authenticated = await controller.authenticateWithBiometric();
    if (authenticated) {
      print('✓ Biometric authentication successful');
      print('Note: Still need to call unlock(pin) for actual unlock');
      
      // After biometric auth, still need PIN for actual unlock
      final unlocked = await controller.unlock(pin);
      if (unlocked) {
        print('✓ Wallet unlocked with PIN after biometric auth');
      }
    } else {
      print('✗ Biometric authentication failed');
    }
    print('');
  }

  // Example 11: Complete transaction flow
  print('=== Complete Transaction Flow ===');

  // 1. Unlock wallet
  await controller.unlock(pin);
  print('1. Wallet unlocked');

  // 2. Create transaction
  print('2. Creating transaction...');
  final transaction = {
    'to': '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    'value': '1000000000000000000', // 1 ETH
    'data': '0x',
  };
  print('   Transaction: ${transaction['to']} - ${transaction['value']} wei');

  // 3. Sign transaction with private key
  final signature = await controller.executeWithPrivateKey(
    (privateKey) async {
      print('3. Signing with private key...');
      // In real app: sign transaction with privateKey
      return 'signature_0x...';
    },
    pin: pin,
  );
  print('4. Transaction signed: $signature');

  // 5. Broadcast transaction
  print('5. Broadcasting transaction...');
  // In real app: broadcast to network

  print('6. ✓ Transaction complete');
  print('');

  // Example 12: Security best practices
  print('=== Security Best Practices ===');
  print('✓ Mnemonic never stored globally');
  print('✓ Mnemonic exists only during operations');
  print('✓ Private key cleared after use');
  print('✓ Auto-lock prevents unauthorized access');
  print('✓ Background lock protects against shoulder surfing');
  print('✓ Biometric provides convenient security');
  print('');

  // Cleanup
  controller.dispose();
}
