# Dependency Injection

This module provides dependency injection and app initialization for the Aimo Wallet.

## Overview

The DI module uses GetX for dependency injection and service location. It follows clean architecture principles with clear separation between layers.

## Components

### ServiceLocator

Registers all dependencies using GetX:

- **Core Services** (Singletons): BIP39, BIP32, KeyDerivation, Encryption
- **Data Sources** (Singletons): FlutterSecureStorage, SecureStorageDataSource
- **Repositories** (Singletons): WalletRepository
- **Use Cases** (Lazy): CreateWallet, ImportWallet, UnlockWallet, etc.
- **Controllers** (Lazy): WalletController, WalletCreationController, etc.

### AppInitializer

Initializes the app on startup:

1. Registers all dependencies via ServiceLocator
2. Initializes WalletController
3. Checks wallet existence
4. Sets initial wallet state

## Usage

### Basic Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app (DI + wallet state)
  await AppInitializer.initialize();

  runApp(MyApp());
}
```

### Accessing Dependencies

```dart
// Get registered dependencies
final walletController = Get.find<WalletController>();
final createWalletUseCase = Get.find<CreateWalletUseCase>();
final bip39Service = Get.find<Bip39Service>();
```

### Testing

```dart
void main() {
  setUp(() {
    // Initialize for testing
    ServiceLocator.init();
  });

  tearDown(() {
    // Clean up after tests
    ServiceLocator.dispose();
  });

  test('example test', () {
    final controller = Get.find<WalletController>();
    // Test logic...
  });
}
```

## Dependency Graph

```
Controllers
    ↓
Use Cases
    ↓
Repositories
    ↓
Data Sources + Services
    ↓
Platform APIs (FlutterSecureStorage, PointyCastle)
```

## Registration Patterns

### Singleton (fenix: true)

Used for services and repositories that maintain state or are expensive to create:

```dart
Get.lazyPut<Bip39Service>(
  () => Bip39ServiceImpl(),
  fenix: true, // Keep alive
);
```

### Lazy Singleton

Used for controllers that should be created when first accessed:

```dart
Get.lazyPut<WalletController>(
  () => WalletController(...),
);
```

### Factory (Not Used)

Use cases are registered as lazy singletons since they're stateless. If needed, factories can be created:

```dart
Get.put<CreateWalletUseCase>(
  CreateWalletUseCase(...),
  permanent: false, // Dispose when not in use
);
```

## Requirements

- **10.3**: Dependency injection for testability
- **10.4**: Clean architecture with dependency inversion
- **7.1**: Check wallet existence on app start
- **7.5**: Set initial wallet state

## Security Considerations

1. **No Sensitive Data in DI**: Dependencies don't store sensitive data (mnemonic, private key)
2. **Secure Storage**: FlutterSecureStorage configured with platform-specific encryption
3. **Lazy Initialization**: Services created only when needed
4. **Proper Cleanup**: ServiceLocator.dispose() clears all dependencies

## Architecture

The DI module follows clean architecture:

- **Core Layer**: Cryptographic services (BIP39, BIP32, Encryption)
- **Domain Layer**: Use cases and repository interfaces
- **Data Layer**: Repository implementations and data sources
- **Presentation Layer**: GetX controllers for UI state

All dependencies flow inward (presentation → domain → data → core), following the dependency rule.
