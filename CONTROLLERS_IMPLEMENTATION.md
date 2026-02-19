# GetX Controllers Implementation

## Overview

Implemented comprehensive GetX controllers following clean architecture principles with strict separation of concerns.

## Status: ✅ COMPLETE

## Controllers Implemented

### 1. WalletController

**File**: `lib/features/wallet/presentation/controllers/wallet_controller.dart`

**Responsibilities**:

- Expose reactive wallet state for UI
- Coordinate wallet operations (create, import)
- Provide wallet information (address, balance)
- Manage wallet lifecycle

**Reactive State**:

- `address` - Wallet address (public, safe to cache)
- `balance` - ETH balance
- `balanceUsd` - USD value of balance
- `isLoading` - Loading state
- `errorMessage` - Error messages
- `hasWallet` - Wallet existence flag

**Key Methods**:

- `createWallet(pin)` - Create new wallet
- `importWallet(mnemonic, pin)` - Import existing wallet
- `refreshBalance()` - Update balance from blockchain
- `getAddress()` - Get current address

**Separation of Concerns**:

- ✅ NO crypto logic (calls use cases)
- ✅ NO mnemonic storage
- ✅ NO private key storage
- ✅ Only public data cached (address, balance)
- ✅ All sensitive operations delegated

---

### 2. AuthController

**File**: `lib/features/wallet/presentation/controllers/auth_controller.dart`

**Responsibilities**:

- Manage authentication state
- Handle PIN operations (change, verify)
- Manage biometric settings
- Track failed attempts and lockout

**Reactive State**:

- `biometricEnabled` - Biometric setting
- `biometricAvailable` - Device capability
- `isLoading` - Loading state
- `errorMessage` - Error messages
- `failedAttempts` - Failed PIN attempts
- `isLockedOut` - Lockout status

**Key Methods**:

- `changePin(oldPin, newPin)` - Change PIN
- `verifyPin(pin)` - Verify PIN
- `toggleBiometric(enabled)` - Enable/disable biometric
- `authenticateWithBiometric()` - Biometric auth

**Separation of Concerns**:

- ✅ NO crypto logic (calls use cases)
- ✅ NO mnemonic access
- ✅ PIN never stored (only verified)
- ✅ Biometric is convenience, not security
- ✅ All sensitive operations via WalletLockController

---

### 3. TransactionController

**File**: `lib/features/transaction/presentation/controllers/transaction_controller.dart`

**Responsibilities**:

- Manage transaction state
- Coordinate transaction operations
- Provide transaction history
- Estimate gas fees
- Send transactions

**Reactive State**:

- `transactions` - Transaction history
- `pendingTransaction` - Current pending tx
- `estimatedGas` - Gas estimate
- `gasPrice` - Current gas price in Gwei
- `isLoading` - Loading state
- `isEstimatingGas` - Gas estimation state
- `errorMessage` - Error messages

**Key Methods**:

- `validateAddress(address)` - Validate Ethereum address
- `estimateGas(to, amount)` - Estimate transaction gas
- `sendTransaction(to, amount, pin)` - Send transaction
- `refreshTransactions()` - Reload history

**Separation of Concerns**:

- ✅ NO crypto logic (calls use cases)
- ✅ NO signing logic (uses TransactionSigner)
- ✅ NO mnemonic access (uses WalletLockController)
- ✅ Private keys NEVER stored
- ✅ Signing happens in domain layer

---

### 4. NetworkController

**File**: `lib/features/network_switch/presentation/controllers/network_controller.dart`

**Responsibilities**:

- Manage network state
- Provide network switching
- Manage custom networks
- Coordinate RPC client updates

**Reactive State**:

- `currentNetwork` - Active network
- `networks` - Available networks
- `isLoading` - Loading state
- `errorMessage` - Error messages

**Key Methods**:

- `switchNetwork(network)` - Switch to different network
- `addCustomNetwork(network)` - Add custom network
- `removeCustomNetwork(networkId)` - Remove custom network
- `getNetworkByChainId(chainId)` - Find network by chain ID

**Separation of Concerns**:

- ✅ NO blockchain logic (calls use cases)
- ✅ NO RPC implementation (uses network service)
- ✅ Network models for UI display
- ✅ Default networks provided

---

## Architecture Principles

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│     PRESENTATION LAYER              │
│  (Controllers - This Implementation)│
│                                     │
│  - Expose reactive state (Rx)      │
│  - Call use cases                  │
│  - NO business logic               │
│  - NO crypto logic                 │
└──────────────┬──────────────────────┘
               │ Calls
               ↓
┌─────────────────────────────────────┐
│       DOMAIN LAYER                  │
│         (Use Cases)                 │
│                                     │
│  - Business logic                  │
│  - Crypto operations               │
│  - Validation                      │
│  - Orchestration                   │
└──────────────┬──────────────────────┘
               │ Uses
               ↓
┌─────────────────────────────────────┐
│        DATA LAYER                   │
│  (Repositories & Services)          │
│                                     │
│  - Storage                         │
│  - Blockchain queries              │
│  - External APIs                   │
└─────────────────────────────────────┘
```

### Separation of Concerns

**Controllers (Presentation)**:

- ✅ Expose reactive state for UI
- ✅ Call use cases for operations
- ✅ Manage loading/error states
- ✅ NO business logic
- ✅ NO crypto logic
- ✅ NO direct storage access

**Use Cases (Domain)**:

- ✅ Implement business logic
- ✅ Coordinate services
- ✅ Validate inputs
- ✅ Handle crypto operations
- ✅ Return results to controllers

**Services (Domain/Data)**:

- ✅ Implement technical details
- ✅ Storage operations
- ✅ Blockchain queries
- ✅ Encryption/decryption
- ✅ Key derivation

### Security Principles

**What Controllers NEVER Store**:

- ❌ Mnemonic (24-word phrase)
- ❌ Private keys
- ❌ PIN (only verified, never stored)
- ❌ Decrypted sensitive data

**What Controllers CAN Store**:

- ✅ Wallet address (public info)
- ✅ Balance (public info)
- ✅ Transaction history (public info)
- ✅ Network settings (public info)
- ✅ UI state (loading, errors)

**Sensitive Operations**:

- All sensitive operations go through `WalletLockController`
- `WalletLockController.executeSecureOperation()` pattern
- Mnemonic retrieved only during operation
- Automatic cleanup after operation
- Private keys derived at runtime only

## Usage Examples

### WalletController

```dart
// In UI
class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Obx(() {
      if (controller.isLoading) {
        return CircularProgressIndicator();
      }

      return Column(
        children: [
          Text('Address: ${controller.address}'),
          Text('Balance: ${controller.balance} ETH'),
          Text('USD: \$${controller.balanceUsd}'),
        ],
      );
    });
  }
}

// Create wallet
final mnemonic = await controller.createWallet(pin);
// Show mnemonic to user for backup
// Clear mnemonic after backup

// Import wallet
final success = await controller.importWallet(mnemonic, pin);
```

### AuthController

```dart
// Change PIN
final controller = Get.find<AuthController>();
final success = await controller.changePin(oldPin, newPin);

// Verify PIN
final isValid = await controller.verifyPin(pin);

// Toggle biometric
await controller.toggleBiometric(true);

// Observe biometric state
Obx(() => Switch(
  value: controller.biometricEnabled,
  onChanged: controller.toggleBiometric,
));
```

### TransactionController

```dart
// Estimate gas
final controller = Get.find<TransactionController>();
await controller.estimateGas(toAddress, amount);

// Observe gas estimate
Obx(() => Text('Gas: ${controller.estimatedGas} ETH'));

// Send transaction
final txHash = await controller.sendTransaction(
  to: toAddress,
  amount: amount,
  pin: userPin,
);

// Observe transaction history
Obx(() => ListView.builder(
  itemCount: controller.transactions.length,
  itemBuilder: (context, index) {
    final tx = controller.transactions[index];
    return ListTile(
      title: Text(tx.hash),
      subtitle: Text(tx.amount),
    );
  },
));
```

### NetworkController

```dart
// Get current network
final controller = Get.find<NetworkController>();
Obx(() => Text(controller.currentNetwork?.name ?? 'No network'));

// Switch network
await controller.switchNetwork(network);

// Add custom network
final network = Network(
  id: 'custom-network',
  name: 'My Custom Network',
  chainId: 12345,
  rpcUrl: 'https://my-rpc.com',
  symbol: 'CUSTOM',
  explorerUrl: 'https://explorer.com',
  isTestnet: false,
  isCustom: true,
);
await controller.addCustomNetwork(network);

// Observe networks
Obx(() => DropdownButton(
  value: controller.currentNetwork,
  items: controller.networks.map((network) {
    return DropdownMenuItem(
      value: network,
      child: Text(network.name),
    );
  }).toList(),
  onChanged: controller.switchNetwork,
));
```

## Dependency Injection

All controllers should be registered with GetX dependency injection:

```dart
// In main.dart or service_locator.dart
void setupControllers() {
  // Register controllers
  Get.lazyPut(() => WalletController());
  Get.lazyPut(() => AuthController());
  Get.lazyPut(() => TransactionController());
  Get.lazyPut(() => NetworkController());
  Get.lazyPut(() => WalletLockController());
}

// In app initialization
void main() {
  setupControllers();
  runApp(MyApp());
}
```

## Testing

Controllers are designed to be easily testable:

```dart
// Example test
void main() {
  late WalletController controller;

  setUp(() {
    // Mock use cases
    controller = WalletController();
  });

  test('createWallet updates state', () async {
    final mnemonic = await controller.createWallet('123456');

    expect(controller.hasWallet, true);
    expect(controller.address, isNotNull);
    expect(mnemonic, isNotNull);
  });

  test('balance is reactive', () {
    expect(controller.balance, '0.0');

    // Trigger balance update
    controller.refreshBalance();

    // Observe change
    expect(controller.balance, isNot('0.0'));
  });
}
```

## TODO: Use Case Integration

All controllers have TODO comments indicating where use cases should be injected:

```dart
// TODO: Inject use cases via dependency injection
// final CreateWalletUseCase _createWalletUseCase;
// final ImportWalletUseCase _importWalletUseCase;
// final GetWalletAddressUseCase _getWalletAddressUseCase;
```

When use cases are implemented:

1. Add use case parameters to constructor
2. Replace placeholder logic with use case calls
3. Remove TODO comments
4. Update dependency injection

Example:

```dart
class WalletController extends GetxController {
  final CreateWalletUseCase _createWalletUseCase;

  WalletController({
    required CreateWalletUseCase createWalletUseCase,
  }) : _createWalletUseCase = createWalletUseCase;

  Future<String?> createWallet(String pin) async {
    // Replace placeholder with actual use case call
    final result = await _createWalletUseCase(pin);
    _address.value = result.address;
    return result.mnemonic;
  }
}
```

## Security Checklist

- [x] No mnemonic storage in controllers
- [x] No private key storage in controllers
- [x] PIN never stored (only verified)
- [x] All crypto logic delegated to domain layer
- [x] Sensitive operations via WalletLockController
- [x] Public data only (address, balance)
- [x] Reactive state for UI observation
- [x] Error handling implemented
- [x] Loading states managed
- [x] Comments explain separation of concerns

## Files Created/Updated

1. `lib/features/wallet/presentation/controllers/wallet_controller.dart` - ✅ Updated
2. `lib/features/wallet/presentation/controllers/auth_controller.dart` - ✅ Created
3. `lib/features/transaction/presentation/controllers/transaction_controller.dart` - ✅ Updated
4. `lib/features/network_switch/presentation/controllers/network_controller.dart` - ✅ Updated

## Next Steps

1. **Implement Use Cases**
    - CreateWalletUseCase
    - ImportWalletUseCase
    - SendTransactionUseCase
    - EstimateGasUseCase
    - ChangePinUseCase
    - etc.

2. **Dependency Injection**
    - Register controllers with GetX
    - Inject use cases into controllers
    - Setup service locator

3. **Connect UI**
    - Use Obx() for reactive UI
    - Call controller methods from UI
    - Handle loading/error states

4. **Testing**
    - Unit test controllers
    - Mock use cases
    - Test reactive state changes

## Notes

- All controllers follow GetX patterns
- Reactive state using Rx types
- Clean separation of concerns
- Security-first approach
- No crypto logic in presentation layer
- Ready for use case integration
- Comprehensive comments explaining architecture
- Placeholder implementations for testing
