import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secure_text_field.dart';
import '../controllers/wallet_controller.dart';

/// Import Wallet Screen
///
/// Allows users to import an existing wallet using their 12/24 word mnemonic phrase,
/// and secure it locally with a new PIN.
class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _mnemonicController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isImporting = false;
  String? _errorText;
  String? _mnemonicErrorText;

  WalletController? get _walletController {
    try {
      return Get.find<WalletController>();
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final mnemonic = _mnemonicController.text.trim();
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    // Reset errors
    setState(() {
      _errorText = null;
      _mnemonicErrorText = null;
    });

    if (mnemonic.isEmpty) {
      setState(() {
        _mnemonicErrorText = 'Please enter your recovery phrase';
      });
      return;
    }

    if (pin.isEmpty || pin.length < 6) {
      setState(() {
        _errorText = 'PIN must be at least 6 digits';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorText = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final controller = _walletController;
      if (controller != null) {
        final success = await controller.importWallet(mnemonic, pin);
        if (success) {
          // Navigate to Home Dashboard after successful import
          Get.offAllNamed('/home');
        } else {
          setState(() {
            // Might be from Validation issues
            _errorText = controller.errorMessage ?? 'Failed to import wallet';
          });
        }
      } else {
        setState(() {
          _errorText = 'Wallet controller not initialized';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Failed to import wallet: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingM),

                // Title
                Text(
                  'Enter Recovery Phrase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingS),

                // Description
                Text(
                  'Typically 12 or 24 words separated by spaces',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Mnemonic Input
                TextField(
                  controller: _mnemonicController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Recovery Phrase',
                    hintText: 'word1 word2 word3...',
                    errorText: _mnemonicErrorText,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  onChanged: (_) {
                    if (_mnemonicErrorText != null) {
                      setState(() => _mnemonicErrorText = null);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingXL),

                Text(
                  'Secure Imported Wallet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Create a PIN to secure this wallet on your device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),

                // PIN Input
                SecureTextField(
                  label: 'Enter New PIN',
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
                const SizedBox(height: AppTheme.spacingM),

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
                    if (!_isImporting) {
                      _handleImport();
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingXXL),

                // Import Button
                PrimaryButton(
                  text: 'Import Wallet',
                  icon: Icons.download_rounded,
                  onPressed: _isImporting ? null : _handleImport,
                  isLoading: _isImporting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
