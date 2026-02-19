import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/security/secure_session_manager.dart';

/// Backup Mnemonic Screen
/// 
/// Displays the 24-word mnemonic for backup.
/// 
/// SECURITY ARCHITECTURE:
/// - Mnemonic received via SECURE SESSION (not navigation argument)
/// - Session ID passed in navigation (safe)
/// - Mnemonic retrieved from SecureSessionManager
/// - Mnemonic stored in local variable (NOT reactive state)
/// - Mnemonic cleared from memory when screen is disposed
/// - Session cleared when screen is disposed
/// - Mnemonic NEVER logged or printed
/// - Copy functionality DISABLED for security
/// - Screenshot warning displayed
/// 
/// Memory Management:
/// 1. Receive session ID from navigation argument
/// 2. Retrieve mnemonic from SecureSessionManager
/// 3. Store in local String variable (not Rx)
/// 4. Split into words for display
/// 5. Clear from memory in dispose()
/// 6. Clear session in dispose()
/// 
/// Security Principles:
/// - Minimize mnemonic lifetime in memory
/// - No persistence in reactive state
/// - No logging or debugging output
/// - User must manually write down words
/// - Confirmation required before proceeding
/// - Auto-expiring sessions (5 minutes)
/// 
/// Navigation Flow:
/// - Receives: sessionId (String) from CreateWalletScreen
/// - Passes: sessionId (String) to ConfirmMnemonicScreen
/// - After confirmation: session cleared
class BackupMnemonicScreen extends StatefulWidget {
  const BackupMnemonicScreen({super.key});

  @override
  State<BackupMnemonicScreen> createState() => _BackupMnemonicScreenState();
}

class _BackupMnemonicScreenState extends State<BackupMnemonicScreen> {
  bool _isRevealed = false;
  bool _hasWrittenDown = false;
  bool _understandsResponsibility = false;

  // SECURITY: Session ID (safe to store)
  String? _sessionId;

  // SECURITY: Mnemonic stored in local variable, NOT reactive state
  // This ensures it's not persisted in GetX state management
  String? _mnemonic;
  List<String>? _mnemonicWords;

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  /// Load mnemonic from secure session
  /// 
  /// SECURITY:
  /// - Session ID passed via Get.arguments (safe)
  /// - Mnemonic retrieved from SecureSessionManager
  /// - Stored in local variable (not reactive state)
  /// - Never logged or printed
  void _loadMnemonic() {
    try {
      // Get session ID from navigation arguments
      final args = Get.arguments as Map<String, dynamic>?;
      _sessionId = args?['sessionId'] as String?;

      if (_sessionId != null) {
        // Retrieve mnemonic from secure session
        _mnemonic = SecureSessionManager.getMnemonic(_sessionId!);

        if (_mnemonic != null && _mnemonic!.isNotEmpty) {
          // Split into words for display
          _mnemonicWords = _mnemonic!.trim().split(RegExp(r'\s+'));

          // SECURITY: Validate word count (should be 24 words)
          if (_mnemonicWords!.length != 24) {
            // Invalid mnemonic - show error
            _showErrorAndGoBack('Invalid recovery phrase format');
          }
        } else {
          // Session expired or invalid
          _showErrorAndGoBack('Session expired. Please try again.');
        }
      } else {
        // No session ID provided - show error and go back
        _showErrorAndGoBack('No session provided');
      }
    } catch (e) {
      // Error loading mnemonic - show error and go back
      _showErrorAndGoBack('Failed to load recovery phrase');
    }
  }

  void _showErrorAndGoBack(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.accentRed,
      colorText: AppTheme.textPrimary,
    );
    Get.back();
  }

  @override
  void dispose() {
    // SECURITY: Clear mnemonic from memory when screen is disposed
    // This ensures mnemonic doesn't remain in memory longer than necessary
    if (_mnemonic != null) {
      // Overwrite string in memory (best effort in Dart)
      // Note: Dart strings are immutable, but we set to empty to help GC
      _mnemonic = '';
      _mnemonic = null;
    }
    if (_mnemonicWords != null) {
      _mnemonicWords!.clear();
      _mnemonicWords = null;
    }
    
    // SECURITY: Clear session when leaving screen
    // Session will be recreated for confirm screen
    // This prevents session from persisting longer than needed
    if (_sessionId != null) {
      SecureSessionManager.clearSession(_sessionId!);
      _sessionId = null;
    }
    
    super.dispose();
  }

  bool get _canContinue => _hasWrittenDown && _understandsResponsibility;

  void _handleContinue() {
    if (!_canContinue) {
      Get.snackbar(
        'Confirmation Required',
        'Please confirm you have written down your recovery phrase and understand your responsibility',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed.withValues(alpha: 0.9),
        colorText: AppTheme.textPrimary,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // SECURITY: Pass mnemonic to confirmation screen via secure session
    // Create new session for confirm screen
    if (_mnemonic != null) {
      NavigationHelper.navigateToConfirm(mnemonic: _mnemonic!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Recovery Phrase'),
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
                // Critical Warning
                _buildCriticalWarning(context),
                const SizedBox(height: AppTheme.spacingXL),

                // Instructions
                Text(
                  'Write Down Your Recovery Phrase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Write these 24 words in order on paper. Store them in a safe place. This is the ONLY way to recover your wallet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // Security Tips
                _buildSecurityTips(context),
                const SizedBox(height: AppTheme.spacingXL),

                // Mnemonic Display
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: AppTheme.accentRed.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _isRevealed
                      ? _buildMnemonicGrid(context)
                      : _buildRevealButton(context),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Screenshot Warning
                if (_isRevealed) _buildScreenshotWarning(context),
                if (_isRevealed) const SizedBox(height: AppTheme.spacingL),

                // Confirmation Checkboxes
                _buildConfirmationCheckbox(
                  value: _hasWrittenDown,
                  onChanged: (value) {
                    setState(() {
                      _hasWrittenDown = value ?? false;
                    });
                  },
                  title: 'I have written down my 24-word recovery phrase on paper',
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildConfirmationCheckbox(
                  value: _understandsResponsibility,
                  onChanged: (value) {
                    setState(() {
                      _understandsResponsibility = value ?? false;
                    });
                  },
                  title: 'I understand that if I lose my recovery phrase, I will lose access to my funds forever',
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // Continue Button
                PrimaryButton(
                  text: 'Continue to Verification',
                  onPressed: _canContinue ? _handleContinue : null,
                  icon: Icons.arrow_forward,
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.15),
        border: Border.all(color: AppTheme.accentRed, width: 2),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentRed,
                size: 32,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  'CRITICAL: Read Carefully',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            '• Never share your recovery phrase with anyone\n'
            '• Aimo Wallet will NEVER ask for your recovery phrase\n'
            '• Anyone with this phrase can steal your funds\n'
            '• If you lose it, your funds are lost forever\n'
            '• Store it offline in a secure location',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Security Best Practices',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildTipItem(context, 'Write on paper, not digitally'),
          _buildTipItem(context, 'Store in a fireproof safe'),
          _buildTipItem(context, 'Consider making multiple copies'),
          _buildTipItem(context, 'Never take screenshots'),
          _buildTipItem(context, 'Keep away from cameras and people'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacingXL),
        const Icon(
          Icons.visibility_off_outlined,
          size: 64,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Your recovery phrase is hidden',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Make sure you are in a private place',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isRevealed = true;
            });
          },
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Reveal Recovery Phrase'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  Widget _buildMnemonicGrid(BuildContext context) {
    // SECURITY: Only display if mnemonic words are loaded
    if (_mnemonicWords == null || _mnemonicWords!.isEmpty) {
      return const Center(
        child: Text('Error loading recovery phrase'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: AppTheme.spacingM,
            mainAxisSpacing: AppTheme.spacingM,
          ),
          itemCount: _mnemonicWords!.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      _mnemonicWords![index],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ],
    );
  }

  Widget _buildScreenshotWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.accentRed.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.screenshot_monitor,
            color: AppTheme.accentRed,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              'Do NOT take screenshots. Write these words on paper.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: value
              ? AppTheme.primaryPurple.withOpacity(0.5)
              : AppTheme.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryPurple,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: 4,
        ),
      ),
    );
  }
}
