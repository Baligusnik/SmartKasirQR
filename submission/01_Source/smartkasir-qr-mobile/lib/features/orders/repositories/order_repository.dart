import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_readers.dart';
import '../models/order_model.dart';

/// Repository untuk membaca daftar dan detail pesanan dari REST API Laravel.
class OrderRepository {
  /// Membuat repository pesanan dengan [apiClient] yang sudah menangani token.
  const OrderRepository({required this.apiClient});

  /// Client REST API bersama yang otomatis memasang Bearer Token.
  final ApiClient apiClient;

  /// Mengambil daftar pesanan dari endpoint `/orders`.
  ///
  /// Parameter [status] dan [search] dikirim sebagai query jika memiliki nilai.
  /// Method ini tidak memanggil endpoint PATCH dan melempar [ApiException] bila
  /// response gagal atau payload bukan list.
  Future<List<OrderModel>> fetchOrders({String? status, String? search}) async {
    final query = <String, Object?>{};
    final trimmedSearch = search?.trim();

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      query['search'] = trimmedSearch;
    }

    final response = await apiClient.get(
      ApiEndpoints.orders,
      queryParameters: query,
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException(message: 'Data pesanan tidak valid.');
    }

    return JsonReaders.asList(
      data,
    ).map(JsonReaders.asMap).map(OrderModel.fromJson).toList(growable: false);
  }

  /// Mengambil detail pesanan dari endpoint `/orders/{orderId}`.
  ///
  /// Detail wajib membaca endpoint khusus agar item pesanan terbaru dari
  /// backend digunakan. Melempar [ApiException] jika payload bukan object.
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    final response = await apiClient.get(ApiEndpoints.orderDetail(orderId));

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Detail pesanan tidak valid.');
    }

    return OrderModel.fromJson(JsonReaders.asMap(data));
  }

  /// Mengonfirmasi pesanan pending melalui `PATCH /orders/{id}/confirm`.
  ///
  /// Backend memvalidasi stok dan menguranginya secara atomik. Mengembalikan
  /// [OrderModel] terbaru dengan status `confirmed` bila berhasil.
  Future<OrderModel> confirmOrder(int orderId) {
    return _patchOrder(ApiEndpoints.orderConfirm(orderId));
  }

  /// Mengubah pesanan confirmed menjadi processing melalui PATCH API.
  ///
  /// Endpoint tidak mengubah stok. Melempar [ApiException] jika status pesanan
  /// sudah berubah atau transisi tidak sah.
  Future<OrderModel> processOrder(int orderId) {
    return _patchOrder(ApiEndpoints.orderProcess(orderId));
  }

  /// Menandai pesanan processing menjadi ready melalui PATCH API.
  ///
  /// Endpoint tidak mengubah stok dan mengembalikan detail pesanan terbaru.
  Future<OrderModel> markOrderReady(int orderId) {
    return _patchOrder(ApiEndpoints.orderReady(orderId));
  }

  /// Membatalkan pesanan melalui `PATCH /orders/{id}/cancel`.
  ///
  /// [reason] dikirim bila tidak kosong. Backend mengembalikan stok untuk
  /// pesanan yang stoknya sudah dikurangi.
  Future<OrderModel> cancelOrder({required int orderId, String? reason}) {
    final trimmedReason = reason?.trim();
    final data = trimmedReason == null || trimmedReason.isEmpty
        ? null
        : <String, String>{'reason': trimmedReason};

    return _patchOrder(ApiEndpoints.orderCancel(orderId), data: data);
  }

  Future<OrderModel> _patchOrder(String endpoint, {Object? data}) async {
    final response = await apiClient.patch(endpoint, data: data);

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final payload = response.data;
    if (payload is! Map) {
      throw const ApiException(message: 'Pesanan hasil aksi tidak valid.');
    }

    return OrderModel.fromJson(JsonReaders.asMap(payload));
  }
}
