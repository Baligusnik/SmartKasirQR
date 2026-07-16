import 'api_exception.dart';

/// Mengubah status HTTP atau error jaringan menjadi pesan Indonesia.
class ErrorMessageMapper {
  /// Mengambil pesan aman dari ApiException.
  ///
  /// Parameter [exception] berisi status, pesan server, dan error validasi.
  /// Mengembalikan pesan bahasa Indonesia untuk UI tanpa stack trace.
  static String fromApiException(ApiException exception) {
    if (exception.isNetworkError) {
      return exception.message;
    }

    if (exception.isUnauthorized) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    return switch (exception.statusCode) {
      400 => 'Permintaan tidak valid.',
      403 => 'Anda tidak memiliki akses untuk aksi ini.',
      404 => 'Data tidak ditemukan.',
      409 => 'Data sedang tidak dapat diproses.',
      422 => exception.message,
      500 => 'Terjadi kesalahan pada server.',
      _ => exception.message,
    };
  }

  /// Mencegah pembuatan instance karena mapper bersifat statis.
  ErrorMessageMapper._();
}
