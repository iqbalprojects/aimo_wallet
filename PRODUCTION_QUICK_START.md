# Production Quick Start Guide

## 🚀 Quick Steps to Production

### 1. Setup Environment (5 minutes)

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your API keys
nano .env

# Add to .gitignore
echo ".env" >> .gitignore
```

### 2. Implement Native Code (30 minutes)

#### Android: `android/app/src/main/kotlin/.../MainActivity.kt`

```kotlin
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aimo_wallet/security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableScreenshotProtection" -> {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                                      WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disableScreenshotProtection" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "isDeviceRooted" -> result.success(checkRoot())
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkRoot() = arrayOf("/sbin/su", "/system/bin/su", "/system/xbin/su")
        .any { File(it).exists() }
}
```

#### iOS: `ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "aimo_wallet/security",
                                          binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "enableScreenshotProtection":
                self?.enableScreenProtection()
                result(nil)
            case "disableScreenshotProtection":
                self?.disableScreenProtection()
                result(nil)
            case "isDeviceRooted":
                result(self?.checkJailbreak() ?? false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func enableScreenProtection() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.window?.isHidden = true }
    }

    private func disableScreenProtection() {
        NotificationCenter.default.removeObserver(self)
    }

    private func checkJailbreak() -> Bool {
        return ["/Applications/Cydia.app", "/bin/bash"].contains {
            FileManager.default.fileExists(atPath: $0)
        }
    }
}
```

### 3. Apply Security Features (10 minutes)

#### Add Screenshot Protection

```dart
// In backup_mnemonic_screen.dart, confirm_mnemonic_screen.dart, unlock_screen.dart
class _BackupMnemonicScreenState extends State<BackupMnemonicScreen>
    with ScreenshotProtectionMixin {
  // Automatically protected
}
```

#### Add Root Detection

```dart
// In splash_screen.dart or main.dart
Future<void> _checkSecurity() async {
  if (await RootDetection.isDeviceRooted()) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Warning'),
        content: const Text('Device is rooted/jailbroken. Proceed at your own risk.'),
        actions: [
          TextButton(onPressed: () => exit(0), child: const Text('Exit')),
          TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Continue')),
        ],
      ),
    );
  }
}
```

### 4. Build Release (5 minutes)

```bash
# Set environment variables
export ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR-PROJECT-ID
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR-PROJECT-ID

# Make script executable
chmod +x build_release.sh

# Build
./build_release.sh android  # or ios, or all
```

### 5. Test (30 minutes)

```bash
# Run tests
flutter test

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk

# Test checklist:
# ✓ Wallet creation
# ✓ Wallet unlock
# ✓ Transaction signing
# ✓ Screenshot blocked on mnemonic screen
# ✓ Root warning shown (if rooted)
# ✓ App locks on background
```

---

## 📋 Pre-Release Checklist

### Critical (Must Do)

- [ ] Native code implemented (Android + iOS)
- [ ] Screenshot protection applied to sensitive screens
- [ ] Root detection check on startup
- [ ] Environment variables configured
- [ ] All tests passing
- [ ] Tested on physical devices
- [ ] Code signing setup

### Important (Should Do)

- [ ] Terms of Service created
- [ ] Privacy Policy created
- [ ] App store listings prepared
- [ ] Crash reporting setup (Firebase/Sentry)
- [ ] User documentation written

### Optional (Nice to Have)

- [ ] Analytics setup
- [ ] Performance optimization
- [ ] Third-party security audit
- [ ] Internationalization (i18n)

---

## 🔧 Build Commands Reference

### Development

```bash
flutter run --debug
```

### Release (Manual)

```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

### Release (Automated)

```bash
./build_release.sh android  # Android only
./build_release.sh ios      # iOS only
./build_release.sh all      # Both platforms
```

---

## 🐛 Troubleshooting

### Build Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
./build_release.sh android
```

### Tests Fail

```bash
# Generate mocks
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test
```

### Native Code Not Working

```bash
# Android: Check MainActivity.kt path
# iOS: Check AppDelegate.swift path
# Verify method channel name: "aimo_wallet/security"
```

---

## 📚 Documentation

- **Full Checklist**: `PRODUCTION_READINESS_CHECKLIST.md`
- **Detailed Summary**: `PRODUCTION_RELEASE_SUMMARY.md`
- **Architecture**: `ARCHITECTURE.md`
- **Security Audit**: `SECURITY_AUDIT_FINAL.md`

---

## 🆘 Need Help?

1. Check `PRODUCTION_READINESS_CHECKLIST.md` for detailed steps
2. Review `PRODUCTION_RELEASE_SUMMARY.md` for changes made
3. Check existing documentation in project root
4. Review Flutter documentation: https://docs.flutter.dev/deployment

---

**Estimated Time to Production**: 2-3 weeks
**Status**: Ready for native implementation and testing
