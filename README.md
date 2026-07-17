# SmartKasir QR

Repository ini berisi proyek UAS SmartKasir QR dalam satu workspace.

## Catatan Untuk Dosen

Panduan login, cara menjalankan aplikasi, cara mengarahkan API, dan tata cara penggunaan tersedia di:

[CATATAN_DOSEN.md](CATATAN_DOSEN.md)

## Struktur

- `smartkasir-qr-api/` - Backend Laravel REST API dan website QR meja.
- `smartkasir-qr-mobile/` - Aplikasi Flutter untuk kasir.
- `submission/` - Folder hasil pengumpulan berisi source, laporan, dokumentasi API, dan catatan build APK.

## Akun Demo

```text
Email    : kasir@smartkasir.test
Password : password
```

## APK Release

APK tersedia di:

```text
submission/02_APK/SmartKasirQR-release.apk
```

## Catatan Koneksi

Untuk menjalankan Flutter web di komputer yang sama dengan Laravel:

```powershell
flutter run -d web-server --web-hostname=localhost --web-port=52396 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Untuk Android emulator gunakan:

```powershell
--dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Untuk HP fisik satu Wi-Fi dengan laptop/komputer, jalankan Laravel dengan:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Lalu build Flutter dengan IP laptop/komputer:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api
```
