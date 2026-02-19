import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/wallet_controller.dart';

/// Splash Screen
/// 
/// Initial screen shown while app initializes.
/// 
/// Navigation Flow:
/// 1. Initialize WalletController
/// 2. Check if wallet exists (via controller.hasWallet)
/// 3. If wallet exists -> Navigate to UnlockScreen
/// 4. If no wallet -> Navigate to OnboardingScreen
/// 
/// Controller Integration:
/// - Initializes WalletController on app start
/// - Reads hasWallet flag from controller
/// - Navigates based on wallet existence
/// 
/// Security:
/// - No sensitive data displayed
/// - Quick check only (no decryption)
/// - Proper route replacement (offNamed)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialize app and navigate to appropriate screen
  /// 
  /// Flow:
  /// 1. Get WalletController (already initialized by AppInitializer)
  /// 2. Wait for initialization to complete
  /// 3. Navigate based on hasWallet flag
  /// 
  /// Navigation:
  /// - hasWallet = true  -> UnlockScreen (existing wallet)
  /// - hasWallet = false -> OnboardingScreen (new user)
  Future<void> _initialize() async {
    try {
      // Get WalletController (already initialized by AppInitializer)
      final walletController = Get.find<WalletController>();

      // Wait for controller initialization
      // Controller's onInit() checks wallet existence
      await Future.delayed(const Duration(milliseconds: 500));

      // Add minimum splash duration for UX
      await Future.delayed(const Duration(seconds: 2));

      // Navigate based on wallet existence
      if (walletController.hasWallet) {
        // Existing wallet -> Unlock screen
        Get.offNamed(AppRoutes.unlock);
      } else {
        // No wallet -> Onboarding screen
        Get.offNamed(AppRoutes.onboarding);
      }
    } catch (e) {
      // If controller not found, navigate to onboarding
      // This should not happen if AppInitializer ran correctly
      Get.offNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // App Name
              Text(
                'Aimo Wallet',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppTheme.spacingS),

              // Tagline
              Text(
                'Your Gateway to Web3',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
