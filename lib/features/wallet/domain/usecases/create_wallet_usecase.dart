import '../entities/wallet_credentials.dart';
import '../entities/wallet_error.dart';
import '../repositories/wallet_repository.dart';
import '../../../../core/crypto/bip39_service.dart';
import '../../../../core/crypto/key_derivation_service.dart';

/// Create Wallet Use Case
/// 
/// Responsibility: Orchestrate wallet creation flow.
/// - Check if wallet already exists (enforce single wallet constraint)
/// - Generate new mnemonic
/// - Derive wallet address
/// - Return mnemonic for user backup confirmation
/// - After confirmation, encrypt and store wallet
/// 
/// Security: Enforces single wallet per device constraint
class CreateWalletUseCase {
  final WalletRepository repository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;

  CreateWalletUseCase({
    required this.repository,
    required this.bip39Service,
    required this.keyDerivationService,
  });

  /// Generate new wallet
  /// Returns wallet credentials (mnemonic and address) for user to backup before encryption
  /// 
  /// Requirements: 1.1, 7.2, 11.1
  /// 
  /// Throws:
  /// - WalletError.walletAlreadyExists: If wallet already exists on device
  Future<WalletCredentials> call() async {
    // Check if wallet already exists (enforce single wallet constraint)
    final hasWallet = await repository.hasWallet();
    if (hasWallet) {
      throw WalletError(
        WalletErrorType.walletAlreadyExists,
        'A wallet already exists on this device. Delete the existing wallet before creating a new one.',
      );
    }

    // Generate new mnemonic using BIP39 service
    final mnemonic = bip39Service.generateMnemonic();

    // Derive wallet address from mnemonic
    final walletKeys = keyDerivationService.deriveWalletKeys(mnemonic);

    // Return mnemonic and address for user confirmation
    // Encryption happens after user confirms backup (via SaveWalletUseCase)
    return WalletCredentials(
      mnemonic: mnemonic,
      address: walletKeys.address,
    );
  }
}
