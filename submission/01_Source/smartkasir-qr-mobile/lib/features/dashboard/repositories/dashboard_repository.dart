import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

/// Repository untuk mengambil ringkasan dashboard dari REST API Laravel.
class DashboardRepository {
  /// Membuat repository dashboard dengan [apiClient] yang sudah menangani token.
  const DashboardRepository({required this.apiClient});

  /// Client REST API yang otomatis menambahkan Bearer Token.
  final ApiClient apiClient;

  /// Mengambil ringkasan dashboard kasir dari endpoint `/dashboard`.
  ///
  /// Request menggunakan GET melalui [ApiClient], sehingga header Authorization
  /// ditambahkan otomatis bila token tersedia. Mengembalikan [DashboardModel]
  /// saat response `success` true dan `data` berupa object. Melempar
  /// [ApiException] jika response gagal, data kosong, atau struktur data tidak
  /// valid.
  Future<DashboardModel> fetchDashboard() async {
    final response = await apiClient.get(ApiEndpoints.dashboard);

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return DashboardModel.fromJson(data);
    }

    if (data is Map) {
      return DashboardModel.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    throw const ApiException(message: 'Data dashboard tidak valid.');
  }
}
