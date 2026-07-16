import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/json_readers.dart';
import '../models/create_order_payment_input.dart';
import '../models/create_transaction_input.dart';
import '../models/transaction_model.dart';

/// Repository untuk membaca daftar dan detail transaksi dari REST API Laravel.
class TransactionRepository {
  /// Membuat repository transaksi dengan [apiClient] yang sudah menangani token.
  const TransactionRepository({required this.apiClient});

  /// Client REST API bersama yang otomatis memasang Bearer Token.
  final ApiClient apiClient;

  /// Mengambil daftar transaksi dari endpoint `/transactions`.
  ///
  /// Parameter [search] dan [date] dikirim sebagai query jika memiliki nilai.
  /// [date] diformat `yyyy-MM-dd` sesuai validator Laravel. Melempar
  /// [ApiException] jika response gagal atau payload bukan list.
  Future<List<TransactionModel>> fetchTransactions({
    String? search,
    DateTime? date,
  }) async {
    final query = <String, Object?>{};
    final trimmedSearch = search?.trim();

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      query['search'] = trimmedSearch;
    }

    if (date != null) {
      query['date'] = DateFormatter.apiDate(date);
    }

    final response = await apiClient.get(
      ApiEndpoints.transactions,
      queryParameters: query,
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException(message: 'Data transaksi tidak valid.');
    }

    return JsonReaders.asList(data)
        .map(JsonReaders.asMap)
        .map(TransactionModel.fromJson)
        .toList(growable: false);
  }

  /// Mengambil detail transaksi dari endpoint `/transactions/{transactionId}`.
  ///
  /// Mengembalikan [TransactionModel] detail dan melempar [ApiException] bila
  /// payload backend bukan object.
  Future<TransactionModel> fetchTransactionDetail(int transactionId) async {
    final response = await apiClient.get(
      ApiEndpoints.transactionDetail(transactionId),
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Detail transaksi tidak valid.');
    }

    return TransactionModel.fromJson(JsonReaders.asMap(data));
  }

  /// Mengirim transaksi langsung kasir ke endpoint `POST /transactions`.
  ///
  /// [input] hanya membawa paid_amount, payment_method, dan product_id beserta
  /// quantity. Harga, subtotal, total, kembalian, kasir, dan nomor transaksi
  /// dihitung oleh backend. Melempar [ApiException] bila validasi server gagal
  /// atau payload response bukan object.
  Future<TransactionModel> createTransaction(
    CreateTransactionInput input,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.transactions,
      data: input.toJson(),
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Transaksi baru tidak valid.');
    }

    return TransactionModel.fromJson(JsonReaders.asMap(data));
  }

  /// Mengirim pembayaran pesanan QR ke endpoint `POST /transactions`.
  ///
  /// [input] hanya membawa order_id, paid_amount, dan payment_method `cash`.
  /// Backend mengambil item dari pesanan, mengubah order menjadi completed,
  /// serta menghitung total dan kembalian final.
  Future<TransactionModel> createOrderPayment(
    CreateOrderPaymentInput input,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.transactions,
      data: input.toJson(),
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Pembayaran pesanan tidak valid.');
    }

    return TransactionModel.fromJson(JsonReaders.asMap(data));
  }
}
