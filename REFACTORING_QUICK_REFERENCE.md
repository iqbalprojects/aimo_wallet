# Clean Architecture Refactoring - Quick Reference

## 🚨 CRITICAL CHANGES - READ FIRST

### 1. Mnemonic Handling (SECURITY CRITICAL)

**❌ NEVER DO THIS**:

```dart
// DON'T pass mnemonic in navigation
Get.toNamed(route, arguments: {'mnemonic': mnemonic});

// DON'T store mnemonic in controller
final RxnString _mnemonic = RxnString();
_mnemonic.value = result.mnemonic;
```

**✅ ALWAYS DO THIS**:

```dart
// DO use secure sessions
final sessionId = SecureSessionManager.createMnemonicSession(mnemonic);
Get.toNamed(route, arguments: {'sessionId': sessionId});

// DO use callbacks
await controller.createWallet(
  pin: pin,
  onSuccess: (mnemonic, address) {
    // Handle immediately, don't store
    NavigationHelper.navigateToBackup(mnemonic: mnemonic);
  },
);
```

---

### 2. Controller Initialization

**❌ NEVER DO THIS**:

```dart
// DON'T create new instances
final controller = Get.put(WalletController());
```

**✅ ALWAYS DO THIS**:

```dart
// DO use dependency injection
final controller = Get.find<WalletController>();
```

---

### 3. App Initialization

**❌ NEVER DO THIS**:

```dart
void main() {
  runApp(const AimoWalletApp());
}
```

**✅ ALWAYS DO THIS**:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();  // CRITICAL
  runApp(const AimoWalletApp());
}
```

---

## 📋 LAYER RESPONSIBILITIES

### Presentation Layer (UI + Controllers)

- ✅ Display data
- ✅ Handle user input
- ✅ Observe reactive state
- ✅ Call use cases
- ❌ NO crypto logic
- ❌ NO mnemonic storage
- ❌ NO vault access
- ❌ NO business logic

### Domain Layer (Use Cases)

- ✅ Business logic
- ✅ Coordinate core services
- ✅ Validate inputs
- ✅ Handle errors
- ❌ NO UI dependencies
- ❌ NO platform dependencies

### Core Layer (Services)

- ✅ Cryptographic operations
- ✅ Secure storage
- ✅ Pure functions
- ❌ NO business logic
- ❌ NO UI dependencies

---

## 🔒 SECURITY CHECKLIST

Before committing code, verify:

- [ ] No mnemonic in navigation arguments
- [ ] No mnemonic in controller state
- [ ] No private keys stored
- [ ] Secure sessions used for sensitive data
- [ ] Sessions cleared after use
- [ ] PIN not logged
- [ ] Error messages don't leak sensitive data
- [ ] Memory cleared after crypto operations

---

## 🧪 TESTING CHECKLIST

Before merging:

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Security tests pass
- [ ] No memory leaks
- [ ] Sessions expire correctly
- [ ] Error handling works
- [ ] Navigation flows work

---

## 📞 NEED HELP?

- Security questions: Review `CLEAN_ARCHITECTURE_REFACTORING.md`
- Architecture questions: Review `ARCHITECTURE.md`
- Implementation examples: Check refactored controllers

---

## 🚀 QUICK START

1. Pull latest changes
2. Run `flutter pub get`
3. Verify `main.dart` has `AppInitializer.initialize()`
4. Update your code to use secure sessions
5. Test thoroughly
6. Submit PR

---

## ⚠️ BREAKING CHANGES

### WalletController API Changed

**Old**:

```dart
await controller.createWallet(pin);
final mnemonic = controller.generatedMnemonic;
```

**New**:

```dart
await controller.createWallet(
  pin: pin,
  onSuccess: (mnemonic, address) {
    // Handle mnemonic
  },
);
```

### Navigation Changed

**Old**:

```dart
NavigationHelper.navigateToBackup(mnemonic: mnemonic);
// Mnemonic in Get.arguments['mnemonic']
```

**New**:

```dart
NavigationHelper.navigateToBackup(mnemonic: mnemonic);
// Session ID in Get.arguments['sessionId']
final sessionId = Get.arguments['sessionId'];
final mnemonic = SecureSessionManager.getMnemonic(sessionId);
```

---

## 📚 FURTHER READING

- Full refactoring details: `CLEAN_ARCHITECTURE_REFACTORING.md`
- Security audit: `COMPREHENSIVE_SECURITY_AUDIT.md` (in previous response)
- Architecture guide: `ARCHITECTURE.md`
