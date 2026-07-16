# SmartKasir QR

Repository ini berisi proyek UAS SmartKasir QR dalam satu workspace.

## Struktur

- `smartkasir-qr-api/` - Backend Laravel REST API dan website QR meja.
- `smartkasir-qr-mobile/` - Aplikasi Flutter untuk kasir.
- `submission/` - Folder hasil pengumpulan berisi source, laporan, dokumentasi API, dan catatan build APK.

## Catatan Koneksi

Untuk menjalankan Flutter web di komputer yang sama dengan Laravel:

```powershell
flutter run -d web-server --web-hostname=localhost --web-port=52396 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Untuk Android emulator gunakan:

```powershell
--dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

