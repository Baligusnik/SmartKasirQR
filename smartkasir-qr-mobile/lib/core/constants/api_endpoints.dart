/// Kumpulan endpoint REST API Laravel SmartKasir QR.
class ApiEndpoints {
  /// Endpoint login kasir.
  static const String login = '/login';

  /// Endpoint profil pengguna aktif.
  static const String me = '/me';

  /// Endpoint logout kasir.
  static const String logout = '/logout';

  /// Endpoint dashboard kasir.
  static const String dashboard = '/dashboard';

  /// Endpoint daftar kategori.
  static const String categories = '/categories';

  /// Endpoint daftar dan pembuatan produk.
  static const String products = '/products';

  /// Endpoint daftar pesanan.
  static const String orders = '/orders';

  /// Endpoint daftar transaksi.
  static const String transactions = '/transactions';

  /// Membentuk endpoint detail produk berdasarkan ID.
  static String productDetail(int id) => '/products/$id';

  /// Membentuk endpoint detail pesanan berdasarkan ID.
  static String orderDetail(int id) => '/orders/$id';

  /// Membentuk endpoint konfirmasi pesanan berdasarkan ID.
  static String orderConfirm(int id) => '/orders/$id/confirm';

  /// Membentuk endpoint proses pesanan berdasarkan ID.
  static String orderProcess(int id) => '/orders/$id/process';

  /// Membentuk endpoint pesanan siap berdasarkan ID.
  static String orderReady(int id) => '/orders/$id/ready';

  /// Membentuk endpoint pembatalan pesanan berdasarkan ID.
  static String orderCancel(int id) => '/orders/$id/cancel';

  /// Membentuk endpoint detail transaksi berdasarkan ID.
  static String transactionDetail(int id) => '/transactions/$id';

  /// Mencegah pembuatan instance karena endpoint bersifat statis.
  ApiEndpoints._();
}
