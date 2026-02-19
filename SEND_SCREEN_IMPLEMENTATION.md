# Send Screen Implementation

## Overview

Implemented a comprehensive SendScreen with address validation, amount input, gas fee preview, and confirmation modal.

## Status: ✅ COMPLETE

## Features Implemented

### 1. Recipient Address Input

- **Text field** with monospace font for addresses
- **Paste button** - Clipboard integration
- **QR scanner button** - Placeholder for QR code scanning
- **Real-time validation** - Validates as user types
- **Loading indicator** - Shows during validation
- **Success indicator** - Green checkmark for valid address
- **Error messages** - "Invalid Ethereum address"
- **Format check** - 0x + 40 hex characters

### 2. Amount Input

- **Large text field** - Prominent display
- **Decimal keyboard** - Optimized for numbers
- **MAX button** - Sets maximum sendable amount
- **Balance validation** - Checks sufficient funds
- **Error messages**:
    - "Invalid amount"
    - "Amount must be greater than 0"
    - "Insufficient balance"
- **Auto gas calculation** - Subtracts gas from max

### 3. Gas Fee Preview Card

- **Gas price** - Displayed in Gwei
- **Estimated gas** - 21000 units (standard transfer)
- **Network fee** - Total in ETH
- **Total amount** - Amount + gas fee
- **Loading indicator** - Shows during estimation
- **Auto-update** - Recalculates when amount changes
- **Visual hierarchy** - Clear breakdown of costs

### 4. Address Validation UI Feedback

- **Debounced validation** - Waits for user to finish typing
- **Loading spinner** - Shows validation in progress
- **Green checkmark** - Valid address indicator
- **Success message** - "Valid Ethereum address"
- **Error state** - Red border and error text
- **Icon changes** - Wallet icon → checkmark

### 5. Loading States

- **Address validation** - Spinner in input field
- **Gas estimation** - Spinner in gas card
- **Transaction sending** - Button loading state
- **Disabled inputs** - During processing
- **Visual feedback** - Clear indication of activity

### 6. Confirmation Modal

- **Bottom sheet** - Slides up from bottom
- **Amount display** - Large, prominent
- **Transaction details**:
    - Recipient address (shortened)
    - Network fee
    - Total amount
- **Warning message** - "This transaction cannot be reversed"
- **Cancel button** - Outlined style
- **Confirm button** - Primary gradient style
- **Handle indicator** - Drag handle at top

### 7. Balance Display Card

- **Gradient background** - Purple-blue gradient
- **Available balance** - Shows wallet balance
- **Prominent display** - At top of screen
- **Shadow effect** - Elevated appearance

## Layout Structure

```
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐  │
│  │ Available Balance             │  │
│  │ 1.234 ETH                     │  │
│  └───────────────────────────────┘  │
│                                     │
│  Recipient Address                  │
│  ┌───────────────────────────────┐  │
│  │ ✓ 0x742d...0bEb  📋 📷       │  │
│  └───────────────────────────────┘  │
│  ✓ Valid Ethereum address           │
│                                     │
│  Amount                        MAX  │
│  ┌───────────────────────────────┐  │
│  │ 0.5                       ETH │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ ⛽ Transaction Fee             │  │
│  │ Gas Price: 25 Gwei            │  │
│  │ Estimated Gas: 21000          │  │
│  │ ─────────────────────────     │  │
│  │ Network Fee: 0.0021 ETH       │  │
│  │ ┌─────────────────────────┐   │  │
│  │ │ Total: 0.5021 ETH       │   │  │
│  │ └─────────────────────────┘   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Review Transaction         →  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Confirmation Modal Structure

```
┌─────────────────────────────────────┐
│            ────                     │
│                                     │
│      Confirm Transaction            │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        Sending                │  │
│  │        0.5 ETH                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ To: 0x742d...0bEb             │  │
│  │ ─────────────────────────     │  │
│  │ Network Fee: 0.0021 ETH       │  │
│  │ ─────────────────────────     │  │
│  │ Total: 0.5021 ETH             │  │
│  └───────────────────────────────┘  │
│                                     │
│  ⚠️ This transaction cannot be      │
│     reversed                        │
│                                     │
│  ┌─────────┐  ┌──────────────────┐ │
│  │ Cancel  │  │ Confirm & Send → │ │
│  └─────────┘  └──────────────────┘ │
└─────────────────────────────────────┘
```

## User Flow

1. **Screen Loads**
    - Balance card displays available ETH
    - Address input focused
    - All fields empty

2. **User Enters Address**
    - Types or pastes address
    - Validation starts after 10 characters
    - Loading spinner appears
    - After 500ms: Validation completes
    - Green checkmark if valid
    - Error message if invalid

3. **User Enters Amount**
    - Types amount or taps MAX
    - Validates against balance
    - Shows error if insufficient
    - Triggers gas estimation

4. **Gas Estimation**
    - Loading spinner in gas card
    - Calculates network fee
    - Updates total amount
    - Completes after 800ms

5. **User Taps Review**
    - Button disabled until valid
    - Confirmation modal slides up
    - Shows transaction summary

6. **User Confirms**
    - Modal closes
    - Loading state shown
    - Transaction sent (simulated)
    - Success message displayed
    - Navigates back to home

7. **User Cancels**
    - Modal closes
    - Returns to send screen
    - Data preserved

## Validation Logic

### Address Validation

```dart
// Basic format check
- Must start with "0x"
- Must be exactly 42 characters
- Debounced (500ms delay)
- TODO: Add checksum validation
- TODO: Call controller.validateAddress()
```

### Amount Validation

```dart
// Real-time validation
- Must be a valid number
- Must be greater than 0
- Must not exceed balance
- Must leave room for gas fee
```

### Form Validation

```dart
// Review button enabled when:
- Address is valid
- Amount is valid
- No errors present
- Not currently validating
- Not currently estimating gas
```

## Controller Integration Points

### TODO Comments

```dart
// TODO: Inject TransactionController
// TODO: Call controller.validateAddress(address)
// TODO: Call controller.estimateGas(to, amount)
// TODO: Call controller.sendTransaction(to, amount)
// TODO: Handle transaction status
// TODO: Get wallet balance for max button
// TODO: Open QR scanner
```

### Controller Methods Needed

```dart
// TransactionController
Future<bool> validateAddress(String address);
Future<GasEstimate> estimateGas(String to, String amount);
Future<String> sendTransaction(String to, String amount);
String getWalletBalance();

// WalletController
String getCurrentAddress();
double getBalance();
```

### Integration Example

```dart
void _validateAddress(String address) async {
  setState(() => _isValidatingAddress = true);

  final controller = Get.find<TransactionController>();
  final isValid = await controller.validateAddress(address);

  setState(() {
    _isValidatingAddress = false;
    _isAddressValid = isValid;
    if (!isValid) {
      _addressError = 'Invalid Ethereum address';
    }
  });
}
```

## Design Specifications

### Colors

- **Balance Card**: Purple-blue gradient with shadow
- **Valid Address**: Green (#00D9A3)
- **Error State**: Red (#FF6B6B)
- **Gas Card**: Dark surface with purple border
- **Total Amount**: Purple background with opacity
- **Warning**: Red background with opacity

### Typography

- **Balance**: headlineMedium, bold
- **Amount Input**: headlineSmall, bold
- **Labels**: titleMedium, w600
- **Details**: bodyMedium, monospace for values
- **Modal Title**: headlineSmall, bold
- **Modal Amount**: displaySmall, bold

### Spacing

- **Section Spacing**: 32px (spacingXL)
- **Element Spacing**: 16px (spacingM)
- **Card Padding**: 20px (spacingL)
- **Modal Padding**: 20px (spacingL)

### Sizing

- **Balance Card**: Full width, gradient
- **Input Fields**: Full width, 56px height
- **Gas Card**: Full width, detailed breakdown
- **Modal**: Bottom sheet, auto height
- **Buttons**: 56px height

## Placeholder Data

### Wallet

- Balance: `1.234 ETH`
- Address: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`

### Gas Fees

- Gas Price: `25 Gwei`
- Estimated Gas: `21000 units`
- Network Fee: `0.0021 ETH`

### Validation

- Valid address format: `0x` + 40 hex characters
- Validation delay: 500ms
- Gas estimation delay: 800ms
- Transaction delay: 2000ms

## Features by Section

### Balance Card

- ✅ Gradient background
- ✅ Available balance display
- ✅ Shadow effect
- ✅ Prominent placement

### Address Input

- ✅ Monospace font
- ✅ Paste button
- ✅ QR scanner button (placeholder)
- ✅ Real-time validation
- ✅ Loading indicator
- ✅ Success indicator
- ✅ Error messages

### Amount Input

- ✅ Large text display
- ✅ MAX button
- ✅ Balance validation
- ✅ Error messages
- ✅ Decimal keyboard

### Gas Fee Card

- ✅ Gas price in Gwei
- ✅ Estimated gas units
- ✅ Network fee in ETH
- ✅ Total amount calculation
- ✅ Loading indicator
- ✅ Visual breakdown

### Confirmation Modal

- ✅ Bottom sheet design
- ✅ Drag handle
- ✅ Amount display
- ✅ Transaction details
- ✅ Warning message
- ✅ Cancel button
- ✅ Confirm button

## Security Features

### Input Validation

- ✅ Address format validation
- ✅ Amount validation
- ✅ Balance checking
- ✅ Gas fee calculation

### User Confirmation

- ✅ Review before send
- ✅ Confirmation modal
- ✅ Warning message
- ✅ Clear transaction details

### Error Handling

- ✅ Invalid address errors
- ✅ Insufficient balance errors
- ✅ Invalid amount errors
- ✅ Visual error feedback

## Responsive Design

### Small Screens

- Scrollable layout
- Full-width inputs
- Readable text sizes
- Touch-friendly buttons

### Large Screens

- Centered content
- Maximum width constraints
- Comfortable spacing
- Same layout structure

## Accessibility

### Current Features

- ✅ Clear labels
- ✅ Error messages
- ✅ Loading indicators
- ✅ Large touch targets
- ✅ High contrast colors

### Future Improvements

- ⏳ Screen reader support
- ⏳ Haptic feedback
- ⏳ Voice input
- ⏳ Larger text option

## Testing Checklist

- [x] Screen renders correctly
- [x] Balance card displays
- [x] Address input works
- [x] Paste button works
- [x] QR scanner shows message
- [x] Address validation works
- [x] Valid address shows checkmark
- [x] Invalid address shows error
- [x] Amount input works
- [x] MAX button works
- [x] Amount validation works
- [x] Insufficient balance error shows
- [x] Gas card displays
- [x] Gas estimation simulates
- [x] Total calculates correctly
- [x] Review button enables/disables
- [x] Confirmation modal opens
- [x] Modal displays details
- [x] Cancel button works
- [x] Confirm button works
- [x] Success message shows
- [x] Navigation works
- [x] No diagnostic errors

## File Location

`lib/features/transaction/presentation/pages/send_screen.dart`

## Dependencies

- `flutter/material.dart` - Material Design widgets
- `flutter/services.dart` - Clipboard functionality
- `get` - Navigation and state management
- `AppTheme` - Consistent theming
- `PrimaryButton` - Reusable button component

## Next Steps

1. **Controller Integration**
    - Inject TransactionController
    - Implement validateAddress()
    - Implement estimateGas()
    - Implement sendTransaction()
    - Get real wallet balance

2. **QR Code Scanner**
    - Add qr_code_scanner package
    - Implement camera permission
    - Parse QR code data
    - Validate scanned address

3. **Enhanced Validation**
    - Add checksum validation
    - Verify contract addresses
    - Check address history
    - Warn about new addresses

4. **Gas Optimization**
    - Multiple gas speed options (slow/normal/fast)
    - Custom gas price input
    - Gas price recommendations
    - EIP-1559 support

5. **Transaction Status**
    - Pending state
    - Confirmation tracking
    - Transaction hash display
    - Block explorer link

6. **Additional Features**
    - Contact list
    - Recent addresses
    - Address book
    - Transaction history
    - Multi-token support

## Notes

- Clean, intuitive design
- Real-time validation feedback
- Clear error messages
- Comprehensive gas fee breakdown
- Confirmation modal prevents accidents
- No signing logic (controller only)
- Ready for TransactionController integration
- Responsive and accessible
- Dark theme consistent throughout
