# GetX Routing Implementation

Complete GetX routing setup with navigation flows, controller bindings, and route guards.

## Overview

The routing system uses GetX for declarative navigation with:

- Type-safe route constants
- Lazy controller initialization
- Route guards and middleware
- Navigation helper utilities
- Clear separation of concerns

## Files Created/Updated

### Core Routing Files

- `lib/core/routes/app_routes.dart` - Route constants
- `lib/core/routes/app_pages.dart` - Page definitions with bindings
- `lib/core/routes/navigation_helper.dart` - Navigation utility methods
- `lib/core/routes/auth_middleware.dart` - Route guards and middleware

### Updated Files

- `lib/features/wallet/presentation/pages/splash_screen.dart` - Navigation logic
- `lib/main.dart` - GetX app configuration

## Route Structure

### Route Constants

```dart
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String createWallet = '/create-wallet';
  static const String backupMnemonic = '/backup-mnemonic';
  static const String confirmMnemonic = '/confirm-mnemonic';
  static const String unlock = '/unlock';
  static const String home = '/home';
  static const String send = '/send';
  static const String receive = '/receive';
  static const String settings = '/settings';
}
```

## Navigation Flows

### 1. New Wallet Flow

```
Splash → Onboarding → Create → Backup → Confirm → Home
```

**Steps:**

1. User opens app (no wallet exists)
2. Splash checks `WalletController.hasWallet` (false)
3. Navigate to Onboarding
4. User taps "Create New Wallet"
5. Navigate to Create Wallet screen
6. User creates wallet, gets mnemonic
7. Navigate to Backup screen (mnemonic passed as argument)
8. User views and confirms backup
9. Navigate to Confirm screen (mnemonic passed for verification)
10. User verifies random words
11. Navigate to Home (clear stack with `offAllNamed`)

**Code Example:**

```dart
// In CreateWalletScreen
final mnemonic = await walletController.createWallet(pin);
NavigationHelper.navigateToBackup(mnemonic: mnemonic);

// In BackupMnemonicScreen
NavigationHelper.navigateToConfirm(mnemonic: mnemonic);

// In ConfirmMnemonicScreen
NavigationHelper.completeWalletCreation(); // Goes to home
```

### 2. Existing Wallet Flow

```
Splash → Unlock → Home
```

**Steps:**

1. User opens app (wallet exists)
2. Splash checks `WalletController.hasWallet` (true)
3. Navigate to Unlock screen
4. User enters PIN
5. `AuthController.verifyPin()` validates
6. Navigate to Home (clear stack with `offAllNamed`)

**Code Example:**

```dart
// In SplashScreen
if (walletController.hasWallet) {
  Get.offNamed(AppRoutes.unlock);
}

// In UnlockScreen
final isValid = await authController.verifyPin(pin);
if (isValid) {
  NavigationHelper.navigateToHomeAfterUnlock();
}
```

### 3. Import Wallet Flow

```
Splash → Onboarding → Create (Import) → Home
```

**Steps:**

1. User opens app (no wallet exists)
2. Navigate to Onboarding
3. User taps "Import Existing Wallet"
4. Navigate to Create Wallet screen
5. User enters mnemonic and PIN
6. `WalletController.importWallet()` validates and imports
7. Navigate to Home (clear stack with `offAllNamed`)

**Code Example:**

```dart
// In CreateWalletScreen (Import mode)
final success = await walletController.importWallet(mnemonic, pin);
if (success) {
  NavigationHelper.completeWalletCreation();
}
```

### 4. Lock Wallet Flow

```
Any Screen → Unlock
```

**Steps:**

1. User taps lock button or auto-lock triggers
2. Clear all navigation stack
3. Navigate to Unlock screen
4. User must re-authenticate

**Code Example:**

```dart
// In any screen
NavigationHelper.lockWallet(); // Clears stack, goes to unlock
```

## Controller Bindings

### Lazy Initialization

Controllers are lazily initialized when their page is accessed:

```dart
GetPage(
  name: AppRoutes.home,
  page: () => const HomeDashboardScreen(),
  binding: BindingsBuilder(() {
    Get.lazyPut<WalletController>(() => WalletController());
    Get.lazyPut<NetworkController>(() => NetworkController());
  }),
)
```

### Global Controllers

Some controllers are initialized on app start (in SplashScreen):

- `WalletController` - Wallet state and operations
- `AuthController` - Authentication and PIN management

### Page-Specific Controllers

Controllers bound to specific pages:

- `TransactionController` - Send/Receive screens
- `NetworkController` - Network switching

## Navigation Helper

Centralized navigation methods for common flows:

```dart
// Wallet creation
NavigationHelper.startWalletCreation();
NavigationHelper.navigateToBackup(mnemonic: mnemonic);
NavigationHelper.navigateToConfirm(mnemonic: mnemonic);
NavigationHelper.completeWalletCreation();

// Authentication
NavigationHelper.navigateToUnlock();
NavigationHelper.navigateToHomeAfterUnlock();
NavigationHelper.lockWallet();

// Home navigation
NavigationHelper.navigateToHome();
NavigationHelper.navigateToSend();
NavigationHelper.navigateToReceive();
NavigationHelper.navigateToSettings();

// Utility
NavigationHelper.goBack();
NavigationHelper.canGoBack();
```

## Route Guards (Middleware)

### AuthMiddleware

Protects authenticated routes:

```dart
GetPage(
  name: AppRoutes.home,
  page: () => const HomeDashboardScreen(),
  middlewares: [AuthMiddleware()],
)
```

**Logic:**

- Checks if wallet exists
- Redirects to onboarding if no wallet
- Redirects to unlock if wallet locked

### PublicRouteMiddleware

Prevents authenticated users from accessing public routes:

```dart
GetPage(
  name: AppRoutes.onboarding,
  page: () => const OnboardingScreen(),
  middlewares: [PublicRouteMiddleware()],
)
```

**Logic:**

- Checks if wallet exists
- Redirects to unlock if wallet exists
- Allows access if no wallet

## Passing Data Between Screens

### Using Arguments

```dart
// Passing data
Get.toNamed(
  AppRoutes.backupMnemonic,
  arguments: {'mnemonic': mnemonic},
);

// Receiving data
final args = Get.arguments as Map<String, dynamic>;
final mnemonic = args['mnemonic'] as String?;
```

### Using Controller State

```dart
// Set state in controller
walletController.setMnemonic(mnemonic);

// Read state in next screen
final mnemonic = walletController.getMnemonic();
```

**Note:** For security, mnemonic should be passed as arguments and cleared after use, not stored in controller state.

## Security Considerations

### 1. Stack Clearing

Use `offAllNamed` for sensitive transitions:

```dart
// After wallet creation
Get.offAllNamed(AppRoutes.home); // Clears backup/confirm screens

// After unlock
Get.offAllNamed(AppRoutes.home); // Clears unlock screen

// Lock wallet
Get.offAllNamed(AppRoutes.unlock); // Clears all screens
```

### 2. Mnemonic Handling

- Pass mnemonic as route argument (not stored in controller)
- Clear mnemonic from memory after use
- Never log mnemonic
- Clear navigation stack after backup

### 3. PIN Verification

- PIN never stored in controller
- Only verified via use case
- Failed attempts tracked
- Auto-lockout after 5 failed attempts

## Testing Navigation

### Unit Tests

```dart
test('should navigate to unlock if wallet exists', () async {
  // Arrange
  when(walletController.hasWallet).thenReturn(true);

  // Act
  await tester.pumpWidget(SplashScreen());
  await tester.pumpAndSettle();

  // Assert
  expect(Get.currentRoute, AppRoutes.unlock);
});
```

### Integration Tests

```dart
testWidgets('complete wallet creation flow', (tester) async {
  // Start at splash
  await tester.pumpWidget(MyApp());

  // Should navigate to onboarding
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingScreen), findsOneWidget);

  // Tap create wallet
  await tester.tap(find.text('Create New Wallet'));
  await tester.pumpAndSettle();
  expect(find.byType(CreateWalletScreen), findsOneWidget);

  // Continue through flow...
});
```

## Best Practices

### 1. Use Navigation Helper

✅ **Good:**

```dart
NavigationHelper.navigateToHome();
```

❌ **Bad:**

```dart
Get.toNamed('/home');
```

### 2. Clear Stack for Security

✅ **Good:**

```dart
Get.offAllNamed(AppRoutes.unlock); // Clears sensitive screens
```

❌ **Bad:**

```dart
Get.toNamed(AppRoutes.unlock); // Leaves screens in stack
```

### 3. Use Route Constants

✅ **Good:**

```dart
Get.toNamed(AppRoutes.home);
```

❌ **Bad:**

```dart
Get.toNamed('/home'); // Magic string
```

### 4. Lazy Controller Initialization

✅ **Good:**

```dart
Get.lazyPut<WalletController>(() => WalletController());
```

❌ **Bad:**

```dart
Get.put(WalletController()); // Eager initialization
```

## Future Enhancements

### 1. Deep Linking

Add support for deep links:

```dart
// Handle deep link
aimo://send?address=0x123&amount=1.5
```

### 2. Route Transitions

Custom transitions for specific routes:

```dart
GetPage(
  name: AppRoutes.home,
  page: () => const HomeDashboardScreen(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(milliseconds: 300),
)
```

### 3. Route History

Track navigation history for analytics:

```dart
class RouteObserver extends GetObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Log navigation
  }
}
```

### 4. Conditional Routes

Dynamic routes based on feature flags:

```dart
if (featureFlags.isEnabled('swap')) {
  routes.add(GetPage(name: AppRoutes.swap, page: () => SwapScreen()));
}
```

## Summary

The routing implementation provides:

- ✅ Type-safe navigation with route constants
- ✅ Lazy controller initialization with bindings
- ✅ Navigation helper for common flows
- ✅ Route guards for authentication
- ✅ Clear separation of concerns
- ✅ Security-first approach (stack clearing)
- ✅ Comprehensive documentation

All navigation flows are implemented and ready for integration with domain layer use cases.
