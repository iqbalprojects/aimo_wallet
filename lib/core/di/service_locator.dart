import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core services
import '../crypto/bip39_service.dart';
import '../crypto/bip39_service_impl.dart';
import '../crypto/bip32_service.dart';
import '../crypto/bip32_service_impl.dart';
import '../crypto/key_derivation_service.dart';
import '../crypto/key_derivation_service_impl.dart';
import '../crypto/wallet_engine.dart';
import '../vault/encryption_service.dart';
import '../vault/secure_vault.dart';
import '../network/rpc_client.dart';
import '../network/rpc_client_impl.dart';

// Data layer
import '../../features/wallet/data/datasources/secure_storage_datasource.dart';
import '../../features/wallet/data/datasources/secure_storage_datasource_impl.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/network_switch/data/network_storage_service.dart';

// Domain layer - Wallet
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/create_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/save_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/import_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/unlock_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/get_wallet_address_usecase.dart';
import '../../features/wallet/domain/usecases/delete_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/export_mnemonic_usecase.dart';
import '../../features/wallet/domain/usecases/verify_backup_usecase.dart';
import '../../features/wallet/domain/usecases/create_new_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/get_current_address_usecase.dart';
import '../../features/wallet/domain/usecases/get_balance_usecase.dart';

// Domain layer - Transaction
import '../../features/transaction/domain/usecases/sign_transaction_usecase.dart';
import '../../features/transaction/domain/usecases/get_nonce_usecase.dart';
import '../../features/transaction/domain/usecases/estimate_gas_usecase.dart';
import '../../features/transaction/domain/usecases/broadcast_transaction_usecase.dart';
import '../../features/transaction/domain/services/transaction_signer.dart';

// Presentation layer - Wallet
import '../../features/wallet/presentation/controllers/wallet_controller.dart';
import '../../features/wallet/presentation/controllers/wallet_creation_controller.dart';
import '../../features/wallet/presentation/controllers/wallet_import_controller.dart';
import '../../features/wallet/presentation/controllers/wallet_unlock_controller.dart';
import '../../features/wallet/presentation/controllers/wallet_settings_controller.dart';
import '../../features/wallet/presentation/controllers/auth_controller.dart';

// Presentation layer - Transaction
import '../../features/transaction/presentation/controllers/transaction_controller.dart';

// Presentation layer - Network
import '../../features/network_switch/presentation/controllers/network_controller.dart';

// Core services - Swap
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../blockchain/evm/swap/zero_x_api_service.dart';
import '../blockchain/evm/erc20/erc20_service.dart';
import '../blockchain/evm/gas/gas_price_oracle_service.dart';

// Domain layer - Swap
import '../../features/swap/domain/usecases/get_swap_quote_usecase.dart';
import '../../features/swap/domain/usecases/check_allowance_usecase.dart';
import '../../features/swap/domain/usecases/approve_token_usecase.dart';
import '../../features/swap/domain/usecases/execute_swap_usecase.dart';
import '../../features/swap/domain/usecases/get_token_balance_usecase.dart';
import '../../features/swap/domain/usecases/swap_preparation_usecase.dart';

/// Service Locator / Dependency Injection
///
/// Responsibility: Register and provide dependencies.
/// - Register services (singletons)
/// - Register repositories (singletons)
/// - Register use cases (factories)
/// - Register controllers
///
/// Pattern:
/// - Singletons: Services and repositories (shared state)
/// - Factories: Use cases (new instance per call, stateless)
/// - Lazy: Controllers (created when first accessed)
///
/// Requirements: 10.3, 10.4
class ServiceLocator {
  static void init() {
    // Register core services
    _registerCoreServices();

    // Register data sources
    _registerDataSources();

    // Register repositories
    _registerRepositories();

    // Register use cases (except those with controller dependencies)
    _registerUseCases();

    // Register swap services and use cases
    _registerSwapDependencies();

    // Register controllers
    _registerControllers();

    // Register use cases that depend on controllers
    _registerControllerDependentUseCases();
  }

  /// Register core cryptographic services (singletons)
  ///
  /// Services are shared across the app and maintain no state.
  /// Using lazyPut for lazy initialization (created when first accessed).
  static void _registerCoreServices() {
    // BIP39 service for mnemonic generation and validation
    Get.lazyPut<Bip39Service>(
      () => Bip39ServiceImpl(),
      fenix: true, // Keep alive even when not in use
    );

    // BIP32 service for hierarchical key derivation
    Get.lazyPut<Bip32Service>(() => Bip32ServiceImpl(), fenix: true);

    // Key derivation service for EVM wallet keys
    Get.lazyPut<KeyDerivationService>(
      () => KeyDerivationServiceImpl(
        Get.find<Bip39Service>(),
        Get.find<Bip32Service>(),
      ),
      fenix: true,
    );

    // Encryption service for AES-256-GCM encryption
    Get.lazyPut<EncryptionService>(() => EncryptionService(), fenix: true);

    // Wallet engine for HD wallet operations
    Get.lazyPut<WalletEngine>(
      () => WalletEngine(
        bip39Service: Get.find<Bip39Service>(),
        keyDerivationService: Get.find<KeyDerivationService>(),
      ),
      fenix: true,
    );

    // Secure vault for encrypted wallet storage
    Get.lazyPut<SecureVault>(
      () => SecureVault(
        storage: Get.find<FlutterSecureStorage>(),
        encryptionService: Get.find<EncryptionService>(),
      ),
      fenix: true,
    );

    // Transaction signer for EIP-155 signing
    Get.lazyPut<TransactionSigner>(() => TransactionSigner(), fenix: true);

    // Network storage service
    Get.lazyPut<NetworkStorageService>(
      () => NetworkStorageService(),
      fenix: true,
    );

    // RPC Client for blockchain communication
    // DYNAMIC: Recreated on each use to ensure correct network
    // This is CRITICAL for network switching to work properly
    Get.lazyPut<RpcClient>(
      () {
        try {
          // Get current network from NetworkController
          final networkController = Get.find<NetworkController>();
          final currentNetwork = networkController.currentNetwork;

          if (currentNetwork == null) {
            // Fallback to Mainnet for testing if no network selected
            print('WARNING: No network selected, defaulting to Mainnet');
            return RpcClientImpl(
              rpcUrl:
                  'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
            );
          }

          // Use current network's RPC URL
          print(
            'RPC Client connecting to: ${currentNetwork.name} (${currentNetwork.rpcUrl})',
          );
          return RpcClientImpl(rpcUrl: currentNetwork.rpcUrl);
        } catch (e) {
          // Ultimate fallback if NetworkController is not injectible yet
          return RpcClientImpl(
            rpcUrl:
                'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
          );
        }
      },
      fenix:
          true, // IMPORTANT: Keep factory alive so RpcClient can be recreated after deletion (network switch)
    );
  }

  /// Register data sources (singletons)
  ///
  /// Data sources handle platform-specific storage.
  /// Using lazyPut for lazy initialization.
  static void _registerDataSources() {
    // Flutter secure storage (platform-specific)
    Get.lazyPut<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
      fenix: true,
    );

    // Secure storage data source
    Get.lazyPut<SecureStorageDataSource>(
      () => SecureStorageDataSourceImpl(Get.find<FlutterSecureStorage>()),
      fenix: true,
    );
  }

  /// Register repositories (singletons)
  ///
  /// Repositories coordinate services and storage.
  /// Using lazyPut for lazy initialization.
  static void _registerRepositories() {
    // Wallet repository
    Get.lazyPut<WalletRepository>(
      () => WalletRepositoryImpl(
        storage: Get.find<SecureStorageDataSource>(),
        encryptionService: Get.find<EncryptionService>(),
        keyDerivationService: Get.find<KeyDerivationService>(),
        bip39Service: Get.find<Bip39Service>(),
      ),
      fenix: true,
    );
  }

  /// Register use cases (factories)
  ///
  /// Use cases are stateless and created new for each call.
  /// Using lazyPut with factory pattern (new instance per Get.find()).
  ///
  /// Note: GetX lazyPut creates singleton by default, but use cases
  /// are designed to be stateless, so sharing instance is acceptable.
  static void _registerUseCases() {
    // Wallet creation use case
    Get.lazyPut<CreateWalletUseCase>(
      () => CreateWalletUseCase(
        repository: Get.find<WalletRepository>(),
        bip39Service: Get.find<Bip39Service>(),
        keyDerivationService: Get.find<KeyDerivationService>(),
      ),
    );

    // Save wallet use case
    Get.lazyPut<SaveWalletUseCase>(
      () => SaveWalletUseCase(repository: Get.find<WalletRepository>()),
    );

    // Import wallet use case
    Get.lazyPut<ImportWalletUseCase>(
      () => ImportWalletUseCase(
        repository: Get.find<WalletRepository>(),
        bip39Service: Get.find<Bip39Service>(),
        keyDerivationService: Get.find<KeyDerivationService>(),
      ),
    );

    // Unlock wallet use case
    Get.lazyPut<UnlockWalletUseCase>(
      () => UnlockWalletUseCase(secureVault: Get.find<SecureVault>()),
      fenix: true,
    );

    // Get wallet address use case
    Get.lazyPut<GetWalletAddressUseCase>(
      () => GetWalletAddressUseCase(repository: Get.find<WalletRepository>()),
    );

    // Delete wallet use case
    Get.lazyPut<DeleteWalletUseCase>(
      () => DeleteWalletUseCase(repository: Get.find<WalletRepository>()),
    );

    // Export mnemonic use case
    Get.lazyPut<ExportMnemonicUseCase>(
      () => ExportMnemonicUseCase(repository: Get.find<WalletRepository>()),
    );

    // Verify backup use case
    Get.lazyPut<VerifyBackupUseCase>(
      () => VerifyBackupUseCase(repository: Get.find<WalletRepository>()),
    );

    // Create new wallet use case (refactored)
    Get.lazyPut<CreateNewWalletUseCase>(
      () => CreateNewWalletUseCase(
        walletEngine: Get.find<WalletEngine>(),
        secureVault: Get.find<SecureVault>(),
      ),
    );

    // Get current address use case (refactored)
    Get.lazyPut<GetCurrentAddressUseCase>(
      () => GetCurrentAddressUseCase(secureVault: Get.find<SecureVault>()),
    );

    // Get balance use case (blockchain)
    // fenix: true so it can be recreated with fresh RpcClient after network switch
    Get.lazyPut<GetBalanceUseCase>(
      () => GetBalanceUseCase(rpcClient: Get.find<RpcClient>()),
      fenix: true,
    );

    // Get nonce use case (blockchain)
    Get.lazyPut<GetNonceUseCase>(
      () => GetNonceUseCase(rpcClient: Get.find<RpcClient>()),
      fenix: true,
    );

    // Estimate gas use case (blockchain)
    Get.lazyPut<EstimateGasUseCase>(
      () => EstimateGasUseCase(rpcClient: Get.find<RpcClient>()),
      fenix: true,
    );

    // Broadcast transaction use case (blockchain)
    Get.lazyPut<BroadcastTransactionUseCase>(
      () => BroadcastTransactionUseCase(rpcClient: Get.find<RpcClient>()),
      fenix: true,
    );
  }

  /// Register swap services and use cases
  static void _registerSwapDependencies() {
    // 0x API service for swap quotes (v2/permit2)
    // IMPORTANT: Uses chainId from current network for multi-chain support
    // fenix: true so it can be recreated after network switch
    Get.lazyPut<ZeroXApiService>(() {
      final networkController = Get.find<NetworkController>();
      final currentNetwork = networkController.currentNetwork;
      // Default to Ethereum mainnet chainId=1 if no network selected
      final chainId = currentNetwork?.chainId ?? 1;
      return ZeroXApiService(chainId: chainId);
    }, fenix: true);

    // ERC20 service for token balance/allowance
    Get.lazyPut<Erc20Service>(() {
      final networkController = Get.find<NetworkController>();
      final currentNetwork = networkController.currentNetwork;
      final rpcUrl =
          currentNetwork?.rpcUrl ??
          'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28';
      final web3Client = Web3Client(rpcUrl, http.Client());
      return Erc20Service(web3Client);
    }, fenix: true);

    // Gas price oracle service
    Get.lazyPut<GasPriceOracleService>(() {
      final networkController = Get.find<NetworkController>();
      final currentNetwork = networkController.currentNetwork;
      final rpcUrl =
          currentNetwork?.rpcUrl ??
          'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28';
      final web3Client = Web3Client(rpcUrl, http.Client());
      return GasPriceOracleService(web3Client: web3Client);
    }, fenix: true);

    // Check allowance use case
    Get.lazyPut<CheckAllowanceUseCase>(
      () => CheckAllowanceUseCase(erc20Service: Get.find<Erc20Service>()),
      fenix: true,
    );

    // Approve token use case
    Get.lazyPut<ApproveTokenUseCase>(
      () => ApproveTokenUseCase(erc20Service: Get.find<Erc20Service>()),
      fenix: true,
    );

    // Get token balance use case
    Get.lazyPut<GetTokenBalanceUseCase>(
      () => GetTokenBalanceUseCase(
        erc20Service: Get.find<Erc20Service>(),
        rpcClient: Get.find<RpcClient>(),
      ),
      fenix: true,
    );

    // Swap preparation use case
    Get.lazyPut<SwapPreparationUseCase>(
      () => SwapPreparationUseCase(
        erc20Service: Get.find<Erc20Service>(),
        checkAllowanceUseCase: Get.find<CheckAllowanceUseCase>(),
        rpcClient: Get.find<RpcClient>(),
      ),
      fenix: true,
    );

    // Get swap quote use case
    Get.lazyPut<GetSwapQuoteUseCase>(
      () => GetSwapQuoteUseCase(zeroXApiService: Get.find<ZeroXApiService>()),
      fenix: true,
    );

    // Execute swap use case (stateless, no dependencies)
    Get.lazyPut<ExecuteSwapUseCase>(() => ExecuteSwapUseCase(), fenix: true);
  }

  /// Register use cases that depend on controllers
  ///
  /// These use cases have circular dependencies with controllers
  /// and must be registered after controllers are initialized.
  static void _registerControllerDependentUseCases() {
    // Sign transaction use case (depends on AuthController)
    Get.lazyPut<SignTransactionUseCase>(
      () => SignTransactionUseCase(
        secureVault: Get.find<SecureVault>(),
        walletEngine: Get.find<WalletEngine>(),
        transactionSigner: Get.find<TransactionSigner>(),
        authController: Get.find<AuthController>(),
      ),
    );

    // Transaction controller (uses lazy getters for dependencies)
    // This avoids circular dependency issues by not requiring all dependencies in constructor
    Get.lazyPut<TransactionController>(
      () => TransactionController(),
      fenix: true, // Keep alive for global state
    );
  }

  /// Register controllers (lazy singletons)
  ///
  /// Controllers manage UI state and are created when first accessed.
  /// Using lazyPut for lazy initialization.
  static void _registerControllers() {
    // Auth controller (global authentication state)
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true, // Keep alive for global state
    );

    // Wallet controller (global wallet state)
    Get.lazyPut<WalletController>(
      () => WalletController(
        createNewWalletUseCase: Get.find<CreateNewWalletUseCase>(),
        getCurrentAddressUseCase: Get.find<GetCurrentAddressUseCase>(),
        getBalanceUseCase: Get.find<GetBalanceUseCase>(),
      ),
      fenix: true, // Keep alive for global state
    );

    // Network controller (global network state)
    Get.lazyPut<NetworkController>(
      () =>
          NetworkController(storageService: Get.find<NetworkStorageService>()),
      fenix: true, // Keep alive for global state
    );

    // Wallet creation controller
    Get.lazyPut<WalletCreationController>(
      () => WalletCreationController(
        createWalletUseCase: Get.find<CreateWalletUseCase>(),
        saveWalletUseCase: Get.find<SaveWalletUseCase>(),
      ),
    );

    // Wallet import controller
    Get.lazyPut<WalletImportController>(
      () => WalletImportController(
        importWalletUseCase: Get.find<ImportWalletUseCase>(),
        saveWalletUseCase: Get.find<SaveWalletUseCase>(),
      ),
    );

    // Wallet unlock controller
    Get.lazyPut<WalletUnlockController>(
      () => WalletUnlockController(
        unlockWalletUseCase: Get.find<UnlockWalletUseCase>(),
      ),
    );

    // Wallet settings controller
    Get.lazyPut<WalletSettingsController>(
      () => WalletSettingsController(
        exportMnemonicUseCase: Get.find<ExportMnemonicUseCase>(),
        verifyBackupUseCase: Get.find<VerifyBackupUseCase>(),
        deleteWalletUseCase: Get.find<DeleteWalletUseCase>(),
      ),
    );

    // NOTE: TransactionController registered in _registerControllerDependentUseCases
    // because it depends on SignTransactionUseCase which depends on AuthController
  }

  /// Dispose all registered dependencies
  ///
  /// Call this when app is closing or during testing cleanup.
  static void dispose() {
    Get.deleteAll(force: true);
  }
}
