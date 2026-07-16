import '../../../core/utils/json_readers.dart';

/// Model item pesanan dari response Laravel.
class OrderItemModel {
  /// Membuat model item pesanan dengan snapshot harga.
  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.priceFormatted,
    required this.subtotal,
    required this.subtotalFormatted,
    this.notes,
  });

  /// ID produk.
  final int productId;

  /// Nama produk pada item pesanan.
  final String productName;

  /// Jumlah item.
  final int quantity;

  /// Harga satuan.
  final int price;

  /// Harga satuan berformat rupiah.
  final String priceFormatted;

  /// Subtotal item.
  final int subtotal;

  /// Subtotal berformat rupiah.
  final String subtotalFormatted;

  /// Catatan item jika tersedia.
  final String? notes;

  /// Membentuk [OrderItemModel] dari JSON item pesanan.
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final price = JsonReaders.asInt(json['price']);
    final subtotal = JsonReaders.asInt(json['subtotal']);

    return OrderItemModel(
      productId: JsonReaders.asInt(json['product_id']),
      productName: JsonReaders.asString(json['product_name'], fallback: '-'),
      quantity: JsonReaders.asInt(json['quantity']),
      price: price,
      priceFormatted: JsonReaders.asString(
        json['price_formatted'],
        fallback: 'Rp$price',
      ),
      subtotal: subtotal,
      subtotalFormatted: JsonReaders.asString(
        json['subtotal_formatted'],
        fallback: 'Rp$subtotal',
      ),
      notes: JsonReaders.asNullableString(json['notes']),
    );
  }
}
