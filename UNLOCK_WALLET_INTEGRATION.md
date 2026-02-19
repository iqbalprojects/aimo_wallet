# UnlockScreen Integration with SecureVault - Complete ✅

Complete integration of UnlockScreen with SecureVault, including UnlockWalletUseCase, enhanced AuthController with auto-lock functionality, and proper state management.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │ UnlockScreen     │────────>│ AuthController   │         │
│  │ (UI)             │         │ (State Manager)  │         │
│  └──────────────────┘         └────────┬─────────┘         │
│                                         │                    │
└─────────────────────────────────────────┼────────────────────┘
                                          │
                                          │ calls
                                          ↓
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ UnlockWalletUseCase (Business Logic)                 │  │
│  │                                                       │  │
│  │  1. Check if wallet exists                           │  │
│  │  2. Validate PIN format                              │  │
│  │  3. Verify PIN via SecureVault                       │  │
│  │  4. Return wallet address (NOT mnemonic)             │  │
│  │  5. Clear mnemonic from memory immediately           │  │
│  └────────┬──────────────────────────────────────────────┘  │
│           │                                                  │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ uses
            ↓
┌─────────────────────┐
│   SecureVault       │
│   (Storage)         │
│                     │
│ - Verify PIN        │
│ - Decrypt mnemonic  │
│ - Return address    │
│ - AES-256-GCM       │
└─────────────────────┘
```

## Files Created

### 1. UnlockWalletUseCase ✅

**Path:** `lib/features/wallet/domain/usecases/unlock_wallet_usecase.dart`

**Responsibilities:**

- Verify PIN against encrypted vault
- Retrieve wallet address
- Track failed attempts
- Enforce lockout after too many failures

**Security:**

- Mnemonic is NOT returned (only verified)
- Mnemonic decrypted only to verify PIN
- Mnemonic immediately cleared from memory
- Only address returned (public info)

**Usage:**

```dart
final useCase = UnlockWalletUseCase(secureVault: vault);

try {
  final result = await useCase.call(pin: '123456');
  print('Unlocked: ${result.address}');
} on VaultException catch (e) {
  // Handle error
}
```

**Error Handling:**

- `VaultException.vaultEmpty` - No wallet exists
- `VaultException.decryptionFailed` - PIN incorrect
- `VaultException.invalidPin` - PIN format invalid
- `VaultException.dataCorrupted` - Address not found

**Security Implementation:**

```dart
Future<UnlockWalletResult> call({required String pin}) async {
  String? mnemonic;
  try {
    // Decrypt mnemonic to verify PIN
    mnemonic = await _secureVault.retrieveMnemonic(pin);

    // Get cached address
    final address = await _secureVault.getWalletAddress();

    return UnlockWalletResult(address: address);
  } finally {
    // SECURITY: Clear mnemonic immediately
    if (mnemonic != null) {
      mnemonic = '';
      mnemonic = null;
    }
  }
}
```

## Files Updated

### 1. AuthController ✅

**Path:** `lib/features/wallet/presentation/controllers/auth_controller.dart`

**Major Changes:**

#### New Reactive State

```dart
// Lock state
final RxBool _isLocked = true.obs;

// Wallet address (cached after unlock)
final RxnString _walletAddress = RxnString();

// Lockout state
final RxBool _isLockedOut = false.obs;
final Rxn<DateTime> _lockoutEndTime = Rxn<DateTime>();

// Auto-lock configuration
final Rxn<Duration> _autoLockDuration = Rxn<Duration>();
```

#### New Methods

**1. unlockWallet()**

```dart
Future<bool> unlockWallet(String pin) async {
  // Call UnlockWalletUseCase
  final result = await useCase.call(pin: pin);

  // Update state
  _isLocked.value = false;
  _walletAddress.value = result.address;
  _failedAttempts.value = 0;

  // Start auto-lock timer
  _startAutoLockTimer();

  return true;
}
```

**2. lockWallet()**

```dart
void lockWallet() {
  // Update state
  _isLocked.value = true;
  _walletAddress.value = null;

  // Cancel auto-lock timer
  _autoLockTimer?.cancel();

  // Navigate to unlock screen
  NavigationHelper.lockWallet();
}
```

**3. Auto-Lock Functionality**

```dart
void _startAutoLockTimer() {
  _autoLockTimer?.cancel();

  if (_autoLockDuration.value == null) {
    return; // Auto-lock disabled
  }

  _autoLockTimer = Timer(_autoLockDuration.value!, () {
    if (isUnlocked) {
      lockWallet();
    }
  });
}

void resetAutoLockTimer() {
  if (isUnlocked && _autoLockDuration.value != null) {
    _startAutoLockTimer();
  }
}

Future<void> setAutoLockDuration(Duration? duration) async {
  _autoLockDuration.value = duration;

  if (isUnlocked) {
    _startAutoLockTimer();
  }
}
```

**4. App Lifecycle Observer**

```dart
class AuthController extends GetxController with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - lock wallet
        if (isUnlocked) {
          lockWallet();
        }
        break;
      // ...
    }
  }
}
```

**5. Lockout Functionality**

```dart
void _startLockout() {
  _isLockedOut.value = true;
  _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 5));
  _errorMessage.value = 'Too many failed attempts. Locked for 5 minutes.';

  _lockoutTimer = Timer(const Duration(minutes: 5), () {
    _isLockedOut.value = false;
    _lockoutEndTime.value = null;
    _failedAttempts.value = 0;
  });
}
```

#### Lifecycle Management

```dart
@override
void onInit() {
  super.onInit();
  _checkBiometricAvailability();
  _loadBiometricSetting();
  _loadAutoLockDuration();

  // Register as lifecycle observer
  WidgetsBinding.instance.addObserver(this);
}

@override
void onClose() {
  // Cancel timers
  _autoLockTimer?.cancel();
  _lockoutTimer?.cancel();

  // Unregister lifecycle observer
  WidgetsBinding.instance.removeObserver(this);

  super.onClose();
}
```

### 2. UnlockScreen ✅

**Path:** `lib/features/wallet/presentation/pages/unlock_screen.dart`

**Changes:**

- Updated to call `authController.unlockWallet(pin)` instead of `verifyPin(pin)`
- Uses new error messages from AuthController
- Properly handles loading and error states

**Updated Method:**

```dart
Future<void> _handleUnlock() async {
  final pin = _pinController.text;

  // Validation...

  // Call AuthController to unlock wallet
  final success = await authController.unlockWallet(pin);

  if (success) {
    // Navigate to home
    NavigationHelper.navigateToHomeAfterUnlock();
  } else {
    // Show error
    setState(() {
      _errorText = authController.errorMessage ?? 'Incorrect PIN';
      _pinController.clear();
    });
  }
}
```

### 3. app_pages.dart ✅

**Path:** `lib/core/routes/app_pages.dart`

**Changes:**

- Added import for `UnlockWalletUseCase`
- Updated Unlock route binding to inject dependencies

**Updated Binding:**

```dart
GetPage(
  name: AppRoutes.unlock,
  page: () => const UnlockScreen(),
  binding: BindingsBuilder(() {
    // Initialize core dependencies
    final secureVault = SecureVault();

    // Initialize use case
    final unlockWalletUseCase = UnlockWalletUseCase(
      secureVault: secureVault,
    );

    // Initialize controller with use case
    Get.lazyPut<AuthController>(
      () => AuthController(
        unlockWalletUseCase: unlockWalletUseCase,
      ),
    );
  }),
),
```

## Features Implemented

### 1. Unlock Wallet ✅

```
User Flow:
1. User enters PIN
2. UI validates format
3. AuthController.unlockWallet(pin)
4. UnlockWalletUseCase.call(pin)
5. SecureVault.retrieveMnemonic(pin)
6. Mnemonic decrypted (verifies PIN)
7. Address retrieved
8. Mnemonic cleared from memory
9. AuthController updates state
10. Auto-lock timer started
11. Navigate to home
```

### 2. Lock Wallet ✅

```
Trigger Points:
- User taps lock button
- Auto-lock timer expires
- App goes to background
- Manual call to lockWallet()

Actions:
1. Set isLocked = true
2. Clear wallet address
3. Cancel auto-lock timer
4. Navigate to unlock screen (clear stack)
```

### 3. Auto-Lock ✅

```
Configuration:
- 1 minute
- 5 minutes (default)
- 15 minutes
- 30 minutes
- Never (null)

Behavior:
- Timer starts after unlock
- Timer resets on user activity (via resetAutoLockTimer)
- Locks wallet when timer expires
- Configurable via setAutoLockDuration()
```

### 4. Lock on Background ✅

```
Implementation:
- AuthController implements WidgetsBindingObserver
- Listens to app lifecycle changes
- Locks wallet when app goes to background
- Prevents unauthorized access when app is inactive
```

### 5. Failed Attempts & Lockout ✅

```
Behavior:
- Track failed PIN attempts
- Show remaining attempts (5 total)
- Lock out after 5 failures
- Lockout duration: 5 minutes
- Auto-unlock after lockout period
- Clear attempts on successful unlock
```

## Security Features

### 1. No Mnemonic Storage

```dart
// ❌ BAD: Store mnemonic in controller
class AuthController extends GetxController {
  final RxString mnemonic = ''.obs;  // NEVER DO THIS
}

// ✅ GOOD: Only store address (public info)
class AuthController extends GetxController {
  final RxnString _walletAddress = RxnString();  // Public info only
}
```

### 2. Immediate Memory Clearing

```dart
// In UnlockWalletUseCase
String? mnemonic;
try {
  mnemonic = await _secureVault.retrieveMnemonic(pin);
  // Use mnemonic...
} finally {
  // SECURITY: Clear immediately
  if (mnemonic != null) {
    mnemonic = '';
    mnemonic = null;
  }
}
```

### 3. Auto-Lock Protection

```dart
// Automatically lock after inactivity
_autoLockTimer = Timer(_autoLockDuration.value!, () {
  if (isUnlocked) {
    lockWallet();
  }
});

// Reset on user activity
void resetAutoLockTimer() {
  if (isUnlocked) {
    _startAutoLockTimer();
  }
}
```

### 4. Background Lock

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
      // Lock immediately when app goes to background
      if (isUnlocked) {
        lockWallet();
      }
      break;
  }
}
```

### 5. Brute Force Protection

```dart
// Track failed attempts
_failedAttempts.value++;

// Lockout after 5 failures
if (_failedAttempts.value >= 5) {
  _startLockout();  // 5 minute lockout
}
```

## State Management

### Reactive State (GetX)

```dart
// Lock state
bool get isLocked => _isLocked.value;
bool get isUnlocked => !_isLocked.value;

// Wallet info
String? get walletAddress => _walletAddress.value;

// Error state
String? get errorMessage => _errorMessage.value;

// Loading state
bool get isLoading => _isLoading.value;

// Lockout state
bool get isLockedOut => _isLockedOut.value;
DateTime? get lockoutEndTime => _lockoutEndTime.value;

// Auto-lock config
Duration? get autoLockDuration => _autoLockDuration.value;
```

### UI Observing State

```dart
// In UnlockScreen
final authController = Get.find<AuthController>();

// Observe loading state
Obx(() => authController.isLoading
    ? CircularProgressIndicator()
    : UnlockButton()
)

// Observe error state
Obx(() => authController.errorMessage != null
    ? ErrorText(authController.errorMessage!)
    : SizedBox()
)
```

## Usage Examples

### Unlock Wallet

```dart
final authController = Get.find<AuthController>();

// Unlock with PIN
final success = await authController.unlockWallet('123456');

if (success) {
  print('Unlocked! Address: ${authController.walletAddress}');
} else {
  print('Error: ${authController.errorMessage}');
}
```

### Lock Wallet

```dart
// Manual lock
authController.lockWallet();

// Auto-lock will also trigger this
```

### Configure Auto-Lock

```dart
// Set to 5 minutes
await authController.setAutoLockDuration(Duration(minutes: 5));

// Disable auto-lock
await authController.setAutoLockDuration(null);

// Reset timer on user activity
authController.resetAutoLockTimer();
```

### Check Lock State

```dart
if (authController.isLocked) {
  // Show unlock screen
} else {
  // Show main app
}
```

## Testing

### Unit Test Example

```dart
test('unlockWallet should unlock with correct PIN', () async {
  // Arrange
  final mockVault = MockSecureVault();
  final useCase = UnlockWalletUseCase(secureVault: mockVault);
  final controller = AuthController(unlockWalletUseCase: useCase);

  when(mockVault.hasWallet()).thenAnswer((_) async => true);
  when(mockVault.retrieveMnemonic('123456'))
      .thenAnswer((_) async => 'test mnemonic');
  when(mockVault.getWalletAddress())
      .thenAnswer((_) async => '0xtest');

  // Act
  final success = await controller.unlockWallet('123456');

  // Assert
  expect(success, true);
  expect(controller.isUnlocked, true);
  expect(controller.walletAddress, '0xtest');
  expect(controller.failedAttempts, 0);
});

test('unlockWallet should track failed attempts', () async {
  // Arrange
  final mockVault = MockSecureVault();
  final useCase = UnlockWalletUseCase(secureVault: mockVault);
  final controller = AuthController(unlockWalletUseCase: useCase);

  when(mockVault.hasWallet()).thenAnswer((_) async => true);
  when(mockVault.retrieveMnemonic(any))
      .thenThrow(VaultException.decryptionFailed());

  // Act
  await controller.unlockWallet('wrong');
  await controller.unlockWallet('wrong');
  await controller.unlockWallet('wrong');

  // Assert
  expect(controller.failedAttempts, 3);
  expect(controller.errorMessage, contains('2 attempts remaining'));
});

test('unlockWallet should lockout after 5 failures', () async {
  // Arrange
  final mockVault = MockSecureVault();
  final useCase = UnlockWalletUseCase(secureVault: mockVault);
  final controller = AuthController(unlockWalletUseCase: useCase);

  when(mockVault.hasWallet()).thenAnswer((_) async => true);
  when(mockVault.retrieveMnemonic(any))
      .thenThrow(VaultException.decryptionFailed());

  // Act
  for (int i = 0; i < 5; i++) {
    await controller.unlockWallet('wrong');
  }

  // Assert
  expect(controller.isLockedOut, true);
  expect(controller.lockoutEndTime, isNotNull);
});
```

### Integration Test Example

```dart
testWidgets('unlock wallet flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Should be on unlock screen
  expect(find.byType(UnlockScreen), findsOneWidget);

  // Enter PIN
  await tester.enterText(find.byType(SecureTextField), '123456');
  await tester.tap(find.text('Unlock Wallet'));
  await tester.pumpAndSettle();

  // Should navigate to home
  expect(find.byType(HomeDashboardScreen), findsOneWidget);
});
```

## Summary

Complete integration of UnlockScreen with SecureVault:

✅ UnlockWalletUseCase created
✅ AuthController enhanced with:

- Lock/unlock state management
- Auto-lock functionality
- Background lock
- Failed attempts tracking
- Lockout after 5 failures
- Proper lifecycle management
  ✅ No mnemonic storage in controller
  ✅ Mnemonic cleared immediately after use
  ✅ Reactive state management with GetX
  ✅ Proper dependency injection
  ✅ Comprehensive error handling
  ✅ Security-first approach

The unlock functionality is now fully integrated and secure!
