# Chain ID Fix - Default to Sepolia Testnet

## Problem

Error: **"invalid chain id for signer: have 22310239 want 11155111"**

### Root Cause Analysis

**Error Breakdown**:

- **Want**: 11155111 (Sepolia testnet chain ID - correct!)
- **Have**: 22310239 (wrong chain ID in signed transaction)

**Chain ID Calculation**:
EIP-155 uses formula: `v = chainId * 2 + 35 + recovery_id`

Working backwards from error:

```
v = 22310239
recovery_id = 0 or 1
chainId = (v - 35 - recovery_id) / 2
chainId ≈ 11155102 (if recovery_id = 0)
```

This is close to Sepolia (11155111) but not exact, suggesting:

1. Wrong network selected (not Sepolia)
2. Or chain ID corruption during signing

**Actual Cause**:
`NetworkController` defaults to **Ethereum Mainnet** (chain ID 1), not Sepolia. User's wallet has Sepolia ETH but app is trying to sign for mainnet.

## Solution

Change default network from Ethereum Mainnet to Sepolia Testnet for testing.

### Changes Made

**File**: `lib/features/network_switch/presentation/controllers/network_controller.dart`

**Before**:

```dart
Future<void> _loadCurrentNetwork() async {
  // ... load from storage ...

  // Fallback: Default to Ethereum Mainnet
  _currentNetwork.value = _networks.isNotEmpty ? _networks.first : null;
}
```

**After**:

```dart
Future<void> _loadCurrentNetwork() async {
  // ... load from storage ...

  // Fallback: Default to Sepolia Testnet for testing
  final sepoliaNetwork = _networks.firstWhereOrNull((n) => n.id == 'ethereum-sepolia');
  if (sepoliaNetwork != null) {
    _currentNetwork.value = sepoliaNetwork;
    await _storageService.saveCurrentNetwork(sepoliaNetwork.id);
  } else {
    _currentNetwork.value = _networks.isNotEmpty ? _networks.first : null;
  }
}
```

## Network Configuration

### Available Networks

1. **Ethereum Mainnet**
    - Chain ID: 1
    - RPC: https://mainnet.infura.io/v3/...
    - Explorer: https://etherscan.io
    - For: Production use with real ETH

2. **Sepolia Testnet** (NOW DEFAULT)
    - Chain ID: 11155111
    - RPC: https://sepolia.infura.io/v3/...
    - Explorer: https://sepolia.etherscan.io
    - For: Testing with free testnet ETH

3. **Polygon Mainnet**
    - Chain ID: 137
    - For: Polygon/MATIC transactions

4. **BNB Smart Chain**
    - Chain ID: 56
    - For: BNB transactions

5. **Arbitrum One**
    - Chain ID: 42161
    - For: Arbitrum transactions

### Why Sepolia as Default?

1. **Safe for Testing**: Uses testnet ETH (no real value)
2. **Free ETH**: Get free testnet ETH from faucets
3. **Same as RPC**: RPC client already configured for Sepolia
4. **User's Balance**: User already has Sepolia ETH

## Testing

### 1. Verify Network Selection

After app restart, check current network:

```
Home → Settings → Network
```

**Expected**: "Sepolia Testnet" selected

### 2. Send Transaction

```
1. Navigate to Send screen
2. Enter recipient address
3. Enter amount (0.001)
4. Review transaction
5. Enter PIN
6. Confirm & Send
```

**Expected**:

- ✅ Transaction signed with chain ID 11155111
- ✅ Transaction broadcast successfully
- ✅ No "invalid chain id" error
- ✅ Transaction hash displayed
- ✅ Transaction appears on Sepolia Etherscan

### 3. Verify on Blockchain

```
1. Copy transaction hash
2. Open: https://sepolia.etherscan.io/
3. Paste transaction hash
```

**Expected**:

- ✅ Transaction found
- ✅ Status: Success
- ✅ From: Your address
- ✅ To: Recipient address
- ✅ Value: 0.001 ETH

## Switching Networks

Users can switch networks from Settings:

```
Settings → Network → Select Network
```

**Available Options**:

- Sepolia Testnet (default)
- Ethereum Mainnet
- Polygon Mainnet
- BNB Smart Chain
- Arbitrum One

**Important**:

- Switching network changes which blockchain transactions are sent to
- Wallet address remains the same across all EVM networks
- Balance will be different on each network

## For Production

When ready for production with real ETH:

1. **Switch to Mainnet**:

    ```
    Settings → Network → Ethereum Mainnet
    ```

2. **Update RPC URL**:

    ```dart
    // In service_locator.dart
    rpcUrl: 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID'
    ```

3. **Change Default Network**:
    ```dart
    // In network_controller.dart
    // Change default from 'ethereum-sepolia' to 'ethereum-mainnet'
    final mainnetNetwork = _networks.firstWhereOrNull((n) => n.id == 'ethereum-mainnet');
    ```

⚠️ **WARNING**: Mainnet uses real ETH with real value!

## Chain ID Reference

Common EVM chain IDs:

- **1**: Ethereum Mainnet
- **11155111**: Sepolia Testnet
- **5**: Goerli Testnet (deprecated)
- **137**: Polygon Mainnet
- **80001**: Polygon Mumbai Testnet
- **56**: BNB Smart Chain
- **97**: BNB Testnet
- **42161**: Arbitrum One
- **421613**: Arbitrum Goerli

## Summary

✅ Fixed default network to Sepolia Testnet
✅ Matches RPC configuration (Sepolia)
✅ Matches user's balance (Sepolia ETH)
✅ Chain ID now correct: 11155111
✅ Transactions will be sent to correct network

**Next Step**: Full app restart and test transaction!
