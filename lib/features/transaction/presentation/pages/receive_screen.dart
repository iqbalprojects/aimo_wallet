import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

/// Receive Screen
/// 
/// Clean and simple screen for receiving tokens.
/// 
/// Features:
/// - Full wallet address display
/// - QR code for easy scanning
/// - Copy address button
/// - Share address button
/// - Clean, minimal design
/// 
/// Controller Integration:
/// - TODO: Inject WalletController
/// - TODO: Call controller.getAddress()
class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  // Placeholder address (in production, get from controller)
  static const String _address = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

  void _copyAddress() {
    Clipboard.setData(const ClipboardData(text: _address));
    Get.snackbar(
      'Copied',
      'Address copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.accentGreen,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.check_circle, color: AppTheme.textPrimary),
      duration: const Duration(seconds: 2),
    );
  }

  void _shareAddress() {
    // TODO: Implement share functionality using share_plus package
    Get.snackbar(
      'Share',
      'Share functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.share, color: AppTheme.primaryPurple),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Receive Crypto',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Subtitle
                  Text(
                    'Scan QR code or share your address',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // QR Code Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // QR Code
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: QrImageView(
                            data: _address,
                            version: QrVersions.auto,
                            size: 240,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Network Label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryPurple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Ethereum Network',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Address Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Wallet Address',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Address Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _address,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: _copyAddress,
                              color: AppTheme.primaryPurple,
                              tooltip: 'Copy Address',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyAddress,
                          icon: const Icon(Icons.copy, size: 20),
                          label: const Text('Copy Address'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: AppTheme.primaryPurple,
                              width: 2,
                            ),
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Share',
                          icon: Icons.share,
                          onPressed: _shareAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Warning Note
                  Container(
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
                          Icons.info_outline,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            'Only send Ethereum (ETH) and ERC-20 tokens to this address',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
