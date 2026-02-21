import 'package:get/get.dart';
import 'service_locator.dart';
import '../../features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App Initializer
///
/// Responsibility: Initialize app on startup.
/// - Initialize dependency injection
/// - Initialize WalletController
/// - Check wallet existence
/// - Set initial wallet state
///
/// Requirements: 7.1, 7.5
///
/// Usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppInitializer.initialize();
///   runApp(MyApp());
/// }
/// ```
class AppInitializer {
  /// Initialize app
  ///
  /// Call this in main() before runApp().
  ///
  /// Steps:
  /// 1. Initialize dependency injection (register all services)
  /// 2. Initialize WalletController (check wallet existence)
  /// 3. Wait for initialization to complete
  ///
  /// Requirements: 7.1, 7.5
  static Future<void> initialize() async {
    // Step 0: Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('WARNING: Could not load .env file: $e');
    }

    // Step 1: Initialize dependency injection
    // Registers all services, repositories, use cases, and controllers
    ServiceLocator.init();

    // Step 2: Initialize WalletController
    // This will:
    // - Check if wallet exists on device
    // - Load cached wallet address if available
    // - Set initial wallet state (notCreated or locked)
    final walletController = Get.find<WalletController>();

    // Step 3: Wait for initialization to complete
    // WalletController.onInit() is called automatically by GetX
    // We need to wait for the async initialization to complete
    await _waitForWalletInitialization(walletController);
  }

  /// Wait for wallet initialization to complete
  ///
  /// Polls wallet controller until initialization is complete.
  /// Timeout after 5 seconds to prevent infinite wait.
  static Future<void> _waitForWalletInitialization(
    WalletController controller,
  ) async {
    const maxWaitTime = Duration(seconds: 5);
    const pollInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    // Wait until loading is complete or timeout
    while (controller.isLoading) {
      // Check timeout
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        // Timeout - log error but continue
        // App can still function, wallet state will be notCreated
        // Note: Removed print statement for production
        break;
      }

      // Wait before next poll
      await Future.delayed(pollInterval);
    }
  }

  /// Dispose app resources
  ///
  /// Call this when app is closing or during testing cleanup.
  static void dispose() {
    ServiceLocator.dispose();
  }
}
