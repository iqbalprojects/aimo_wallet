# Aimo Wallet ProGuard Rules
# 
# These rules ensure proper obfuscation while keeping necessary classes.

# Keep crypto classes (BouncyCastle, etc.)
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

-keep class com.google.crypto.** { *; }
-dontwarn com.google.crypto.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Keep wallet classes (adjust package name if different)
-keep class com.aimo.wallet.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Keep generic signatures for reflection
-keepattributes Signature

# Keep exceptions
-keepattributes Exceptions

# Web3j / Ethereum libraries
-keep class org.web3j.** { *; }
-dontwarn org.web3j.**

# BIP39 / HD Wallet libraries
-keep class org.bitcoinj.** { *; }
-dontwarn org.bitcoinj.**

# Secure storage
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
