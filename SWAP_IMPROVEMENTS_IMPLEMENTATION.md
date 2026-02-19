# Implementasi Improvements Fitur Swap

## 📋 Overview

Dokumen ini berisi implementasi dari improvements yang telah diidentifikasi dalam review fitur swap. Implementasi fokus pada 3 area kritis yang akan meningkatkan fungsionalitas dan user experience secara signifikan.

## ✅ Implementasi yang Telah Dibuat

### 1. Gas Price Oracle Service ⚡

**File:** `lib/core/blockchain/evm/gas/gas_price_oracle_service.dart`

**Features:**

- ✅ Multiple gas speed tiers (slow, standard, fast, instant)
- ✅ Multi-provider support dengan fallback mechanism
- ✅ Price caching untuk reduce API calls
- ✅ Gas cost estimation dalam wei dan ETH
- ✅ Support untuk EthGasStation API
- ✅ Fallback ke RPC eth_gasPrice

**Usage Example:**

```dart
final service = GasPriceOracleService(
  web3Client: web3Client,
  httpClient: http.Client(),
);

// Get current gas prices
final prices = await service.getCurrentGasPrices();
print('Standard: ${prices.standard} wei');

// Get recommended price for specific speed
final gasPrice = await service.getRecommendedGasPrice(GasSpeed.fast);

// Estimate total cost
final cost = service.estimateGasCostInEth(
  gasLimit: BigInt.from(21000),
  gasPrice: gasPrice,
);
print('Estimated cost: $cost ETH');
```

**Integration Steps:**

1. Register service di DI container
2. Inject ke SwapController
3. Replace hardcoded gas price dengan dynamic fetching
4. Add gas speed selector di UI
5. Display estimated gas cost

### 2. Token Balance Use Case 💰

**File:** `lib/features/swap/domain/usecases/get_token_balance_usecase.dart`

**Features:**

- ✅ Fetch ERC20 token balance
- ✅ Support untuk native token (ETH)
- ✅ Automatic decimal conversion
- ✅ Formatted balance display
- ✅ Batch balance fetching
- ✅ Balance sufficiency checking

**Usage Example:**

```dart
final useCase = GetTokenBalanceUseCase(erc20Service: service);

// Get token balance
final balance = await useCase.call(
  tokenAddress: '0xUSDT...',
  walletAddress: '0xUser...',
  decimals: 6,
  symbol: 'USDT',
);

print(balance.toFormattedString()); // "100.5 USDT"
print(balance.raw); // BigInt: 100500000

// Check if balance is sufficient
if (balance.isSufficient(sellAmount)) {
  // Proceed with swap
}
```

**Integration Steps:**

1. Register use case di DI container
2. Add balance state ke SwapController
3. Fetch balance when token selected
4. Update UI untuk display balance
5. Add "Max" button untuk set amount to balance
6. Add balance validation before swap

### 3. Price Oracle Service 💵

**File:** `lib/core/blockchain/evm/price/price_oracle_service.dart`

**Features:**

- ✅ Fetch token prices dari CoinGecko API
- ✅ Price caching (5-minute cache)
- ✅ Batch price fetching
- ✅ USD value calculation
- ✅ Stale cache fallback
- ✅ Support untuk major tokens (ETH, USDT, USDC, DAI, WBTC)

**Usage Example:**

```dart
final service = PriceOracleService(httpClient: http.Client());

// Get single token price
final price = await service.getTokenPriceUSD(
  '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
);
print('USDT: \$$price');

// Get multiple token prices
final prices = await service.getTokenPricesUSD([
  '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
  '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
]);

// Calculate USD value
final usdValue = service.calculateUSDValue(
  BigInt.from(1000000), // 1 USDT (6 decimals)
  6,
  price,
);
print('USD Value: \$$usdValue');
```

**Integration Steps:**

1. Register service di DI container
2. Inject ke SwapController
3. Fetch prices when quote received
4. Calculate USD values untuk sell/buy amounts
5. Display USD values di UI
6. Add price refresh mechanism

## 🔧 Integration Guide

### Step 1: Update Dependency Injection

**File:** `lib/core/di/app_initializer.dart`

```dart
// Register Gas Price Oracle Service
Get.lazyPut<GasPriceOracleService>(
  () => GasPriceOracleService(
    web3Client: Get.find<Web3Client>(),
    httpClient: http.Client(),
  ),
);

// Register Price Oracle Service
Get.lazyPut<PriceOracleService>(
  () => PriceOracleService(
    httpClient: http.Client(),
  ),
);

// Register Get Token Balance Use Case
Get.lazyPut<GetTokenBalanceUseCase>(
  () => GetTokenBalanceUseCase(
    erc20Service: Get.find<Erc20Service>(),
  ),
);
```

### Step 2: Update SwapController

**File:** `lib/features/swap/presentation/controllers/swap_controller.dart`

```dart
class SwapController extends GetxController {
  // Add new dependencies
  GasPriceOracleService? _gasPriceOracleService;
  PriceOracleService? _priceOracleService;
  GetTokenBalanceUseCase? _getTokenBalanceUseCase;

  // Add new state
  final Rxn<TokenBalance> _sellTokenBalance = Rxn<TokenBalance>();
  final Rxn<TokenBalance> _buyTokenBalance = Rxn<TokenBalance>();
  final RxnDouble _sellTokenPriceUSD = RxnDouble();
  final RxnDouble _buyTokenPriceUSD = RxnDouble();
  final Rx<GasSpeed> _selectedGasSpeed = GasSpeed.standard.obs;

  // Getters
  TokenBalance? get sellTokenBalance => _sellTokenBalance.value;
  TokenBalance? get buyTokenBalance => _buyTokenBalance.value;
  double? get sellTokenPriceUSD => _sellTokenPriceUSD.value;
  double? get buyTokenPriceUSD => _buyTokenPriceUSD.value;
  GasSpeed get selectedGasSpeed => _selectedGasSpeed.value;

  // Fetch token balance
  Future<void> fetchTokenBalance({
    required String tokenAddress,
    required int decimals,
    required String symbol,
    required bool isSellToken,
  }) async {
    final walletAddress = authController?.walletAddress;
    if (walletAddress == null) return;

    final useCase = _getTokenBalanceUseCase;
    if (useCase == null) return;

    try {
      final balance = await useCase.call(
        tokenAddress: tokenAddress,
        walletAddress: walletAddress,
        decimals: decimals,
        symbol: symbol,
      );

      if (isSellToken) {
        _sellTokenBalance.value = balance;
      } else {
        _buyTokenBalance.value = balance;
      }
    } catch (e) {
      // Log error but don't fail
      print('Failed to fetch balance: $e');
    }
  }

  // Fetch token price
  Future<void> fetchTokenPrice({
    required String tokenAddress,
    required bool isSellToken,
  }) async {
    final service = _priceOracleService;
    if (service == null) return;

    try {
      final price = await service.getTokenPriceUSD(tokenAddress);

      if (isSellToken) {
        _sellTokenPriceUSD.value = price;
      } else {
        _buyTokenPriceUSD.value = price;
      }
    } catch (e) {
      // Log error but don't fail
      print('Failed to fetch price: $e');
    }
  }

  // Get dynamic gas price
  Future<BigInt> _getDynamicGasPrice() async {
    final service = _gasPriceOracleService;
    if (service == null) {
      // Fallback to 20 Gwei
      return BigInt.from(20000000000);
    }

    try {
      return await service.getRecommendedGasPrice(_selectedGasSpeed.value);
    } catch (e) {
      // Fallback to 20 Gwei
      return BigInt.from(20000000000);
    }
  }

  // Update signAndBroadcastApproval to use dynamic gas price
  Future<String?> signAndBroadcastApproval({
    required String tokenAddress,
    required String pin,
  }) async {
    // ... existing code ...

    // Replace hardcoded gas price with dynamic
    final gasPrice = await _getDynamicGasPrice();

    // ... rest of the code ...
  }

  // Calculate USD value for display
  double? calculateSellAmountUSD(BigInt amount, int decimals) {
    final price = _sellTokenPriceUSD.value;
    if (price == null) return null;

    final service = _priceOracleService;
    if (service == null) return null;

    return service.calculateUSDValue(amount, decimals, price);
  }

  double? calculateBuyAmountUSD(BigInt amount, int decimals) {
    final price = _buyTokenPriceUSD.value;
    if (price == null) return null;

    final service = _priceOracleService;
    if (service == null) return null;

    return service.calculateUSDValue(amount, decimals, price);
  }
}
```

### Step 3: Update SwapScreen UI

**File:** `lib/features/swap/presentation/pages/swap_screen.dart`

```dart
// Update balance display
Text(
  'Balance: ${_swapController.sellTokenBalance?.toDecimalString() ?? '0.0'}',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: AppTheme.textTertiary,
  ),
),

// Add Max button
TextButton(
  onPressed: () {
    final balance = _swapController.sellTokenBalance;
    if (balance != null && !balance.isZero) {
      _amountController.text = balance.toDecimalString();
    }
  },
  child: Text('Max'),
),

// Update USD value display
Obx(() {
  final quote = _swapController.swapQuote;
  final usdValue = quote != null
      ? _swapController.calculateBuyAmountUSD(
          quote.buyAmount,
          _buyToken!.decimals,
        )
      : null;

  if (usdValue == null) return const SizedBox.shrink();

  return Text(
    '~\$${usdValue.toStringAsFixed(2)}',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textTertiary,
    ),
  );
}),

// Add gas speed selector
Row(
  children: [
    Text('Gas Speed:', style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(width: 8),
    Obx(() => DropdownButton<GasSpeed>(
      value: _swapController.selectedGasSpeed,
      items: GasSpeed.values.map((speed) {
        return DropdownMenuItem(
          value: speed,
          child: Text(speed.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (speed) {
        if (speed != null) {
          _swapController.setGasSpeed(speed);
        }
      },
    )),
  ],
),
```

### Step 4: Update Token Selection Handler

```dart
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
            // Fetch balance and price
            _swapController.fetchTokenBalance(
              tokenAddress: token.address,
              decimals: token.decimals,
              symbol: token.symbol,
              isSellToken: true,
            );
            _swapController.fetchTokenPrice(
              tokenAddress: token.address,
              isSellToken: true,
            );
          } else {
            _buyToken = token;
            // Fetch price
            _swapController.fetchTokenPrice(
              tokenAddress: token.address,
              isSellToken: false,
            );
          }
        });
        _swapController.reset();
        Get.back();
      },
    ),
  );
}
```

## 📊 Testing Checklist

### Unit Tests

- [ ] GasPriceOracleService
    - [ ] Test getCurrentGasPrices()
    - [ ] Test getRecommendedGasPrice()
    - [ ] Test estimateGasCost()
    - [ ] Test cache mechanism
    - [ ] Test fallback mechanism

- [ ] GetTokenBalanceUseCase
    - [ ] Test call() dengan ERC20 token
    - [ ] Test call() dengan native token
    - [ ] Test toDecimalString()
    - [ ] Test isSufficient()
    - [ ] Test getMultipleBalances()

- [ ] PriceOracleService
    - [ ] Test getTokenPriceUSD()
    - [ ] Test getTokenPricesUSD()
    - [ ] Test calculateUSDValue()
    - [ ] Test cache mechanism
    - [ ] Test stale cache fallback

### Integration Tests

- [ ] Complete swap flow dengan dynamic gas price
- [ ] Token balance fetching dan display
- [ ] USD value calculation dan display
- [ ] Gas speed selection
- [ ] Max button functionality

### UI Tests

- [ ] Balance display updates correctly
- [ ] USD values display correctly
- [ ] Gas speed selector works
- [ ] Max button sets correct amount
- [ ] Error handling displays properly

## 🚀 Deployment Steps

### 1. Code Review

- Review semua implementasi
- Check for security issues
- Verify error handling
- Validate input sanitization

### 2. Testing

- Run unit tests
- Run integration tests
- Manual testing di testnet
- Test dengan different network conditions

### 3. Staging Deployment

- Deploy ke testnet
- Monitor for errors
- Collect user feedback
- Fix any issues

### 4. Production Deployment

- Deploy ke mainnet
- Monitor closely
- Have rollback plan ready
- Collect metrics

## 📈 Success Metrics

### Performance

- Gas price accuracy: >95%
- Balance fetch time: <1 second
- Price fetch time: <2 seconds
- Cache hit rate: >80%

### User Experience

- Swap completion rate: >90%
- Transaction success rate: >95%
- Error rate: <5%
- User satisfaction: >4.5/5

## 🔜 Next Steps

### Immediate (Week 1)

1. ✅ Implement Gas Price Oracle Service
2. ✅ Implement Token Balance Use Case
3. ✅ Implement Price Oracle Service
4. ⏳ Integrate services ke SwapController
5. ⏳ Update UI untuk display new data

### Short-term (Week 2-3)

1. ⏳ Implement transaction monitoring
2. ⏳ Implement price impact calculation
3. ⏳ Add slippage validation
4. ⏳ Implement token list service
5. ⏳ Add comprehensive error handling

### Medium-term (Week 4-6)

1. ⏳ Add swap history
2. ⏳ Implement multi-DEX routing
3. ⏳ Add advanced order types
4. ⏳ Implement MEV protection
5. ⏳ Add analytics and monitoring

## 📝 Notes

### API Rate Limits

- **CoinGecko Free:** 10-50 calls/minute
- **EthGasStation:** No official limit, use responsibly
- **RPC Nodes:** Depends on provider

### Caching Strategy

- Gas prices: 1 minute cache
- Token prices: 5 minute cache
- Token balances: No cache (always fresh)

### Error Handling

- Always provide fallback values
- Never expose raw API errors to users
- Log errors for debugging
- Implement retry mechanism for transient failures

### Security Considerations

- Validate all API responses
- Sanitize error messages
- Never expose API keys in client
- Implement rate limiting
- Use HTTPS for all API calls

---

**Document Version:** 1.0
**Last Updated:** 2026-02-19
**Status:** Implementation Complete - Integration Pending
