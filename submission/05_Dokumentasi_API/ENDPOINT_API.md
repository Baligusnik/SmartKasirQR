# Dokumentasi Endpoint API SmartKasir QR

Base URL development browser: `http://127.0.0.1:8000/api`
Base URL Android Emulator: `http://10.0.2.2:8000/api`

Endpoint privat menggunakan header:

```http
Authorization: Bearer {{bearer_token}}
Accept: application/json
```

Token nyata tidak ditulis pada dokumentasi ini.

| No | Method | Endpoint | Auth | Request Body | Response Ringkas | Status Code | Digunakan Pada |
|---:|---|---|---|---|---|---|---|
| 1 | POST | `/api/login` | Tidak | `email`, `password`, opsional `device_name` | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Halaman Login |
| 2 | GET | `/api/me` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Pemulihan Sesi |
| 3 | POST | `/api/logout` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Profil |
| 4 | GET | `/api/dashboard` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Beranda |
| 5 | GET | `/api/categories` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Produk dan Tambah Produk |
| 6 | GET | `/api/products` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Produk |
| 7 | GET | `/api/products/{id}` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Produk |
| 8 | POST | `/api/products` | Bearer Token | `category_id`, `name`, `sku`, `description`, `price`, `stock`, `unit`, `is_available` | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Tambah Produk |
| 9 | GET | `/api/orders` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Pesanan |
| 10 | GET | `/api/orders/{id}` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Pesanan |
| 11 | PATCH | `/api/orders/{id}/confirm` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Pesanan |
| 12 | PATCH | `/api/orders/{id}/process` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Pesanan |
| 13 | PATCH | `/api/orders/{id}/ready` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Pesanan |
| 14 | PATCH | `/api/orders/{id}/cancel` | Bearer Token | Opsional `reason` | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Pesanan |
| 15 | GET | `/api/transactions` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Transaksi |
| 16 | GET | `/api/transactions/{id}` | Bearer Token | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Detail Transaksi |
| 17 | POST | `/api/transactions` | Bearer Token | Transaksi langsung: `paid_amount`, `payment_method`, `items[]`; pembayaran QR: `order_id`, `paid_amount`, `payment_method` | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Transaksi dan Pembayaran |
| 18 | GET | `/api/public/tables/{qrToken}/menu` | Tidak | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Website Pelanggan |
| 19 | POST | `/api/public/tables/{qrToken}/orders` | Tidak | `customer_name`, `notes`, `items[]` | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Website Pelanggan |
| 20 | GET | `/api/public/orders/{orderNumber}/status` | Tidak | - | JSON berisi `success`, `message`, dan `data` sesuai resource. | 200/201 sukses, 401 tanpa token, 422 validasi, 404 data tidak ditemukan | Website Pelanggan |
