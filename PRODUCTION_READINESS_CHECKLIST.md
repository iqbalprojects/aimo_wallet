# Production Readiness Checklist

## Overview

This checklist ensures the Aimo Wallet app is ready for production release with proper security, performance, and user experience.

---

## 1. Security Hardening ✅

### 1.1 Code Obfuscation

- [ ] **Enable Flutter obfuscation** in release builds
    ```bash
    flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
    flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
    ```
- [ ] **Store symbol files** for crash reporting (build/app/outputs/symbols)
- [ ] **Test obfuscated build** to ensure no runtime errors

### 1.2 Screenshot Protection

- [x] **Created** `lib/core/security/screenshot_protection.dart`
- [ ] **Implement native Android code** (MainActivity.kt):
    ```kotlin
    // Add to MainActivity.kt
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Setup method channel
        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "aimo_wallet/security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableScreenshotProtection" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disableScreenshotProtection" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    ```
- [ ] **Implement native iOS code** (AppDelegate.swift):
    ```swift
    // Add to AppDelegate.swift
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let securityChannel = FlutterMethodChannel(
            name: "aimo_wallet/security",
            binaryMessenger: controller.binaryMessenger
        )

        securityChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "enableScreenshotProtection":
                // iOS: Hide content in app switcher
                NotificationCenter.default.addObserver(
                    forName: UIApplication.willResignActiveNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    self?.window?.isHidden = true
                }
                result(nil)
            case "disableScreenshotProtection":
                NotificationCenter.default.removeObserver(self!)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    ```
- [ ] **Apply to sensitive screens**:
    - BackupMnemonicScreen
    - ConfirmMnemonicScreen
    - UnlockScreen (PIN entry)
    - SettingsScreen (when viewing recovery phrase)

### 1.3 Root/Jailbreak Detection

- [x] **Created** `lib/core/security/root_detection.dart`
- [ ] **Add dependency** to pubspec.yaml:
    ```yaml
    dependencies:
        flutter_jailbreak_detection: ^1.10.0 # Or implement native
    ```
- [ ] **Implement native Android code** (MainActivity.kt):
    ```kotlin
    private fun isDeviceRooted(): Boolean {
        // Check for su binary
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )

        for (path in paths) {
            if (File(path).exists()) return true
        }

        // Check for test-keys
        val buildTags = android.os.Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }

        return false
    }
    ```
- [ ] **Implement native iOS code** (AppDelegate.swift):
    ```swift
    private func isDeviceJailbroken() -> Bool {
        // Check for Cydia
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") {
            return true
        }

        // Check for suspicious paths
        let paths = [
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }
    ```
- [ ] **Add check on app startup** (main.dart or splash screen)
- [ ] **Show warning dialog** if device is rooted/jailbroken
- [ ] **Optionally block app** on compromised devices (configurable)

### 1.4 Remove Debug Code

- [x] **Removed print statement** from app_initializer.dart
- [x] **Created AppConfig** for centralized logging
- [ ] **Replace all print() calls** with AppConfig.log()
- [ ] **Remove all debugPrint() calls** or wrap in kDebugMode
- [ ] **Remove all TODO comments** or convert to GitHub issues
- [ ] **Remove example/ directory** from production build:
    ```yaml
    # In pubspec.yaml
    flutter:
        assets:
            # Don't include example files
    ```

### 1.5 Sensitive Data Logging

- [x] **Verified no mnemonic logging** (grep search completed)
- [x] **Verified no private key logging** (grep search completed)
- [x] **Verified no PIN logging** (grep search completed)
- [ ] **Review all error messages** to ensure no sensitive data exposure
- [ ] **Implement secure error reporting** (e.g., Sentry with data scrubbing)

### 1.6 API Keys and Secrets

- [x] **Moved RPC URLs to environment variables**
- [ ] **Create .env file** for development:
    ```env
    ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR-PROJECT-ID
    SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR-PROJECT-ID
    ```
- [ ] **Add .env to .gitignore**
- [ ] **Use flutter_dotenv** or build-time environment variables:
    ```bash
    flutter build apk --release --dart-define=ETHEREUM_RPC_URL=https://...
    ```
- [ ] **Document environment variables** in README.md

---

## 2. Build Configuration 🔧

### 2.1 Android Configuration

- [ ] **Update android/app/build.gradle**:
    ```gradle
    android {
        compileSdkVersion 34

        defaultConfig {
            minSdkVersion 21
            targetSdkVersion 34
            versionCode 1
            versionName "1.0.0"
        }

        buildTypes {
            release {
                signingConfig signingConfigs.release
                minifyEnabled true
                shrinkResources true
                proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            }
        }
    }
    ```
- [ ] **Create proguard-rules.pro**:

    ```proguard
    # Keep crypto classes
    -keep class org.bouncycastle.** { *; }
    -keep class com.google.crypto.** { *; }

    # Keep Flutter classes
    -keep class io.flutter.** { *; }
    -keep class io.flutter.plugins.** { *; }

    # Keep wallet classes
    -keep class com.aimo.wallet.** { *; }
    ```

- [ ] **Setup signing** (android/key.properties):
    ```properties
    storePassword=<password>
    keyPassword=<password>
    keyAlias=upload
    storeFile=<path-to-keystore>
    ```
- [ ] **Add permissions** to AndroidManifest.xml:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    ```

### 2.2 iOS Configuration

- [ ] **Update ios/Runner/Info.plist**:
    ```xml
    <key>NSFaceIDUsageDescription</key>
    <string>Use Face ID to unlock your wallet</string>
    <key>NSCameraUsageDescription</key>
    <string>Scan QR codes for transactions</string>
    ```
- [ ] **Update ios/Runner.xcodeproj** build settings:
    - Set ENABLE_BITCODE = NO
    - Set SWIFT_VERSION = 5.0
    - Set IPHONEOS_DEPLOYMENT_TARGET = 12.0
- [ ] **Setup code signing** in Xcode
- [ ] **Create App Store Connect entry**

### 2.3 Flutter Configuration

- [ ] **Update pubspec.yaml version**:
    ```yaml
    version: 1.0.0+1
    ```
- [ ] **Remove dev dependencies** from release:
    ```yaml
    # These are already in dev_dependencies, verify they're not in dependencies
    ```
- [ ] **Optimize assets**:
    - Compress images
    - Remove unused assets
    - Use vector graphics where possible

---

## 3. Error Handling & UX 🎨

### 3.1 User-Friendly Error Messages

- [ ] **Review all error messages** in controllers
- [ ] **Replace technical errors** with user-friendly messages:

    ```dart
    // Before
    _errorMessage.value = 'VaultException: decryption_failed';

    // After
    _errorMessage.value = 'Incorrect PIN. Please try again.';
    ```

- [ ] **Add error message constants**:
    ```dart
    class ErrorMessages {
      static const incorrectPin = 'Incorrect PIN. Please try again.';
      static const walletLocked = 'Wallet is locked. Please unlock to continue.';
      static const networkError = 'Network error. Please check your connection.';
      static const insufficientFunds = 'Insufficient funds for this transaction.';
    }
    ```

### 3.2 Loading States

- [ ] **Add loading indicators** to all async operations
- [ ] **Add timeout handling** for network requests
- [ ] **Add retry mechanisms** for failed operations

### 3.3 Offline Support

- [ ] **Handle offline mode** gracefully
- [ ] **Cache wallet address** for offline display
- [ ] **Show offline indicator** in UI
- [ ] **Queue transactions** for when online

---

## 4. Testing 🧪

### 4.1 Unit Tests

- [x] **Created use case tests** (GetCurrentAddress, UnlockWallet, SignTransaction)
- [ ] **Run all tests**: `flutter test`
- [ ] **Generate coverage**: `flutter test --coverage`
- [ ] **Achieve 80%+ coverage** on critical paths

### 4.2 Integration Tests

- [ ] **Create wallet creation flow test**
- [ ] **Create transaction signing flow test**
- [ ] **Create unlock/lock flow test**
- [ ] **Run integration tests**: `flutter test integration_test/`

### 4.3 Manual Testing

- [ ] **Test on physical Android device**
- [ ] **Test on physical iOS device**
- [ ] **Test wallet creation flow**
- [ ] **Test wallet import flow**
- [ ] **Test transaction signing**
- [ ] **Test PIN change**
- [ ] **Test biometric authentication**
- [ ] **Test auto-lock**
- [ ] **Test network switching**
- [ ] **Test app backgrounding** (wallet should lock)
- [ ] **Test app kill and restart** (wallet should be locked)

### 4.4 Security Testing

- [ ] **Test on rooted Android device** (should show warning)
- [ ] **Test on jailbroken iOS device** (should show warning)
- [ ] **Test screenshot protection** (screenshots should be blocked)
- [ ] **Test memory dumps** (no sensitive data in memory)
- [ ] **Test network traffic** (no sensitive data in plaintext)
- [ ] **Penetration testing** (optional, recommended)

---

## 5. Performance Optimization ⚡

### 5.1 App Size

- [ ] **Analyze app size**: `flutter build apk --analyze-size`
- [ ] **Remove unused dependencies**
- [ ] **Enable tree shaking** (automatic in release mode)
- [ ] **Split APKs by ABI**:
    ```bash
    flutter build apk --release --split-per-abi
    ```

### 5.2 Startup Time

- [ ] **Measure startup time**
- [ ] **Optimize AppInitializer** (already async)
- [ ] **Lazy load controllers** where possible
- [ ] **Defer non-critical initialization**

### 5.3 Memory Usage

- [ ] **Profile memory usage**: `flutter run --profile`
- [ ] **Fix memory leaks** (dispose controllers properly)
- [ ] **Optimize image loading**
- [ ] **Clear sensitive data** from memory (already implemented)

---

## 6. Documentation 📚

### 6.1 User Documentation

- [ ] **Create user guide** (how to use wallet)
- [ ] **Create FAQ** (common questions)
- [ ] **Create security guide** (best practices)
- [ ] **Create backup guide** (how to backup mnemonic)

### 6.2 Developer Documentation

- [x] **Architecture documentation** (ARCHITECTURE.md exists)
- [x] **Security audit** (SECURITY_AUDIT_FINAL.md exists)
- [ ] **API documentation** (generate with dartdoc)
- [ ] **Build instructions** (README.md)
- [ ] **Deployment guide** (how to release)

### 6.3 Legal Documentation

- [ ] **Create Terms of Service**
- [ ] **Create Privacy Policy**
- [ ] **Create Open Source Licenses** (flutter pub licenses)
- [ ] **Add disclaimers** (non-custodial wallet, user responsibility)

---

## 7. App Store Preparation 📱

### 7.1 Google Play Store

- [ ] **Create app listing**
- [ ] **Prepare screenshots** (5-8 screenshots)
- [ ] **Write app description**
- [ ] **Create feature graphic** (1024x500)
- [ ] **Create app icon** (512x512)
- [ ] **Set content rating**
- [ ] **Set pricing** (free)
- [ ] **Add privacy policy URL**
- [ ] **Submit for review**

### 7.2 Apple App Store

- [ ] **Create app listing** in App Store Connect
- [ ] **Prepare screenshots** (6.5" and 5.5" displays)
- [ ] **Write app description**
- [ ] **Create app icon** (1024x1024)
- [ ] **Set age rating**
- [ ] **Set pricing** (free)
- [ ] **Add privacy policy URL**
- [ ] **Submit for review**

---

## 8. Monitoring & Analytics 📊

### 8.1 Crash Reporting

- [ ] **Integrate Firebase Crashlytics** or Sentry:
    ```yaml
    dependencies:
        firebase_crashlytics: ^3.4.0
    ```
- [ ] **Setup crash reporting** in main.dart:
    ```dart
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    ```
- [ ] **Test crash reporting**

### 8.2 Analytics

- [ ] **Integrate Firebase Analytics** (optional):
    ```yaml
    dependencies:
        firebase_analytics: ^10.7.0
    ```
- [ ] **Track key events** (wallet created, transaction sent, etc.)
- [ ] **Respect user privacy** (no sensitive data in analytics)

### 8.3 Performance Monitoring

- [ ] **Integrate Firebase Performance** (optional)
- [ ] **Monitor app startup time**
- [ ] **Monitor network requests**
- [ ] **Monitor screen rendering**

---

## 9. Final Checks ✔️

### 9.1 Pre-Release Checklist

- [ ] **All tests passing**
- [ ] **No debug code in production**
- [ ] **No hardcoded secrets**
- [ ] **Obfuscation enabled**
- [ ] **Screenshot protection implemented**
- [ ] **Root detection implemented**
- [ ] **Error messages user-friendly**
- [ ] **App icon set**
- [ ] **Splash screen set**
- [ ] **Version number updated**
- [ ] **Build number incremented**

### 9.2 Security Audit

- [ ] **Review security audit** (SECURITY_AUDIT_FINAL.md)
- [ ] **Verify all critical issues fixed**
- [ ] **Verify all high issues fixed**
- [ ] **Document remaining medium/low issues**
- [ ] **Third-party security audit** (recommended)

### 9.3 Legal Compliance

- [ ] **GDPR compliance** (if applicable)
- [ ] **CCPA compliance** (if applicable)
- [ ] **Financial regulations** (check local laws)
- [ ] **Open source license compliance**

---

## 10. Release Process 🚀

### 10.1 Build Release

```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

### 10.2 Test Release Build

- [ ] **Install release APK** on test device
- [ ] **Test all critical flows**
- [ ] **Verify obfuscation** (check stack traces)
- [ ] **Verify screenshot protection**
- [ ] **Verify root detection**

### 10.3 Deploy

- [ ] **Upload to Google Play Console** (internal testing first)
- [ ] **Upload to App Store Connect** (TestFlight first)
- [ ] **Test via TestFlight/Internal Testing**
- [ ] **Promote to production** after testing

### 10.4 Post-Release

- [ ] **Monitor crash reports**
- [ ] **Monitor user reviews**
- [ ] **Monitor analytics**
- [ ] **Prepare hotfix process** (if needed)
- [ ] **Plan next release**

---

## Summary

### Critical Items (Must Complete)

1. ✅ Remove debug print statements
2. ✅ Remove sensitive data logging
3. ✅ Move API keys to environment variables
4. ⚠️ Enable Flutter obfuscation
5. ⚠️ Implement screenshot protection (native code)
6. ⚠️ Implement root/jailbreak detection (native code)
7. ⚠️ Replace technical error messages with user-friendly ones
8. ⚠️ Run all tests and achieve 80%+ coverage
9. ⚠️ Test on physical devices
10. ⚠️ Setup crash reporting

### High Priority Items

11. Remove TODO comments
12. Setup code signing
13. Create app store listings
14. Write user documentation
15. Create Terms of Service and Privacy Policy

### Medium Priority Items

16. Optimize app size
17. Setup analytics
18. Create FAQ
19. Third-party security audit
20. Performance monitoring

---

## Status Legend

- ✅ Complete
- ⚠️ In Progress / Needs Attention
- ❌ Not Started
- 🔄 Ongoing

---

**Last Updated**: [Current Date]
**Version**: 1.0.0
**Status**: Pre-Production
