import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Token List Item
/// 
/// Displays token information in a list.
/// 
/// Usage:
/// ```dart
/// TokenListItem(
///   symbol: 'ETH',
///   name: 'Ethereum',
///   balance: '1.234',
///   usdValue: '2,468.00',
///   change24h: '+5.2',
///   onTap: () => controller.selectToken('ETH'),
/// )
/// ```
class TokenListItem extends StatelessWidget {
  final String symbol;
  final String name;
  final String balance;
  final String usdValue;
  final String? change24h;
  final String? iconUrl;
  final VoidCallback? onTap;

  const TokenListItem({
    super.key,
    required this.symbol,
    required this.name,
    required this.balance,
    required this.usdValue,
    this.change24h,
    this.iconUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change24h != null && !change24h!.startsWith('-');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            // Token Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol[0],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),

            // Token Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Balance and Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$$usdValue',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (change24h != null) ...[
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        change24h!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPositive
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentRed,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
