# Panduan Setup Base Network

## 🎯 Situasi Anda

**Network yang Benar:** Base Network (Coinbase Layer 2)
**Address:** `0xe43726738e770f667c5536abcb64c7aeeabd823f`
**Saldo:** `0.000194 ETH`
**Explorer:** https://basescan.org/address/0xe43726738e770f667c5536abcb64c7aeeabd823f

## ✅ Fix yang Telah Diimplementasikan

### 1. RPC Configuration Update

**File:** `lib/core/di/service_locator.dart`

Saya telah mengubah RPC URL untuk terhubung ke **Base Network**:

```dart
// SEBELUM (Ethereum Mainnet)
rpcUrl: 'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',

// SESUDAH (Base Network)
rpcUrl: 'https://mainnet.base.org',
```

### 2. Network List Update

**File:** `lib/features/network_switch/presentation/controllers/network_controller.dart`

Saya telah menambahkan **Base Network** dan **Optimism** ke daftar predefined networks:

```dart
Network(
  id: 'base-mainnet',
  name: 'Base',
  chainId: 8453,
  rpcUrl: 'https://mainnet.base.org',
  symbol: 'ETH',
  explorerUrl: 'https://basescan.org',
  isTestnet: false,
),
Network(
  id: 'optimism-mainnet',
  name: 'Optimism',
  chainId: 10,
  rpcUrl: 'https://mainnet.optimism.io',
  symbol: 'ETH',
  explorerUrl: 'https://optimistic.etherscan.io',
  isTestnet: false,
),
```

## 📱 Cara Menggunakan Fix

### Step 1: Rebuild Aplikasi

```bash
# Clean build untuk memastikan semua perubahan ter-apply
flutter clean

# Get dependencies
flutter pub get

# Run aplikasi
flutter run
```

### Step 2: Verifikasi Network

Setelah aplikasi terbuka:

1. Lihat **network indicator** di bagian atas home screen
2. Pastikan menunjukkan **"Base"** atau chain ID **8453**
3. Jika belum, tap network indicator dan pilih **"Base"**

### Step 3: Refresh Balance

Ada 3 cara untuk refresh balance:

**Cara 1: Pull to Refresh**

- Swipe down pada home screen
- Aplikasi akan fetch balance dari Base Network

**Cara 2: Restart Aplikasi**

- Close dan buka kembali aplikasi
- Balance akan di-fetch otomatis saat startup

**Cara 3: Switch Network**

- Tap network indicator
- Pilih network lain, lalu kembali ke Base
- Balance akan di-fetch ulang

### Step 4: Verifikasi Saldo

Setelah refresh, Anda seharusnya melihat:

- **Balance:** `0.000194 ETH`
- **USD Value:** ~$0.39 (tergantung harga ETH saat ini)
- **Network:** Base

## 🌐 Tentang Base Network

### Apa itu Base?

**Base** adalah Layer 2 blockchain yang dibangun oleh **Coinbase** di atas Ethereum menggunakan teknologi Optimism.

**Karakteristik:**

- ⚡ **Gas Fee Murah:** ~$0.10 - $1 per transaksi
- 🚀 **Cepat:** Konfirmasi dalam hitungan detik
- 🔒 **Aman:** Secured by Ethereum
- 💰 **Currency:** ETH (sama seperti Ethereum)
- 🏢 **Backed by:** Coinbase

### Keuntungan Base Network

1. **Gas Fee Sangat Murah**
    - Ethereum Mainnet: $5-50 per transaksi
    - Base: $0.10-1 per transaksi
    - Hemat 50-500x!

2. **Kecepatan Tinggi**
    - Ethereum: 12-15 detik per block
    - Base: 2 detik per block
    - Konfirmasi lebih cepat!

3. **Kompatibilitas Penuh**
    - Semua tools Ethereum bekerja di Base
    - Address sama dengan Ethereum
    - Smart contracts compatible

4. **Ekosistem Berkembang**
    - Banyak DeFi protocols
    - NFT marketplaces
    - Gaming applications

### Base vs Ethereum Mainnet

| Feature  | Ethereum Mainnet | Base Network |
| -------- | ---------------- | ------------ |
| Gas Fee  | $5-50            | $0.10-1      |
| Speed    | 12-15s           | 2s           |
| Security | Highest          | High (L2)    |
| Finality | ~15 min          | ~2 min       |
| Use Case | High value       | Daily use    |

## 🔧 Network Switching

Aplikasi Anda sekarang mendukung **7 networks**:

### Mainnet Networks (Real Money)

1. **Ethereum Mainnet**
    - Chain ID: 1
    - Symbol: ETH
    - Gas: Expensive ($5-50)
    - Use: High value transactions

2. **Base** ⭐ (Your current network)
    - Chain ID: 8453
    - Symbol: ETH
    - Gas: Cheap ($0.10-1)
    - Use: Daily transactions

3. **Optimism**
    - Chain ID: 10
    - Symbol: ETH
    - Gas: Cheap ($0.50-2)
    - Use: DeFi, NFTs

4. **Arbitrum One**
    - Chain ID: 42161
    - Symbol: ETH
    - Gas: Cheap ($0.50-2)
    - Use: DeFi, Gaming

5. **Polygon**
    - Chain ID: 137
    - Symbol: MATIC
    - Gas: Very cheap ($0.01-0.10)
    - Use: Gaming, NFTs

6. **BNB Smart Chain**
    - Chain ID: 56
    - Symbol: BNB
    - Gas: Cheap ($0.10-0.50)
    - Use: DeFi, Trading

### Testnet Networks (Test Money)

7. **Sepolia Testnet**
    - Chain ID: 11155111
    - Symbol: ETH (test)
    - Gas: Free
    - Use: Testing only

## 📊 Cara Switch Network

### Di Aplikasi

1. Tap **network indicator** di bagian atas
2. Pilih network yang diinginkan dari list
3. Aplikasi akan:
    - Switch RPC connection
    - Fetch balance dari network baru
    - Update UI

### Di MetaMask (untuk konsistensi)

1. Buka MetaMask
2. Tap dropdown network di atas
3. Pilih **Base** (atau network yang sama dengan aplikasi)
4. Sekarang MetaMask dan aplikasi Anda sync!

## 🔍 Verifikasi Transaksi

### Cek di BaseScan

**Your Address:**
https://basescan.org/address/0xe43726738e770f667c5536abcb64c7aeeabd823f

**Yang Akan Terlihat:**

- Balance: 0.000194 ETH
- Transaction history
- Incoming transaction dari MetaMask
- Gas fees yang dibayar

### Cek di Aplikasi

**Home Dashboard:**

- Total Balance: $0.39 (approx)
- ETH Balance: 0.000194 ETH
- Network: Base

## 🐛 Troubleshooting

### Problem 1: Saldo Masih 0 Setelah Rebuild

**Solutions:**

```bash
# 1. Full clean
flutter clean
rm -rf build/
rm -rf .dart_tool/

# 2. Rebuild
flutter pub get
flutter run

# 3. Force refresh
# Swipe down pada home screen
```

### Problem 2: Network Tidak Berubah

**Check:**

1. Lihat network indicator - apakah menunjukkan "Base"?
2. Jika tidak, tap dan pilih Base manually
3. Restart aplikasi

**Verify RPC:**

```dart
// Di service_locator.dart, pastikan:
rpcUrl: 'https://mainnet.base.org',
```

### Problem 3: "Failed to refresh balance"

**Possible Causes:**

1. No internet connection
2. Base RPC down (rare)
3. Invalid address

**Solutions:**

1. Check internet connection
2. Wait 1 minute and try again
3. Try alternative RPC:
    ```dart
    rpcUrl: 'https://base.llamarpc.com',
    // atau
    rpcUrl: 'https://base-mainnet.public.blastapi.io',
    ```

### Problem 4: Balance Berbeda dengan BaseScan

**Explanation:**

- Balance di blockchain update real-time
- Aplikasi perlu manual refresh
- Cache mungkin outdated

**Solutions:**

1. Pull to refresh
2. Restart aplikasi
3. Clear app cache

## 💡 Tips & Best Practices

### 1. Selalu Cek Network Sebelum Transaksi

**Di MetaMask:**

- Lihat network di bagian atas
- Pastikan sama dengan aplikasi

**Di Aplikasi:**

- Lihat network indicator
- Pastikan sesuai dengan tujuan

### 2. Simpan ETH di Multiple Networks

**Strategi:**

- Ethereum Mainnet: High value, long-term
- Base: Daily transactions, DeFi
- Polygon: Gaming, NFTs
- Sepolia: Testing

### 3. Bridge Antar Network

Jika ingin pindahkan ETH dari Base ke Ethereum:

**Official Base Bridge:**
https://bridge.base.org/

**Steps:**

1. Connect wallet
2. Select: Base → Ethereum
3. Enter amount
4. Confirm transaction
5. Wait ~7 days (withdrawal period)

**Alternative (Faster):**

- Use third-party bridges (Hop, Across)
- Faster but with fees

### 4. Monitor Gas Fees

**Base Gas Tracker:**
https://basescan.org/gastracker

**Tips:**

- Base gas usually stable
- Peak hours: slightly higher
- Off-peak: cheapest

## 🔐 Security Notes

### Multi-Network Security

**Same Address, Different Networks:**

- Your address `0xe43726738e770f667c5536abcb64c7aeeabd823f` works on ALL networks
- But balance is SEPARATE on each network
- Losing private key = lose access to ALL networks

**Best Practices:**

1. ✅ Backup mnemonic securely
2. ✅ Use strong PIN
3. ✅ Verify network before sending
4. ✅ Double-check recipient address
5. ✅ Start with small test transactions

### Phishing Protection

**Red Flags:**

- ❌ Apps asking for mnemonic
- ❌ Websites asking for private key
- ❌ Unsolicited DMs about "wallet issues"
- ❌ Too-good-to-be-true offers

**Safe Practices:**

- ✅ Only enter mnemonic in official app
- ✅ Verify URLs (basescan.org, not basescan.com)
- ✅ Use hardware wallet for large amounts
- ✅ Enable 2FA where possible

## 📈 Next Steps

### Immediate (Sekarang)

1. ✅ Rebuild aplikasi
2. ✅ Verify network = Base
3. ✅ Refresh balance
4. ✅ Confirm saldo muncul

### Short-term (1-2 hari)

1. ⏳ Test send transaction di Base
2. ⏳ Explore Base DeFi apps
3. ⏳ Add more tokens (USDC, etc)
4. ⏳ Try network switching

### Medium-term (1 minggu)

1. ⏳ Bridge ETH dari Base ke Ethereum (jika perlu)
2. ⏳ Explore other L2s (Optimism, Arbitrum)
3. ⏳ Set up multi-network portfolio
4. ⏳ Learn about Base ecosystem

## 🎓 Learn More

### Official Resources

**Base Documentation:**
https://docs.base.org/

**Base Bridge:**
https://bridge.base.org/

**Base Explorer:**
https://basescan.org/

**Base Ecosystem:**
https://base.org/ecosystem

### Community

**Base Discord:**
https://discord.gg/buildonbase

**Base Twitter:**
https://twitter.com/base

**Coinbase Support:**
https://help.coinbase.com/

## 📝 Summary

**Problem:** Saldo tidak muncul karena aplikasi terhubung ke network yang salah

**Root Cause:** Transaksi di Base Network, aplikasi terhubung ke Ethereum Mainnet

**Solution:** Update RPC configuration ke Base Network

**Result:** Setelah rebuild, saldo 0.000194 ETH akan muncul

**Verification:**

- BaseScan: https://basescan.org/address/0xe43726738e770f667c5536abcb64c7aeeabd823f
- Expected Balance: 0.000194 ETH
- Network: Base (Chain ID: 8453)

---

**Document Version:** 1.0
**Last Updated:** 2026-02-19
**Status:** Ready to Deploy
**Network:** Base Mainnet (Chain ID: 8453)
