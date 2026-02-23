import '../../../../core/blockchain/evm/swap/zero_x_api_service.dart';
import '../entities/swap_quote.dart';
import '../../data/models/swap_quote_model.dart';

/// Get Swap Quote Use Case
///
/// DOMAIN LAYER - Business Logic
///
/// Responsibilities:
/// - Fetch swap quotes from 0x API v2 aggregator
/// - Convert API response to domain entity
/// - Handle parameter conversion (BigInt to string)
/// - Pass chainId to API service for multi-chain support
///
/// Swap Flow Overview:
/// ==================
/// This use case is step 1 in the complete swap flow:
///
/// 1. **Get Quote** (this use case)
///    - Fetch best swap route from 0x aggregator
///    - Returns transaction data and gas estimates
///    - Includes price impact and min buy amount
///
/// 2. **Check Allowance** (CheckAllowanceUseCase)
///    - Check if token is approved for allowanceTarget (permit2)
///    - Determine if approval is needed
///
/// 3. **Approve Token** (ApproveTokenUseCase) - if needed
///    - Build approve transaction
///    - Sign and broadcast
///    - Wait for confirmation
///
/// 4. **Build Swap Transaction**
///    - Use quote.to, quote.data, quote.value
///    - Add nonce, gas parameters
///
/// 5. **Sign Transaction** (TransactionEngine)
///    - Sign with user's private key
///    - Apply EIP-155 protection
///
/// 6. **Broadcast Transaction**
///    - Send to network
///    - Wait for confirmation
///
/// Usage:
/// ```dart
/// final useCase = GetSwapQuoteUseCase(zeroXApiService: service);
///
/// final quote = await useCase.call(
///   sellToken: '0xUSDT...',      // Token to sell
///   buyToken: '0xWETH...',       // Token to buy
///   sellAmount: BigInt.from(100000000), // 100 USDT (6 decimals)
///   walletAddress: '0xUser...',   // User wallet
///   slippage: 0.01,              // 1% tolerance
///   chainId: 1,                  // Ethereum mainnet
/// );
///
/// // Use quote for transaction building
/// print('Swap to: ${quote.to}');
/// print('Buy amount: ${quote.buyAmount}');
/// print('Price impact: ${quote.priceImpactText}');
/// print('Allowance target: ${quote.allowanceTarget}');
/// ```
///
/// Security:
/// - No private key handling
/// - No transaction signing
/// - Read-only operation (fetches quote only)
class GetSwapQuoteUseCase {
  final ZeroXApiService _zeroXApiService;

  GetSwapQuoteUseCase({required ZeroXApiService zeroXApiService})
    : _zeroXApiService = zeroXApiService;

  /// Execute use case
  ///
  /// Fetches a swap quote from the 0x v2 aggregator API.
  ///
  /// Parameters:
  /// - sellToken: ERC20 token address to sell
  /// - buyToken: ERC20 token address to buy (or native token address for ETH)
  /// - sellAmount: Amount to sell in smallest units (BigInt)
  /// - walletAddress: User's wallet address (taker address)
  /// - slippage: Maximum acceptable price movement (0.01 = 1%)
  ///
  /// Returns: SwapQuote domain entity with transaction data
  ///
  /// Throws:
  /// - ZeroXApiException: If API call fails or chain not supported
  /// - ArgumentError: If parameters are invalid
  Future<SwapQuote> call({
    required String sellToken,
    required String buyToken,
    required BigInt sellAmount,
    required String walletAddress,
    required double slippage,
  }) async {
    // Validate chain is supported before making API call
    if (!_zeroXApiService.isChainSupported) {
      throw ZeroXApiException(
        'Current network (chainId: ${_zeroXApiService.chainId}) is not supported for swap. '
        'Please switch to Ethereum, Polygon, BSC, Base, Arbitrum, or Optimism.',
      );
    }

    // Convert BigInt to string for API
    // API expects amount as string in smallest units
    final sellAmountString = sellAmount.toString();

    // Fetch quote from 0x API v2
    final model = await _zeroXApiService.getQuote(
      sellToken: sellToken,
      buyToken: buyToken,
      sellAmount: sellAmountString,
      takerAddress: walletAddress,
      slippagePercentage: slippage,
    );

    // Convert data model to domain entity
    return _mapModelToEntity(model);
  }

  /// Converts data model to domain entity.
  ///
  /// This separation allows:
  /// - API response format to change without affecting domain
  /// - Domain entity to have different types (BigInt vs String)
  /// - Clean architecture boundaries
  SwapQuote _mapModelToEntity(SwapQuoteModel model) {
    // Parse price impact from string to double
    double? priceImpact;
    if (model.estimatedPriceImpact != null) {
      priceImpact = double.tryParse(model.estimatedPriceImpact!);
    }

    return SwapQuote(
      to: model.to,
      data: model.data,
      value: BigInt.tryParse(model.value) ?? BigInt.zero,
      gas: BigInt.tryParse(model.gas) ?? BigInt.zero,
      gasPrice: BigInt.tryParse(model.gasPrice) ?? BigInt.zero,
      allowanceTarget: model.allowanceTarget,
      buyAmount: BigInt.tryParse(model.buyAmount) ?? BigInt.zero,
      sellAmount: BigInt.tryParse(model.sellAmount) ?? BigInt.zero,
      minBuyAmount: model.minBuyAmount != null
          ? BigInt.tryParse(model.minBuyAmount!)
          : null,
      estimatedPriceImpact: priceImpact,
      permit2Eip712: model.permit2Eip712,
    );
  }
}
