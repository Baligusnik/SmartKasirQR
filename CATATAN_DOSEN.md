# Catatan Penggunaan SmartKasir QR

Dokumen ini berisi catatan singkat untuk menjalankan dan mencoba aplikasi SmartKasir QR.

## Repository

GitHub:
https://github.com/Baligusnik/SmartKasirQR

Struktur utama:

- `smartkasir-qr-api/` - Backend Laravel REST API dan website QR meja.
- `smartkasir-qr-mobile/` - Aplikasi Flutter untuk kasir.
- `submission/` - Folder pengumpulan berisi source, APK, laporan, dan dokumentasi API.

## Akun Login Kasir

Gunakan akun demo berikut untuk masuk ke aplikasi Flutter:

```text
Email    : kasir@smartkasir.test
Password : password
```

Akun tersebut dibuat otomatis dari Laravel seeder.

## Menjalankan Backend Laravel

Buka PowerShell pada folder backend:

```powershell
cd C:\SmartKasirQR\smartkasir-qr-api
composer install
copy .env.example .env
php artisan key:generate
New-Item -ItemType File database\database.sqlite -Force
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Alamat backend:

```text
http://127.0.0.1:8000
```

Jika ingin dicoba dari HP dalam jaringan Wi-Fi yang sama, gunakan alamat IP laptop/komputer. Contoh saat APK ini dibuat:

```text
http://192.168.1.3:8000
```

Jika IP laptop berubah, cek kembali dengan:

```powershell
ipconfig
```

Lihat bagian `IPv4 Address` pada adapter Wi-Fi.

## Menjalankan Flutter Web

Buka PowerShell pada folder Flutter:

```powershell
cd C:\SmartKasirQR\smartkasir-qr-mobile
flutter pub get
flutter run -d web-server --web-hostname=localhost --web-port=52396 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Buka aplikasi:

```text
http://localhost:52396
```

Untuk login gunakan akun demo:

```text
kasir@smartkasir.test
password
```

## Menjalankan APK di HP

APK tersedia di:

```text
submission/02_APK/SmartKasirQR-release.apk
```

APK ini dibuild dengan alamat API:

```text
http://192.168.1.3:8000/api
```

Agar APK bisa terhubung:

1. HP dan laptop/komputer harus berada di Wi-Fi yang sama.
2. Jalankan Laravel dengan `--host=0.0.0.0 --port=8000`.
3. Pastikan Windows Firewall mengizinkan `php.exe`.
4. Pastikan IP laptop masih `192.168.1.3`.

Jika IP laptop berubah, build ulang APK dengan IP baru:

```powershell
cd C:\SmartKasirQR\smartkasir-qr-mobile
flutter build apk --release --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api
```

Contoh:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
```

## Website QR Meja

Website QR meja dapat dibuka tanpa login:

```text
http://127.0.0.1:8000/qr/tables
```

Untuk HP satu jaringan:

```text
http://IP-LAPTOP:8000/qr/tables
```

Contoh:

```text
http://192.168.1.3:8000/qr/tables
```

Dari halaman ini pengguna dapat memilih meja, membuka menu pelanggan, memasukkan item ke keranjang, lalu mengirim pesanan.

## Tata Cara Penggunaan

### Alur Kasir

1. Jalankan backend Laravel.
2. Buka aplikasi Flutter web atau install APK.
3. Login dengan akun demo.
4. Masuk ke halaman Dashboard untuk melihat ringkasan pesanan, produk, dan transaksi.
5. Buka menu Produk untuk melihat daftar produk.
6. Tambah produk dari halaman Tambah Produk jika diperlukan.
7. Buka menu Pesanan untuk melihat pesanan dari QR meja.
8. Ubah status pesanan sesuai proses dapur/kasir.
9. Buka halaman pembayaran pesanan untuk menyelesaikan order QR.
10. Buka menu Transaksi untuk melihat transaksi yang sudah masuk.
11. Gunakan halaman Transaksi Kasir untuk membuat transaksi langsung dari kasir.

### Alur Pelanggan QR

1. Buka halaman QR meja:

```text
http://127.0.0.1:8000/qr/tables
```

2. Pilih meja.
3. Pilih menu makanan/minuman.
4. Masukkan item ke keranjang.
5. Isi nama atau catatan jika diperlukan.
6. Kirim pesanan.
7. Pesanan akan masuk ke aplikasi kasir pada menu Pesanan.

## Endpoint API Utama

Beberapa endpoint utama:

- `POST /api/login`
- `GET /api/dashboard`
- `GET /api/products`
- `POST /api/products`
- `GET /api/orders`
- `PATCH /api/orders/{order}/status`
- `GET /api/transactions`
- `POST /api/transactions`

Dokumentasi lebih lengkap tersedia di:

```text
submission/05_Dokumentasi_API/ENDPOINT_API.md
```

## Catatan Penting

- `127.0.0.1` hanya berlaku untuk komputer yang menjalankan Laravel.
- Untuk HP fisik, gunakan IP Wi-Fi laptop/komputer, bukan `127.0.0.1`.
- Untuk Android emulator, gunakan `http://10.0.2.2:8000/api`.
- Untuk web browser di komputer yang sama, gunakan `http://127.0.0.1:8000/api`.
- Aplikasi demo masih menggunakan HTTP lokal untuk kebutuhan UAS. Untuk deployment publik sebaiknya memakai HTTPS.

