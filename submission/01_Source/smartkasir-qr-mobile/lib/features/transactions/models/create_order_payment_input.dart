/// Input pembayaran pesanan QR untuk `POST /api/transactions`.
class CreateOrderPaymentInput {
  /// Membuat payload pembayaran pesanan.
  const CreateOrderPaymentInput({
    required this.orderId,
    required this.paidAmount,
    required this.paymentMethod,
  });

  /// ID pesanan QR yang sudah berstatus ready.
  final int orderId;

  /// Nominal uang dibayar dalam integer.
  final int paidAmount;

  /// Metode pembayaran. Tahap 10 memakai `cash`.
  final String paymentMethod;

  /// Mengubah input menjadi JSON request Laravel.
  ///
  /// Tidak mengirim items, total, change_amount, user_id, order_number,
  /// transaction_number, atau status karena backend menjadi sumber final.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'order_id': orderId,
    'paid_amount': paidAmount,
    'payment_method': paymentMethod,
  };
}
