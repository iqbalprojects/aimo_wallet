import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../../../../core/widgets/primary_button.dart';

/// Onboarding Screen
/// 
/// Welcome screen explaining wallet features.
/// 
/// Actions:
/// - Create New Wallet -> Navigate to CreateWalletScreen
/// - Import Wallet -> Navigate to ImportWalletScreen (future)
/// 
/// Controller Integration:
/// - No controller needed (navigation only)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // Title
                Text(
                  'Welcome to\nAimo Wallet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Description
                Text(
                  'Your secure, non-custodial wallet for\nEthereum and EVM-compatible chains',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),

                // Features
                _buildFeature(
                  context,
                  Icons.security,
                  'Secure',
                  'Your keys, your crypto',
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFeature(
                  context,
                  Icons.speed,
                  'Fast',
                  'Quick transactions',
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFeature(
                  context,
                  Icons.verified_user,
                  'Private',
                  'No tracking, no data collection',
                ),

                const Spacer(),

                // Create Wallet Button
                PrimaryButton(
                  text: 'Create New Wallet',
                  icon: Icons.add_circle_outline,
                  onPressed: () {
                    NavigationHelper.startWalletCreation();
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Import Wallet Button
                OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to import wallet screen
                    Get.snackbar(
                      'Coming Soon',
                      'Import wallet feature will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.primaryPurple),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  child: const Text(
                    'Import Existing Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
