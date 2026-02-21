# Perbaikan Fitur Swap - Integrasi 0x API

## Masalah yang Ditemukan

Fitur swap tidak berfungsi dan tidak ada request yang terlihat di dashboard 0x. Setelah mempelajari dokumentasi 0x ([Swap API Quickstart](https://docs.0x.org/docs/introduction/quickstart/swap-tokens-with-0x-swap-api)), ditemukan beberapa masalah:

### 1. API Key Tidak Valid atau Tidak Dikonfigurasi

**Masalah**: Kode menggunakan API key default yang tidak valid atau sudah expired.

**Solusi**:

- Menghapus default API key
- Menambahkan validasi untuk memastikan API key sudah dikonfigurasi
- Memberikan error message yang jelas jika API key tidak diset

```dart
// SEBELUM
static const String _apiKey = String.fromEnvironment(
  'ZERO_X_API_KEY',
  defaultValue: 'e60b82af-e6fa-4132-969e-efe1d43cd4bb', // Invalid key
);

// SESUDAH
static const String _apiKey = String.fromEnvironment(
  'ZERO_X_API_KEY',
  defaultValue: '', // Empty - forces user to set their own
);

// Validasi ditambahkan di setiap method
if (_apiKey.isEmpty) {
  throw ZeroXApiException(
    'ZERO_X_API_KEY is not set. Please get your API key from https://dashboard.0x.org/'
  );
}
```

### 2. Header HTTP yang Tidak Sesuai Dokumentasi

**Masalah**: Kode mengirim header `Accept: application/json` dan `0x-version: v2` yang tidak diperlukan dan mungkin menyebabkan request ditolak.

**Solusi**: Menurut dokumentasi 0x, hanya header `0x-api-key` yang diperlukan.

```dart
// SEBELUM (salah)
headers: {
  'Accept': 'application/json',
  '0x-api-key': _apiKey,
  '0x-version': 'v2',
}

// SESUDAH (benar)
headers: {
  '0x-api-key': _apiKey,
}
```

### 3. Tidak Ada Logging untuk Debugging

**Masalah**: Sulit untuk mendiagnosis masalah karena tidak ada logging.

**Solusi**: Menambahkan logging untuk:

- Request URL
- Response status code
- Error messages
- Success confirmations

```dart
print('[0x API] GET $uri');
print('[0x API] Response status: ${response.statusCode}');
print('[0x API] Error response: ${response.body}');
print('[0x API] Success - received quote data');
```

### 4. Tidak Ada Endpoint Price (Indicative Quote)

**Masalah**: Kode langsung memanggil `/quote` endpoint tanpa terlebih dahulu mendapatkan harga indikasi. Ini tidak sesuai dengan best practice 0x.

**Solusi**: Menambahkan method `getPrice()` untuk mendapatkan harga indikasi sebelum melakukan swap.

## Perubahan yang Dilakukan

### 1. Perbaikan Method `getQuote()`

- Menghapus header yang tidak perlu
- Menambahkan validasi API key
- Menambahkan logging untuk debugging
- Menyederhanakan request sesuai dokumentasi 0x

### 2. Penambahan Method `getPrice()`

- Menambahkan endpoint `/price` untuk mendapatkan harga indikasi
- Memungkinkan user melihat harga sebelum commit ke swap
- Sesuai dengan flow yang direkomendasikan 0x

### 3. Perbaikan Error Handling

- Error message yang lebih jelas
- Logging untuk debugging
- Validasi API key sebelum request

## Alur Swap yang Benar (Sesuai Dokumentasi 0x)

```
1. Get Indicative Price (getPrice) - OPTIONAL tapi recommended
   └─> Tampilkan harga ke user untuk review

2. Set Token Allowance (jika diperlukan)
   ├─> Check allowance
   ├─> Build approve transaction
   ├─> Sign & broadcast approval
   └─> Wait for confirmation

3. Fetch Firm Quote (getQuote) - REQUIRED
   └─> Market maker reserves assets

4. Submit Transaction
   ├─> Sign transaction
   └─> Broadcast to network
```

## Langkah-Langkah untuk Memperbaiki

### 1. Dapatkan API Key 0x

1. Kunjungi https://dashboard.0x.org/
2. Buat akun atau login
3. Generate API key baru
4. Copy API key

### 2. Konfigurasi API Key

#### Opsi A: Menggunakan file .env (Recommended)

Edit file `.env` di root project:

```env
ZERO_X_API_KEY=paste-your-api-key-here
```

#### Opsi B: Menggunakan --dart-define saat build

```bash
flutter run --dart-define=ZERO_X_API_KEY=your-api-key-here
```

#### Opsi C: Menambahkan ke build configuration

Edit `android/app/build.gradle` atau `ios/Runner/Info.plist` untuk menambahkan environment variable.

### 3. Rebuild Aplikasi

Karena API key dibaca saat compile time, rebuild aplikasi:

```bash
flutter clean
flutter pub get
flutter run --dart-define=ZERO_X_API_KEY=your-api-key-here
```

### 4. Test Swap

1. Buka aplikasi
2. Pilih network yang didukung (Ethereum, Polygon, BSC, Base, Arbitrum, Optimism)
3. Pilih token untuk swap
4. Masukkan amount
5. Klik "Get Quote"
6. Lihat console log untuk melihat request/response
7. Cek dashboard 0x untuk melihat request

## Debugging

### Cek Console Log

Setelah perubahan ini, Anda akan melihat log seperti:

```
[0x API] GET https://api.0x.org/swap/allowance-holder/quote?chainId=1&sellToken=0x...
[0x API] Response status: 200
[0x API] Success - received quote data
```

Jika ada error:

```
[0x API] Response status: 401
[0x API] Error response: {"reason":"Invalid API key"}
```

### Troubleshooting

#### Error: "ZERO_X_API_KEY is not set"

**Penyebab**: API key tidak dikonfigurasi atau tidak terbaca saat compile time.

**Solusi**:

1. Pastikan API key sudah ditambahkan ke `.env` atau `--dart-define`
2. Rebuild aplikasi dengan `flutter clean && flutter run`
3. Jika menggunakan `.env`, pastikan package `flutter_dotenv` sudah dikonfigurasi

#### Error: "Invalid API key" (401)

**Penyebab**: API key tidak valid atau sudah expired.

**Solusi**:

1. Generate API key baru di https://dashboard.0x.org/
2. Update `.env` dengan API key yang baru
3. Rebuild aplikasi

#### Error: "Chain ID X is not supported"

**Penyebab**: Network yang dipilih tidak didukung oleh 0x API.

**Solusi**:

1. Switch ke network yang didukung:
    - Ethereum (chainId: 1)
    - Polygon (chainId: 137)
    - BSC (chainId: 56)
    - Base (chainId: 8453)
    - Arbitrum (chainId: 42161)
    - Optimism (chainId: 10)

#### Tidak Ada Request di Dashboard 0x

**Penyebab**: Request tidak sampai ke server 0x.

**Solusi**:

1. Cek console log untuk melihat apakah request dikirim
2. Cek response status code
3. Pastikan API key valid
4. Pastikan network connection aktif
5. Cek firewall atau proxy settings

## Rekomendasi Tambahan

### 1. Implementasi getPrice() di UI (Optional)

Untuk UX yang lebih baik, pertimbangkan untuk memanggil `getPrice()` terlebih dahulu sebelum `getQuote()`:

```dart
// Di swap_controller.dart, tambahkan method:
Future<SwapQuote?> getPrice({...}) async {
  final useCase = getSwapQuoteUseCase;
  if (useCase == null) return null;

  // Call getPrice instead of getQuote
  final quote = await useCase.callPrice(...);
  return quote;
}
```

### 2. Rate Limiting

0x API memiliki rate limit. Pertimbangkan untuk:

- Debounce input amount (tunggu 500ms sebelum fetch quote)
- Cache quote untuk beberapa detik
- Tampilkan loading state yang jelas

### 3. Error Handling yang Lebih Baik

Tambahkan handling untuk error spesifik:

- Insufficient liquidity
- Price impact too high
- Slippage too low
- Network congestion

### 4. Monitoring

Untuk production, pertimbangkan:

- Menghapus print statements
- Menggunakan proper logging library (logger, sentry)
- Monitoring API usage di dashboard 0x
- Alert jika error rate tinggi

## Referensi

- [0x Swap API Quickstart](https://docs.0x.org/docs/introduction/quickstart/swap-tokens-with-0x-swap-api)
- [0x API Documentation](https://0x.org/docs/api)
- [0x Dashboard](https://dashboard.0x.org/)
- [0x API Reference](https://0x.org/docs/api/swap/v2/introduction)

## Testing Checklist

Setelah implementasi, test hal-hal berikut:

- [ ] API key terkonfigurasi dengan benar
- [ ] Request terlihat di dashboard 0x
- [ ] Console log menampilkan request/response
- [ ] Quote berhasil didapatkan untuk berbagai token pairs
- [ ] Error handling bekerja dengan baik
- [ ] Swap berhasil dieksekusi
- [ ] Transaction hash muncul setelah broadcast
- [ ] Balance terupdate setelah swap berhasil
