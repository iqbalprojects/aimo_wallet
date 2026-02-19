# 🚀 Setup RPC Provider - Step by Step

Panduan lengkap untuk setup RPC provider agar aplikasi bisa connect ke blockchain.

---

## 📋 PILIHAN RPC PROVIDER

### 1. Infura (RECOMMENDED) ⭐

- **Free Tier:** 100,000 requests/day
- **Pros:** Reliable, popular, easy setup
- **Cons:** Rate limited on free tier
- **Website:** https://infura.io

### 2. Alchemy

- **Free Tier:** 300M compute units/month
- **Pros:** Generous free tier, advanced features
- **Cons:** Slightly complex dashboard
- **Website:** https://alchemy.com

### 3. QuickNode

- **Free Tier:** Available
- **Pros:** Fast, global network
- **Cons:** Limited free tier
- **Website:** https://quicknode.com

---

## 🔧 SETUP INFURA (Step by Step)

### Step 1: Create Account (2 menit)

1. Buka https://infura.io
2. Click "Sign Up" atau "Get Started"
3. Isi form:
    - Email
    - Password
    - Agree to terms
4. Verify email
5. Login

### Step 2: Create Project (1 menit)

1. Di dashboard, click "Create New API Key"
2. Pilih product: **"Ethereum"**
3. Isi nama project: **"Aimo Wallet"**
4. Click "Create"

### Step 3: Get API Key (30 detik)

1. Click project yang baru dibuat
2. Di tab "Settings", lihat section "Keys"
3. Copy **API KEY** (format: `abc123def456...`)

### Step 4: Get RPC URLs (30 detik)

Di halaman project, Anda akan melihat endpoints:

**Mainnet:**

```
https://mainnet.infura.io/v3/YOUR_API_KEY
```

**Sepolia Testnet:**

```
https://sepolia.infura.io/v3/YOUR_API_KEY
```

**Polygon:**

```
https://polygon-mainnet.infura.io/v3/YOUR_API_KEY
```

---

## 💻 UPDATE CODE

### Step 1: Update Service Locator

Edit file: `lib/core/di/service_locator.dart`

Cari baris ini (sekitar line 70):

```dart
// RPC Client for blockchain communication
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    // TODO: Get RPC URL from NetworkController or AppConfig
    rpcUrl: const String.fromEnvironment(
      'ETHEREUM_MAINNET_RPC',
      defaultValue: 'https://mainnet.infura.io/v3/YOUR_API_KEY',
    ),
  ),
  fenix: true,
);
```

**GANTI dengan:**

```dart
// RPC Client for blockchain communication
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    // UNTUK TESTING: Gunakan Sepolia testnet
    rpcUrl: 'https://sepolia.infura.io/v3/PASTE_YOUR_API_KEY_HERE',

    // UNTUK PRODUCTION: Gunakan mainnet
    // rpcUrl: 'https://mainnet.infura.io/v3/PASTE_YOUR_API_KEY_HERE',
  ),
  fenix: true,
);
```

**PENTING:** Ganti `PASTE_YOUR_API_KEY_HERE` dengan API key Anda!

### Step 2: Save File

Save file `service_locator.dart`

---

## 🧪 GET TESTNET ETH

Untuk testing, Anda perlu testnet ETH (gratis):

### Option 1: Sepolia Faucet (RECOMMENDED)

1. Buka https://sepoliafaucet.com/
2. Masukkan wallet address Anda
3. Click "Send Me ETH"
4. Tunggu 1-2 menit
5. Check balance di app

### Option 2: QuickNode Faucet

1. Buka https://faucet.quicknode.com/ethereum/sepolia
2. Connect wallet atau paste address
3. Request testnet ETH
4. Tunggu konfirmasi

### Option 3: Alchemy Faucet

1. Buka https://sepoliafaucet.com/
2. Login dengan Alchemy account
3. Request testnet ETH
4. Receive 0.5 ETH per day

---

## ✅ VERIFY SETUP

### Test 1: Run App

```bash
flutter pub get
flutter run
```

### Test 2: Check Balance

1. Open app
2. Create atau import wallet
3. Lihat balance
4. **Expected:** Balance muncul (bisa 0 jika belum ada ETH)
5. **If error:** Check RPC URL dan API key

### Test 3: Get Testnet ETH

1. Copy wallet address dari app
2. Request testnet ETH dari faucet
3. Tunggu 1-2 menit
4. Refresh balance di app
5. **Expected:** Balance bertambah

### Test 4: Send Transaction

1. Click "Send"
2. Enter recipient address (bisa address lain atau address sendiri)
3. Enter amount (misal: 0.01 ETH)
4. Click "Send"
5. Enter PIN
6. **Expected:** Transaction hash muncul
7. Verify di https://sepolia.etherscan.io/

---

## 🔍 TROUBLESHOOTING

### Error: "Network error"

**Possible causes:**

- API key salah
- RPC URL salah
- Internet connection issue
- Rate limit exceeded

**Solutions:**

1. Verify API key correct
2. Check RPC URL format
3. Test internet connection
4. Wait if rate limited

### Error: "Invalid API key"

**Solution:**

1. Go to Infura dashboard
2. Verify API key
3. Copy again (might have extra spaces)
4. Update code
5. Restart app

### Balance shows 0

**Possible causes:**

- Belum request testnet ETH
- Faucet belum process
- Wrong network

**Solutions:**

1. Request testnet ETH from faucet
2. Wait 1-2 minutes
3. Refresh balance
4. Check address on explorer

### Transaction fails

**Possible causes:**

- Insufficient balance
- Gas price too low
- Network congestion

**Solutions:**

1. Check balance sufficient
2. Try again with higher gas
3. Wait and retry

---

## 📱 EXAMPLE CONFIGURATION

### For Testing (Sepolia)

```dart
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    rpcUrl: 'https://sepolia.infura.io/v3/abc123def456...',
  ),
  fenix: true,
);
```

### For Production (Mainnet)

```dart
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    rpcUrl: 'https://mainnet.infura.io/v3/abc123def456...',
  ),
  fenix: true,
);
```

### For Polygon

```dart
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    rpcUrl: 'https://polygon-mainnet.infura.io/v3/abc123def456...',
  ),
  fenix: true,
);
```

---

## 🔐 SECURITY BEST PRACTICES

### DO ✅

- Keep API key private
- Use environment variables for production
- Use testnet for testing
- Monitor API usage
- Have backup provider

### DON'T ❌

- Commit API key to git
- Share API key publicly
- Use mainnet for testing
- Exceed rate limits
- Hardcode in production

---

## 📊 RATE LIMITS

### Infura Free Tier

- **Requests:** 100,000/day
- **Concurrent:** 10 requests
- **Bandwidth:** Unlimited

**Tips:**

- Cache responses when possible
- Batch requests
- Use websockets for real-time data
- Upgrade if needed

---

## 🚀 PRODUCTION CHECKLIST

Before deploying to production:

- [ ] API key configured
- [ ] Using mainnet RPC URL
- [ ] API key in environment variable (not hardcoded)
- [ ] Rate limiting handled
- [ ] Error handling tested
- [ ] Backup RPC provider configured
- [ ] Monitoring setup
- [ ] Tested with real transactions (small amounts)

---

## 📞 SUPPORT

### Infura Support

- Documentation: https://docs.infura.io/
- Status: https://status.infura.io/
- Support: support@infura.io

### Community

- Discord: https://discord.gg/infura
- Forum: https://community.infura.io/

---

## ✅ CHECKLIST

Setup completion checklist:

- [ ] RPC provider account created
- [ ] Project created
- [ ] API key obtained
- [ ] RPC URL updated in code
- [ ] Code saved
- [ ] App runs without errors
- [ ] Balance query works
- [ ] Testnet ETH received
- [ ] Transaction sent successfully
- [ ] Transaction verified on explorer

---

**Status:** Ready to test! 🎉

**Next:** Run app dan test transaksi di testnet

**Time:** ~10 menit total setup time
