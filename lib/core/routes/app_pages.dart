import 'package:get/get.dart';
import '../../features/wallet/presentation/pages/splash_screen.dart';
import '../../features/wallet/presentation/pages/onboarding_screen.dart';
import '../../features/wallet/presentation/pages/create_wallet_screen.dart';
import '../../features/wallet/presentation/pages/backup_mnemonic_screen.dart';
import '../../features/wallet/presentation/pages/confirm_mnemonic_screen.dart';
import '../../features/wallet/presentation/pages/unlock_screen.dart';
import '../../features/wallet/presentation/pages/home_dashboard_screen.dart';
import '../../features/transaction/presentation/pages/send_screen.dart';
import '../../features/transaction/presentation/pages/receive_screen.dart';
import '../../features/wallet/presentation/pages/settings_screen.dart';
import '../../features/swap/presentation/pages/swap_screen.dart';
import '../../features/swap/presentation/controllers/swap_controller.dart';
import '../../features/wallet/presentation/controllers/wallet_controller.dart';
import '../../features/wallet/presentation/controllers/auth_controller.dart';
import '../../features/network_switch/presentation/controllers/network_controller.dart';
import '../../features/wallet/domain/usecases/create_new_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/unlock_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/get_current_address_usecase.dart';
import '../crypto/wallet_engine.dart';
import '../vault/secure_vault.dart';
import 'app_routes.dart';

/// App Pages
///
/// Defines GetX page routes and bindings.
///
/// Each page can have its own bindings for dependency injection.
/// Controllers are lazily initialized when the page is accessed.
///
/// Navigation Flows:
///
/// 1. New Wallet Flow:
///    Splash → Onboarding → Create → Backup → Confirm → Home
///
/// 2. Existing Wallet Flow:
///    Splash → Unlock → Home
///
/// 3. Import Wallet Flow:
///    Splash → Onboarding → Create (Import) → Home
///
/// Bindings:
/// - Global controllers (WalletController, AuthController) are bound on app start
/// - Page-specific controllers are bound when page is accessed
/// - Controllers are disposed when page is removed from stack
class AppPages {
  // Private constructor
  AppPages._();

  // Initial route
  static const String initial = AppRoutes.splash;

  // All pages with bindings
  static final routes = [
    // Splash Screen - No bindings (uses global controllers)
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),

    // Onboarding Screen - No bindings
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),

    // Create Wallet Screen - Binds WalletController with dependencies
    GetPage(
      name: AppRoutes.createWallet,
      page: () => const CreateWalletScreen(),
      binding: BindingsBuilder(() {
        // Initialize core dependencies
        final walletEngine = WalletEngine();
        final secureVault = SecureVault();

        // Initialize use case
        final createNewWalletUseCase = CreateNewWalletUseCase(
          walletEngine: walletEngine,
          secureVault: secureVault,
        );

        // Initialize controller with use case
        Get.lazyPut<WalletController>(
          () =>
              WalletController(createNewWalletUseCase: createNewWalletUseCase),
        );
      }),
    ),

    // Backup Mnemonic Screen - Uses existing WalletController
    GetPage(
      name: AppRoutes.backupMnemonic,
      page: () => const BackupMnemonicScreen(),
    ),

    // Confirm Mnemonic Screen - Uses existing WalletController
    GetPage(
      name: AppRoutes.confirmMnemonic,
      page: () => const ConfirmMnemonicScreen(),
    ),

    // Unlock Screen - Binds AuthController with dependencies
    GetPage(
      name: AppRoutes.unlock,
      page: () => const UnlockScreen(),
      binding: BindingsBuilder(() {
        // Initialize core dependencies
        final secureVault = SecureVault();

        // Initialize use case
        final unlockWalletUseCase = UnlockWalletUseCase(
          secureVault: secureVault,
        );

        // Initialize controller with use case
        Get.lazyPut<AuthController>(
          () => AuthController(unlockWalletUseCase: unlockWalletUseCase),
        );
      }),
    ),

    // Home Dashboard - Binds all main controllers with dependencies
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeDashboardScreen(),
      binding: BindingsBuilder(() {
        // Initialize core dependencies
        final secureVault = SecureVault();

        // Initialize use cases
        final getCurrentAddressUseCase = GetCurrentAddressUseCase(
          secureVault: secureVault,
        );

        // Initialize controllers with use cases
        Get.lazyPut<WalletController>(
          () => WalletController(
            getCurrentAddressUseCase: getCurrentAddressUseCase,
          ),
        );
        Get.lazyPut<NetworkController>(() => NetworkController());
      }),
    ),

    // Send Screen - Uses controllers from service locator
    GetPage(
      name: AppRoutes.send,
      page: () => const SendScreen(),
      // No binding needed - controllers already registered in service locator
    ),

    // Receive Screen - Uses existing WalletController
    GetPage(name: AppRoutes.receive, page: () => const ReceiveScreen()),

    // Settings Screen - Uses existing controllers
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),

    // Swap Screen - Binds SwapController
    GetPage(
      name: AppRoutes.swap,
      page: () => const SwapScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SwapController>(() => SwapController());
        Get.lazyPut<NetworkController>(() => NetworkController());
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
  ];
}
