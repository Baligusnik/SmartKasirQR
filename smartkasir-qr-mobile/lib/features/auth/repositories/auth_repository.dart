import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

/// Repository autentikasi kasir melalui Laravel Sanctum Bearer Token.
class AuthRepository {
  /// Membuat repository dengan API client dan token storage.
  const AuthRepository({required this.apiClient, required this.tokenStorage});

  /// Client REST API yang sudah menambahkan token bila tersedia.
  final ApiClient apiClient;

  /// Storage aman untuk menyimpan atau menghapus token.
  final TokenStorage tokenStorage;

  /// Melakukan login kasir dan menyimpan token jika berhasil.
  ///
  /// Parameter [email] dan [password] dikirim ke API login. Mengembalikan
  /// UserModel dari response Laravel. Dapat melempar ApiException ketika
  /// kredensial salah, validasi gagal, atau server tidak dapat dihubungi.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: <String, Object>{'email': email, 'password': password},
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = _asMap(response.data);
    final token = data['token']?.toString();
    final user = _userFromResponse(data['user']);

    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Token login tidak ditemukan.');
    }

    await tokenStorage.saveToken(token);

    return user;
  }

  /// Mengambil profil user aktif dari endpoint /me.
  ///
  /// Mengembalikan null bila response tidak berisi user yang valid. Dapat
  /// melempar ApiException bila token tidak valid atau koneksi gagal.
  Future<UserModel?> fetchCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.me);

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = _asMap(response.data);

    if (!data.containsKey('user')) {
      throw const ApiException(message: 'Data pengguna tidak ditemukan.');
    }

    return _userFromResponse(data['user']);
  }

  /// Logout dari API dan menghapus token lokal.
  ///
  /// Token tetap dihapus walaupun request logout gagal agar sesi lokal bersih.
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } finally {
      await tokenStorage.deleteToken();
    }
  }

  /// Mengubah Object response menjadi Map bertipe aman.
  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }

    return <String, dynamic>{};
  }

  /// Membaca data user dari response dan memastikan field utama tersedia.
  ///
  /// Melempar [ApiException] bila response tidak berisi data user yang valid.
  UserModel _userFromResponse(Object? value) {
    final userData = _asMap(value);
    final id = userData['id'];
    final name = userData['name']?.toString().trim();
    final email = userData['email']?.toString().trim();

    if (id == null ||
        name == null ||
        name.isEmpty ||
        email == null ||
        email.isEmpty) {
      throw const ApiException(message: 'Data pengguna tidak valid.');
    }

    return UserModel.fromJson(userData);
  }
}
