/// Token amount parsing and formatting utilities.
///
/// These utilities handle conversion between human-readable token amounts
/// and on-chain amounts (in smallest units / wei).
///
/// # Precision Handling
///
/// ERC20 tokens store amounts as integers in the smallest unit (like wei for ETH).
/// For example, 1.5 USDT with 6 decimals is stored as 1500000.
///
/// To avoid floating point precision errors, all calculations use BigInt:
/// - Never use `double` for token amounts
/// - Parse decimal strings character by character
/// - Multiply by powers of 10 using BigInt multiplication
///
/// Example:
/// - Input: "1.5", decimals: 6
/// - Calculation: 1 * 10^6 + 5 * 10^5 = 1000000 + 500000 = 1500000
/// - Result: BigInt.from(1500000)
///
/// # Security
///
/// - Input validation prevents overflow and injection
/// - Descriptive exceptions aid debugging
/// - No external dependencies or network calls

/// Exception thrown for invalid token amount input.
class TokenAmountException implements Exception {
  final String message;

  TokenAmountException(this.message);

  @override
  String toString() => 'TokenAmountException: $message';
}

/// Parses a human-readable token amount string to BigInt.
///
/// Converts decimal notation to the smallest unit representation.
/// Uses BigInt arithmetic exclusively to avoid floating point errors.
///
/// Example:
/// ```dart
/// // 1.5 USDT with 6 decimals
/// final amount = parseTokenAmount('1.5', 6);
/// print(amount); // BigInt.from(1500000)
///
/// // 0.000000000000000001 ETH (18 decimals)
/// final wei = parseTokenAmount('0.000000000000000001', 18);
/// print(wei); // BigInt.from(1)
/// ```
///
/// Parameters:
/// - input: Human-readable amount string (e.g., "1.5", "100", "0.001")
/// - decimals: Token decimals (e.g., 18 for ETH, 6 for USDT)
///
/// Returns: Amount in smallest units as BigInt
///
/// Throws: TokenAmountException if:
/// - Input is empty or null-like
/// - Input contains invalid characters
/// - Decimal places exceed token decimals
/// - Decimals parameter is negative
BigInt parseTokenAmount(String input, int decimals) {
  // Validate decimals parameter
  if (decimals < 0) {
    throw TokenAmountException('Decimals cannot be negative: $decimals');
  }

  // Normalize input
  final trimmed = input.trim();

  if (trimmed.isEmpty) {
    throw TokenAmountException('Input cannot be empty');
  }

  // Validate characters
  final validPattern = RegExp(r'^[0-9]+\.?[0-9]*$|^\.[0-9]+$');
  if (!validPattern.hasMatch(trimmed)) {
    throw TokenAmountException(
      'Invalid input format: "$input". Expected decimal number like "1.5" or "100"',
    );
  }

  // Split into integer and decimal parts
  final parts = trimmed.split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '';

  // Validate decimal places don't exceed token decimals
  if (decimalPart.length > decimals) {
    throw TokenAmountException(
      'Input has ${decimalPart.length} decimal places but token only has $decimals decimals',
    );
  }

  // Calculate using BigInt to avoid floating point errors
  // Formula: integerPart * 10^decimals + decimalPart * 10^(decimals - decimalPlaces)

  // 10^decimals as BigInt
  final multiplier = BigInt.from(10).pow(decimals);

  // Parse integer part (empty string becomes 0)
  final integerAmount = integerPart.isEmpty
      ? BigInt.zero
      : BigInt.parse(integerPart);

  // Calculate integer contribution: integerPart * 10^decimals
  final integerContribution = integerAmount * multiplier;

  // Parse decimal part (empty string becomes 0)
  final decimalAmount = decimalPart.isEmpty
      ? BigInt.zero
      : BigInt.parse(decimalPart);

  // Calculate decimal contribution: decimalPart * 10^(decimals - decimalPlaces)
  // This pads the decimal part to the right position
  final decimalPadding = decimals - decimalPart.length;
  final decimalMultiplier = BigInt.from(10).pow(decimalPadding);
  final decimalContribution = decimalAmount * decimalMultiplier;

  // Total amount
  return integerContribution + decimalContribution;
}

/// Formats a BigInt token amount to human-readable string.
///
/// Converts smallest unit representation to decimal notation.
/// Handles edge cases like very small amounts and removes trailing zeros.
///
/// Example:
/// ```dart
/// // 1500000 units with 6 decimals
/// final formatted = formatTokenAmount(BigInt.from(1500000), 6);
/// print(formatted); // "1.5"
///
/// // 1 wei (smallest ETH unit)
/// final tiny = formatTokenAmount(BigInt.from(1), 18);
/// print(tiny); // "0.000000000000000001"
///
/// // Zero amount
/// final zero = formatTokenAmount(BigInt.from(0), 18);
/// print(zero); // "0"
/// ```
///
/// Parameters:
/// - amount: Token amount in smallest units
/// - decimals: Token decimals (e.g., 18 for ETH, 6 for USDT)
///
/// Returns: Human-readable decimal string
///
/// Throws: TokenAmountException if decimals is negative
String formatTokenAmount(BigInt amount, int decimals) {
  // Validate decimals parameter
  if (decimals < 0) {
    throw TokenAmountException('Decimals cannot be negative: $decimals');
  }

  // Handle zero case
  if (amount == BigInt.zero) {
    return '0';
  }

  // Handle negative amounts (for completeness)
  final isNegative = amount < BigInt.zero;
  final absAmount = amount.abs();

  // Get the multiplier (10^decimals)
  final multiplier = BigInt.from(10).pow(decimals);

  // Split into integer and decimal parts
  final integerPart = absAmount ~/ multiplier;
  final decimalPart = absAmount % multiplier;

  // Build result string
  final buffer = StringBuffer();

  if (isNegative) {
    buffer.write('-');
  }

  // Write integer part
  buffer.write(integerPart.toString());

  // Write decimal part if non-zero
  if (decimalPart > BigInt.zero) {
    buffer.write('.');

    // Convert decimal part to string and pad with leading zeros
    var decimalStr = decimalPart.toString();

    // Pad with leading zeros to reach decimals length
    // e.g., if decimals=6 and decimalPart=500, we need "000500"
    final neededLength = decimals;
    if (decimalStr.length < neededLength) {
      decimalStr = decimalStr.padLeft(neededLength, '0');
    }

    // Remove trailing zeros for cleaner output
    // e.g., "000500" -> "0005" (but keep at least one digit after decimal)
    decimalStr = decimalStr.replaceAll(RegExp(r'0+$'), '');

    // Handle case where all digits were zeros (shouldn't happen with > BigInt.zero check)
    if (decimalStr.isEmpty) {
      decimalStr = '0';
    }

    buffer.write(decimalStr);
  }

  return buffer.toString();
}
