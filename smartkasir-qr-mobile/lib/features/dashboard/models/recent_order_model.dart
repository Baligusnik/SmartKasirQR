/// Model pesanan terbaru yang ditampilkan pada Home Dashboard.
class RecentOrderModel {
  /// Membuat model pesanan terbaru dari data aman untuk UI.
  const RecentOrderModel({
    required this.id,
    required this.orderNumber,
    required this.tableName,
    required this.tableCode,
    required this.status,
    required this.statusLabel,
    required this.total,
    required this.totalFormatted,
    required this.itemsCount,
    required this.createdAt,
    this.customerName,
  });

  /// ID pesanan dari backend.
  final int id;

  /// Nomor pesanan yang tampil untuk kasir.
  final String orderNumber;

  /// Nama meja, atau fallback transaksi langsung jika meja tidak tersedia.
  final String tableName;

  /// Kode meja jika diberikan backend.
  final String tableCode;

  /// Nama pelanggan, null jika tidak dikirim atau kosong.
  final String? customerName;

  /// Status teknis pesanan dari backend.
  final String status;

  /// Label status berbahasa Indonesia dari backend.
  final String statusLabel;

  /// Total pesanan dalam angka.
  final int total;

  /// Total pesanan yang sudah diformat backend.
  final String totalFormatted;

  /// Jumlah item dalam pesanan.
  final int itemsCount;

  /// Waktu pesanan dibuat, null jika format tanggal tidak valid.
  final DateTime? createdAt;

  /// Membentuk [RecentOrderModel] dari JSON Laravel.
  ///
  /// Parameter [json] adalah satu item dari `recent_orders`. Nilai angka,
  /// meja, nama pelanggan, dan tanggal dibaca secara defensif agar UI tetap
  /// stabil jika ada nilai null atau tipe angka yang berbeda.
  factory RecentOrderModel.fromJson(Map<String, dynamic> json) {
    final table = _asMap(json['table']);
    final customerName = json['customer_name']?.toString().trim();
    final total = _asInt(json['total']);

    return RecentOrderModel(
      id: _asInt(json['id']),
      orderNumber: _asText(json['order_number'], fallback: '-'),
      tableName: _asText(table['name'], fallback: 'Transaksi Langsung'),
      tableCode: _asText(table['code']),
      customerName: customerName == null || customerName.isEmpty
          ? null
          : customerName,
      status: _asText(json['status'], fallback: 'pending'),
      statusLabel: _asText(json['status_label'], fallback: 'Menunggu'),
      total: total,
      totalFormatted: _asText(json['total_formatted'], fallback: 'Rp$total'),
      itemsCount: _asInt(json['items_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
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

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asText(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }
}
