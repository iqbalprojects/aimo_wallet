import '../entities/wallet_credentials.dart';
import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';
import '../../../../core/crypto/bip39_service.dart';
import '../../../../core/crypto/key_derivation_service.dart';

/// Import Wallet Use Case
///
/// Responsibility: Orchestrate wallet import flow.
/// - Check if wallet already exists (enforce single wallet constraint)
/// - Validate imported mnemonic
/// - Normalize mnemonic
/// - Derive wallet address
/// - Return normalized mnemonic and address for confirmation
///
/// Security: Validates mnemonic before storage, enforces single wallet constraint
class ImportWalletUseCase {
  final WalletRepository repository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;

  ImportWalletUseCase({
    required this.repository,
    required this.bip39Service,
    required this.keyDerivationService,
  });

  /// Import wallet from mnemonic
  /// Returns wallet credentials (normalized mnemonic and address) for user confirmation
  ///
  /// Requirements: 2.1, 2.2, 2.3, 2.4, 7.3
  ///
  /// Parameters:
  /// - mnemonic: 24-word mnemonic phrase to import
  ///
  /// Returns: WalletCredentials with normalized mnemonic and derived address
  ///
  /// Throws:
  /// - WalletError.walletAlreadyExists: If wallet already exists on device
  /// - WalletError.invalidMnemonicLength: If mnemonic is not 24 words
  /// - WalletError.invalidMnemonicWords: If mnemonic contains invalid words
  /// - WalletError.invalidMnemonicChecksum: If mnemonic checksum is invalid
  Future<WalletCredentials> call(String mnemonic) async {
    // Check if wallet already exists (enforce single wallet constraint)
    final hasWallet = await repository.hasWallet();
    if (hasWallet) {
      throw WalletError(
        WalletErrorType.walletAlreadyExists,
        'A wallet already exists on this device. Delete the existing wallet before importing a new one.',
      );
    }

    // Normalize mnemonic (lowercase, single spaces)
    final normalizedMnemonic = bip39Service.normalizeMnemonic(mnemonic);

    // Validate mnemonic (word count, word list, checksum)
    final words = normalizedMnemonic.split(' ');

    // Check word count (must be 12, 15, 18, 21, or 24 words)
    if (![12, 15, 18, 21, 24].contains(words.length)) {
      throw WalletError(
        WalletErrorType.invalidMnemonicLength,
        'Mnemonic must be 12, 15, 18, 21, or 24 words, got ${words.length}',
      );
    }

    // Validate mnemonic against BIP39 rules
    if (!bip39Service.validateMnemonic(normalizedMnemonic)) {
      // Determine specific error
      // Note: validateMnemonic checks word list and checksum
      // We already checked length above
      throw WalletError(
        WalletErrorType.invalidMnemonicChecksum,
        'Invalid mnemonic: checksum verification failed',
      );
    }

    // Derive wallet address from normalized mnemonic
    final walletKeys = keyDerivationService.deriveWalletKeys(
      normalizedMnemonic,
    );

    // Return normalized mnemonic and address for confirmation
    // Encryption happens after user confirms (via SaveWalletUseCase)
    return WalletCredentials(
      mnemonic: normalizedMnemonic,
      address: walletKeys.address,
    );
  }
}
