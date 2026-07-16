import '../../products/models/product_model.dart';

/// Item keranjang kasir untuk transaksi langsung.
class CashierCartItem {
  /// Membuat item keranjang berdasarkan produk dan jumlah.
  const CashierCartItem({required this.product, required this.quantity});

  /// Produk yang dipilih.
  final ProductModel product;

  /// Jumlah produk pada keranjang.
  final int quantity;

  /// Subtotal sementara untuk tampilan.
  ///
  /// Backend tetap menghitung ulang harga, subtotal, total, stok, dan
  /// kembalian saat transaksi disimpan.
  int get subtotalPreview => product.price * quantity;

  /// Membuat salinan item dengan quantity baru.
  CashierCartItem copyWith({int? quantity}) {
    return CashierCartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
