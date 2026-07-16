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

Catatan: Windows Firewall harus mengizinkan php.exe menerima koneksi lokal.
HTTP cleartext hanya untuk demo lokal. Deployment publik sebaiknya memakai HTTPS.
