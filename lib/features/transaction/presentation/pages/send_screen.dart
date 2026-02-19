import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/transaction_controller.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';

/// Send Screen
/// 
/// Screen for sending tokens with comprehensive validation and UI feedback.
/// 
/// Features:
/// - Recipient address input with validation
/// - Amount input with max button
/// - Gas fee preview card
/// - Address validation UI feedback
/// - Loading states
/// - Confirmation modal
/// - QR scanner button (placeholder)
/// 
/// Flow:
/// 1. User enters recipient address (validates format)
/// 2. User enters amount (validates balance)
/// 3. User reviews gas fee estimate
/// 4. User taps "Review Transaction"
/// 5. Confirmation modal appears
/// 6. User confirms and transaction is signed
/// 7. Signed transaction returned (not broadcast automatically)
/// 
/// Controller Integration:
/// - TransactionController: Validates address, signs transaction
/// - WalletController: Gets wallet balance
/// - AuthController: Checks lock state
class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  
  bool _isLoading = false;
  bool _isValidatingAddress = false;
  bool _isEstimatingGas = false;
  
  String? _addressError;
  String? _amountError;
  bool _isAddressValid = false;
  
  // Get controllers
  TransactionController? get _transactionController {
    try {
      return Get.find<TransactionController>();
    } catch (e) {
      return null;
    }
  }
  
  WalletController? get _walletController {
    try {
      return Get.find<WalletController>();
    } catch (e) {
      return null;
    }
  }
  
  // Placeholder data (in production, get from controller)
  String get _walletBalance {
    return _walletController?.balance ?? '1.234';
  }
  
  String get _estimatedGas {
    return _transactionController?.estimatedGas ?? '0.0021';
  }
  
  String get _gasPrice {
    return _transactionController?.gasPrice ?? '25';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _amountController.addListener(_onAmountChanged);
  }

  void _onAddressChanged() {
    // Debounce validation
    if (_addressController.text.isEmpty) {
      setState(() {
        _addressError = null;
        _isAddressValid = false;
      });
      return;
    }

    // Basic format check (0x + 40 hex characters)
    final address = _addressController.text;
    if (address.length >= 10) {
      _validateAddress(address);
    }
  }

  void _validateAddress(String address) async {
    setState(() {
      _isValidatingAddress = true;
      _addressError = null;
    });

    // Call controller to validate address
    final controller = _transactionController;
    bool isValid = false;
    
    if (controller != null) {
      isValid = await controller.validateAddress(address);
    } else {
      // Fallback: Basic validation
      isValid = address.startsWith('0x') && address.length == 42;
    }
    
    if (!mounted) return;
    
    setState(() {
      _isValidatingAddress = false;
      _isAddressValid = isValid;
      if (!isValid && address.length >= 42) {
        _addressError = 'Invalid Ethereum address';
      }
    });

    if (isValid && _amountController.text.isNotEmpty) {
      _estimateGas();
    }
  }

  void _onAmountChanged() {
    if (_amountController.text.isEmpty) {
      setState(() {
        _amountError = null;
      });
      return;
    }

    final amount = double.tryParse(_amountController.text);
    final balance = double.tryParse(_walletBalance);

    if (amount == null) {
      setState(() {
        _amountError = 'Invalid amount';
      });
      return;
    }

    if (amount <= 0) {
      setState(() {
        _amountError = 'Amount must be greater than 0';
      });
      return;
    }

    if (balance != null && amount > balance) {
      setState(() {
        _amountError = 'Insufficient balance';
      });
      return;
    }

    setState(() {
      _amountError = null;
    });

    if (_isAddressValid) {
      _estimateGas();
    }
  }

  void _estimateGas() async {
    setState(() {
      _isEstimatingGas = true;
    });

    // Call controller to estimate gas
    final controller = _transactionController;
    if (controller != null) {
      await controller.estimateGas(
        _addressController.text,
        _amountController.text,
      );
    } else {
      // Fallback: Simulate estimation
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    if (!mounted) return;
    setState(() {
      _isEstimatingGas = false;
    });
  }

  void _handleMaxAmount() {
    // Get actual balance from controller
    final balance = double.tryParse(_walletBalance) ?? 0;
    final gas = double.tryParse(_estimatedGas) ?? 0;
    final maxAmount = (balance - gas).clamp(0, balance);
    
    _amountController.text = maxAmount.toStringAsFixed(6);
  }

  void _handleScanQR() {
    // TODO: Implement QR scanner
    Get.snackbar(
      'QR Scanner',
      'QR code scanning coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryPurple),
      duration: const Duration(seconds: 2),
    );
  }

  void _handlePasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _addressController.text = data!.text!;
    }
  }

  bool get _canReview {
    return _isAddressValid &&
        _amountController.text.isNotEmpty &&
        _addressError == null &&
        _amountError == null &&
        !_isValidatingAddress &&
        !_isEstimatingGas;
  }

  void _handleReview() {
    if (!_canReview) return;

    _showConfirmationModal();
  }

  void _showConfirmationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildConfirmationModal(),
    );
  }

  void _handleConfirmSend() async {
    // Validate PIN is entered
    if (_pinController.text.isEmpty) {
      Get.snackbar(
        'PIN Required',
        'Please enter your PIN to confirm transaction',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.error, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    Navigator.pop(context); // Close modal

    setState(() => _isLoading = true);

    // No need to check wallet lock state
    // SignTransactionUseCase will use PIN directly to decrypt mnemonic
    
    // Call controller to sign and broadcast transaction
    final controller = _transactionController;
    
    // Debug: Check if controller is available
    if (controller == null) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'TransactionController not found. Please restart the app.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.error, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    // Get current wallet address for nonce
    final walletController = _walletController;
    final currentAddress = walletController?.currentAddress.value ?? '';
    
    if (currentAddress.isEmpty) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Could not get wallet address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.error, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    // Get nonce from blockchain
    int nonce;
    try {
      nonce = await controller.getNonce(currentAddress);
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to get transaction nonce: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.error, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    final signedTransaction = await controller.sendTransaction(
      to: _addressController.text,
      amount: _amountController.text,
      pin: _pinController.text,
      nonce: nonce,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (signedTransaction != null) {
      // Clear PIN from memory
      _pinController.clear();
      
      // ============================================================================
      // DEBUG: Print FULL transaction hash to console for verification
      // ============================================================================
      print('');
      print('═══════════════════════════════════════════════════════════════');
      print('🚀 TRANSACTION SENT SUCCESSFULLY');
      print('═══════════════════════════════════════════════════════════════');
      print('');
      print('📋 TRANSACTION DETAILS:');
      print('   From:    ${controller.authController?.walletAddress ?? "Unknown"}');
      print('   To:      ${_addressController.text}');
      print('   Amount:  ${_amountController.text} ETH');
      print('   Network: ${controller.networkController?.currentNetwork?.name ?? "Unknown"}');
      print('   Chain ID: ${controller.networkController?.currentNetwork?.chainId ?? "Unknown"}');
      print('');
      print('🔗 TRANSACTION HASH (FULL):');
      print('   ${signedTransaction.transactionHash}');
      print('');
      print('🔍 VERIFY ON EXPLORER:');
      final network = controller.networkController?.currentNetwork;
      if (network != null) {
        final explorerUrl = '${network.explorerUrl}/tx/${signedTransaction.transactionHash}';
        print('   $explorerUrl');
      }
      print('');
      print('═══════════════════════════════════════════════════════════════');
      print('');
      
      // Show success and navigate back
      Get.back();
      Get.snackbar(
        'Transaction Sent',
        'Transaction hash: ${signedTransaction.transactionHash.substring(0, 10)}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentGreen,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.check_circle, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 3),
      );
      
      // Refresh wallet balance
      if (walletController != null) {
        await walletController.refreshBalance();
      }
    } else {
      // Show error
      final errorMessage = controller.errorMessage ?? 'Unknown error';
      
      // ============================================================================
      // DEBUG: Print error to console
      // ============================================================================
      print('');
      print('═══════════════════════════════════════════════════════════════');
      print('❌ TRANSACTION FAILED');
      print('═══════════════════════════════════════════════════════════════');
      print('');
      print('Error: $errorMessage');
      print('');
      print('═══════════════════════════════════════════════════════════════');
      print('');
      
      Get.snackbar(
        'Transaction Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.accentRed,
        colorText: AppTheme.textPrimary,
        icon: const Icon(Icons.error, color: AppTheme.textPrimary),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
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
                // Balance Display
                _buildBalanceCard(),
                const SizedBox(height: AppTheme.spacingXL),

                // Recipient Address
                _buildAddressInput(),
                const SizedBox(height: AppTheme.spacingXL),

                // Amount Input
                _buildAmountInput(),
                const SizedBox(height: AppTheme.spacingXL),

                // Gas Fee Card
                _buildGasFeeCard(),
                const SizedBox(height: AppTheme.spacingXXL),

                // Review Button
                PrimaryButton(
                  text: 'Review Transaction',
                  onPressed: _canReview ? _handleReview : null,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '$_walletBalance ETH',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient Address',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: '0x...',
            hintStyle: TextStyle(
              color: AppTheme.textTertiary,
              fontFamily: 'monospace',
            ),
            errorText: _addressError,
            prefixIcon: Icon(
              _isAddressValid
                  ? Icons.check_circle
                  : Icons.account_balance_wallet_outlined,
              color: _isAddressValid
                  ? AppTheme.accentGreen
                  : AppTheme.textSecondary,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isValidatingAddress)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _handlePasteAddress,
                  tooltip: 'Paste',
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _handleScanQR,
                  tooltip: 'Scan QR',
                ),
              ],
            ),
          ),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
        if (_isAddressValid) ...[
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppTheme.accentGreen,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Valid Ethereum address',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: _handleMaxAmount,
              icon: const Icon(Icons.account_balance_wallet, size: 16),
              label: const Text('MAX'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.0',
            errorText: _amountError,
            suffixText: 'ETH',
            suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildGasFeeCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_gas_station,
                size: 20,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Transaction Fee',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_isEstimatingGas)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildFeeRow('Gas Price', '$_gasPrice Gwei'),
          const SizedBox(height: AppTheme.spacingS),
          _buildFeeRow('Estimated Gas', '21000'),
          const Divider(height: AppTheme.spacingL, color: AppTheme.divider),
          _buildFeeRow(
            'Network Fee',
            '$_estimatedGas ETH',
            isTotal: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildTotalRow(),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : null,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : null,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }

  Widget _buildTotalRow() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final gas = double.tryParse(_estimatedGas) ?? 0;
    final total = amount + gas;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '${total.toStringAsFixed(6)} ETH',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationModal() {
    final amount = _amountController.text;
    final address = _addressController.text;
    final gas = _estimatedGas;
    final total = (double.tryParse(amount) ?? 0) + (double.tryParse(gas) ?? 0);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppTheme.spacingL,
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingL,
      ),
      child: SingleChildScrollView(
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
              'Confirm Transaction',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Amount Display
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                children: [
                  Text(
                    'Sending',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '$amount ETH',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Details
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                children: [
                  _buildModalRow('To', _shortenAddress(address)),
                  const Divider(height: AppTheme.spacingL),
                  _buildModalRow('Network Fee', '$gas ETH'),
                  const Divider(height: AppTheme.spacingL),
                  _buildModalRow(
                    'Total',
                    '${total.toStringAsFixed(6)} ETH',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // PIN Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter PIN to Confirm',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your PIN',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  autofocus: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Warning
            Container(
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
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'This transaction cannot be reversed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pinController.clear();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.textSecondary),
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Confirm & Send',
                    onPressed: _handleConfirmSend,
                    icon: Icons.send,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : null,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
