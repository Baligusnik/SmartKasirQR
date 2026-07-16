import '../../../core/utils/json_readers.dart';
import 'transaction_item_model.dart';

/// Model transaksi kasir dari endpoint `/transactions`.
class TransactionModel {
  /// Membuat model transaksi beserta item jika tersedia.
  const TransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.cashierId,
    required this.cashierName,
    required this.total,
    required this.totalFormatted,
    required this.paidAmount,
    required this.paidAmountFormatted,
    required this.changeAmount,
    required this.changeAmountFormatted,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    required this.itemsCount,
    required this.createdAt,
    required this.items,
    this.orderNumber,
  });

  /// ID transaksi.
  final int id;

  /// Nomor transaksi.
  final String transactionNumber;

  /// Nomor pesanan terkait, null untuk transaksi langsung.
  final String? orderNumber;

  /// ID kasir.
  final int cashierId;

  /// Nama kasir.
  final String cashierName;

  /// Total transaksi.
  final int total;

  /// Total transaksi berformat rupiah.
  final String totalFormatted;

  /// Nominal uang dibayar.
  final int paidAmount;

  /// Nominal uang dibayar berformat rupiah.
  final String paidAmountFormatted;

  /// Nominal kembalian.
  final int changeAmount;

  /// Nominal kembalian berformat rupiah.
  final String changeAmountFormatted;

  /// Metode pembayaran teknis.
  final String paymentMethod;

  /// Label metode pembayaran.
  final String paymentMethodLabel;

  /// Jumlah item transaksi.
  final int itemsCount;

  /// Waktu transaksi dibuat.
  final DateTime? createdAt;

  /// Item transaksi, kosong jika list endpoint tidak mengirim item.
  final List<TransactionItemModel> items;

  /// Membentuk [TransactionModel] dari JSON Laravel.
  ///
  /// Parameter [json] dapat berasal dari list `/transactions` maupun detail
  /// `/transactions/{id}`. Field orderNumber dapat null untuk transaksi
  /// langsung.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final cashier = JsonReaders.asMap(json['cashier']);
    final total = JsonReaders.asInt(json['total']);
    final paidAmount = JsonReaders.asInt(json['paid_amount']);
    final changeAmount = JsonReaders.asInt(json['change_amount']);
    final items = JsonReaders.asList(json['items'])
        .map(JsonReaders.asMap)
        .map(TransactionItemModel.fromJson)
        .toList(growable: false);

    return TransactionModel(
      id: JsonReaders.asInt(json['id']),
      transactionNumber: JsonReaders.asString(
        json['transaction_number'],
        fallback: '-',
      ),
      orderNumber: JsonReaders.asNullableString(json['order_number']),
      cashierId: JsonReaders.asInt(cashier['id']),
      cashierName: JsonReaders.asString(cashier['name'], fallback: '-'),
      total: total,
      totalFormatted: JsonReaders.asString(
        json['total_formatted'],
        fallback: 'Rp$total',
      ),
      paidAmount: paidAmount,
      paidAmountFormatted: JsonReaders.asString(
        json['paid_amount_formatted'],
        fallback: 'Rp$paidAmount',
      ),
      changeAmount: changeAmount,
      changeAmountFormatted: JsonReaders.asString(
        json['change_amount_formatted'],
        fallback: 'Rp$changeAmount',
      ),
      paymentMethod: JsonReaders.asString(json['payment_method']),
      paymentMethodLabel: JsonReaders.asString(
        json['payment_method_label'],
        fallback: '-',
      ),
      itemsCount: JsonReaders.asInt(json['items_count']),
      createdAt: JsonReaders.asDateTime(json['created_at']),
      items: items,
    );
  }
}
