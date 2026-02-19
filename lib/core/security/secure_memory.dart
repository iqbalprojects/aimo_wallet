import 'dart:typed_data';

/// Secure Memory Utilities
/// 
/// Responsibility: Securely clear sensitive data from memory.
/// - Clear Uint8List data by overwriting with zeros
/// - Clear String data (best effort in Dart)
/// - Provide automatic cleanup helper
/// 
/// Security: Minimizes exposure window for sensitive data in memory
/// Note: Dart's garbage collector makes complete memory clearing difficult,
/// but overwriting reduces the exposure window significantly.
class SecureMemory {
  /// Overwrite Uint8List with zeros
  /// 
  /// Clears sensitive data from memory by overwriting all bytes with zeros.
  /// This reduces the window of exposure for sensitive data.
  static void clear(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  /// Overwrite String in memory (best effort)
  /// 
  /// Attempts to clear string data from memory. Due to Dart's string
  /// immutability and garbage collection, this is best-effort only.
  /// Converts string to bytes, overwrites them, then clears reference.
  static void clearString(String data) {
    // Convert string to bytes
    final bytes = Uint8List.fromList(data.codeUnits);
    // Overwrite bytes
    clear(bytes);
    // Note: The original string object cannot be directly overwritten
    // due to Dart's immutability, but we clear the byte representation
  }

  /// Execute function with automatic cleanup
  /// 
  /// Executes the provided operation with the sensitive data, then
  /// automatically clears the data from memory using try-finally to
  /// ensure cleanup even if an exception occurs.
  /// 
  /// Example:
  /// ```dart
  /// final result = SecureMemory.withSecureData(
  ///   sensitiveBytes,
  ///   (data) => processData(data),
  /// );
  /// // sensitiveBytes is automatically cleared after use
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
}
