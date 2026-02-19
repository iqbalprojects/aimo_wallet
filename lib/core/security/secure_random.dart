import 'dart:typed_data';

/// Secure Random Generator
/// 
/// Responsibility: Generate cryptographically secure random data.
/// - Use platform-specific secure random (dart:math Random.secure())
/// - Generate random bytes for salts, IVs, entropy
/// 
/// Security: Uses cryptographically secure random number generator
abstract class SecureRandom {
  /// Generate secure random bytes
  Uint8List nextBytes(int length);

  /// Generate random integer in range [0, max)
  int nextInt(int max);
}
