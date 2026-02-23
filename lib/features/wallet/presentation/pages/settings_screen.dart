import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/wallet_settings_controller.dart';

/// Settings Screen
///
/// App settings and wallet management with grouped list design.
///
/// Sections:
/// - Security (Change PIN, Auto-lock duration, Biometric)
/// - Network (Switch Network)
/// - Wallet (View Recovery Phrase, Add Account)
/// - About (Version, Terms, Privacy)
///
/// Controller Integration:
/// - TODO: Inject WalletLockController
/// - TODO: Inject SettingsController
/// - TODO: Call controller.lock() for manual lock
/// - TODO: Call controller.changePin()
/// - TODO: Call controller.setAutoLockDuration()
/// - TODO: Call controller.toggleBiometric()
/// - TODO: Call controller.viewRecoveryPhrase()
/// - TODO: Call controller.addAccount()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Placeholder state (in production, get from controller)
  bool _biometricEnabled = false;
  String _autoLockDuration = '5 minutes';
  final String _currentNetwork = 'Ethereum Mainnet';

  void _handleChangePin() {
    // TODO: Navigate to change PIN screen
    Get.snackbar(
      'Change PIN',
      'Change PIN feature coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.lock_outline, color: AppTheme.primaryPurple),
      duration: const Duration(seconds: 2),
    );
  }

  void _handleAutoLockDuration() {
    // TODO: Show duration picker
    _showAutoLockDialog();
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Auto-Lock Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDurationOption('1 minute'),
            _buildDurationOption('5 minutes'),
            _buildDurationOption('15 minutes'),
            _buildDurationOption('30 minutes'),
            _buildDurationOption('Never'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String duration) {
    final isSelected = _autoLockDuration == duration;
    return ListTile(
      title: Text(duration),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryPurple)
          : null,
      onTap: () {
        setState(() {
          _autoLockDuration = duration;
        });
        Navigator.pop(context);
        // TODO: Call controller.setAutoLockDuration(duration)
      },
    );
  }

  void _handleToggleBiometric(bool value) {
    setState(() {
      _biometricEnabled = value;
    });
    // TODO: Call controller.toggleBiometric(value)
  }

  void _handleSwitchNetwork() {
    // TODO: Navigate to network selection screen
    Get.snackbar(
      'Switch Network',
      'Network selection coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.language, color: AppTheme.primaryPurple),
      duration: const Duration(seconds: 2),
    );
  }

  void _handleViewRecoveryPhrase() {
    final pinController = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please enter your PIN to view your recovery phrase. Make sure no one is watching your screen.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pin = pinController.text;
                          if (pin.length < 4) {
                            setState(
                              () => errorText = 'PIN must be 4-8 digits',
                            );
                            return;
                          }

                          setState(() => isLoading = true);
                          final settingsController =
                              Get.find<WalletSettingsController>();
                          final success = await settingsController
                              .exportMnemonic(pin);

                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context);
                              _showRecoveryPhraseModal(settingsController);
                            } else {
                              setState(() {
                                isLoading = false;
                                errorText =
                                    settingsController.errorMessage ??
                                    'Incorrect PIN';
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecoveryPhraseModal(WalletSettingsController settingsController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusL),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recovery Phrase',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        settingsController.clearExportedMnemonic();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.1),
                          border: Border.all(
                            color: AppTheme.accentRed,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.accentRed,
                              size: 28,
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Text(
                                'Never share this phrase with anyone. Keep it secure and offline.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.5,
                                crossAxisSpacing: AppTheme.spacingM,
                                mainAxisSpacing: AppTheme.spacingM,
                              ),
                          itemCount: settingsController
                              .getExportedMnemonicWords()
                              .length,
                          itemBuilder: (context, index) {
                            final word = settingsController
                                .getExportedMnemonicWords()[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${index + 1}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textTertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Expanded(
                                    child: Text(
                                      word,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      settingsController.clearExportedMnemonic();
    });
  }

  void _handleAddAccount() {
    // TODO: Navigate to add account screen
    Get.snackbar(
      'Add Account',
      'Multi-account feature coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryPurple),
      duration: const Duration(seconds: 2),
    );
  }

  void _handleLockWallet() {
    // TODO: Call controller.lock()
    Get.offAllNamed(AppRoutes.unlock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            // Security Section
            _buildSectionHeader('Security', Icons.security),
            _buildSettingsGroup([
              _buildSettingsTile(
                title: 'Change PIN',
                icon: Icons.lock_outline,
                onTap: _handleChangePin,
              ),
              _buildSettingsTile(
                title: 'Auto-Lock Duration',
                icon: Icons.timer_outlined,
                subtitle: _autoLockDuration,
                onTap: _handleAutoLockDuration,
              ),
              _buildSettingsTile(
                title: 'Biometric Authentication',
                icon: Icons.fingerprint,
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: _handleToggleBiometric,
                  activeColor: AppTheme.primaryPurple,
                ),
              ),
            ]),
            const SizedBox(height: AppTheme.spacingXL),

            // Network Section
            _buildSectionHeader('Network', Icons.language),
            _buildSettingsGroup([
              _buildSettingsTile(
                title: 'Switch Network',
                icon: Icons.swap_horiz,
                subtitle: _currentNetwork,
                onTap: _handleSwitchNetwork,
              ),
            ]),
            const SizedBox(height: AppTheme.spacingXL),

            // Wallet Section
            _buildSectionHeader(
              'Wallet',
              Icons.account_balance_wallet_outlined,
            ),
            _buildSettingsGroup([
              _buildSettingsTile(
                title: 'View Recovery Phrase',
                icon: Icons.visibility_outlined,
                onTap: _handleViewRecoveryPhrase,
                isWarning: true,
              ),
              _buildSettingsTile(
                title: 'Add Account',
                icon: Icons.add_circle_outline,
                onTap: _handleAddAccount,
              ),
            ]),
            const SizedBox(height: AppTheme.spacingXL),

            // About Section
            _buildSectionHeader('About', Icons.info_outline),
            _buildSettingsGroup([
              _buildSettingsTile(
                title: 'Version',
                icon: Icons.apps,
                subtitle: '1.0.0',
              ),
              _buildSettingsTile(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                onTap: () {
                  // TODO: Open terms
                },
              ),
              _buildSettingsTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
            ]),
            const SizedBox(height: AppTheme.spacingXXL),

            // Lock Wallet Button
            OutlinedButton.icon(
              onPressed: _handleLockWallet,
              icon: const Icon(Icons.lock),
              label: const Text('Lock Wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                side: const BorderSide(color: AppTheme.accentRed, width: 2),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.spacingM,
        left: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryPurple),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isWarning = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.divider.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isWarning
                    ? AppTheme.accentRed.withOpacity(0.1)
                    : AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: isWarning ? AppTheme.accentRed : AppTheme.primaryPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
