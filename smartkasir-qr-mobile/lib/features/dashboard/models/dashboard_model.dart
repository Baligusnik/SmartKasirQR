import 'recent_order_model.dart';

/// Model utama ringkasan dashboard kasir.
class DashboardModel {
  /// Membuat model dashboard dari ringkasan pesanan, penjualan, produk, dan
  /// pesanan terbaru.
  const DashboardModel({
    required this.orders,
    required this.today,
    required this.products,
    required this.recentOrders,
  });

  /// Ringkasan jumlah pesanan berdasarkan status.
  final OrderSummary orders;

  /// Ringkasan transaksi dan pendapatan hari ini.
  final TodaySummary today;

  /// Ringkasan produk aktif dan stok menipis.
  final ProductSummary products;

  /// Daftar pesanan terbaru dari backend.
  final List<RecentOrderModel> recentOrders;

  /// Membentuk [DashboardModel] dari field `data` response Laravel.
  ///
  /// Parameter [json] harus berisi object dashboard. List `recent_orders`
  /// boleh kosong. Nilai angka dibaca secara defensif agar aman untuk response
  /// integer, double, maupun string angka.
  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final recentOrdersJson = json['recent_orders'];

    return DashboardModel(
      orders: OrderSummary.fromJson(_asMap(json['orders'])),
      today: TodaySummary.fromJson(_asMap(json['today'])),
      products: ProductSummary.fromJson(_asMap(json['products'])),
      recentOrders: recentOrdersJson is List
          ? recentOrdersJson
                .whereType<Object?>()
                .map(_asMap)
                .map(RecentOrderModel.fromJson)
                .toList(growable: false)
          : const <RecentOrderModel>[],
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }

    return <String, dynamic>{};
  }
}

/// Ringkasan jumlah pesanan berdasarkan status operasional.
class OrderSummary {
  /// Membuat ringkasan status pesanan.
  const OrderSummary({
    required this.pending,
    required this.confirmed,
    required this.processing,
    required this.ready,
  });

  /// Jumlah pesanan menunggu.
  final int pending;

  /// Jumlah pesanan dikonfirmasi.
  final int confirmed;

  /// Jumlah pesanan sedang diproses.
  final int processing;

  /// Jumlah pesanan siap.
  final int ready;

  /// Membentuk [OrderSummary] dari object `orders` response dashboard.
  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      pending: _asInt(json['pending']),
      confirmed: _asInt(json['confirmed']),
      processing: _asInt(json['processing']),
      ready: _asInt(json['ready']),
    );
  }
}

/// Ringkasan transaksi kasir pada tanggal berjalan.
class TodaySummary {
  /// Membuat ringkasan transaksi dan pendapatan hari ini.
  const TodaySummary({
    required this.transactions,
    required this.revenue,
    required this.revenueFormatted,
  });

  /// Jumlah transaksi hari ini.
  final int transactions;

  /// Total pendapatan hari ini dalam angka.
  final int revenue;

  /// Total pendapatan hari ini dalam format rupiah.
  final String revenueFormatted;

  /// Membentuk [TodaySummary] dari object `today` response dashboard.
  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    final revenue = _asInt(json['revenue']);

    return TodaySummary(
      transactions: _asInt(json['transactions']),
      revenue: revenue,
      revenueFormatted: _asText(
        json['revenue_formatted'],
        fallback: 'Rp$revenue',
      ),
    );
  }
}

/// Ringkasan kondisi produk yang tersedia untuk kasir.
class ProductSummary {
  /// Membuat ringkasan produk aktif dan stok menipis.
  const ProductSummary({required this.totalActive, required this.lowStock});

  /// Jumlah produk aktif.
  final int totalActive;

  /// Jumlah produk dengan stok menipis.
  final int lowStock;

  /// Membentuk [ProductSummary] dari object `products` response dashboard.
  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      totalActive: _asInt(json['total_active']),
      lowStock: _asInt(json['low_stock']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return fallback;
  }

  return text;
}
