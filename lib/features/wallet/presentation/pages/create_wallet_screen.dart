import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secure_text_field.dart';
import '../controllers/wallet_controller.dart';

/// Create Wallet Screen
/// 
/// Entry point for wallet creation flow.
/// 
/// Flow:
/// 1. User enters PIN (6-8 digits)
/// 2. User confirms PIN
/// 3. Call WalletController.createWallet(pin)
/// 4. Navigate to BackupMnemonicScreen with mnemonic
/// 
/// Options:
/// - Create New Wallet: Generate new 24-word mnemonic
/// - Import Existing Wallet: Import from existing mnemonic (future)
/// 
/// Controller Integration:
/// - Uses WalletController for wallet creation
/// - Observes loading and error states
/// - Passes mnemonic to backup screen via navigation
/// 
/// Security:
/// - PIN validated (6-8 digits)
/// - PIN confirmation required
/// - Mnemonic never stored in UI state
/// - Mnemonic passed only via navigation arguments
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isCreatingWallet = false;
  String? _errorText;

  // Get WalletController (will be injected by binding)
  WalletController? get _walletController {
    try {
      return Get.find<WalletController>();
    } catch (e) {
      // Controller not yet initialized
      return null;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateNew() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    // Validate PIN
    if (pin.isEmpty) {
      setState(() {
        _errorText = 'Please enter a PIN';
      });
      return;
    }

    if (pin.length < 6) {
      setState(() {
        _errorText = 'PIN must be at least 6 digits';
      });
      return;
    }

    if (pin.length > 8) {
      setState(() {
        _errorText = 'PIN must be at most 8 digits';
      });
      return;
    }

    // Validate PIN confirmation
    if (confirmPin.isEmpty) {
      setState(() {
        _errorText = 'Please confirm your PIN';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorText = 'PINs do not match';
      });
      return;
    }

    // Create wallet
    setState(() {
      _isCreatingWallet = true;
      _errorText = null;
    });

    try {
      final controller = _walletController;
      if (controller != null) {
        // Call controller with callback pattern (SECURITY: no mnemonic storage)
        await controller.createWallet(
          pin: pin,
          onSuccess: (mnemonic, address) {
            // Navigate immediately with secure session
            NavigationHelper.navigateToBackup(mnemonic: mnemonic);
          },
        );
        
        // Check for errors
        if (controller.errorMessage != null) {
          setState(() {
            _errorText = controller.errorMessage;
          });
        }
      } else {
        // Fallback: Controller not initialized
        setState(() {
          _errorText = 'Wallet controller not initialized';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Failed to create wallet: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingWallet = false;
        });
      }
    }
  }

  void _handleImportExisting() {
    // TODO: Navigate to import mnemonic screen
    Get.snackbar(
      'Import Wallet',
      'Import functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Wallet'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingXL),

                // Icon
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 60,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),

                // Title
                Text(
                  'Secure Your Wallet',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Description
                Text(
                  'Create a PIN to secure your wallet. You\'ll need this PIN to access your wallet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXXL),

                // PIN Input
                SecureTextField(
                  label: 'Enter PIN',
                  hint: '6-8 digits',
                  controller: _pinController,
                  maxLength: 8,
                  errorText: _errorText,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Confirm PIN Input
                SecureTextField(
                  label: 'Confirm PIN',
                  hint: '6-8 digits',
                  controller: _confirmPinController,
                  maxLength: 8,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  onSubmitted: () {
                    if (!_isCreatingWallet) {
                      _handleCreateNew();
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingXXL),

                // Create New Wallet Button
                PrimaryButton(
                  text: 'Create New Wallet',
                  icon: Icons.add_circle_outline,
                  onPressed: _isCreatingWallet ? null : _handleCreateNew,
                  isLoading: _isCreatingWallet,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Import Existing Wallet Button
                OutlinedButton.icon(
                  onPressed: _isCreatingWallet ? null : _handleImportExisting,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Import Existing Wallet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.primaryPurple),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Security Notice
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
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
                          'Your PIN encrypts your wallet. Never share your PIN or recovery phrase with anyone.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
