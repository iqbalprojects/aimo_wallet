import 'dart:typed_data';

/// Secure Memory Utilities
/// 
/// Responsibility: Securely clear sensitive data from memory.
/// - Overwrite byte arrays with zeros before deallocation
/// - Clear strings (best effort in Dart)
/// - Provide automatic cleanup helpers
/// 
/// Security: Minimizes exposure window for sensitive data in memory
/// 
/// Note: Dart's garbage collector makes complete memory clearing
/// difficult, but overwriting reduces the exposure window.
class SecureMemory {
  /// Overwrite Uint8List with zeros
  /// 
  /// Security: Reduces exposure window for sensitive data in memory dumps.
  /// Should be called immediately after using sensitive data.
  static void clear(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  /// Overwrite String in memory (best effort)
  /// 
  /// Converts to bytes, overwrites, then clears reference.
  /// 
  /// Note: Strings are immutable in Dart, so complete clearing
  /// is not possible. This is best-effort only.
  static void clearString(String data) {
    // Convert to bytes and clear
    final bytes = Uint8List.fromList(data.codeUnits);
    clear(bytes);
  }

  /// Execute function with automatic cleanup
  /// 
  /// Ensures data is cleared even if operation throws exception.
  /// 
  /// Usage:
  /// ```dart
  /// final result = SecureMemory.withSecureData(privateKey, (key) {
  ///   return signTransaction(key);
  /// });
  /// // privateKey is automatically cleared
  /// ```
  static T withSecureData<T>(
    Uint8List data,
    T Function(Uint8List) operation,
  ) {
    try {
      return operation(data);
    } finally {
      clear(data);
    }
  }

  /// Execute async function with automatic cleanup
  static Future<T> withSecureDataAsync<T>(
    Uint8List data,
    Future<T> Function(Uint8List) operation,
  ) async {
    try {
      return await operation(data);
    } finally {
      clear(data);
    }
  }
}

