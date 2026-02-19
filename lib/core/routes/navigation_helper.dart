import 'package:get/get.dart';
import 'app_routes.dart';
import '../security/secure_session_manager.dart';

/// Navigation Helper
///
/// Provides convenient methods for common navigation flows.
///
/// SECURITY:
/// - Uses SecureSessionManager for sensitive data
/// - No mnemonic in navigation arguments
/// - Auto-expiring sessions
///
/// Benefits:
/// - Centralized navigation logic
/// - Type-safe navigation
/// - Easy to test and maintain
/// - Clear navigation flows
///
/// Usage:
/// ```dart
/// // Navigate to wallet creation flow
/// NavigationHelper.startWalletCreation();
///
/// // Navigate to home after unlock
/// NavigationHelper.navigateToHome();
///
/// // Navigate back to unlock (lock wallet)
/// NavigationHelper.lockWallet();
/// ```
class NavigationHelper {
  // Private constructor to prevent instantiation
  NavigationHelper._();

  // ============================================================================
  // WALLET CREATION FLOW
  // ============================================================================

  /// Start wallet creation flow
  ///
  /// Flow: Create → Backup → Confirm → Home
  static void startWalletCreation() {
    Get.toNamed(AppRoutes.createWallet);
  }

  /// Navigate to backup mnemonic screen
  ///
  /// Called after wallet creation
  ///
  /// SECURITY:
  /// - Creates secure session for mnemonic
  /// - Only session ID passed in navigation
  /// - Session auto-expires after 5 minutes
  static void navigateToBackup({required String mnemonic}) {
    final sessionId = SecureSessionManager.createMnemonicSession(mnemonic);
    Get.toNamed(AppRoutes.backupMnemonic, arguments: {'sessionId': sessionId});
  }

  /// Navigate to confirm mnemonic screen
  ///
  /// Called after user views backup
  ///
  /// SECURITY:
  /// - Creates secure session for mnemonic
  /// - Only session ID passed in navigation
  /// - Session auto-expires after 5 minutes
  static void navigateToConfirm({required String mnemonic}) {
    final sessionId = SecureSessionManager.createMnemonicSession(mnemonic);
    Get.toNamed(AppRoutes.confirmMnemonic, arguments: {'sessionId': sessionId});
  }

  /// Complete wallet creation and navigate to home
  ///
  /// Called after mnemonic confirmation
  /// Clears navigation stack
  static void completeWalletCreation() {
    Get.offAllNamed(AppRoutes.home);
  }

  // ============================================================================
  // AUTHENTICATION FLOW
  // ============================================================================

  /// Navigate to unlock screen
  ///
  /// Called when app starts with existing wallet
  static void navigateToUnlock() {
    Get.offAllNamed(AppRoutes.unlock);
  }

  /// Navigate to home after successful unlock
  ///
  /// Clears navigation stack
  static void navigateToHomeAfterUnlock() {
    Get.offAllNamed(AppRoutes.home);
  }

  /// Lock wallet and return to unlock screen
  ///
  /// Called when user locks wallet or auto-lock triggers
  /// Clears navigation stack for security
  static void lockWallet() {
    Get.offAllNamed(AppRoutes.unlock);
  }

  // ============================================================================
  // HOME NAVIGATION
  // ============================================================================

  /// Navigate to home screen
  ///
  /// Used for general navigation to home
  static void navigateToHome() {
    Get.toNamed(AppRoutes.home);
  }

  /// Navigate to send screen
  static void navigateToSend() {
    Get.toNamed(AppRoutes.send);
  }

  /// Navigate to receive screen
  static void navigateToReceive() {
    Get.toNamed(AppRoutes.receive);
  }

  /// Navigate to settings screen
  static void navigateToSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  /// Navigate to swap screen
  static void navigateToSwap() {
    Get.toNamed(AppRoutes.swap);
  }

  // ============================================================================
  // ONBOARDING FLOW
  // ============================================================================

  /// Navigate to onboarding screen
  ///
  /// Called when no wallet exists
  static void navigateToOnboarding() {
    Get.offAllNamed(AppRoutes.onboarding);
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Go back to previous screen
  static void goBack() {
    Get.back();
  }

  /// Check if can go back
  static bool canGoBack() {
    return Get.key.currentState?.canPop() ?? false;
  }

  /// Clear all navigation stack and go to route
  static void clearStackAndNavigate(String route) {
    Get.offAllNamed(route);
  }
}
