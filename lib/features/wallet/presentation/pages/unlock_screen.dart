import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secure_text_field.dart';
import '../controllers/auth_controller.dart';

/// Unlock Screen
///
/// User enters PIN to unlock wallet.
///
/// Features:
/// - Secure PIN input (obscured)
/// - Biometric authentication button (placeholder)
/// - Error state handling
/// - Clean minimal layout
/// - Loading state
///
/// Flow:
/// 1. User enters 6-digit PIN
/// 2. Call AuthController.verifyPin(pin)
/// 3. If successful -> Navigate to HomeDashboardScreen
/// 4. If failed -> Show error message
/// 5. Alternative: Use biometric authentication
///
/// Controller Integration:
/// - Uses AuthController for PIN verification
/// - Uses NavigationHelper for navigation
/// - Handles failed attempts (lockout after 5 attempts)
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  // Get AuthController (will be injected by binding)
  AuthController? get _authController {
    try {
      return Get.find<AuthController>();
    } catch (e) {
      // Controller not yet initialized
      return null;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    final pin = _pinController.text;

    // Basic validation
    if (pin.isEmpty) {
      setState(() {
        _errorText = 'Please enter your PIN';
      });
      return;
    }

    if (pin.length < 6) {
      setState(() {
        _errorText = 'PIN must be 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Call AuthController to unlock wallet
    final authController = _authController;
    if (authController != null) {
      final success = await authController.unlockWallet(pin);

      if (success) {
        // Check if we were navigated here expecting a result (e.g., from swap screen)
        // If 'returnResult' argument is true, just pop back with result
        // instead of replacing the entire navigation stack
        final args = Get.arguments;
        final shouldReturnResult = args is Map && args['returnResult'] == true;

        if (shouldReturnResult) {
          // Return to calling screen (e.g., swap) with success result
          Get.back(result: true);
        } else {
          // Normal unlock flow -> Navigate to home (replaces entire stack)
          NavigationHelper.navigateToHomeAfterUnlock();
        }
      } else {
        // Unlock failed -> Show error
        setState(() {
          _isLoading = false;
          _errorText = authController.errorMessage ?? 'Incorrect PIN';
          _pinController.clear();
        });
      }
    } else {
      // Fallback: Controller not initialized (placeholder mode)
      await Future.delayed(const Duration(milliseconds: 800));

      final args = Get.arguments;
      final shouldReturnResult = args is Map && args['returnResult'] == true;

      if (shouldReturnResult) {
        Get.back(result: true);
      } else {
        NavigationHelper.navigateToHomeAfterUnlock();
      }
    }
  }

  Future<void> _handleBiometric() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Call AuthController for biometric authentication
    final authController = _authController;
    if (authController != null) {
      final success = await authController.authenticateWithBiometric();

      if (success) {
        // Check if we were navigated here expecting a result
        final args = Get.arguments;
        final shouldReturnResult = args is Map && args['returnResult'] == true;

        if (shouldReturnResult) {
          Get.back(result: true);
        } else {
          NavigationHelper.navigateToHomeAfterUnlock();
        }
      } else {
        // Biometric failed -> Show error
        setState(() {
          _isLoading = false;
          _errorText =
              authController.errorMessage ?? 'Biometric authentication failed';
        });
      }
    } else {
      // Fallback: Show coming soon message
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() => _isLoading = false);

      Get.snackbar(
        'Biometric Authentication',
        'Biometric authentication will be available soon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.fingerprint, color: AppTheme.primaryPurple),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Lock Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Title
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Subtitle
                  Text(
                    'Enter your PIN to unlock your wallet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // PIN Input Container
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        // PIN Input
                        SecureTextField(
                          label: 'Enter PIN',
                          hint: '••••••',
                          controller: _pinController,
                          maxLength: 6,
                          autofocus: true,
                          errorText: _errorText,
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                          },
                          onSubmitted: () {
                            if (!_isLoading) {
                              _handleUnlock();
                            }
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingXL),

                        // Unlock Button
                        PrimaryButton(
                          text: 'Unlock Wallet',
                          onPressed: _isLoading ? null : _handleUnlock,
                          isLoading: _isLoading,
                          icon: Icons.lock_open,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppTheme.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                        ),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textTertiary),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppTheme.divider)),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Biometric Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleBiometric,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('Use Biometric'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      side: const BorderSide(
                        color: AppTheme.primaryPurple,
                        width: 2,
                      ),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXXL),

                  // Security Notice
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            'Your wallet is encrypted and secured. Your PIN never leaves this device.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
