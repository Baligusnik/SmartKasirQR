import '../../../core/utils/json_readers.dart';
import 'order_item_model.dart';

/// Model pesanan kasir dari endpoint `/orders`.
class OrderModel {
  /// Membuat model pesanan beserta item jika tersedia.
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.tableId,
    required this.tableName,
    required this.tableCode,
    required this.status,
    required this.statusLabel,
    required this.total,
    required this.totalFormatted,
    required this.stockDeducted,
    required this.itemsCount,
    required this.createdAt,
    required this.items,
    this.customerName,
    this.notes,
  });

  /// ID pesanan.
  final int id;

  /// Nomor pesanan.
  final String orderNumber;

  /// ID meja jika tersedia.
  final int? tableId;

  /// Nama meja atau fallback transaksi langsung.
  final String tableName;

  /// Kode meja jika tersedia.
  final String tableCode;

  /// Nama pelanggan jika tersedia.
  final String? customerName;

  /// Status teknis pesanan.
  final String status;

  /// Label status pesanan.
  final String statusLabel;

  /// Catatan umum pesanan.
  final String? notes;

  /// Total pesanan dalam angka.
  final int total;

  /// Total pesanan berformat rupiah.
  final String totalFormatted;

  /// Status apakah stok sudah dikurangi.
  final bool stockDeducted;

  /// Jumlah item pesanan.
  final int itemsCount;

  /// Waktu pesanan dibuat.
  final DateTime? createdAt;

  /// Item pesanan, kosong jika list endpoint tidak mengirim item.
  final List<OrderItemModel> items;

  /// Membentuk [OrderModel] dari JSON Laravel.
  ///
  /// Parameter [json] dapat berasal dari list `/orders` maupun detail
  /// `/orders/{id}`. Field table, customerName, notes, dan items boleh null.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final table = JsonReaders.asMap(json['table']);
    final total = JsonReaders.asInt(json['total']);
    final items = JsonReaders.asList(json['items'])
        .map(JsonReaders.asMap)
        .map(OrderItemModel.fromJson)
        .toList(growable: false);

    return OrderModel(
      id: JsonReaders.asInt(json['id']),
      orderNumber: JsonReaders.asString(json['order_number'], fallback: '-'),
      tableId: table['id'] == null ? null : JsonReaders.asInt(table['id']),
      tableName: JsonReaders.asString(
        table['name'],
        fallback: 'Transaksi Langsung',
      ),
      tableCode: JsonReaders.asString(table['code']),
      customerName: JsonReaders.asNullableString(json['customer_name']),
      status: JsonReaders.asString(json['status'], fallback: 'pending'),
      statusLabel: JsonReaders.asString(
        json['status_label'],
        fallback: 'Menunggu',
      ),
      notes: JsonReaders.asNullableString(json['notes']),
      total: total,
      totalFormatted: JsonReaders.asString(
        json['total_formatted'],
        fallback: 'Rp$total',
      ),
      stockDeducted: JsonReaders.asBool(json['stock_deducted']),
      itemsCount: JsonReaders.asInt(json['items_count']),
      createdAt: JsonReaders.asDateTime(json['created_at']),
      items: items,
    );
  }
}
