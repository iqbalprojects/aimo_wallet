import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../network_switch/presentation/controllers/network_controller.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';
import '../../../swap/domain/usecases/get_token_balance_usecase.dart';
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
  final TextEditingController _customSlippageController =
      TextEditingController();
  Timer? _quoteExpiryTimer;
  int _quoteSecondsRemaining = 0;
  Timer? _debounceTimer;

  // Per-network token balance state
  String _sellTokenBalance = '...';
  bool _isLoadingBalance = false;

  // Token lists per network (dynamic, based on active chainId)
  // Default tokens for Ethereum Mainnet (chainId: 1)
  static final List<TokenInfo> _ethereumTokens = [
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
      address: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'WETH',
      name: 'Wrapped ETH',
      address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
      decimals: 18,
    ),
  ];

  static final List<TokenInfo> _polygonTokens = [
    TokenInfo(
      symbol: 'MATIC',
      name: 'Polygon',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDT',
      name: 'Tether USD',
      address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'WETH',
      name: 'Wrapped ETH',
      address: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
      decimals: 18,
    ),
  ];

  static final List<TokenInfo> _bscTokens = [
    TokenInfo(
      symbol: 'BNB',
      name: 'BNB',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDT',
      name: 'Tether USD',
      address: '0x55d398326f99059fF775485246999027B3197955',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'WBNB',
      name: 'Wrapped BNB',
      address: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
      decimals: 18,
    ),
  ];

  static final List<TokenInfo> _baseTokens = [
    TokenInfo(
      symbol: 'ETH',
      name: 'Ethereum',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'DAI',
      name: 'Dai Stablecoin',
      address: '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb',
      decimals: 18,
    ),
  ];

  static final List<TokenInfo> _arbitrumTokens = [
    TokenInfo(
      symbol: 'ETH',
      name: 'Ethereum',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDT',
      name: 'Tether USD',
      address: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'WETH',
      name: 'Wrapped ETH',
      address: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
      decimals: 18,
    ),
  ];

  static final List<TokenInfo> _optimismTokens = [
    TokenInfo(
      symbol: 'ETH',
      name: 'Ethereum',
      address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      decimals: 18,
    ),
    TokenInfo(
      symbol: 'USDT',
      name: 'Tether USD',
      address: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'USDC',
      name: 'USD Coin',
      address: '0x7F5c764cBc14f9669B88837ca1490cCa17c31607',
      decimals: 6,
    ),
    TokenInfo(
      symbol: 'WETH',
      name: 'Wrapped ETH',
      address: '0x4200000000000000000000000000000000000006',
      decimals: 18,
    ),
  ];

  /// Get token list for current network
  List<TokenInfo> get _availableTokens {
    final chainId = _networkController.currentNetwork?.chainId;
    switch (chainId) {
      case 1:
        return _ethereumTokens; // Ethereum Mainnet
      case 137:
        return _polygonTokens; // Polygon
      case 56:
        return _bscTokens; // BSC
      case 8453:
        return _baseTokens; // Base
      case 42161:
        return _arbitrumTokens; // Arbitrum
      case 10:
        return _optimismTokens; // Optimism
      default:
        return _ethereumTokens; // Fallback to Ethereum tokens
    }
  }

  // Get controllers (will be injected by binding)
  SwapController get _swapController => Get.find<SwapController>();
  NetworkController get _networkController => Get.find<NetworkController>();

  @override
  void initState() {
    super.initState();
    // Set default tokens based on current network
    final tokens = _availableTokens;
    _sellToken = tokens.isNotEmpty ? tokens[0] : null; // Native token
    _buyToken = tokens.length > 1 ? tokens[1] : null; // First stablecoin
    // Fetch initial balance for selected sell token
    if (_sellToken != null) {
      _fetchSellTokenBalance();
    }
  }

  /// Fetch token balance for the currently selected sell token.
  Future<void> _fetchSellTokenBalance() async {
    if (_sellToken == null) return;
    final walletAddress = Get.find<WalletController>().currentAddress.value;
    if (walletAddress.isEmpty) return;

    setState(() {
      _isLoadingBalance = true;
      _sellTokenBalance = '...';
    });

    try {
      final useCase = Get.find<GetTokenBalanceUseCase>();
      final balance = await useCase.call(
        tokenAddress: _sellToken!.address,
        walletAddress: walletAddress,
        decimals: _sellToken!.decimals,
        symbol: _sellToken!.symbol,
      );
      if (mounted) {
        setState(() {
          _sellTokenBalance = balance.toDecimalString(maxDecimals: 6);
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sellTokenBalance = 'N/A';
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.dispose();
    _customSlippageController.dispose();
    _quoteExpiryTimer?.cancel();
    super.dispose();
  }

  void _onInputsChanged() {
    _swapController.reset();
    _stopQuoteExpiryTimer();
    _debounceTimer?.cancel();

    if (_sellToken == null || _buyToken == null) return;

    final value = _amountController.text.trim();
    if (value.isEmpty) return;

    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return;

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _getQuote();
      }
    });
  }

  /// Start 30-second quote expiry countdown
  void _startQuoteExpiryTimer() {
    _quoteExpiryTimer?.cancel();
    setState(() => _quoteSecondsRemaining = 30);
    _quoteExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _quoteSecondsRemaining--;
        if (_quoteSecondsRemaining <= 0) {
          timer.cancel();
          _getQuote();
        }
      });
    });
  }

  void _stopQuoteExpiryTimer() {
    _quoteExpiryTimer?.cancel();
    setState(() => _quoteSecondsRemaining = 0);
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

  /// Network indicator showing current network (Clickable to switch)
  Widget _buildNetworkIndicator(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () => _showNetworkSelector(context),
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
              Obx(() {
                final network = _networkController.currentNetwork;
                return Text(
                  network?.name ?? 'All Networks',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                );
              }),
              const SizedBox(width: AppTheme.spacingS),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show network selection bottom sheet
  void _showNetworkSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(
                  'Switch Network',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(color: AppTheme.divider, height: 1),
              Obx(() {
                final networks = _networkController.networks;
                final currentNetwork = _networkController.currentNetwork;

                final mainnets = networks.where((n) => !n.isTestnet).toList();
                final testnets = networks.where((n) => n.isTestnet).toList();

                Widget buildNetworkTile(dynamic network) {
                  final isSelected = network.id == currentNetwork?.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceDark,
                      radius: 16,
                      child: Text(
                        network.symbol.substring(0, 1),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      network.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryPurple
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryPurple,
                          )
                        : null,
                    onTap: () async {
                      Get.back(); // Close bottom sheet

                      // Switch network
                      await _networkController.switchNetwork(network);

                      if (mounted) {
                        setState(() {
                          final tokens = _availableTokens;
                          _sellToken = tokens.isNotEmpty ? tokens[0] : null;
                          _buyToken = tokens.length > 1 ? tokens[1] : null;
                        });
                        _fetchSellTokenBalance();
                      }

                      Get.snackbar(
                        'Network Switched',
                        'Successfully switched to ${network.name}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppTheme.surfaceDark,
                        colorText: AppTheme.textPrimary,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  );
                }

                return Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (mainnets.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppTheme.spacingL,
                            right: AppTheme.spacingL,
                            top: AppTheme.spacingM,
                            bottom: AppTheme.spacingS,
                          ),
                          child: Text(
                            'Mainnets',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...mainnets.map((n) => buildNetworkTile(n)),
                      ],
                      if (testnets.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppTheme.spacingL,
                            right: AppTheme.spacingL,
                            top: AppTheme.spacingM,
                            bottom: AppTheme.spacingS,
                          ),
                          child: Text(
                            'Testnets',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...testnets.map((n) => buildNetworkTile(n)),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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
                        _onInputsChanged();
                      },
                    ),
                    const SizedBox(height: 2),
                    // Display actual balance for selected sell token
                    Text(
                      _isLoadingBalance
                          ? 'Balance: ...'
                          : 'Balance: $_sellTokenBalance ${_sellToken?.symbol ?? ""}',
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
                        quote != null
                            ? _formatAmount(
                                quote.buyAmount,
                                decimals: _buyToken?.decimals ?? 18,
                              )
                            : '0.0',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    Obx(() {
                      final quote = _swapController.swapQuote;
                      if (quote == null) return const SizedBox.shrink();
                      // Estimate USD value using ETH gas price as rough proxy
                      // In production: integrate a price oracle (CoinGecko, etc.)
                      final buyAmtDecimal = _formatAmountDouble(
                        quote.buyAmount,
                        decimals: _buyToken?.decimals ?? 18,
                      );
                      final usdEstimate = _estimateUsdValue(
                        buyAmtDecimal,
                        _buyToken?.symbol ?? '',
                      );
                      return Text(
                        usdEstimate != null ? '≈\$$usdEstimate USD' : '',
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
          setState(() {
            final temp = _sellToken;
            _sellToken = _buyToken;
            _buyToken = temp;
          });
          _fetchSellTokenBalance();
          _onInputsChanged();
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
        _onInputsChanged();
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
    final isCustomSelected = ![0.005, 0.01, 0.02].contains(_selectedSlippage);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isCustomSelected ? AppTheme.primaryPurple : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: isCustomSelected
              ? AppTheme.primaryPurple
              : AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customSlippageController,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isCustomSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
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
                final parsed = double.tryParse(value);
                if (parsed != null && parsed > 0 && parsed <= 50) {
                  setState(() {
                    _selectedSlippage = parsed / 100;
                  });
                  _onInputsChanged();
                }
              },
            ),
          ),
          Text(
            '%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isCustomSelected
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
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

      // Calculate rate: how many buyTokens per 1 sellToken
      String rateText = 'Loading...';
      String networkFeeText = 'Loading...';
      String priceImpactText = 'Loading...';

      if (quote != null && _sellToken != null && _buyToken != null) {
        final sellDecimals = _sellToken!.decimals;
        final buyDecimals = _buyToken!.decimals;

        if (quote.sellAmount > BigInt.zero) {
          final sellD = quote.sellAmount / BigInt.from(10).pow(sellDecimals);
          final buyD = quote.buyAmount / BigInt.from(10).pow(buyDecimals);
          if (sellD > 0) {
            final rate = buyD / sellD;
            rateText =
                '1 ${_sellToken!.symbol} = ${rate.toStringAsFixed(6)} ${_buyToken!.symbol}';
          }
        }

        // Network fee in ETH
        final feeWei = quote.gas * quote.gasPrice;
        final feeEth = feeWei / BigInt.from(10).pow(18);
        networkFeeText = '~${feeEth.toStringAsFixed(6)} ETH';

        // Price impact: use real data from 0x API v2 (estimatedPriceImpact)
        priceImpactText = quote.priceImpactText;
      }

      return Column(
        children: [
          // Quote expiry countdown
          if (_quoteSecondsRemaining > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: _quoteSecondsRemaining <= 10
                      ? AppTheme.accentRed
                      : AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Refreshing in ${_quoteSecondsRemaining}s...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _quoteSecondsRemaining <= 10
                        ? AppTheme.accentGreen
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // Gas Estimate
          _buildInfoRow(
            context,
            'Gas Limit',
            isLoading ? 'Loading...' : _formatGasEstimate(quote?.gas),
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Gas Fee
          _buildInfoRow(
            context,
            'Network Fee',
            isLoading ? 'Loading...' : networkFeeText,
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Rate
          _buildInfoRow(context, 'Rate', isLoading ? 'Loading...' : rateText),
          const SizedBox(height: AppTheme.spacingS),

          // Price Impact
          _buildInfoRow(
            context,
            'Price Impact',
            isLoading ? 'Loading...' : priceImpactText,
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

    final amountText = _amountController.text.trim();
    final parsed = double.tryParse(amountText);
    final hasValidAmount =
        amountText.isNotEmpty && parsed != null && parsed > 0;

    if (!hasValidAmount) {
      label = 'Enter Amount';
      enabled = false;
      onTap = null;
    } else if (isLoading) {
      label = 'Fetching Quote...';
      enabled = false;
      onTap = null;
    } else if (!hasQuote) {
      label = 'Get Quote';
      enabled = true; // Allow manual retry
      onTap = () => _getQuote();
    } else if (needsApproval) {
      label = 'Waiting for Approval...';
      enabled = false;
      onTap = null;
    } else {
      label = 'Swap';
      // Enable swap button when: allowance sufficient, valid quote, not loading
      // Wallet unlock is handled by _showSwapConfirmation when tapped
      final swapReady = hasQuote && !needsApproval && !isLoading;
      enabled = swapReady;
      onTap = swapReady ? () => _showSwapConfirmation(context) : null;
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
          if (type == 'sell') {
            _fetchSellTokenBalance();
          }
          _onInputsChanged();
          Get.back();
        },
      ),
    );
  }

  /// Get quote from controller
  ///
  /// Getting a quote is a read-only API call that does NOT need
  /// private keys or wallet unlocking. It only needs the wallet
  /// address (public info) as the taker address.
  ///
  /// The wallet must only be unlocked later for:
  /// - Token approval (signing)
  /// - Swap execution (signing)
  Future<void> _getQuote() async {
    _debounceTimer?.cancel();
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

    _stopQuoteExpiryTimer();

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
      // Start expiry countdown after quote is ready
      _startQuoteExpiryTimer();
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
      _fetchSellTokenBalance();
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

  /// Format BigInt amount to readable string using token decimals
  String _formatAmount(BigInt amount, {int decimals = 18}) {
    if (amount == BigInt.zero) return '0';
    final str = amount.toString();
    if (str.length <= decimals) {
      final padded = str.padLeft(decimals, '0');
      final trimmed = padded.replaceAll(RegExp(r'0+$'), '');
      if (trimmed.isEmpty) return '0';
      return '0.$trimmed';
    }
    final integerPart = str.substring(0, str.length - decimals);
    final decimalPart = str.substring(str.length - decimals);
    final trimmedDecimal = decimalPart
        .substring(0, decimals.clamp(0, 6))
        .replaceAll(RegExp(r'0+$'), '');
    if (trimmedDecimal.isEmpty) return integerPart;
    return '$integerPart.$trimmedDecimal';
  }

  /// Format gas estimate
  String _formatGasEstimate(BigInt? gas) {
    if (gas == null) return '0';
    return gas.toString();
  }

  /// Format BigInt amount to double for calculations
  double _formatAmountDouble(BigInt amount, {int decimals = 18}) {
    if (amount == BigInt.zero) return 0.0;
    final str = amount.toString().padLeft(decimals + 1, '0');
    final intPart = str.substring(0, str.length - decimals);
    final decPart = str.substring(str.length - decimals);
    return double.tryParse('$intPart.$decPart') ?? 0.0;
  }

  /// Estimate USD value for common stablecoins.
  /// Returns null for non-stablecoin tokens (no reliable price without oracle).
  /// In production: integrate CoinGecko, Chainlink Price Feeds, or similar.
  String? _estimateUsdValue(double amount, String symbol) {
    if (amount <= 0) return null;
    // For stablecoins: 1:1 with USD
    const stablecoins = ['USDT', 'USDC', 'DAI', 'BUSD', 'TUSD', 'FRAX'];
    if (stablecoins.contains(symbol.toUpperCase())) {
      return amount.toStringAsFixed(2);
    }
    // For other tokens: cannot estimate without price oracle
    return null;
  }
}

/// Token Selector Bottom Sheet
///
/// Shows list of available tokens for selection with working search/filter.
class _TokenSelectorSheet extends StatefulWidget {
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
  State<_TokenSelectorSheet> createState() => _TokenSelectorSheetState();
}

class _TokenSelectorSheetState extends State<_TokenSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<TokenInfo> _filteredTokens = [];

  @override
  void initState() {
    super.initState();
    _filteredTokens = _getVisibleTokens(widget.tokens);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<TokenInfo> _getVisibleTokens(List<TokenInfo> tokens) {
    return tokens
        .where((t) => t.symbol != widget.excludeToken?.symbol)
        .toList();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    final visible = _getVisibleTokens(widget.tokens);
    setState(() {
      if (query.isEmpty) {
        _filteredTokens = visible;
      } else {
        _filteredTokens = visible.where((t) {
          return t.symbol.toLowerCase().contains(query) ||
              t.name.toLowerCase().contains(query) ||
              t.address.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

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

          // Search (fully functional with filter)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search token name, symbol or address',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
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
            child: _filteredTokens.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Text(
                        'No tokens found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredTokens.length,
                    itemBuilder: (context, index) {
                      final token = _filteredTokens[index];
                      return _buildTokenItem(
                        context,
                        token,
                        isSelected:
                            token.symbol == widget.selectedToken?.symbol,
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
      onTap: () => widget.onSelect(token),
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

  const TokenInfo({
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

  /// Format BigInt amount to readable string using token decimals
  String _formatAmount(BigInt amount, {int decimals = 18}) {
    if (amount == BigInt.zero) return '0';
    final str = amount.toString();
    if (str.length <= decimals) {
      final padded = str.padLeft(decimals, '0');
      final trimmed = padded.replaceAll(RegExp(r'0+$'), '');
      if (trimmed.isEmpty) return '0';
      return '0.$trimmed';
    }
    final integerPart = str.substring(0, str.length - decimals);
    final decimalPart = str.substring(str.length - decimals);
    final trimmedDecimal = decimalPart
        .substring(0, decimals.clamp(0, 6))
        .replaceAll(RegExp(r'0+$'), '');
    if (trimmedDecimal.isEmpty) return integerPart;
    return '$integerPart.$trimmedDecimal';
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
                    '~${_formatAmount(buyAmount, decimals: buyToken.decimals)} ${buyToken.symbol}',
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
