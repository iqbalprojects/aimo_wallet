/// PIN Validator
/// 
/// Responsibility: Validate PIN format and strength.
/// - Ensure PIN is 4-8 digits
/// - Reject non-numeric PINs
/// - Provide constant-time comparison for authentication
/// 
/// Security: Constant-time comparison prevents timing attacks
abstract class PinValidator {
  /// Validate PIN format (4-8 digits, numeric only)
  bool isValidFormat(String pin);

  /// Constant-time comparison of two strings
  /// Prevents timing attacks on PIN validation
  bool constantTimeCompare(String a, String b);
}
