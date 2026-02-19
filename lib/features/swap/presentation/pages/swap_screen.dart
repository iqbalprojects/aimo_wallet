import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../../wallet/presentation/controllers/auth_controller.dart';
import '../controllers/swap_controller.dart';
import '../../domain/entities/swap_quote.dart';

/// Swap Screen
///
/// UI for token swap functionality.
///
/// Features:
/// - Sell/Buy token selectors
/// - Sell amount input
/// - Slippage selector (0.5%, 1%, 2%, custom)
/// - Estimated buy amount display
/// - Gas estimate display
/// - Network indicator
/// - Get Quote / Approve / Swap buttons
///
/// Design:
/// - Dark crypto style
/// - Card-based layout
/// - Clear error display
/// - Disabled buttons when invalid state
/// - Responsive layout
///
/// Controller Integration:
/// - Uses SwapController for swap operations
/// - Uses NetworkController for network info
/// - Observes reactive state with Obx
/// - NO business logic in UI (controller hooks only)
class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  // UI-only state for slippage and token selection
  double _selectedSlippage = 0.005; // Default 0.5%
  TokenInfo? _sellToken;
  TokenInfo? _buyToken;
  final TextEditingController _amountController = TextEditingController();

  // Placeholder tokens - in production these would come from controller/token list
  static final List<TokenInfo> _availableTokens = [
    TokenInfo(
      symbol: 'ETH',
      name: 'Ethereum',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDT',
      name: 'Tether USD',
      address: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'DAI',
      name: 'Dai Stablecoin',
      address: '0x6B175474E89094C44Da98b954EesddFD659F90E',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'WETH',
      name: 'Wrapped ETH',
      address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
      decimals: 18,
    ),
  ];

  // Get controllers (will be injected by binding)
  SwapController get _swapController => Get.find<SwapController>();
  NetworkController get _networkController => Get.find<NetworkController>();
  AuthController get _authController => Get.find<AuthController>();

  /// Check if wallet is unlocked
  bool get _isWalletUnlocked {
    try {
      return _authController.isUnlocked;
    } catch (e) {
      return false;
    }
  }

  /// Navigate to unlock screen and return result
  Future<bool> _ensureWalletUnlocked() async {
    if (_isWalletUnlocked) return true;

    // Show message that wallet is locked
    Get.snackbar(
      'Wallet Locked',
      'Please unlock your wallet to continue',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.accentRed,
      colorText: AppTheme.textPrimary,
    );

    // Navigate to unlock screen
    final result = await Get.toNamed<bool>('/unlock');
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    // Set default tokens
    _sellToken = _availableTokens[0]; // ETH
    _buyToken = _availableTokens[1]; // USDT
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Swap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Network Indicator
                _buildNetworkIndicator(context),
                const SizedBox(height: AppTheme.spacingL),

                // Swap Card
                _buildSwapCard(context),
                const SizedBox(height: AppTheme.spacingL),

                // Error Display
                _buildErrorDisplay(context),
                const SizedBox(height: AppTheme.spacingL),

                // Action Buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Network indicator showing current network
  Widget _buildNetworkIndicator(BuildContext context) {
    return Container(
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
          Obx(() {
            final network = _networkController.currentNetwork;
            return Text(
              network?.name ?? 'No Network',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            );
          }),
        ],
      ),
    );
  }

  /// Main swap card with token selectors and inputs
  Widget _buildSwapCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sell Section
          _buildSellSection(context),
          const SizedBox(height: AppTheme.spacingM),

          // Swap Direction Indicator
          _buildSwapDirectionButton(context),
          const SizedBox(height: AppTheme.spacingM),

          // Buy Section
          _buildBuySection(context),
          const SizedBox(height: AppTheme.spacingL),

          // Divider
          const Divider(color: AppTheme.divider),
          const SizedBox(height: AppTheme.spacingL),

          // Slippage Selector
          _buildSlippageSelector(context),
          const SizedBox(height: AppTheme.spacingL),

          // Quote Info (estimated amount, gas)
          _buildQuoteInfo(context),
        ],
      ),
    );
  }

  /// Sell token section with selector and amount input
  Widget _buildSellSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Sell',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            children: [
              // Token Selector
              _buildTokenSelector(
                context,
                label: 'Sell Token',
                symbol: _sellToken?.symbol ?? 'Select',
                onTap: () => _showTokenSelector(context, 'sell'),
              ),
              const SizedBox(width: AppTheme.spacingM),

              // Amount Input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _amountController,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        // Clear quote when amount changes
                        _swapController.reset();
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Balance: 0.0', // TODO: Get from controller
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Buy token section with selector and estimated amount
  Widget _buildBuySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Buy (estimated)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            children: [
              // Token Selector
              _buildTokenSelector(
                context,
                label: 'Buy Token',
                symbol: _buyToken?.symbol ?? 'Select',
                onTap: () => _showTokenSelector(context, 'buy'),
              ),
              const SizedBox(width: AppTheme.spacingM),

              // Estimated Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(() {
                      final quote = _swapController.swapQuote;
                      final isLoading = _swapController.isLoading;

                      if (isLoading) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryPurple,
                          ),
                        );
                      }

                      return Text(
                        quote != null ? _formatAmount(quote.buyAmount) : '0.0',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    Obx(() {
                      final quote = _swapController.swapQuote;
                      if (quote == null) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '~\$0.00', // TODO: Calculate USD value
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Token selector button
  Widget _buildTokenSelector(
    BuildContext context, {
    required String label,
    required String symbol,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol.isNotEmpty ? symbol[0] : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              symbol.isEmpty ? 'Select' : symbol,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppTheme.spacingXS),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Swap direction button (swap sell/buy tokens)
  Widget _buildSwapDirectionButton(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          // Controller hook for swapping tokens
          _swapController.clearError();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.swap_vert,
            color: AppTheme.primaryPurple,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Slippage selector
  Widget _buildSlippageSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Slippage Tolerance',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            Obx(() {
              final step = _swapController.currentStep;
              if (step == SwapStep.gettingQuote) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryPurple,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            _buildSlippageOption(context, '0.5%', 0.005),
            const SizedBox(width: AppTheme.spacingS),
            _buildSlippageOption(context, '1%', 0.01),
            const SizedBox(width: AppTheme.spacingS),
            _buildSlippageOption(context, '2%', 0.02),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(child: _buildCustomSlippageInput(context)),
          ],
        ),
      ],
    );
  }

  /// Individual slippage option button
  Widget _buildSlippageOption(
    BuildContext context,
    String label,
    double value,
  ) {
    final isSelected = _selectedSlippage == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSlippage = value;
        });
        // Controller hook for slippage selection
        _swapController.clearError();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Custom slippage input field
  Widget _buildCustomSlippageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                hintText: 'Custom',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                // Controller hook for custom slippage
                _swapController.clearError();
              },
            ),
          ),
          Text(
            '%',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Quote information display (gas estimate, rates)
  Widget _buildQuoteInfo(BuildContext context) {
    return Obx(() {
      final quote = _swapController.swapQuote;
      final isLoading = _swapController.isLoading;

      if (quote == null && !isLoading) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          // Gas Estimate
          _buildInfoRow(
            context,
            'Estimated Gas',
            isLoading ? 'Loading...' : _formatGasEstimate(quote?.gas),
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Gas Fee
          _buildInfoRow(
            context,
            'Network Fee',
            isLoading ? 'Loading...' : '~\$0.00',
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Rate
          _buildInfoRow(
            context,
            'Rate',
            isLoading ? 'Loading...' : '1 ETH = 0 USDT',
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Price Impact
          _buildInfoRow(
            context,
            'Price Impact',
            isLoading ? 'Loading...' : '<0.01%',
            valueColor: AppTheme.accentGreen,
          ),
        ],
      );
    });
  }

  /// Info row for quote details
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor ?? AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Error display
  Widget _buildErrorDisplay(BuildContext context) {
    return Obx(() {
      final error = _swapController.errorMessage;

      if (error == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.accentRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentRed,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                error,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.accentRed),
              ),
            ),
            InkWell(
              onTap: () => _swapController.clearError(),
              child: const Icon(
                Icons.close,
                color: AppTheme.accentRed,
                size: 18,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Action buttons (Get Quote, Approve, Swap)
  Widget _buildActionButtons(BuildContext context) {
    return Obx(() {
      final step = _swapController.currentStep;
      final isLoading = _swapController.isLoading;
      final needsApproval = _swapController.needsApproval;
      final hasQuote = _swapController.swapQuote != null;
      final canSwap = _swapController.canSwap;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Action Button
          _buildPrimaryButton(
            context,
            step: step,
            isLoading: isLoading,
            needsApproval: needsApproval,
            hasQuote: hasQuote,
            canSwap: canSwap,
          ),

          // Approve Button (shown when approval needed)
          if (needsApproval && hasQuote) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildApproveButton(context, isLoading: isLoading, step: step),
          ],
        ],
      );
    });
  }

  /// Primary action button (Get Quote or Swap)
  Widget _buildPrimaryButton(
    BuildContext context, {
    required SwapStep step,
    required bool isLoading,
    required bool needsApproval,
    required bool hasQuote,
    required bool canSwap,
  }) {
    String label;
    bool enabled;
    VoidCallback? onTap;

    if (!hasQuote) {
      label = 'Get Quote';
      enabled = !isLoading;
      onTap = () => _getQuote();
    } else if (needsApproval) {
      label = 'Waiting for Approval...';
      enabled = false;
      onTap = null;
    } else {
      label = 'Swap';
      // Swap enabled only when: allowance sufficient, valid quote, wallet unlocked
      enabled = canSwap;
      onTap = canSwap ? () => _showSwapConfirmation(context) : null;
    }

    return _buildButton(
      context,
      label: label,
      isLoading: isLoading && step != SwapStep.needsApproval,
      enabled: enabled,
      isPrimary: true,
      onTap: onTap,
    );
  }

  /// Approve button (shown when token needs approval)
  Widget _buildApproveButton(
    BuildContext context, {
    required bool isLoading,
    required SwapStep step,
  }) {
    // Disable during any approval-related step
    final isApproveInProgress =
        isLoading ||
        step == SwapStep.signingApproval ||
        step == SwapStep.approvalReady;

    return _buildButton(
      context,
      label: 'Approve Token',
      isLoading: isApproveInProgress,
      enabled: !isApproveInProgress,
      isPrimary: false,
      onTap: () => _showApproveConfirmation(context),
    );
  }

  /// Reusable button widget
  Widget _buildButton(
    BuildContext context, {
    required String label,
    required bool isLoading,
    required bool enabled,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    final backgroundColor = isPrimary
        ? AppTheme.primaryPurple
        : AppTheme.surfaceDark;
    final textColor = isPrimary ? AppTheme.textPrimary : AppTheme.primaryPurple;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: AppTheme.primaryPurple, width: 1),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textPrimary,
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Show token selector bottom sheet
  void _showTokenSelector(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TokenSelectorSheet(
        tokens: _availableTokens,
        selectedToken: type == 'sell' ? _sellToken : _buyToken,
        excludeToken: type == 'sell' ? _buyToken : _sellToken,
        onSelect: (token) {
          setState(() {
            if (type == 'sell') {
              _sellToken = token;
            } else {
              _buyToken = token;
            }
          });
          // Clear quote when tokens change
          _swapController.reset();
          Get.back();
        },
      ),
    );
  }

  /// Get quote from controller
  Future<void> _getQuote() async {
    // Validate inputs
    if (_sellToken == null || _buyToken == null) {
      Get.snackbar(
        'Error',
        'Please select both tokens',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
      );
      return;
    }

    // Parse amount to BigInt (in smallest units)
    final amount = _parseAmountToBigInt(amountText, _sellToken!.decimals);
    if (amount == null || amount <= BigInt.zero) {
      Get.snackbar(
        'Error',
        'Invalid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
      );
      return;
    }

    // Call controller to get quote
    final quote = await _swapController.getQuote(
      sellToken: _sellToken!.address,
      buyToken: _buyToken!.address,
      sellAmount: amount,
      slippage: _selectedSlippage,
    );

    if (quote != null) {
      // Prepare swap (check balance and allowance)
      await _swapController.prepareSwap(
        tokenAddress: _sellToken!.address,
        spenderAddress: quote.allowanceTarget,
        sellAmount: amount,
      );
    }
  }

  /// Parse decimal amount string to BigInt
  BigInt? _parseAmountToBigInt(String amount, int decimals) {
    try {
      final parts = amount.split('.');
      final integerPart = parts[0].isEmpty ? '0' : parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      // Pad or truncate decimal part
      final paddedDecimal = decimalPart.length >= decimals
          ? decimalPart.substring(0, decimals)
          : decimalPart.padRight(decimals, '0');

      final weiString = '$integerPart$paddedDecimal'.replaceFirst(
        RegExp(r'^0+'),
        '',
      );
      if (weiString.isEmpty) return BigInt.zero;
      return BigInt.parse(weiString);
    } catch (e) {
      return null;
    }
  }

  /// Show approve confirmation dialog with PIN input
  Future<void> _showApproveConfirmation(BuildContext context) async {
    // Check wallet lock state first
    if (!_isWalletUnlocked) {
      final unlocked = await _ensureWalletUnlocked();
      if (!unlocked) return;
    }

    final quote = _swapController.swapQuote;
    if (quote == null || _sellToken == null) return;

    // Build approval transaction first
    final neededAllowance = _swapController.neededAllowance ?? quote.sellAmount;
    await _swapController.buildApproveTransaction(
      tokenAddress: _sellToken!.address,
      spenderAddress: quote.allowanceTarget,
      amount: neededAllowance,
    );

    if (_swapController.approveTransaction == null) {
      return; // Error already set in controller
    }

    // Show PIN input dialog (uses Get.dialog, not context)
    final pin = await _showPinInputDialog('Approve Token');
    if (pin == null) return;

    // Sign and broadcast approval
    final txHash = await _swapController.signAndBroadcastApproval(
      tokenAddress: _sellToken!.address,
      pin: pin,
    );

    if (txHash != null) {
      Get.snackbar(
        'Approval Submitted',
        'Transaction: ${_shortenHash(txHash)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: AppTheme.accentGreen,
        colorText: AppTheme.textPrimary,
      );
    }
  }

  /// Show swap confirmation dialog with PIN input
  Future<void> _showSwapConfirmation(BuildContext context) async {
    // Check wallet lock state first
    if (!_isWalletUnlocked) {
      final unlocked = await _ensureWalletUnlocked();
      if (!unlocked) return;
    }

    final quote = _swapController.swapQuote;
    if (quote == null) return;

    // Show SwapReviewModal
    final result = await Get.dialog<SwapReviewResult>(
      SwapReviewModal(
        sellToken: _sellToken!,
        buyToken: _buyToken!,
        sellAmount: _amountController.text,
        buyAmount: quote.buyAmount,
        slippage: _selectedSlippage,
        gasFee: _estimateGasFee(quote),
        gasEstimate: quote.gas,
      ),
    );

    if (result == null || !result.confirmed) return;

    // Show PIN input dialog (uses Get.dialog, not context)
    final pin = await _showPinInputDialog('Confirm Swap');
    if (pin == null) return;

    // Execute swap - controller call only
    final txHash = await _swapController.executeSwap(pin: pin);

    if (txHash != null) {
      Get.snackbar(
        'Swap Submitted',
        'Transaction: ${_shortenHash(txHash)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: AppTheme.accentGreen,
        colorText: AppTheme.textPrimary,
      );

      // Clear state after successful swap
      _swapController.reset();
      _amountController.clear();
    }
  }

  /// Show PIN input dialog
  Future<String?> _showPinInputDialog(String title) async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Get.dialog<String>(
      AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text(title, style: Theme.of(Get.context!).textTheme.titleLarge),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your PIN to confirm',
                style: Theme.of(
                  Get.context!,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(
                  Get.context!,
                ).textTheme.titleLarge?.copyWith(letterSpacing: 8),
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Get.back(result: pinController.text);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Estimate gas fee in USD (placeholder)
  String _estimateGasFee(SwapQuote quote) {
    // Simple estimation - in production use gas price oracle
    final gasEth = (quote.gas * quote.gasPrice) / BigInt.from(10).pow(18);
    return gasEth.toStringAsFixed(4);
  }

  /// Shorten transaction hash for display
  String _shortenHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';
  }

  /// Format BigInt amount to readable string
  String _formatAmount(BigInt amount) {
    // Simple formatting - in production use proper decimal conversion
    final str = amount.toString();
    if (str.length <= 18) {
      return '0.${str.padLeft(18, '0').substring(0, 4)}';
    }
    final integerPart = str.substring(0, str.length - 18);
    final decimalPart = str.substring(str.length - 18, str.length - 14);
    return '$integerPart.$decimalPart';
  }

  /// Format gas estimate
  String _formatGasEstimate(BigInt? gas) {
    if (gas == null) return '0';
    return gas.toString();
  }
}

/// Token Selector Bottom Sheet
///
/// Shows list of available tokens for selection.
class _TokenSelectorSheet extends StatelessWidget {
  final List<TokenInfo> tokens;
  final TokenInfo? selectedToken;
  final TokenInfo? excludeToken;
  final Function(TokenInfo) onSelect;

  const _TokenSelectorSheet({
    required this.tokens,
    this.selectedToken,
    this.excludeToken,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Title
          Text(
            'Select Token',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Search (placeholder)
          TextField(
            decoration: InputDecoration(
              hintText: 'Search token name or paste address',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Token List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tokens.length,
              itemBuilder: (context, index) {
                final token = tokens[index];
                // Skip excluded token (can't swap same token)
                if (excludeToken != null &&
                    token.symbol == excludeToken!.symbol) {
                  return const SizedBox.shrink();
                }
                return _buildTokenItem(
                  context,
                  token,
                  isSelected: token.symbol == selectedToken?.symbol,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(
    BuildContext context,
    TokenInfo token, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () => onSelect(token),
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            // Token Icon
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  token.symbol[0],
                  style: const TextStyle(
                    fontSize: 18,
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
                    token.symbol,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    token.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Token info model for selection
class TokenInfo {
  final String symbol;
  final String name;
  final String address;
  final int decimals;

  TokenInfo({
    required this.symbol,
    required this.name,
    required this.address,
    required this.decimals,
  });
}

/// Result from SwapReviewModal
class SwapReviewResult {
  final bool confirmed;

  SwapReviewResult({required this.confirmed});
}

/// Swap Review Modal
///
/// Displays swap details for user confirmation.
/// No business logic - only displays data and returns user decision.
///
/// Display:
/// - Sell token & amount
/// - Buy token & estimated amount
/// - Slippage percentage
/// - Gas fee estimate
/// - Warning if slippage > 2%
///
/// Buttons:
/// - Cancel
/// - Confirm Swap
class SwapReviewModal extends StatelessWidget {
  final TokenInfo sellToken;
  final TokenInfo buyToken;
  final String sellAmount;
  final BigInt buyAmount;
  final double slippage;
  final String gasFee;
  final BigInt gasEstimate;

  const SwapReviewModal({
    super.key,
    required this.sellToken,
    required this.buyToken,
    required this.sellAmount,
    required this.buyAmount,
    required this.slippage,
    required this.gasFee,
    required this.gasEstimate,
  });

  /// Format BigInt amount to readable string
  String _formatAmount(BigInt amount) {
    final str = amount.toString();
    if (str.length <= 18) {
      return '0.${str.padLeft(18, '0').substring(0, 4)}';
    }
    final integerPart = str.substring(0, str.length - 18);
    final decimalPart = str.substring(str.length - 18, str.length - 14);
    return '$integerPart.$decimalPart';
  }

  bool get _isHighSlippage => slippage > 0.02;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Review Swap',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Swap details card
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  // Sell row
                  _buildDetailRow(
                    context,
                    'You Sell',
                    '$sellAmount ${sellToken.symbol}',
                    isPrimary: true,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Arrow
                  const Icon(
                    Icons.arrow_downward,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Buy row
                  _buildDetailRow(
                    context,
                    'You Get (est.)',
                    '~${_formatAmount(buyAmount)} ${buyToken.symbol}',
                    isPrimary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Details section
            _buildDetailRow(
              context,
              'Slippage',
              '${(slippage * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildDetailRow(context, 'Gas Fee', '~$gasFee ETH'),
            const SizedBox(height: AppTheme.spacingS),
            _buildDetailRow(context, 'Gas Limit', gasEstimate.toString()),

            // High slippage warning
            if (_isHighSlippage) ...[
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(
                    color: AppTheme.accentRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppTheme.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        'High slippage selected. Your swap may be executed at a less favorable rate.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacingL),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        Get.back(result: SwapReviewResult(confirmed: false)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Get.back(result: SwapReviewResult(confirmed: true)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: const Text('Confirm Swap'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isPrimary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isPrimary ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
