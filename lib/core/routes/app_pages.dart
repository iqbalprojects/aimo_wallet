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

    // Create Wallet Screen - Uses controllers from service locator
    GetPage(
      name: AppRoutes.createWallet,
      page: () => const CreateWalletScreen(),
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

    // Unlock Screen - Uses controllers from service locator
    GetPage(name: AppRoutes.unlock, page: () => const UnlockScreen()),

    // Home Dashboard - Uses controllers from service locator
    GetPage(name: AppRoutes.home, page: () => const HomeDashboardScreen()),

    // Send Screen - Uses controllers from service locator
    GetPage(
      name: AppRoutes.send,
      page: () => const SendScreen(),
      // No binding needed - controllers already registered in service locator
    ),

    // Receive Screen - Uses existing WalletController
    GetPage(name: AppRoutes.receive, page: () => const ReceiveScreen()),

    // Settings Screen - Uses controllers from service locator
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),

    // Swap Screen - Binds SwapController
    GetPage(
      name: AppRoutes.swap,
      page: () => const SwapScreen(),
      binding: BindingsBuilder(() {
        // Only create SwapController if not already registered
        if (!Get.isRegistered<SwapController>()) {
          Get.lazyPut<SwapController>(
            () => SwapController(),
            fenix: true, // Keep alive and recreatable
          );
        }
      }),
    ),
  ];
}
