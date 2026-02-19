# Wallet Lock State Management

## Overview

The Wallet Lock Controller provides secure state management for wallet lock/unlock operations using GetX. It implements auto-lock, background lock, and secure operation execution without storing decrypted mnemonics globally.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              WalletLockController (GetX)                 │
│  State management + lifecycle + security                 │
└─────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
┌───────────────────────┐   ┌───────────────────────┐
│    SecureVault        │   │   WalletEngine        │
│  Encrypted storage    │   │  HD wallet core       │
└───────────────────────┘   └───────────────────────┘
```

## Features

### 1. Lock States

**LOCKED:**

- Wallet requires authentication
- No operations allowed
- Mnemonic not accessible

**UNLOCKED:**

- Wallet authenticated
- Operations allowed
- Mnemonic retrieved on-demand

### 2. Auto-Lock

**Configurable Timeout:**

- Default: 5 minutes (300 seconds)
- Customizable per user preference
- Resets on activity

**Inactivity Detection:**

- Monitors last activity time
- Checks every 10 seconds
- Locks automatically after timeout

### 3. Background Lock

**App Lifecycle Monitoring:**

- Detects app moving to background
- Locks wallet immediately
- Prevents shoulder surfing

**States Monitored:**

- `paused` - App in background
- `inactive` - App transitioning
- `resumed` - App in foreground

### 4. Biometric Authentication

**Optional Feature:**

- Fingerprint unlock
- Face unlock
- Falls back to PIN

**Device Support:**

- Checks availability
- Graceful degradation
- User opt-in required

### 5. Secure Operations

**Mnemonic Handling:**

- Retrieved only during operations
- Cleared immediately after use
- Never stored globally

**Private Key Handling:**

- Derived on-demand
- Cleared after use
- Automatic cleanup

## Security Principles

### 1. No Global Mnemonic Storage

**Problem:** Storing decrypted mnemonic in memory is dangerous

- Memory dumps can expose mnemonic
- Long exposure window
- Difficult to secure

**Solution:** Retrieve mnemonic only during operations

```dart
// ❌ WRONG: Store mnemonic globally
class Controller {
  String? _mnemonic; // NEVER DO THIS
}

// ✅ CORRECT: Retrieve on-demand
await controller.executeSecureOperation(
  (mnemonic) async {
    // Use mnemonic
    return result;
  }, // Mnemonic cleared here
  pin: pin,
);
```

### 2. Automatic Cleanup

**Problem:** Forgetting to clear sensitive data

- Human error
- Exception handling complexity
- Memory leaks

**Solution:** Automatic cleanup with try-finally

```dart
Future<T> executeSecureOperation<T>(
  Future<T> Function(String mnemonic) operation,
) async {
  String? mnemonic;
  try {
    mnemonic = await _vault.retrieveMnemonic(pin);
    return await operation(mnemonic);
  } finally {
    // ALWAYS cleared, even on error
    if (mnemonic != null) {
      SecureMemory.clearString(mnemonic);
    }
  }
}
```

### 3. Lock State Enforcement

**Problem:** Operations when wallet should be locked

- Unauthorized access
- Security bypass

**Solution:** Check lock state before operations

```dart
if (isLocked) {
  throw Exception('Wallet is locked');
}
```

### 4. Activity Tracking

**Problem:** Wallet left unlocked indefinitely

- Unattended device access
- Forgotten unlock

**Solution:** Auto-lock after inactivity

```dart
void _resetActivityTimer() {
  _lastActivityTime = DateTime.now();
}

// Check periodically
if (inactiveSeconds >= config.autoLockTimeoutSeconds) {
  lock();
}
```

## Usage

### Basic Usage

```dart
// Initialize controller
final controller = Get.put(WalletLockController());

// Unlock wallet
await controller.unlock('123456');

// Execute operation
final result = await controller.executeSecureOperation(
  (mnemonic) async {
    // Use mnemonic for operation
    return signTransaction(mnemonic);
  },
  pin: '123456',
);

// Lock wallet
controller.lock();
```

### Secure Transaction Signing

```dart
// Sign transaction with private key
final signature = await controller.executeWithPrivateKey(
  (privateKey) async {
    // Sign transaction
    final signature = signTransaction(transaction, privateKey);
    return signature;
  },
  pin: pin,
);

// Private key automatically cleared
```

### Configuration

```dart
// Update lock configuration
controller.updateConfig(WalletLockConfig(
  autoLockTimeoutSeconds: 600, // 10 minutes
  lockOnBackground: true,
  biometricEnabled: true,
));
```

### Biometric Authentication

```dart
// Check availability
if (controller.biometricAvailable) {
  // Enable biometric
  await controller.enableBiometric();

  // Unlock with biometric
  await controller.unlockWithBiometric();
}
```

### Reactive UI

```dart
// Listen to lock state
Obx(() {
  if (controller.isLocked) {
    return LockScreen();
  } else {
    return WalletScreen();
  }
});

// Show auto-lock countdown
Obx(() {
  final timeLeft = controller.getTimeUntilAutoLock();
  return Text('Auto-lock in: ${timeLeft}s');
});
```

## API Reference

### Properties

| Property             | Type               | Description                |
| -------------------- | ------------------ | -------------------------- |
| `lockState`          | `WalletLockState`  | Current lock state         |
| `isLocked`           | `bool`             | Whether wallet is locked   |
| `isUnlocked`         | `bool`             | Whether wallet is unlocked |
| `config`             | `WalletLockConfig` | Lock configuration         |
| `walletAddress`      | `String?`          | Cached wallet address      |
| `isLoading`          | `bool`             | Loading state              |
| `errorMessage`       | `String?`          | Error message              |
| `biometricAvailable` | `bool`             | Biometric availability     |

### Methods

| Method                                   | Description              | Returns        |
| ---------------------------------------- | ------------------------ | -------------- |
| `unlock(pin)`                            | Unlock with PIN          | `Future<bool>` |
| `unlockWithBiometric()`                  | Unlock with biometric    | `Future<bool>` |
| `lock()`                                 | Lock wallet              | `void`         |
| `executeSecureOperation(operation, pin)` | Execute with mnemonic    | `Future<T>`    |
| `executeWithPrivateKey(operation, pin)`  | Execute with private key | `Future<T>`    |
| `updateConfig(config)`                   | Update configuration     | `void`         |
| `enableBiometric()`                      | Enable biometric         | `Future<bool>` |
| `disableBiometric()`                     | Disable biometric        | `void`         |
| `getTimeUntilAutoLock()`                 | Time until auto-lock     | `int?`         |
| `hasWallet()`                            | Check wallet existence   | `Future<bool>` |

## Configuration

### WalletLockConfig

```dart
class WalletLockConfig {
  final int autoLockTimeoutSeconds;  // Default: 300 (5 min)
  final bool lockOnBackground;       // Default: true
  final bool biometricEnabled;       // Default: false
}
```

### Recommended Settings

**High Security:**

```dart
WalletLockConfig(
  autoLockTimeoutSeconds: 60,  // 1 minute
  lockOnBackground: true,
  biometricEnabled: false,     // PIN only
)
```

**Balanced:**

```dart
WalletLockConfig(
  autoLockTimeoutSeconds: 300, // 5 minutes
  lockOnBackground: true,
  biometricEnabled: true,
)
```

**Convenience:**

```dart
WalletLockConfig(
  autoLockTimeoutSeconds: 900, // 15 minutes
  lockOnBackground: false,
  biometricEnabled: true,
)
```

## Testing

### Unit Tests

**Location:** `test/features/wallet/presentation/controllers/`

**Coverage:**

- Lock/unlock operations
- Secure operation execution
- Auto-lock behavior
- Background lock
- Biometric authentication
- Configuration updates
- Error handling

**Run Tests:**

```bash
flutter test test/features/wallet/presentation/controllers/
```

### Test Scenarios

✅ Unlock with correct PIN
✅ Reject wrong PIN
✅ Lock wallet
✅ Execute operation when unlocked
✅ Prevent operation when locked
✅ Clear mnemonic after operation
✅ Clear mnemonic on error
✅ Update configuration
✅ Enable/disable biometric
✅ Check wallet existence

## Security Considerations

### 1. Memory Security

**Mnemonic Lifetime:**

- Retrieved from vault
- Used in operation
- Cleared immediately
- Never stored globally

**Private Key Lifetime:**

- Derived from mnemonic
- Used for signing
- Cleared immediately
- Never stored

### 2. Lock State

**Enforcement:**

- Check before operations
- Throw error if locked
- No bypass possible

**Auto-Lock:**

- Prevents unattended access
- Configurable timeout
- Activity-based reset

### 3. Background Lock

**Protection:**

- Immediate lock on background
- Prevents shoulder surfing
- Protects against app switching

### 4. Biometric

**Security:**

- Optional feature
- Falls back to PIN
- Device-level security
- User opt-in required

## Best Practices

### 1. Always Use Secure Operations

```dart
// ✅ CORRECT: Use executeSecureOperation
final result = await controller.executeSecureOperation(
  (mnemonic) async => signTransaction(mnemonic),
  pin: pin,
);

// ❌ WRONG: Retrieve mnemonic directly
final mnemonic = await vault.retrieveMnemonic(pin);
// Mnemonic not cleared!
```

### 2. Handle Lock State in UI

```dart
// ✅ CORRECT: Check lock state
Obx(() {
  if (controller.isLocked) {
    return LockScreen(
      onUnlock: (pin) => controller.unlock(pin),
    );
  }
  return WalletScreen();
});
```

### 3. Configure Auto-Lock

```dart
// ✅ CORRECT: Set appropriate timeout
controller.updateConfig(WalletLockConfig(
  autoLockTimeoutSeconds: 300, // 5 minutes
  lockOnBackground: true,
));
```

### 4. Show Lock Status

```dart
// ✅ CORRECT: Show auto-lock countdown
Obx(() {
  final timeLeft = controller.getTimeUntilAutoLock();
  if (timeLeft != null && timeLeft < 60) {
    return Text('Locking in ${timeLeft}s');
  }
  return SizedBox.shrink();
});
```

## Integration Example

### Complete Wallet Flow

```dart
class WalletScreen extends StatelessWidget {
  final controller = Get.find<WalletLockController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show lock screen if locked
      if (controller.isLocked) {
        return LockScreen(
          onUnlock: _handleUnlock,
          biometricAvailable: controller.biometricAvailable,
        );
      }

      // Show wallet screen if unlocked
      return Scaffold(
        appBar: AppBar(
          title: Text('Wallet'),
          actions: [
            // Lock button
            IconButton(
              icon: Icon(Icons.lock),
              onPressed: controller.lock,
            ),
            // Auto-lock countdown
            _buildAutoLockCountdown(),
          ],
        ),
        body: WalletContent(),
      );
    });
  }

  Future<void> _handleUnlock(String pin) async {
    final unlocked = await controller.unlock(pin);
    if (!unlocked) {
      // Show error
      Get.snackbar('Error', controller.errorMessage ?? 'Unlock failed');
    }
  }

  Widget _buildAutoLockCountdown() {
    return Obx(() {
      final timeLeft = controller.getTimeUntilAutoLock();
      if (timeLeft == null || timeLeft > 60) {
        return SizedBox.shrink();
      }
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text('${timeLeft}s'),
      );
    });
  }
}
```

## Performance

### Memory Usage

- **Locked:** ~1KB (state only)
- **Unlocked:** ~1KB (no mnemonic stored)
- **During Operation:** ~1KB + mnemonic size (~200 bytes)

### CPU Usage

- **Auto-Lock Check:** Negligible (every 10s)
- **Unlock:** ~100ms (PBKDF2)
- **Operation:** Depends on operation

### Battery Impact

- **Auto-Lock Timer:** Minimal (periodic check)
- **Background Lock:** None (lifecycle callback)
- **Biometric:** Minimal (system-level)

## Troubleshooting

### Wallet Won't Unlock

**Check:**

1. PIN is correct
2. Vault has wallet
3. No storage errors

### Auto-Lock Not Working

**Check:**

1. Configuration timeout
2. Activity timer reset
3. Timer running

### Biometric Not Available

**Check:**

1. Device support
2. Biometric enrolled
3. Permissions granted

## Future Enhancements

1. **Rate Limiting:** Limit unlock attempts
2. **Account Lockout:** Lock after failed attempts
3. **Secure Enclave:** Use hardware security
4. **Multi-Factor:** Combine PIN + biometric
5. **Session Tokens:** Temporary auth tokens
6. **Audit Logging:** Log security events

## References

- [GetX State Management](https://pub.dev/packages/get)
- [local_auth Package](https://pub.dev/packages/local_auth)
- [Flutter Lifecycle](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
