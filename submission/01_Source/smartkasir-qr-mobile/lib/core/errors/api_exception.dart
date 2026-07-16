/// Exception terstruktur untuk error komunikasi REST API.
class ApiException implements Exception {
  /// Membuat exception API dengan pesan, status HTTP, dan error validasi.
  const ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors = const <String, List<String>>{},
    this.isNetworkError = false,
  });

  /// Pesan aman yang dapat ditampilkan ke pengguna.
  final String message;

  /// Status HTTP jika response server tersedia.
  final int? statusCode;

  /// Daftar error validasi dari Laravel.
  final Map<String, List<String>> validationErrors;

  /// Bernilai true ketika status menunjukkan sesi tidak valid.
  bool get isUnauthorized => statusCode == 401;

  /// Bernilai true ketika request gagal karena koneksi atau timeout.
  final bool isNetworkError;

  @override
  String toString() => message;
}
