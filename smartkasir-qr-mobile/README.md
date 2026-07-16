# SmartKasir QR Mobile

SmartKasir QR Mobile adalah fondasi aplikasi kasir Flutter untuk UAS SmartKasir QR. Aplikasi ini disiapkan untuk terhubung ke backend Laravel REST API pada folder `../smartkasir-qr-api`.

Tahap 5 hanya membuat fondasi proyek, struktur folder, konfigurasi API, penyimpanan token, theme, auth repository/provider, dan halaman placeholder. Login final, integrasi halaman GET API, integrasi halaman POST API, dan build APK belum dibuat pada tahap ini.

Tahap 6 telah menambahkan autentikasi Flutter, meliputi login aktif, Bearer Token, pemeriksaan sesi melalui `/api/me`, profil pengguna sederhana, dan logout.

Tahap 7 telah menambahkan Home Dashboard melalui `GET /api/dashboard`, Bottom Navigation final empat menu, AppBar utama, akses Profil, loading, error, empty state, dan refresh dashboard.

Tahap 8 telah menambahkan tiga halaman GET API wajib: Produk, Pesanan, dan Transaksi. Ketiganya memakai Bearer Token otomatis dari `ApiClient`, mendukung pencarian/filter, pull-to-refresh, loading, error, empty state, detail page, dan penanganan sesi 401.

Dua halaman POST API, aksi PATCH pesanan, dan build APK belum dibuat pada tahap ini.

## Prasyarat

- Flutter 3.35.6 atau versi kompatibel.
- Dart 3.9.2 atau versi kompatibel.
- Backend Laravel SmartKasir QR sudah dapat berjalan.
- Android SDK untuk target APK Android.

## Menjalankan Backend Laravel

Dari folder `../smartkasir-qr-api`:

```powershell
composer install
copy .env.example .env
php artisan key:generate
New-Item database\database.sqlite -ItemType File
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Jika file SQLite sudah ada, pembuatan `database\database.sqlite` boleh dilewati.

## Akun Demo

Gunakan akun seeder Laravel berikut untuk uji login:

```text
Email    : kasir@smartkasir.test
Password : password
```

## Base URL API

Base URL dipusatkan di `lib/config/app_config.dart` memakai `dart-define`:

```dart
const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);
```

Gunakan URL sesuai target:

- Android Emulator: `http://10.0.2.2:8000/api`
- Edge atau Windows: `http://127.0.0.1:8000/api`
- Android fisik satu Wi-Fi: `http://IPV4-KOMPUTER:8000/api`

`10.0.2.2` adalah alamat khusus Android Emulator untuk mengakses `localhost` komputer host.

Untuk perangkat fisik, cari IPv4 Windows:

```powershell
ipconfig
```

Contoh jika IPv4 adalah `192.168.1.10`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

## Menjalankan Flutter

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Edge:

```powershell
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Android fisik:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Mode development Android mengaktifkan `android:usesCleartextTraffic="true"` agar HTTP lokal dapat diakses. Production sebaiknya memakai HTTPS.

## Package

- `dio` untuk REST API.
- `provider` untuk state management sederhana.
- `flutter_secure_storage` untuk menyimpan Bearer Token.
- `intl` untuk format rupiah dan tanggal.
- `flutter_lints` untuk kualitas kode.

## Endpoint Dashboard

Home Dashboard memakai endpoint:

```text
GET /api/dashboard
Authorization: Bearer TOKEN
Accept: application/json
```

Bearer Token ditambahkan otomatis oleh `ApiClient`. Response dashboard berisi ringkasan pesanan, transaksi hari ini, produk, dan pesanan terbaru.

Catatan UAS: Home Dashboard tidak dihitung sebagai salah satu dari tiga halaman GET wajib. Tiga halaman GET wajib tetap Produk, Pesanan, dan Transaksi.

## Endpoint GET Wajib Tahap 8

Halaman Produk memakai endpoint:

```text
GET /api/categories
GET /api/products
GET /api/products/{id}
```

Filter Produk yang didukung UI: `search`, `category_id`, dan `available=1/0`.

Halaman Pesanan memakai endpoint:

```text
GET /api/orders
GET /api/orders/{id}
```

Filter Pesanan yang didukung UI: `status` dan `search`.

Halaman Transaksi memakai endpoint:

```text
GET /api/transactions
GET /api/transactions/{id}
```

Filter Transaksi yang didukung UI: `search` dan `date=yyyy-MM-dd`.

Semua endpoint kasir memakai `Authorization: Bearer TOKEN` yang ditambahkan otomatis oleh `ApiClient`. Halaman tidak menyimpan token sendiri dan tidak melakukan request langsung dari widget.

## Struktur Folder

```text
lib/
|-- main.dart
|-- app.dart
|-- config/
|-- core/
|   |-- constants/
|   |-- errors/
|   |-- network/
|   |-- storage/
|   |-- utils/
|   `-- widgets/
|-- features/
|   |-- auth/
|   |-- dashboard/
|   |-- orders/
|   |-- products/
|   |-- transactions/
|   `-- profile/
`-- navigation/
```

## Pemeriksaan

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
```

Tahap 10 belum membuat APK:

```powershell
flutter build apk
```

Perintah build APK akan dikerjakan pada tahap build/release setelah audit akhir disetujui.

## Status Tahap 6

- Login final sudah dibuat.
- Bearer Token disimpan memakai `flutter_secure_storage`.
- Sesi diverifikasi melalui endpoint `/api/me`.
- Logout memanggil API dan tetap menghapus token lokal jika server gagal.
- Profil menampilkan nama, email, dan role pengguna aktif.
- Dashboard, produk, pesanan, dan transaksi masih placeholder pada akhir Tahap 6.
- Tiga halaman GET API belum selesai.
- Dua halaman POST API belum selesai.
- APK belum dibuat.

## Status Tahap 7

- Home Dashboard sudah terintegrasi dengan `GET /api/dashboard`.
- Bottom Navigation memiliki empat menu: Beranda, Pesanan, Produk, dan Transaksi.
- AppBar utama dan akses Profil tersedia.
- Loading, error, empty state, dan refresh dashboard tersedia.
- Pesanan terbaru tampil dari response dashboard.
- Sesi invalid pada dashboard menghapus token lokal dan kembali ke LoginPage.
- Dashboard dibersihkan saat logout agar data akun lama tidak tampil.
- Produk, Pesanan, dan Transaksi masih placeholder.
- Tiga halaman GET wajib belum selesai.
- Dua halaman POST belum selesai.
- APK belum dibuat.

## Status Tahap 8

- Halaman Produk sudah terintegrasi dengan `GET /api/categories`, `GET /api/products`, dan `GET /api/products/{id}`.
- Halaman Pesanan sudah terintegrasi dengan `GET /api/orders` dan `GET /api/orders/{id}`.
- Halaman Transaksi sudah terintegrasi dengan `GET /api/transactions` dan `GET /api/transactions/{id}`.
- Pencarian, filter, pull-to-refresh, loading, error, empty state, dan detail page tersedia pada tiga halaman GET wajib.
- Request API tetap melalui repository dan `ApiClient`; widget tidak melakukan request langsung.
- Sesi 401 menghapus sesi lokal melalui `AuthProvider.expireSession()` dan provider terkait di-reset.
- Logout mereset DashboardProvider, ProductProvider, OrderProvider, dan TransactionProvider.
- Tiga halaman GET wajib selesai.
- Dua halaman POST belum selesai.
- Aksi PATCH status pesanan belum selesai.
- APK belum dibuat.

## Status Tahap 9

- Halaman Tambah Produk sudah terintegrasi dengan `POST /api/products`.
- Halaman Transaksi Kasir sudah terintegrasi dengan `POST /api/transactions`.
- Kedua endpoint POST memakai Bearer Token otomatis dari `ApiClient`.
- Form Tambah Produk memiliki validasi lokal dan validasi server.
- Form Transaksi Kasir memiliki keranjang, validasi pembayaran, pencegahan submit ganda, dan validasi server.
- Request transaksi hanya mengirim `paid_amount`, `payment_method`, `product_id`, dan `quantity`; harga, subtotal, total, kembalian, kasir, stok, dan nomor transaksi tetap dihitung backend.
- Setelah POST berhasil, daftar produk, daftar transaksi, stok, dan dashboard dimuat ulang.
- State tambah produk dan keranjang transaksi dibersihkan saat logout.
- Tiga halaman GET wajib selesai pada Tahap 8.
- Dua halaman POST wajib selesai pada Tahap 9.
- PATCH status pesanan belum dibuat.
- Pembayaran pesanan QR belum dibuat.
- APK belum dibuat.

## Status Tahap 10

- Kasir dapat mengonfirmasi pesanan QR melalui `PATCH /api/orders/{id}/confirm`.
- Kasir dapat memulai proses melalui `PATCH /api/orders/{id}/process`.
- Kasir dapat menandai pesanan siap melalui `PATCH /api/orders/{id}/ready`.
- Kasir dapat membatalkan pesanan melalui `PATCH /api/orders/{id}/cancel`.
- Kasir dapat menerima pembayaran pesanan QR melalui `POST /api/transactions` dengan `order_id`.
- Pesanan QR yang dibayar menghasilkan transaksi dan berubah menjadi `completed`.
- Stok berkurang saat pesanan dikonfirmasi oleh backend.
- Stok tidak berkurang lagi saat pembayaran pesanan QR.
- Stok dikembalikan oleh backend ketika pesanan dibatalkan setelah stok dikurangi.
- Dashboard, produk, pesanan, dan transaksi disinkronkan ulang setelah aksi penting.
- Seluruh syarat fitur coding UAS sudah terpenuhi.
- APK belum dibuat.
- Screenshot laporan belum dibuat.
- Laporan PDF belum dibuat.

Alur status utama:

```text
pending -> confirmed -> processing -> ready -> completed
```

Alur pembatalan:

```text
pending/confirmed/processing/ready -> cancelled
```
