/// App Routes
///
/// Defines all route names for GetX navigation.
///
/// Usage:
/// ```dart
/// Get.toNamed(AppRoutes.home);
/// ```
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String createWallet = '/create-wallet';
  static const String backupMnemonic = '/backup-mnemonic';
  static const String confirmMnemonic = '/confirm-mnemonic';
  static const String unlock = '/unlock';
  static const String home = '/home';
  static const String send = '/send';
  static const String receive = '/receive';
  static const String settings = '/settings';
  static const String swap = '/swap';
}
