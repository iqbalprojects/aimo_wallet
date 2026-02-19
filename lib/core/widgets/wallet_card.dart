import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Wallet Card
/// 
/// Displays wallet balance and address with gradient background.
/// 
/// Usage:
/// ```dart
/// WalletCard(
///   balance: '1.234',
///   symbol: 'ETH',
///   address: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
/// )
/// ```
class WalletCard extends StatelessWidget {
  final String balance;
  final String symbol;
  final String address;
  final String? usdValue;

  const WalletCard({
    super.key,
    required this.balance,
    required this.symbol,
    required this.address,
    this.usdValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Label
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Balance Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  symbol,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary.withOpacity(0.9),
                      ),
                ),
              ),
            ],
          ),

          // USD Value
          if (usdValue != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              '\$$usdValue USD',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.8),
                  ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingL),

          // Address
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatAddress(address),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () {
                    // TODO: Call controller to copy address
                    Clipboard.setData(ClipboardData(text: address));
                    // Show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
