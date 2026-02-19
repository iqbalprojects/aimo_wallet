# Persiapan Production - Aimo Wallet

Checklist lengkap untuk mempersiapkan aplikasi blockchain wallet ini ke production.

---

## ✅ SUDAH SELESAI

### 1. Keamanan Kode

- ✅ Debug prints sudah dihapus
- ✅ Tidak ada logging data sensitif (mnemonic, private key, PIN)
- ✅ API keys dipindahkan ke environment variables
- ✅ Obfuscation configuration (ProGuard) sudah dibuat
- ✅ Screenshot protection framework sudah ada
- ✅ Root/jailbreak detection framework sudah ada
- ✅ Centralized configuration (AppConfig) sudah dibuat

### 2. Arsitektur & Kode

- ✅ Clean Architecture sudah diimplementasi
- ✅ Dependency Injection sudah lengkap
- ✅ Error handling sudah proper
- ✅ Semua compilation errors sudah diperbaiki
- ✅ Test suite sudah ada (unit tests, integration tests)

### 3. Keamanan Wallet

- ✅ Mnemonic encryption dengan AES-256-GCM
- ✅ Secure storage menggunakan platform keychain
- ✅ PIN-based authentication
- ✅ Auto-lock functionality
- ✅ Private key tidak pernah disimpan
- ✅ Mnemonic hanya ada di memory saat dibutuhkan

---

## 🔧 PERLU DILENGKAPI

### 1. KONFIGURASI ENVIRONMENT

#### A. Setup Environment Variables

```bash
# Buat file .env dari template
cp .env.example .env

# Edit .env dan isi dengan nilai production:
# - RPC URLs untuk mainnet
# - API keys untuk blockchain explorers
# - Analytics keys (jika ada)
```

**File yang perlu dikonfigurasi:**

- `.env` - Environment variables production
- `lib/core/config/app_config.dart` - Pastikan mode production

#### B. Network Configuration

**File:** `lib/features/network_switch/presentation/controllers/network_controller.dart`

Pastikan RPC URLs menggunakan environment variables:

```dart
// Jangan hardcode RPC URLs
final rpcUrl = AppConfig.ethereumRpcUrl; // Dari .env
```

---

### 2. IMPLEMENTASI NATIVE CODE

#### A. Screenshot Protection (Android)

**File:** `android/app/src/main/kotlin/com/example/aimo_wallet/MainActivity.kt`

```kotlin
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "aimo_wallet/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
}
```

#### B. Screenshot Protection (iOS)

**File:** `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var blurView: UIVisualEffectView?

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
                self?.addBlurEffect()
                result(nil)
            case "disableScreenshotProtection":
                self?.removeBlurEffect()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func addBlurEffect() {
        guard blurView == nil else { return }
        let blurEffect = UIBlurEffect(style: .light)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView?.frame = window?.bounds ?? .zero
        window?.addSubview(blurView!)
    }

    private func removeBlurEffect() {
        blurView?.removeFromSuperview()
        blurView = nil
    }
}
```

#### C. Root Detection (Android)

**File:** `android/app/src/main/kotlin/com/example/aimo_wallet/RootDetection.kt`

```kotlin
import android.os.Build
import java.io.File

object RootDetection {
    fun isDeviceRooted(): Boolean {
        return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
    }

    private fun checkRootMethod1(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkRootMethod2(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        return paths.any { File(it).exists() }
    }

    private fun checkRootMethod3(): Boolean {
        var process: Process? = null
        return try {
            process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val input = java.io.BufferedReader(
                java.io.InputStreamReader(process.inputStream)
            )
            input.readLine() != null
        } catch (t: Throwable) {
            false
        } finally {
            process?.destroy()
        }
    }
}
```

Tambahkan ke MainActivity:

```kotlin
"checkRootStatus" -> {
    result.success(RootDetection.isDeviceRooted())
}
```

#### D. Root Detection (iOS)

**File:** `ios/Runner/JailbreakDetection.swift`

```swift
import Foundation

class JailbreakDetection {
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkJailbreakFiles() || checkJailbreakPaths() || canEditSystemFiles()
        #endif
    }

    private static func checkJailbreakFiles() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private static func checkJailbreakPaths() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!)
    }

    private static func canEditSystemFiles() -> Bool {
        let path = "/private/jailbreak.txt"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
}
```

---

### 3. BUILD CONFIGURATION

#### A. Android Build Configuration

**File:** `android/app/build.gradle`

```gradle
android {
    // ... existing config

    buildTypes {
        release {
            // Enable obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            // Signing config
            signingConfig signingConfigs.release
        }
    }

    // Signing configuration
    signingConfigs {
        release {
            storeFile file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "keystore.jks")
            storePassword System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias System.getenv("ANDROID_KEY_ALIAS")
            keyPassword System.getenv("ANDROID_KEY_PASSWORD")
        }
    }
}
```

#### B. Generate Android Keystore

```bash
keytool -genkey -v -keystore ~/aimo-wallet-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias aimo-wallet

# Simpan password dengan aman!
# Jangan commit keystore ke git!
```

#### C. iOS Build Configuration

**File:** `ios/Runner.xcodeproj/project.pbxproj`

Pastikan:

- Bundle Identifier unik (com.yourcompany.aimowallet)
- Version dan Build number sudah benar
- Signing & Capabilities sudah dikonfigurasi
- App Groups (jika perlu untuk extensions)

---

### 4. TESTING PRODUCTION BUILD

#### A. Test di Device Fisik

```bash
# Android
flutter build apk --release
flutter install --release

# iOS
flutter build ios --release
# Kemudian test via Xcode
```

#### B. Test Checklist

- [ ] Wallet creation berfungsi
- [ ] Wallet import berfungsi
- [ ] Wallet unlock berfungsi
- [ ] Transaction signing berfungsi
- [ ] Network switching berfungsi
- [ ] Screenshot protection aktif di screen sensitif
- [ ] Auto-lock berfungsi
- [ ] Background lock berfungsi
- [ ] Tidak ada crash saat rotate screen
- [ ] Tidak ada memory leak
- [ ] Performance baik (smooth animations)

---

### 5. SECURITY AUDIT

#### A. Penetration Testing

- [ ] Test root/jailbreak detection
- [ ] Test screenshot protection
- [ ] Test secure storage (coba extract dari backup)
- [ ] Test PIN brute force protection
- [ ] Test memory dump (pastikan tidak ada mnemonic)
- [ ] Test network traffic (pastikan HTTPS)

#### B. Code Review

- [ ] Review semua TODO comments
- [ ] Review semua UnimplementedError
- [ ] Review error handling
- [ ] Review logging (pastikan tidak ada sensitive data)
- [ ] Review dependencies (check for vulnerabilities)

---

### 6. LEGAL & COMPLIANCE

#### A. Privacy Policy

Buat privacy policy yang mencakup:

- Data apa yang dikumpulkan
- Bagaimana data disimpan
- Tidak ada data yang dikirim ke server
- User memiliki kontrol penuh atas wallet

#### B. Terms of Service

Buat ToS yang mencakup:

- Disclaimer tentang risiko cryptocurrency
- User bertanggung jawab atas keamanan mnemonic
- Tidak ada recovery jika mnemonic hilang

#### C. Licenses

- [ ] Check semua dependencies licenses
- [ ] Pastikan compatible dengan app license
- [ ] Tambahkan attribution jika diperlukan

---

### 7. APP STORE PREPARATION

#### A. Google Play Store

**Persiapan:**

1. Developer account ($25 one-time)
2. App icon (512x512 PNG)
3. Feature graphic (1024x500)
4. Screenshots (minimal 2, max 8)
5. Short description (80 chars)
6. Full description (4000 chars)
7. Privacy policy URL
8. Content rating questionnaire

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <!-- Permissions yang diperlukan -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Permissions yang TIDAK diperlukan (hapus jika ada) -->
    <!-- <uses-permission android:name="android.permission.CAMERA"/> -->
    <!-- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/> -->
</manifest>
```

#### B. Apple App Store

**Persiapan:**

1. Apple Developer account ($99/year)
2. App icon (1024x1024 PNG)
3. Screenshots untuk semua device sizes
4. App preview video (optional)
5. Description
6. Keywords
7. Privacy policy URL
8. Export compliance information

**Catatan Penting:**

- Cryptocurrency apps memerlukan approval khusus
- Harus comply dengan financial regulations
- Mungkin perlu license di beberapa jurisdiksi

---

### 8. MONITORING & ANALYTICS

#### A. Crash Reporting

Tambahkan Firebase Crashlytics atau Sentry:

```yaml
# pubspec.yaml
dependencies:
    firebase_crashlytics: ^3.4.0
    # atau
    sentry_flutter: ^7.0.0
```

**PENTING:** Jangan log sensitive data ke crash reports!

#### B. Analytics (Optional)

Jika ingin analytics, pastikan:

- User privacy terjaga
- Tidak track sensitive actions
- Comply dengan GDPR/privacy laws

---

### 9. BACKUP & RECOVERY

#### A. User Education

Buat tutorial/guide untuk:

- [ ] Cara backup mnemonic dengan aman
- [ ] Cara restore wallet
- [ ] Apa yang terjadi jika mnemonic hilang
- [ ] Best practices keamanan

#### B. In-App Warnings

Tambahkan warnings di:

- Backup mnemonic screen
- Delete wallet confirmation
- Export mnemonic screen

---

### 10. PERFORMANCE OPTIMIZATION

#### A. Build Optimization

```bash
# Build dengan optimization
flutter build apk --release --split-per-abi
flutter build ios --release
```

#### B. Code Optimization

- [ ] Remove unused dependencies
- [ ] Optimize images (compress)
- [ ] Lazy load heavy widgets
- [ ] Cache network responses
- [ ] Optimize database queries

---

### 11. DOCUMENTATION

#### A. User Documentation

- [ ] Getting started guide
- [ ] FAQ
- [ ] Troubleshooting guide
- [ ] Security best practices

#### B. Developer Documentation

- [ ] API documentation
- [ ] Architecture documentation (sudah ada)
- [ ] Deployment guide
- [ ] Maintenance guide

---

## 📋 FINAL CHECKLIST SEBELUM RELEASE

### Pre-Release

- [ ] Semua tests passing
- [ ] No compilation warnings
- [ ] No TODO/FIXME yang critical
- [ ] Environment variables configured
- [ ] Native code implemented
- [ ] Keystore/certificates ready
- [ ] Privacy policy published
- [ ] Terms of service published

### Build

- [ ] Build release APK/IPA
- [ ] Test di multiple devices
- [ ] Test di different OS versions
- [ ] Performance testing
- [ ] Security testing
- [ ] Beta testing dengan users

### Store Submission

- [ ] App store assets ready
- [ ] Descriptions written
- [ ] Screenshots captured
- [ ] Privacy policy linked
- [ ] Content rating completed
- [ ] Pricing configured

### Post-Release

- [ ] Monitor crash reports
- [ ] Monitor user reviews
- [ ] Prepare hotfix process
- [ ] Plan for updates
- [ ] Customer support ready

---

## 🚀 QUICK START COMMANDS

```bash
# 1. Setup environment
cp .env.example .env
# Edit .env dengan production values

# 2. Run tests
flutter test

# 3. Build release
./build_release.sh

# 4. Test release build
flutter install --release

# 5. Generate app bundle (untuk Play Store)
flutter build appbundle --release

# 6. Generate IPA (untuk App Store)
flutter build ipa --release
```

---

## 📞 SUPPORT & MAINTENANCE

### Monitoring

- Setup crash reporting alerts
- Monitor app store reviews
- Track user feedback

### Updates

- Plan regular security updates
- Monitor dependency vulnerabilities
- Keep Flutter SDK updated

### Incident Response

- Have rollback plan ready
- Prepare emergency hotfix process
- Document incident response procedures

---

## ⚠️ CRITICAL REMINDERS

1. **NEVER** commit:
    - `.env` file dengan production values
    - Keystore files
    - Private keys
    - API keys

2. **ALWAYS** test:
    - Di device fisik (bukan hanya emulator)
    - Dengan production environment
    - Semua critical flows

3. **BACKUP**:
    - Keystore files (simpan di tempat aman)
    - Environment configurations
    - Build configurations

---

## 📚 REFERENSI

- [PRODUCTION_READINESS_CHECKLIST.md](./PRODUCTION_READINESS_CHECKLIST.md)
- [PRODUCTION_RELEASE_SUMMARY.md](./PRODUCTION_RELEASE_SUMMARY.md)
- [PRODUCTION_QUICK_START.md](./PRODUCTION_QUICK_START.md)
- [SECURITY_AUDIT_FINAL.md](./SECURITY_AUDIT_FINAL.md)

---

**Status Saat Ini:** 🟡 Perlu implementasi native code dan testing production build

**Estimasi Waktu:** 2-3 hari untuk implementasi lengkap + 1 minggu testing
