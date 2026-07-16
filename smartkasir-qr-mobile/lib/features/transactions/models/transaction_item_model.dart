import '../../../core/utils/json_readers.dart';

/// Model item transaksi dari response Laravel.
class TransactionItemModel {
  /// Membuat model item transaksi dengan snapshot harga.
  const TransactionItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.priceFormatted,
    required this.subtotal,
    required this.subtotalFormatted,
  });

  /// ID produk.
  final int productId;

  /// Nama produk.
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

  /// Membentuk [TransactionItemModel] dari JSON item transaksi.
  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    final price = JsonReaders.asInt(json['price']);
    final subtotal = JsonReaders.asInt(json['subtotal']);

    return TransactionItemModel(
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
    );
  }
}
