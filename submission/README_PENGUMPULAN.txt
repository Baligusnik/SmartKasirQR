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
03_Laporan: DOCX/PDF laporan UAS
04_Screenshot: screenshot aktual
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
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

Status test terbaru:
Flutter analyze: No issues found.
Flutter test: 89 tests passed.
Laravel test: 95 tests passed, 267 assertions.
Laravel Pint: passed.
npm run build: passed.

Tautan GitHub Flutter: [ISI LINK GITHUB FLUTTER SETELAH PUSH]
Tautan GitHub Laravel: [ISI LINK GITHUB LARAVEL SETELAH PUSH]

Catatan Tahap 11:
Android SDK/device belum tersedia pada audit ini, sehingga APK release dan uji APK belum selesai.
Tanggal finalisasi dokumen: 16 July 2026
