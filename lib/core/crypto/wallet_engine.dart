import 'dart:typed_data';
import 'bip39_service.dart';
import 'bip32_service.dart';
import 'key_derivation_service.dart';
import 'bip39_service_impl.dart';
import 'bip32_service_impl.dart';
import 'key_derivation_service_impl.dart';

/// Wallet Creation Result
class WalletCreationResult {
  final String mnemonic;
  final String address;

  WalletCreationResult({
    required this.mnemonic,
    required this.address,
  });
}

/// Wallet Import Result
class WalletImportResult {
  final String address;
  final bool isValid;
  final String? error;

  WalletImportResult({
    required this.address,
    required this.isValid,
    this.error,
  });
}

/// Account Derivation Result
class AccountDerivationResult {
  final String address;
  final int index;

  AccountDerivationResult({
    required this.address,
    required this.index,
  });
}

/// Wallet Engine - Core HD Wallet Implementation
/// 
/// Provides high-level wallet operations using BIP39/BIP32/BIP44 standards.
/// 
/// Features:
/// - Generate 24-word mnemonic (BIP39)
/// - Import existing mnemonic
/// - Derive Ethereum addresses (BIP44 path: m/44'/60'/0'/0/index)
/// - Support multiple accounts from single mnemonic
/// 
/// Security Principles:
/// - Private keys NEVER stored
/// - Private keys derived at runtime only
/// - Mnemonic must be encrypted before storage (handled by caller)
/// - All sensitive data cleared from memory after use
/// 
/// Usage:
/// ```dart
/// final engine = WalletEngine();
/// 
/// // Create new wallet
/// final result = engine.createWallet();
/// print('Mnemonic: ${result.mnemonic}');
/// print('Address: ${result.address}');
/// 
/// // Import existing wallet
/// final importResult = engine.importWallet(mnemonic);
/// if (importResult.isValid) {
///   print('Address: ${importResult.address}');
/// }
/// 
/// // Derive additional accounts
/// final account1 = engine.deriveAccount(mnemonic, 1);
/// print('Account 1: ${account1.address}');
/// ```
class WalletEngine {
  final Bip39Service _bip39Service;
  final Bip32Service _bip32Service;
  final KeyDerivationService _keyDerivationService;

  WalletEngine({
    Bip39Service? bip39Service,
    Bip32Service? bip32Service,
    KeyDerivationService? keyDerivationService,
  })  : _bip39Service = bip39Service ?? Bip39ServiceImpl(),
        _bip32Service = bip32Service ?? Bip32ServiceImpl(),
        _keyDerivationService = keyDerivationService ??
            KeyDerivationServiceImpl(
              bip39Service ?? Bip39ServiceImpl(),
              bip32Service ?? Bip32ServiceImpl(),
            );

  /// Create new wallet with 24-word mnemonic
  /// 
  /// Cryptographic Flow:
  /// 1. Generate 256 bits of secure random entropy
  /// 2. Convert to 24-word mnemonic (BIP39)
  /// 3. Derive seed from mnemonic (PBKDF2-HMAC-SHA512)
  /// 4. Derive master key (BIP32)
  /// 5. Derive account 0 key (BIP44 path: m/44'/60'/0'/0/0)
  /// 6. Derive Ethereum address (Keccak-256)
  /// 
  /// Returns: WalletCreationResult with mnemonic and address
  /// 
  /// Security: 
  /// - Mnemonic must be encrypted before storage
  /// - Mnemonic NOT stored in this class
  /// - Caller must clear mnemonic after use
  WalletCreationResult createWallet() {
    // Generate 24-word mnemonic (256-bit entropy)
    final mnemonic = _bip39Service.generateMnemonic();

    // Derive address for account 0
    final keys = _keyDerivationService.deriveWalletKeys(mnemonic);

    return WalletCreationResult(
      mnemonic: mnemonic,
      address: keys.address,
    );
  }

  /// Import existing wallet from mnemonic
  /// 
  /// Validates mnemonic and derives address.
  /// 
  /// Validation:
  /// - Word count (must be 24 words)
  /// - Word list membership (all words in BIP39 list)
  /// - Checksum (BIP39 checksum validation)
  /// 
  /// Returns: WalletImportResult with validation status and address
  /// 
  /// Security:
  /// - Mnemonic NOT stored in this class
  /// - Caller must clear mnemonic after use
  WalletImportResult importWallet(String mnemonic) {
    // Normalize mnemonic (lowercase, trim, collapse spaces)
    final normalizedMnemonic = _bip39Service.normalizeMnemonic(mnemonic);

    // Validate mnemonic
    if (!_bip39Service.validateMnemonic(normalizedMnemonic)) {
      return WalletImportResult(
        address: '',
        isValid: false,
        error: 'Invalid mnemonic: checksum validation failed',
      );
    }

    // Derive address
    try {
      final keys = _keyDerivationService.deriveWalletKeys(normalizedMnemonic);

      return WalletImportResult(
        address: keys.address,
        isValid: true,
      );
    } catch (e) {
      return WalletImportResult(
        address: '',
        isValid: false,
        error: 'Failed to derive address: $e',
      );
    }
  }

  /// Derive account at specific index
  /// 
  /// Allows multiple accounts from single mnemonic.
  /// Derivation path: m/44'/60'/0'/0/{index}
  /// 
  /// Parameters:
  /// - mnemonic: The wallet mnemonic
  /// - index: Account index (0, 1, 2, ...)
  /// 
  /// Returns: AccountDerivationResult with address and index
  /// 
  /// Security: 
  /// - Private key derived at runtime, not stored
  /// - Mnemonic NOT stored in this class
  AccountDerivationResult deriveAccount(String mnemonic, int index) {
    if (index < 0) {
      throw ArgumentError('Account index must be non-negative');
    }

    // Derive keys for specific account index
    final seed = _bip39Service.mnemonicToSeed(mnemonic);
    final privateKey = _bip32Service.derivePrivateKey(
      seed,
      "m/44'/60'/0'/0/$index",
    );

    final publicKey = _keyDerivationService.derivePublicKey(privateKey);
    final address = _keyDerivationService.deriveAddress(publicKey);

    return AccountDerivationResult(
      address: address,
      index: index,
    );
  }

  /// Derive private key for specific account index
  /// 
  /// WARNING: Private key is sensitive data.
  /// - Use only for signing transactions
  /// - Clear from memory immediately after use
  /// - Never store or log private key
  /// 
  /// Parameters:
  /// - mnemonic: The wallet mnemonic
  /// - index: Account index (default: 0)
  /// 
  /// Returns: Private key as Uint8List (32 bytes)
  Uint8List derivePrivateKeyForAccount(String mnemonic, {int index = 0}) {
    if (index < 0) {
      throw ArgumentError('Account index must be non-negative');
    }

    final seed = _bip39Service.mnemonicToSeed(mnemonic);
    return _bip32Service.derivePrivateKey(
      seed,
      "m/44'/60'/0'/0/$index",
    );
  }

  /// Validate mnemonic without importing
  /// 
  /// Useful for validation before storage.
  bool validateMnemonic(String mnemonic) {
    final normalized = _bip39Service.normalizeMnemonic(mnemonic);
    return _bip39Service.validateMnemonic(normalized);
  }
}
