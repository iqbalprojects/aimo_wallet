# 🔍 Troubleshooting: Balance Masih 0.00

## ❌ MASALAH

Balance di app menunjukkan 0.00 padahal sudah menerima transfer 0.01 Sepolia ETH.

---

## ✅ PENYEBAB

**RPC URL masih menggunakan Ethereum Mainnet, bukan Sepolia Testnet!**

Ketika teman Anda mengirim Sepolia ETH, transaksi tersebut ada di **Sepolia testnet blockchain**. Tapi aplikasi Anda query balance ke **Ethereum mainnet blockchain** (yang berbeda).

Ini seperti mencari uang di bank A, padahal uang Anda ada di bank B.

---

## 🔧 SOLUSI

### Step 1: Update RPC URL ke Sepolia

Edit file: `lib/core/di/service_locator.dart`

**Cari baris ini (sekitar line 156-163):**

```dart
// RPC Client for blockchain communication
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    // TODO: Get RPC URL from NetworkController or AppConfig
    rpcUrl: const String.fromEnvironment(
      'ETHEREUM_MAINNET_RPC',
      defaultValue: 'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
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
    // SEPOLIA TESTNET (untuk testing)
    rpcUrl: 'https://sepolia.infura.io/v3/363def80155a4bda9db9a2203db6ca28',

    // ETHEREUM MAINNET (untuk production)
    // rpcUrl: 'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
  ),
  fenix: true,
);
```

### Step 2: Restart App

```bash
# Stop app
# Kemudian run lagi:
flutter run
```

### Step 3: Refresh Balance

1. Buka app
2. Pull to refresh atau restart app
3. Balance seharusnya muncul: **0.01 ETH**

---

## ✅ VERIFIKASI

### Check di Blockchain Explorer

1. Copy wallet address dari app
2. Buka: https://sepolia.etherscan.io/
3. Paste address di search box
4. Verify balance: **0.01 ETH**

Jika balance di explorer menunjukkan 0.01 ETH tapi di app masih 0.00, berarti RPC URL belum diupdate dengan benar.

---

## 🔍 CARA CHECK RPC URL YANG AKTIF

Tambahkan log untuk debug:

```dart
// Di service_locator.dart
Get.lazyPut<RpcClient>(
  () {
    final rpcUrl = 'https://sepolia.infura.io/v3/363def80155a4bda9db9a2203db6ca28';
    print('🌐 RPC URL: $rpcUrl'); // Debug log
    return RpcClientImpl(rpcUrl: rpcUrl);
  },
  fenix: true,
);
```

Check console output saat app start. Harus muncul:

```
🌐 RPC URL: https://sepolia.infura.io/v3/...
```

---

## 📊 PERBEDAAN MAINNET vs TESTNET

### Ethereum Mainnet

- **RPC:** `https://mainnet.infura.io/v3/...`
- **Explorer:** https://etherscan.io/
- **ETH:** Real money (ada nilai)
- **Untuk:** Production

### Sepolia Testnet

- **RPC:** `https://sepolia.infura.io/v3/...`
- **Explorer:** https://sepolia.etherscan.io/
- **ETH:** Fake money (tidak ada nilai)
- **Untuk:** Testing

**PENTING:** Wallet address yang sama bisa digunakan di mainnet dan testnet, tapi balance-nya berbeda!

---

## 🎯 QUICK FIX

Jika ingin cepat, edit langsung:

```dart
// lib/core/di/service_locator.dart line ~158
rpcUrl: 'https://sepolia.infura.io/v3/363def80155a4bda9db9a2203db6ca28',
```

Save → Hot reload → Check balance

---

## ⚠️ COMMON MISTAKES

### 1. Salah Network

- ❌ Mainnet RPC + Sepolia ETH = Balance 0
- ✅ Sepolia RPC + Sepolia ETH = Balance muncul

### 2. Belum Restart App

- Hot reload mungkin tidak cukup
- Perlu full restart (stop & run lagi)

### 3. Salah Address

- Pastikan address di app sama dengan address yang menerima transfer
- Check di Sepolia explorer

### 4. Transaction Belum Confirmed

- Tunggu 1-2 menit untuk konfirmasi
- Check status di explorer

---

## 🧪 TEST SETELAH FIX

### Test 1: Check Balance

```
Expected: 0.01 ETH
Actual: _____ ETH
Status: [ ] Pass [ ] Fail
```

### Test 2: Send Transaction

```
1. Send 0.001 ETH ke address lain
2. Check transaction di explorer
3. Verify balance berkurang
Status: [ ] Pass [ ] Fail
```

### Test 3: Receive Transaction

```
1. Minta teman kirim lagi 0.01 ETH
2. Tunggu 1-2 menit
3. Refresh balance
4. Verify balance bertambah
Status: [ ] Pass [ ] Fail
```

---

## 📝 CHECKLIST

Setelah fix, pastikan:

- [ ] RPC URL updated ke Sepolia
- [ ] App di-restart (bukan hot reload)
- [ ] Balance muncul di app
- [ ] Balance match dengan explorer
- [ ] Bisa send transaction
- [ ] Transaction muncul di explorer

---

## 🚀 UNTUK PRODUCTION

Ketika siap deploy ke production:

1. **Ganti RPC URL ke Mainnet:**

```dart
rpcUrl: 'https://mainnet.infura.io/v3/YOUR_API_KEY',
```

2. **Test dengan small amount dulu**
3. **Verify semua fungsi works**
4. **Deploy**

---

## 💡 TIPS

### Dynamic Network Switching

Untuk support multiple networks, bisa implement:

```dart
String getRpcUrl(String network) {
  switch (network) {
    case 'mainnet':
      return 'https://mainnet.infura.io/v3/YOUR_KEY';
    case 'sepolia':
      return 'https://sepolia.infura.io/v3/YOUR_KEY';
    case 'polygon':
      return 'https://polygon-rpc.com';
    default:
      return 'https://sepolia.infura.io/v3/YOUR_KEY';
  }
}

// Usage:
Get.lazyPut<RpcClient>(
  () => RpcClientImpl(
    rpcUrl: getRpcUrl('sepolia'), // Change network here
  ),
  fenix: true,
);
```

---

## 📞 MASIH BERMASALAH?

Jika setelah fix balance masih 0.00:

1. **Check console logs** - Ada error message?
2. **Check internet connection** - RPC bisa diakses?
3. **Verify address** - Address di app = address di explorer?
4. **Check explorer** - Balance di explorer berapa?
5. **Try different RPC** - Coba Alchemy atau QuickNode

---

**Status:** Ready to fix! 🔧

**Estimasi:** 2 menit untuk fix + restart
