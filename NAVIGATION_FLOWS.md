# Navigation Flows - Visual Guide

Visual representation of all navigation flows in the Aimo Wallet app.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP START                                │
│                            ↓                                     │
│                     ┌──────────────┐                            │
│                     │ SplashScreen │                            │
│                     └──────┬───────┘                            │
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              │                           │                      │
│         hasWallet?                  hasWallet?                  │
│           false                        true                     │
│              │                           │                      │
│              ↓                           ↓                      │
│    ┌──────────────────┐        ┌──────────────────┐           │
│    │ OnboardingScreen │        │  UnlockScreen    │           │
│    └────────┬─────────┘        └────────┬─────────┘           │
│             │                            │                      │
│    ┌────────┴────────┐                  │                      │
│    │                 │              verifyPin()                 │
│  Create           Import                 │                      │
│    │                 │                   ↓                      │
│    ↓                 ↓          ┌──────────────────┐           │
│ ┌──────────────────────┐        │ HomeDashboard    │←──────┐   │
│ │ CreateWalletScreen   │        └────────┬─────────┘       │   │
│ └──────────┬───────────┘                 │                 │   │
│            │                    ┌─────────┼─────────┐       │   │
│     createWallet()               │         │         │       │   │
│            │                     ↓         ↓         ↓       │   │
│            ↓              ┌──────────┐ ┌──────────┐ ┌──────────┐│
│ ┌──────────────────────┐  │SendScreen│ │ReceiveScr│ │Settings  ││
│ │ BackupMnemonicScreen │  └──────────┘ └──────────┘ └────┬─────┘│
│ └──────────┬───────────┘                                  │      │
│            │                                               │      │
│     userConfirmed                                    lockWallet() │
│            │                                               │      │
│            ↓                                               │      │
│ ┌──────────────────────┐                                  │      │
│ │ ConfirmMnemonicScreen│                                  │      │
│ └──────────┬───────────┘                                  │      │
│            │                                               │      │
│    verificationSuccess                                     │      │
│            │                                               │      │
│            └───────────────────────────────────────────────┘      │
│                            │                                      │
│                            ↓                                      │
│                   ┌──────────────────┐                           │
│                   │ HomeDashboard    │                           │
│                   └──────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## Flow 1: New Wallet Creation

```
┌─────────────┐
│   Splash    │ Check hasWallet → false
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Onboarding  │ User taps "Create New Wallet"
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Create    │ User enters PIN, wallet created
└──────┬──────┘ Returns mnemonic
       │
       ↓
┌─────────────┐
│   Backup    │ User views 24-word mnemonic
└──────┬──────┘ Confirms checkboxes
       │
       ↓
┌─────────────┐
│   Confirm   │ User verifies 3 random words
└──────┬──────┘ Verification successful
       │
       ↓
┌─────────────┐
│    Home     │ Stack cleared (offAllNamed)
└─────────────┘
```

**Navigation Methods:**

1. `NavigationHelper.startWalletCreation()`
2. `NavigationHelper.navigateToBackup(mnemonic: mnemonic)`
3. `NavigationHelper.navigateToConfirm(mnemonic: mnemonic)`
4. `NavigationHelper.completeWalletCreation()`

**Stack State:**

- After Backup: [Splash, Onboarding, Create, Backup]
- After Confirm: [Splash, Onboarding, Create, Backup, Confirm]
- After Home: [Home] ← Stack cleared for security

## Flow 2: Existing Wallet (Unlock)

```
┌─────────────┐
│   Splash    │ Check hasWallet → true
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Unlock    │ User enters PIN
└──────┬──────┘ AuthController.verifyPin()
       │
       ├─ PIN correct ──→ Navigate to Home
       │
       └─ PIN incorrect ─→ Show error, retry
                           (5 attempts → lockout)
       │
       ↓
┌─────────────┐
│    Home     │ Stack cleared (offAllNamed)
└─────────────┘
```

**Navigation Methods:**

1. `Get.offNamed(AppRoutes.unlock)` (from Splash)
2. `NavigationHelper.navigateToHomeAfterUnlock()`

**Stack State:**

- After Unlock: [Unlock]
- After Home: [Home] ← Stack cleared for security

## Flow 3: Import Wallet

```
┌─────────────┐
│   Splash    │ Check hasWallet → false
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Onboarding  │ User taps "Import Existing Wallet"
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Create    │ User enters mnemonic + PIN
└──────┬──────┘ WalletController.importWallet()
       │
       ↓
┌─────────────┐
│    Home     │ Stack cleared (offAllNamed)
└─────────────┘
```

**Navigation Methods:**

1. `NavigationHelper.startWalletCreation()`
2. `NavigationHelper.completeWalletCreation()` (after import)

**Stack State:**

- After Import: [Home] ← Stack cleared

## Flow 4: Lock Wallet

```
┌─────────────┐
│  Any Screen │ User taps lock button
└──────┬──────┘ OR auto-lock triggers
       │
       ↓
┌─────────────┐
│   Unlock    │ Stack cleared (offAllNamed)
└─────────────┘ User must re-authenticate
```

**Navigation Methods:**

1. `NavigationHelper.lockWallet()`

**Stack State:**

- Before Lock: [Home, Send] (example)
- After Lock: [Unlock] ← All screens cleared for security

## Flow 5: Home Navigation

```
┌─────────────┐
│    Home     │
└──────┬──────┘
       │
       ├─ Send button ──────→ SendScreen
       │
       ├─ Receive button ───→ ReceiveScreen
       │
       ├─ Settings button ──→ SettingsScreen
       │
       └─ Lock button ──────→ UnlockScreen (stack cleared)
```

**Navigation Methods:**

1. `NavigationHelper.navigateToSend()`
2. `NavigationHelper.navigateToReceive()`
3. `NavigationHelper.navigateToSettings()`
4. `NavigationHelper.lockWallet()`

**Stack State:**

- Send: [Home, Send]
- Receive: [Home, Receive]
- Settings: [Home, Settings]
- Lock: [Unlock] ← Stack cleared

## Controller Lifecycle

### Splash Screen

```
┌─────────────────────────────────────┐
│ SplashScreen                        │
│                                     │
│ 1. Get.put(WalletController())      │
│    - Initializes controller         │
│    - Checks wallet existence        │
│    - Sets hasWallet flag            │
│                                     │
│ 2. Wait for initialization          │
│                                     │
│ 3. Navigate based on hasWallet      │
└─────────────────────────────────────┘
```

### Unlock Screen

```
┌─────────────────────────────────────┐
│ UnlockScreen                        │
│                                     │
│ Binding: AuthController             │
│                                     │
│ 1. User enters PIN                  │
│ 2. authController.verifyPin(pin)    │
│ 3. If valid → Navigate to Home      │
│ 4. If invalid → Show error          │
└─────────────────────────────────────┘
```

### Home Screen

```
┌─────────────────────────────────────┐
│ HomeDashboardScreen                 │
│                                     │
│ Bindings:                           │
│ - WalletController (lazy)           │
│ - NetworkController (lazy)          │
│                                     │
│ Controllers provide:                │
│ - Wallet address                    │
│ - Balance (ETH + USD)               │
│ - Token list                        │
│ - Network info                      │
└─────────────────────────────────────┘
```

### Send Screen

```
┌─────────────────────────────────────┐
│ SendScreen                          │
│                                     │
│ Bindings:                           │
│ - TransactionController (lazy)      │
│ - NetworkController (lazy)          │
│                                     │
│ Controllers provide:                │
│ - Address validation                │
│ - Gas estimation                    │
│ - Transaction sending               │
│ - Network info                      │
└─────────────────────────────────────┘
```

## Security Considerations

### Stack Clearing Strategy

**When to clear stack (offAllNamed):**

1. ✅ After wallet creation → Home
2. ✅ After unlock → Home
3. ✅ Lock wallet → Unlock
4. ✅ After import → Home

**When NOT to clear stack (toNamed):**

1. ✅ Home → Send (user can go back)
2. ✅ Home → Receive (user can go back)
3. ✅ Home → Settings (user can go back)
4. ✅ Onboarding → Create (user can go back)

### Mnemonic Security

```
┌─────────────────────────────────────┐
│ Mnemonic Flow                       │
│                                     │
│ 1. Created in CreateWalletScreen    │
│    ↓                                │
│ 2. Passed to BackupScreen           │
│    (via route arguments)            │
│    ↓                                │
│ 3. Passed to ConfirmScreen          │
│    (via route arguments)            │
│    ↓                                │
│ 4. Verified and cleared             │
│    ↓                                │
│ 5. Navigate to Home                 │
│    (stack cleared - mnemonic gone)  │
└─────────────────────────────────────┘
```

**Security Rules:**

- ✅ Mnemonic passed as route arguments (not stored in controller)
- ✅ Cleared from memory after verification
- ✅ Never logged
- ✅ Stack cleared after backup (can't go back to view mnemonic)

## Route Guards

### AuthMiddleware (Protected Routes)

```
┌─────────────────────────────────────┐
│ User tries to access /home          │
│         ↓                           │
│ AuthMiddleware checks:              │
│   - Does wallet exist?              │
│   - Is wallet unlocked?             │
│         ↓                           │
│ ┌───────┴────────┐                 │
│ │                │                 │
│ No wallet    Wallet exists         │
│ │                │                 │
│ ↓                ↓                 │
│ Redirect to   Allow access         │
│ Onboarding    to /home             │
└─────────────────────────────────────┘
```

### PublicRouteMiddleware (Public Routes)

```
┌─────────────────────────────────────┐
│ User tries to access /onboarding    │
│         ↓                           │
│ PublicRouteMiddleware checks:       │
│   - Does wallet exist?              │
│         ↓                           │
│ ┌───────┴────────┐                 │
│ │                │                 │
│ Wallet exists  No wallet           │
│ │                │                 │
│ ↓                ↓                 │
│ Redirect to   Allow access         │
│ Unlock        to /onboarding       │
└─────────────────────────────────────┘
```

## Summary

The navigation system provides:

- ✅ Clear, predictable flows
- ✅ Security-first approach (stack clearing)
- ✅ Proper controller lifecycle management
- ✅ Type-safe navigation
- ✅ Route guards for authentication
- ✅ Mnemonic security (no storage in memory)

All flows are implemented and ready for integration with domain layer!
