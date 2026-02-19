# CreateWalletScreen Integration - Complete ✅

Complete integration of CreateWalletScreen with wallet core following clean architecture principles.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │ CreateWallet     │────────>│ WalletController │         │
│  │ Screen (UI)      │         │ (State Manager)  │         │
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
│  │ CreateNewWalletUseCase (Business Logic)              │  │
│  │                                                       │  │
│  │  1. Check if wallet exists (single wallet)           │  │
│  │  2. Validate PIN format                              │  │
│  │  3. Generate mnemonic via WalletEngine               │  │
│  │  4. Store encrypted mnemonic via SecureVault         │  │
│  │  5. Return mnemonic + address for backup             │  │
│  └────────┬──────────────────────────┬──────────────────┘  │
│           │                          │                      │
└───────────┼──────────────────────────┼──────────────────────┘
            │                          │
            │ uses                     │ uses
            ↓                          ↓
┌─────────────────────┐    ┌─────────────────────┐
│   WalletEngine      │    │   SecureVault       │
│   (Crypto Core)     │    │   (Storage)         │
│                     │    │                     │
│ - Generate mnemonic │    │ - Encrypt mnemonic  │
│ - Derive address    │    │ - Store in Keychain │
│ - BIP39/BIP32/BIP44 │    │ - AES-256-GCM       │
└─────────────────────┘    └─────────────────────┘
```

## Files Created

### 1. CreateNewWalletUseCase ✅

**Path:** `lib/features/wallet/domain/usecases/create_new_wallet_usecase.dart`

**Responsibilities:**

- Check if wallet already exists (single wallet constraint)
- Validate PIN format (6-8 digits)
- Generate mnemonic via WalletEngine
- Store encrypted mnemonic in SecureVault
- Return mnemonic + address for backup

**Dependencies:**

- `WalletEngine` - Crypto operations
- `SecureVault` - Secure storage

**Security:**

- Enforces single wallet per device
- Mnemonic encrypted before storage
- PIN never stored
- Mnemonic returned only for immediate backup

**Usage:**

```dart
final useCase = CreateNewWalletUseCase(
  walletEngine: walletEngine,
  secureVault: secureVault,
);

try {
  final result = await useCase.call(pin: '123456');
  print('Address: ${result.address}');
  // Show mnemonic to user for backup
} catch (e) {
  // Handle error
}
```

**Error Handling:**

- `VaultException.vaultNotEmpty` - Wallet already exists
- `VaultException.invalidPin` - PIN format invalid
- `VaultException.encryptionFailed` - Encryption failed
- `VaultException.storageFailed` - Storage failed

## Files Updated

### 1. WalletController ✅

**Path:** `lib/features/wallet/presentation/controllers/wallet_controller.dart`

**Changes:**

- Added `CreateNewWalletUseCase` dependency injection
- Updated `createWallet()` method to call use case
- Added comprehensive error handling
- Returns `CreateNewWalletResult` instead of `String?`
- Added VaultException handling with user-friendly messages

**New Method Signature:**

```dart
Future<CreateNewWalletResult?> createWallet(String pin)
```

**Error Messages:**

- "Wallet already exists on this device"
- "Invalid PIN format. Use 6-8 digits"
- "Failed to encrypt wallet"
- "Failed to save wallet"

**Security:**

- Mnemonic never stored in controller state
- Mnemonic returned only for immediate backup
- PIN validated by use case
- All crypto logic delegated to domain layer

### 2. CreateWalletScreen ✅

**Path:** `lib/features/wallet/presentation/pages/create_wallet_screen.dart`

**Changes:**

- Changed from StatelessWidget to StatefulWidget
- Added PIN input fields (PIN + Confirm PIN)
- Added PIN validation (6-8 digits, match confirmation)
- Integrated with WalletController
- Added loading state during wallet creation
- Added error display
- Navigate to BackupMnemonicScreen with mnemonic on success

**UI Flow:**

1. User enters PIN (6-8 digits)
2. User confirms PIN
3. Validate PIN format and match
4. Call `WalletController.createWallet(pin)`
5. Show loading indicator
6. On success: Navigate to backup with mnemonic
7. On error: Show error message

**Validation:**

- PIN not empty
- PIN at least 6 digits
- PIN at most 8 digits
- PIN matches confirmation

**Security:**

- PIN never logged
- Mnemonic never stored in UI state
- Mnemonic passed only via navigation arguments
- Loading state prevents double submission

### 3. app_pages.dart ✅

**Path:** `lib/core/routes/app_pages.dart`

**Changes:**

- Added imports for `CreateNewWalletUseCase`, `WalletEngine`, `SecureVault`
- Updated CreateWallet route binding to inject dependencies
- Proper dependency injection chain:
    1. Create `WalletEngine` instance
    2. Create `SecureVault` instance
    3. Create `CreateNewWalletUseCase` with dependencies
    4. Create `WalletController` with use case

**Binding Code:**

```dart
GetPage(
  name: AppRoutes.createWallet,
  page: () => const CreateWalletScreen(),
  binding: BindingsBuilder(() {
    // Initialize core dependencies
    final walletEngine = WalletEngine();
    final secureVault = SecureVault();

    // Initialize use case
    final createNewWalletUseCase = CreateNewWalletUseCase(
      walletEngine: walletEngine,
      secureVault: secureVault,
    );

    // Initialize controller with use case
    Get.lazyPut<WalletController>(
      () => WalletController(
        createNewWalletUseCase: createNewWalletUseCase,
      ),
    );
  }),
),
```

## Data Flow

### Wallet Creation Flow

```
1. User Input (CreateWalletScreen)
   ├─ Enter PIN: "123456"
   ├─ Confirm PIN: "123456"
   └─ Tap "Create New Wallet"
         ↓
2. UI Validation (CreateWalletScreen)
   ├─ PIN not empty ✓
   ├─ PIN length 6-8 ✓
   ├─ PINs match ✓
   └─ Set loading state
         ↓
3. Controller Call (WalletController)
   ├─ createWallet(pin: "123456")
   ├─ Set isLoading = true
   └─ Clear error message
         ↓
4. Use Case Execution (CreateNewWalletUseCase)
   ├─ Check if wallet exists
   │  └─ secureVault.hasWallet() → false ✓
   ├─ Validate PIN format
   │  └─ length >= 6 ✓
   ├─ Generate wallet
   │  └─ walletEngine.createWallet()
   │     ├─ Generate 24-word mnemonic (BIP39)
   │     └─ Derive address (BIP44: m/44'/60'/0'/0/0)
   ├─ Store encrypted mnemonic
   │  └─ secureVault.storeMnemonic(mnemonic, pin, address)
   │     ├─ Encrypt with AES-256-GCM
   │     ├─ Store in Keychain/KeyStore
   │     └─ Cache address
   └─ Return result
      ├─ mnemonic: "abandon ability able..."
      └─ address: "0x742d35Cc..."
         ↓
5. Controller Response (WalletController)
   ├─ Update state
   │  ├─ address = "0x742d35Cc..."
   │  ├─ hasWallet = true
   │  └─ isLoading = false
   └─ Return CreateNewWalletResult
         ↓
6. Navigation (CreateWalletScreen)
   └─ NavigationHelper.navigateToBackup(
        mnemonic: result.mnemonic
      )
         ↓
7. Backup Screen
   └─ Display mnemonic for user backup
```

### Error Handling Flow

```
1. Error Occurs (Any Layer)
   └─ throw VaultException.vaultNotEmpty()
         ↓
2. Use Case Catches (CreateNewWalletUseCase)
   └─ Propagate to controller
         ↓
3. Controller Catches (WalletController)
   ├─ Map VaultException to user message
   │  ├─ vaultNotEmpty → "Wallet already exists"
   │  ├─ invalidPin → "Invalid PIN format"
   │  ├─ encryptionFailed → "Failed to encrypt"
   │  └─ storageFailed → "Failed to save"
   ├─ Set errorMessage
   ├─ Set isLoading = false
   └─ Return null
         ↓
4. UI Displays Error (CreateWalletScreen)
   └─ Show error message to user
```

## Security Features

### 1. Single Wallet Constraint

```dart
// In CreateNewWalletUseCase
final hasWallet = await _secureVault.hasWallet();
if (hasWallet) {
  throw VaultException.vaultNotEmpty();
}
```

**Why:** Prevents multiple wallets on same device, simplifies security model.

### 2. PIN Validation

```dart
// In CreateNewWalletUseCase
if (pin.isEmpty || pin.length < 6) {
  throw VaultException.invalidPin('PIN must be at least 6 digits');
}
```

**Why:** Ensures minimum security level for encryption key derivation.

### 3. Mnemonic Encryption

```dart
// In SecureVault
await _secureVault.storeMnemonic(
  walletResult.mnemonic,
  pin,
  address: walletResult.address,
);
```

**Encryption:**

- Algorithm: AES-256-GCM
- Key Derivation: PBKDF2-HMAC-SHA512 (100,000 iterations)
- Storage: iOS Keychain / Android KeyStore

### 4. No Mnemonic Storage in Memory

```dart
// In WalletController
Future<CreateNewWalletResult?> createWallet(String pin) async {
  // ...
  final result = await _createNewWalletUseCase.call(pin: pin);

  // Mnemonic NOT stored in controller
  // Returned only for immediate backup
  return result;
}
```

**Why:** Minimizes attack surface, mnemonic exists only during backup flow.

### 5. Secure Navigation

```dart
// In CreateWalletScreen
NavigationHelper.navigateToBackup(mnemonic: result.mnemonic);
```

**Security:**

- Mnemonic passed as route argument (not stored)
- Cleared when navigation stack is cleared
- Never logged or persisted

## Testing

### Unit Test Example

```dart
test('createWallet should generate wallet and store encrypted', () async {
  // Arrange
  final mockEngine = MockWalletEngine();
  final mockVault = MockSecureVault();
  final useCase = CreateNewWalletUseCase(
    walletEngine: mockEngine,
    secureVault: mockVault,
  );

  when(mockVault.hasWallet()).thenAnswer((_) async => false);
  when(mockEngine.createWallet()).thenReturn(
    WalletCreationResult(
      mnemonic: 'test mnemonic',
      address: '0xtest',
    ),
  );

  // Act
  final result = await useCase.call(pin: '123456');

  // Assert
  expect(result.mnemonic, 'test mnemonic');
  expect(result.address, '0xtest');
  verify(mockVault.storeMnemonic('test mnemonic', '123456', address: '0xtest'));
});
```

### Integration Test Example

```dart
testWidgets('create wallet flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to create wallet
  await tester.tap(find.text('Create New Wallet'));
  await tester.pumpAndSettle();

  // Enter PIN
  await tester.enterText(find.byType(SecureTextField).first, '123456');
  await tester.enterText(find.byType(SecureTextField).last, '123456');

  // Tap create button
  await tester.tap(find.text('Create New Wallet'));
  await tester.pumpAndSettle();

  // Should navigate to backup screen
  expect(find.byType(BackupMnemonicScreen), findsOneWidget);
});
```

## Error Scenarios

### 1. Wallet Already Exists

```
User Action: Create new wallet
Result: Error "Wallet already exists on this device"
Reason: Single wallet constraint enforced
Solution: User must delete existing wallet first
```

### 2. Invalid PIN Format

```
User Action: Enter PIN "123"
Result: Error "PIN must be at least 6 digits"
Reason: PIN too short for security
Solution: Enter 6-8 digit PIN
```

### 3. PIN Mismatch

```
User Action: PIN "123456", Confirm "123457"
Result: Error "PINs do not match"
Reason: Confirmation doesn't match
Solution: Re-enter matching PINs
```

### 4. Storage Failure

```
User Action: Create wallet
Result: Error "Failed to save wallet"
Reason: Keychain/KeyStore access denied
Solution: Check app permissions
```

## Next Steps

### 1. Import Wallet Flow

Create `ImportWalletUseCase`:

```dart
class ImportWalletUseCase {
  Future<ImportWalletResult> call({
    required String mnemonic,
    required String pin,
  });
}
```

### 2. Backup Confirmation

Update `ConfirmMnemonicScreen` to verify backup:

```dart
final isValid = await walletController.verifyBackup(
  enteredMnemonic: userInput,
  originalMnemonic: passedMnemonic,
);
```

### 3. Balance Fetching

Create `GetBalanceUseCase`:

```dart
class GetBalanceUseCase {
  Future<WalletBalance> call({required String address});
}
```

### 4. Transaction Signing

Integrate with existing `TransactionSigner`:

```dart
final signature = await transactionSigner.signTransaction(
  transaction: tx,
  privateKey: derivedKey,
);
```

## Summary

Complete integration of CreateWalletScreen with wallet core:

✅ Clean architecture (Presentation → Domain → Core)
✅ Proper dependency injection
✅ Comprehensive error handling
✅ Security-first approach
✅ No mnemonic storage in memory
✅ Single wallet constraint enforced
✅ PIN validation (6-8 digits)
✅ Encrypted storage (AES-256-GCM)
✅ Platform secure storage (Keychain/KeyStore)
✅ User-friendly error messages
✅ Loading states
✅ Navigation with mnemonic passing

The wallet creation flow is now fully functional and ready for testing!
