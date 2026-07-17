SMARTKASIR QR - README PENGUMPULAN

Nama proyek: SmartKasir QR
Nama mahasiswa: [ISI NAMA LENGKAP MAHASISWA]
NIM: 2323050026
Program Studi: Sistem Informasi
Universitas: Universitas Tabanan

Deskripsi:
SmartKasir QR adalah aplikasi kasir Flutter yang terhubung dengan REST API Laravel dan website QR meja.

Struktur:
01_Source: source Flutter dan Laravel bersih
02_APK: APK release jika Android SDK/device sudah tersedia
03_Laporan: laporan final DOCX dan PDF
04_Screenshot: screenshot aktual aplikasi
05_Dokumentasi_API: dokumentasi endpoint

Akun demo:
Email: kasir@smartkasir.test
Password: password

Menjalankan Laravel:
cd C:\SmartKasirQR\smartkasir-qr-api
composer install
copy .env.example .env
php artisan key:generate
New-Item -ItemType File database\database.sqlite -Force
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000

Menjalankan Flutter Web:
cd C:\SmartKasirQR\smartkasir-qr-mobile
flutter pub get
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

Build APK:
flutter build apk --release --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api

APK release yang sudah dibuat:
02_APK/SmartKasirQR-release.apk

API base URL APK yang sudah dibuat:
http://192.168.1.3:8000/api

Catatan koneksi APK:
HP dan laptop harus berada pada Wi-Fi yang sama.
Laravel harus dijalankan dengan:
php artisan serve --host=0.0.0.0 --port=8000
Jika IP laptop berubah, APK perlu dibuild ulang menggunakan IP baru.

Website QR meja:
http://127.0.0.1:8000/qr/tables
Untuk HP satu jaringan:
http://IP-LAPTOP:8000/qr/tables

Tata cara penggunaan singkat:
1. Jalankan Laravel.
2. Jalankan Flutter web atau install APK.
3. Login memakai akun demo.
4. Gunakan Dashboard untuk melihat ringkasan.
5. Gunakan Produk untuk melihat/tambah produk.
6. Gunakan Pesanan untuk memproses order QR.
7. Gunakan Transaksi untuk melihat transaksi.
8. Gunakan Transaksi Kasir untuk transaksi langsung.
9. Pelanggan membuka QR meja, memilih menu, memasukkan keranjang, lalu mengirim pesanan.

Status test terbaru:
Flutter analyze: No issues found.
Flutter test: 89 tests passed.
Laravel test: 95 tests passed, 267 assertions.
Laravel Pint: passed.
npm run build: passed.

Tautan GitHub:
https://github.com/Baligusnik/SmartKasirQR

Catatan Tahap 11:
APK release sudah dibuat pada 17 July 2026.
Uji APK pada HP fisik bergantung pada koneksi satu jaringan dan IP laptop yang sesuai.
Tanggal finalisasi dokumen: 17 July 2026
