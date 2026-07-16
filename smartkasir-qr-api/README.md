# SmartKasir QR API

SmartKasir QR adalah backend Laravel REST API untuk aplikasi kasir Flutter. Proyek ini memakai Laravel Sanctum untuk autentikasi Bearer Token dan memakai SQLite sebagai database utama resmi agar mudah di-clone, dipindahkan, dan dijalankan tanpa instalasi MySQL.

## Teknologi

- Laravel 13
- Laravel Sanctum
- SQLite `database/database.sqlite`
- Laravel Blade, Vite, CSS, dan JavaScript untuk website QR pelanggan
- `endroid/qr-code` untuk membuat QR Code lokal tanpa layanan internet
- PHPUnit Feature Test dengan SQLite dan `RefreshDatabase`

## Ketentuan Database

Proyek ini secara resmi memakai SQLite.

- Jangan mengubah `DB_CONNECTION` ke MySQL untuk kebutuhan UAS ini.
- Jangan mewajibkan `DB_HOST`, `DB_PORT`, `DB_USERNAME`, atau `DB_PASSWORD`.
- Migration memakai tipe kolom dan constraint yang kompatibel dengan SQLite.
- Status seperti role, status order, dan metode pembayaran disimpan sebagai string dan divalidasi di aplikasi, bukan enum database native.
- Foreign key SQLite aktif melalui konfigurasi Laravel `foreign_key_constraints`.
- File database lokal berada di `database/database.sqlite`.
- File SQLite diabaikan oleh Git melalui `database/.gitignore`, sehingga data test, token lama, atau transaksi percobaan tidak ikut terunggah.

Konfigurasi `.env.example` yang digunakan:

```env
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite
```

## Setup Setelah Clone

Jalankan perintah berikut dari root proyek:

```powershell
composer install
copy .env.example .env
php artisan key:generate
New-Item database\database.sqlite -ItemType File
php artisan migrate:fresh --seed
php artisan test
php artisan serve
```

Jika file `database/database.sqlite` sudah tersedia, perintah `New-Item database\database.sqlite -ItemType File` boleh dilewati.

## Akun Seeder

Seeder menyediakan akun kasir dan data dummy kategori, produk, serta meja.

```text
Email    : kasir@smartkasir.test
Password : password
Role     : cashier
Status   : aktif
```

## Endpoint Autentikasi

```http
POST /api/login
GET  /api/me
POST /api/logout
```

Endpoint `GET /api/me` dan `POST /api/logout` wajib memakai Bearer Token:

```http
Authorization: Bearer TOKEN_SANCTUM
```

## Endpoint Kategori dan Produk

Seluruh endpoint berikut wajib memakai Bearer Token:

```http
GET  /api/categories
GET  /api/products
GET  /api/products/{product}
POST /api/products
```

Contoh filter produk:

```http
GET /api/products?search=ice&category_id=2&available=1
```

Contoh tambah produk:

```json
{
  "category_id": 1,
  "name": "Nugget Goreng",
  "sku": "MKN-007",
  "description": "Nugget ayam goreng.",
  "price": 5000,
  "stock": 25,
  "unit": "porsi",
  "is_available": true
}
```

## Endpoint Dashboard, Pesanan, dan Transaksi

Endpoint kasir berikut wajib memakai Bearer Token:

```http
GET   /api/dashboard
GET   /api/orders
GET   /api/orders/{order}
PATCH /api/orders/{order}/confirm
PATCH /api/orders/{order}/process
PATCH /api/orders/{order}/ready
PATCH /api/orders/{order}/cancel
GET   /api/transactions
GET   /api/transactions/{transaction}
POST  /api/transactions
```

Endpoint publik QR meja berikut tidak memakai Bearer Token dan hanya menampilkan data aman:

```http
GET  /api/public/tables/{qrToken}/menu
POST /api/public/tables/{qrToken}/orders
GET  /api/public/orders/{orderNumber}/status
```

Alur stok:

- Pesanan publik dari QR dibuat berstatus `pending` dan belum mengurangi stok.
- Kasir mengonfirmasi pesanan melalui endpoint confirm, lalu stok dikurangi secara atomik.
- Pesanan yang sudah dikurangi stoknya dapat dibatalkan, dan stok dikembalikan satu kali.
- Transaksi langsung kasir langsung mengurangi stok ketika transaksi berhasil dibuat.
- Pembayaran pesanan QR berstatus `ready` tidak mengurangi stok lagi dan akan mengubah pesanan menjadi `completed`.

## Website Pemesanan QR

Tahap 4 menambahkan website pelanggan berbasis QR Code. Website ini adalah fitur pendukung agar pelanggan dapat memindai QR meja, memilih menu, mengisi keranjang, dan mengirim pesanan ke kasir. Website QR tidak menggantikan aplikasi Flutter UAS; Flutter belum dibuat pada Tahap 4.

Route pelanggan:

```http
GET  /menu/{qrToken}
GET  /menu/{qrToken}/cart
POST /menu/{qrToken}/orders
GET  /order/success/{orderNumber}
GET  /order/status/{orderNumber}
```

Route QR meja:

```http
GET /qr/tables
GET /qr/tables/print
```

Alur website QR:

- Buka `/qr/tables` untuk melihat QR Code semua meja aktif.
- QR Code mengarah ke `/menu/{qrToken}`, bukan endpoint JSON API.
- Pelanggan memilih menu dan keranjang disimpan sementara di `localStorage` berdasarkan QR token meja.
- Browser hanya mengirim `product_id`, `quantity`, dan `notes`; harga, subtotal, total, status, dan meja dihitung ulang oleh Laravel.
- Pesanan dibuat berstatus `pending` dan stok belum dikurangi.
- Stok baru dikurangi saat kasir mengonfirmasi pesanan melalui API kasir.
- Halaman sukses menampilkan nomor pesanan dan tombol cek status.
- Halaman status dapat diperbarui manual dan melakukan polling ringan setiap 15 detik.

## Uji QR dari Ponsel Satu Wi-Fi

Untuk menguji QR Code dari ponsel pada jaringan Wi-Fi yang sama, jalankan server agar dapat diakses perangkat lain:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Cari IPv4 komputer Windows:

```powershell
ipconfig
```

Contoh jika IPv4 komputer adalah `192.168.1.10`, atur `.env`:

```env
APP_URL=http://192.168.1.10:8000
```

Lalu buka:

```http
http://192.168.1.10:8000/qr/tables
```

QR Code akan mengarah ke URL seperti:

```http
http://192.168.1.10:8000/menu/{qrToken}
```

## Menjalankan Test

```powershell
php artisan test
```

Test memakai SQLite dan `RefreshDatabase`, sehingga tidak merusak database pengembangan.

## Laravel Pint

Karena path Windows proyek dapat berisi karakter `&`, gunakan perintah berikut:

```powershell
php .\vendor\laravel\pint\builds\pint --dirty
```

## Batas Tahap Saat Ini

Tahap yang sudah dikerjakan:

- Tahap 1: fondasi database, model relasi, Sanctum auth, seeder, respons API, dan test auth.
- Tahap 2: API kategori dan produk.
- Tahap 3: API dashboard, pesanan, transaksi, menu publik QR, dan sinkronisasi stok.
- Tahap 4: website pemesanan pelanggan melalui QR Code, keranjang localStorage, halaman status, daftar QR, dan halaman cetak QR.

Status Flutter:

Tahap 8 telah selesai sampai integrasi tiga halaman GET API wajib. Aplikasi
Flutter sekarang memiliki fondasi REST API, Dio client, secure token storage,
state autentikasi, login aktif, pemeriksaan sesi, dashboard, navigasi utama,
halaman Produk, halaman Pesanan, halaman Transaksi, detail data, pencarian,
filter, refresh, loading, error, empty state, dan pengujian dasar.

Tiga halaman GET wajib sudah selesai: Produk, Pesanan, dan Transaksi.

Halaman POST API, aksi PATCH status pesanan, dan build APK akan dilanjutkan
pada tahap berikutnya.

