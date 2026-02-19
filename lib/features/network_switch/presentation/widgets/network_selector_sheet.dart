import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/network_controller.dart';

/// Network Selector Bottom Sheet
/// 
/// Modal bottom sheet for selecting network.
/// 
/// Features:
/// - List of available networks
/// - Current network highlighted
/// - Testnet badge
/// - Custom network indicator
/// - Add custom network button
/// - Reactive updates
/// 
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => const NetworkSelectorSheet(),
/// );
/// ```
class NetworkSelectorSheet extends StatelessWidget {
  const NetworkSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NetworkController>();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Network',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // Network List
          Flexible(
            child: Obx(() {
              final networks = controller.networks;
              final currentNetwork = controller.currentNetwork;

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
                itemCount: networks.length,
                itemBuilder: (context, index) {
                  final network = networks[index];
                  final isSelected = network.id == currentNetwork?.id;

                  return _buildNetworkItem(
                    context,
                    network: network,
                    isSelected: isSelected,
                    onTap: () async {
                      final success = await controller.switchNetwork(network);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Network Changed',
                          'Switched to ${network.name}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.accentGreen,
                          colorText: AppTheme.textPrimary,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),

          // Add Custom Network Button
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to add custom network screen
                Get.snackbar(
                  'Add Network',
                  'Custom network feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceDark,
                  colorText: AppTheme.textPrimary,
                  duration: const Duration(seconds: 2),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Custom Network'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                side: const BorderSide(color: AppTheme.primaryPurple),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(
    BuildContext context, {
    required Network network,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Network Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.surfaceDark,
                          AppTheme.surfaceDark.withValues(alpha: 0.8),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : AppTheme.textTertiary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  network.symbol[0],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),

            // Network Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        network.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primaryPurple
                                  : AppTheme.textPrimary,
                            ),
                      ),
                      if (network.isTestnet) ...[
                        const SizedBox(width: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            'TESTNET',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                      if (network.isCustom) ...[
                        const SizedBox(width: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            'CUSTOM',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chain ID: ${network.chainId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Selected Indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
