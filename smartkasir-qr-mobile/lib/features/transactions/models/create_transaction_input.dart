/// Input item transaksi langsung untuk `POST /api/transactions`.
class CreateTransactionItemInput {
  /// Membuat item request transaksi dari ID produk dan jumlah.
  const CreateTransactionItemInput({
    required this.productId,
    required this.quantity,
  });

  /// ID produk yang dibeli.
  final int productId;

  /// Jumlah produk.
  final int quantity;

  /// Mengubah item transaksi menjadi JSON request Laravel.
  ///
  /// Harga, subtotal, dan stok tidak dikirim karena backend menjadi sumber
  /// kebenaran untuk perhitungan transaksi.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'product_id': productId,
    'quantity': quantity,
  };
}

/// Input transaksi langsung kasir untuk `POST /api/transactions`.
class CreateTransactionInput {
  /// Membuat request transaksi langsung.
  const CreateTransactionInput({
    required this.paidAmount,
    required this.paymentMethod,
    required this.items,
  });

  /// Nominal uang dibayar dalam integer.
  final int paidAmount;

  /// Metode pembayaran. Tahap 9 memakai `cash`.
  final String paymentMethod;

  /// Daftar item transaksi.
  final List<CreateTransactionItemInput> items;

  /// Mengubah input menjadi JSON request Laravel.
  ///
  /// Tidak mengirim price, subtotal, total, change_amount, user_id,
  /// transaction_number, atau order_id pada transaksi langsung Tahap 9.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'paid_amount': paidAmount,
    'payment_method': paymentMethod,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}
