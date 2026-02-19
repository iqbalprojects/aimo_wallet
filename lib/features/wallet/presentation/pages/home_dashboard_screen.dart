import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../controllers/wallet_controller.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../../network_switch/presentation/widgets/network_selector_sheet.dart';

/// Home Dashboard Screen
///
/// Main screen showing wallet balance and tokens.
///
/// Features:
/// - Network indicator at top
/// - Wallet address display (shortened with copy) - REACTIVE
/// - Total balance section with USD value - REACTIVE
/// - Quick actions (Send, Receive, Swap)
/// - Token list with placeholder data
/// - Lock button in app bar
/// - Pull to refresh
/// - Responsive layout
///
/// Controller Integration:
/// - Uses WalletController for address and balance
/// - Observes reactive state with Obx
/// - Address displayed from controller.currentAddress
/// - Balance displayed from controller.balance
///
/// SECURITY:
/// - Address is public info (safe to display)
/// - No sensitive data displayed
/// - Lock button clears sensitive data
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  // Get WalletController (will be injected by binding)
  WalletController get _walletController => Get.find<WalletController>();

  // Get NetworkController (will be injected by binding)
  NetworkController get _networkController => Get.find<NetworkController>();

  String _shortenAddress(String address) {
    if (address.isEmpty || address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyAddress(String address) {
    if (address.isEmpty) return;

    Clipboard.setData(ClipboardData(text: address));
    Get.snackbar(
      'Copied',
      'Address copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
    );
  }

  void _lockWallet() {
    // Lock wallet and navigate to unlock screen
    NavigationHelper.lockWallet();
  }

  void _changeNetwork() {
    // Show network selection bottom sheet
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NetworkSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Wallet'),
        actions: [
          // Lock Button
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: _lockWallet,
            tooltip: 'Lock Wallet',
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => NavigationHelper.navigateToSettings(),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh balance from blockchain
            await _walletController.refreshBalance();
          },
          color: AppTheme.primaryPurple,
          backgroundColor: AppTheme.surfaceDark,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Network Indicator
                    _buildNetworkIndicator(context),

                    const SizedBox(height: AppTheme.spacingL),

                    // Wallet Address
                    _buildAddressSection(context),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Total Balance Card
                    _buildBalanceCard(context),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Quick Actions
                    _buildQuickActions(context),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Tokens Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assets',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to add token screen
                            },
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingM),
                  ],
                ),
              ),

              // Token List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTokenItem(
                      context,
                      symbol: 'ETH',
                      name: 'Ethereum',
                      balance: '1.234',
                      usdValue: '2,468.00',
                      change24h: '+5.2%',
                      isPositive: true,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildTokenItem(
                      context,
                      symbol: 'USDT',
                      name: 'Tether USD',
                      balance: '1,000.00',
                      usdValue: '1,000.00',
                      change24h: '+0.1%',
                      isPositive: true,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildTokenItem(
                      context,
                      symbol: 'DAI',
                      name: 'Dai Stablecoin',
                      balance: '500.00',
                      usdValue: '500.00',
                      change24h: '-0.2%',
                      isPositive: false,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildTokenItem(
                      context,
                      symbol: 'USDC',
                      name: 'USD Coin',
                      balance: '0.00',
                      usdValue: '0.00',
                      change24h: '0.0%',
                      isPositive: true,
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: InkWell(
        onTap: _changeNetwork,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              // REACTIVE: Observe current network from NetworkController
              Obx(() {
                final network = _networkController.currentNetwork;
                return Text(
                  network?.name ?? 'No Network',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                );
              }),
              const SizedBox(width: AppTheme.spacingS),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // REACTIVE: Observe address from WalletController
          Obx(() {
            final address = _walletController.currentAddress.value;
            return Text(
              address.isEmpty ? 'No address' : _shortenAddress(address),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                color: AppTheme.textSecondary,
              ),
            );
          }),
          const SizedBox(width: AppTheme.spacingS),
          // REACTIVE: Only show copy button if address exists
          Obx(() {
            final address = _walletController.currentAddress.value;
            if (address.isEmpty) return const SizedBox.shrink();

            return InkWell(
              onTap: () => _copyAddress(address),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: AppTheme.primaryPurple.withValues(alpha: 0.8),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // REACTIVE: Observe balance USD from WalletController
          Obx(
            () => Text(
              '\$${_walletController.balanceUsd}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          // REACTIVE: Observe balance ETH from WalletController
          Obx(
            () => Text(
              '${_walletController.balance} ETH',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              'Send',
              Icons.arrow_upward_rounded,
              () => NavigationHelper.navigateToSend(),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: _buildActionButton(
              context,
              'Receive',
              Icons.arrow_downward_rounded,
              () => NavigationHelper.navigateToReceive(),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: _buildActionButton(
              context,
              'Swap',
              Icons.swap_horiz_rounded,
              () => NavigationHelper.navigateToSwap(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textPrimary, size: 24),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenItem(
    BuildContext context, {
    required String symbol,
    required String name,
    required String balance,
    required String usdValue,
    required String change24h,
    required bool isPositive,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to token details
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Token Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Balance and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$$usdValue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      change24h,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
