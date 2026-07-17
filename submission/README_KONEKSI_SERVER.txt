SMARTKASIR QR - README KONEKSI SERVER

Jalankan Laravel dari folder C:\SmartKasirQR\smartkasir-qr-api:
php artisan serve --host=0.0.0.0 --port=8000

URL API untuk Android Emulator:
http://10.0.2.2:8000/api

URL API untuk perangkat fisik satu Wi-Fi:
http://IPV4-KOMPUTER:8000/api
Cari IPv4 komputer dengan perintah ipconfig.

Alternatif perangkat fisik via USB:
adb reverse tcp:8000 tcp:8000
Gunakan API URL: http://127.0.0.1:8000/api

Akun demo:
Email: kasir@smartkasir.test
Password: password

APK release:
C:\SmartKasirQR\submission\02_APK\SmartKasirQR-release.apk

API base URL APK yang sudah dibuat:
http://192.168.1.3:8000/api

Jika IP komputer berubah, build ulang APK:
cd C:\SmartKasirQR\smartkasir-qr-mobile
flutter build apk --release --dart-define=API_BASE_URL=http://IPV4-KOMPUTER:8000/api

Website QR meja:
http://127.0.0.1:8000/qr/tables
Untuk HP satu jaringan:
http://IPV4-KOMPUTER:8000/qr/tables

Tata cara penggunaan ringkas:
1. Jalankan Laravel.
2. Buka Flutter web atau install APK.
3. Login dengan akun demo.
4. Kelola Produk, Pesanan, dan Transaksi dari aplikasi kasir.
5. Pelanggan membuka website QR meja untuk memilih menu dan mengirim pesanan.

Catatan: Windows Firewall harus mengizinkan php.exe menerima koneksi lokal.
HTTP cleartext hanya untuk demo lokal. Deployment publik sebaiknya memakai HTTPS.
