import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

/// Bentuk response umum dari Laravel API.
class ApiResponseBody {
  /// Membuat wrapper response API yang aman untuk data Map, List, atau null.
  const ApiResponseBody({
    required this.success,
    required this.message,
    required this.data,
  });

  /// Status sukses dari response Laravel.
  final bool success;

  /// Pesan response dari server.
  final String message;

  /// Payload response yang dapat berupa Map, List, atau null.
  final Object? data;
}

/// Client HTTP berbasis Dio untuk REST API SmartKasir QR.
class ApiClient {
  /// Membuat client API dengan base URL, token storage, dan Dio opsional.
  ApiClient({required this.tokenStorage, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: const {
                Headers.acceptHeader: 'application/json',
                Headers.contentTypeHeader: 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  /// Penyimpanan token yang dibaca untuk header Authorization.
  final TokenStorage tokenStorage;

  /// Mengirim request GET dan mengembalikan wrapper response API.
  Future<ApiResponseBody> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    return _request(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
    );
  }

  /// Mengirim request POST dan mengembalikan wrapper response API.
  Future<ApiResponseBody> post(String path, {Object? data}) {
    return _request(() => _dio.post<Object?>(path, data: data));
  }

  /// Mengirim request PATCH dan mengembalikan wrapper response API.
  Future<ApiResponseBody> patch(String path, {Object? data}) {
    return _request(() => _dio.patch<Object?>(path, data: data));
  }

  /// Menjalankan request Dio dan mengubah error menjadi ApiException.
  Future<ApiResponseBody> _request(
    Future<Response<Object?>> Function() sender,
  ) async {
    try {
      final response = await sender();

      return _parseResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Membaca struktur response Laravel yang berisi success, message, dan data.
  ApiResponseBody _parseResponse(Object? body) {
    if (body is Map<String, dynamic>) {
      return ApiResponseBody(
        success: body['success'] == true,
        message: body['message']?.toString() ?? 'Request berhasil.',
        data: body['data'],
      );
    }

    return ApiResponseBody(
      success: true,
      message: 'Request berhasil.',
      data: body,
    );
  }

  /// Mengubah DioException menjadi ApiException dengan pesan aman.
  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    final validationErrors = data is Map<String, dynamic>
        ? _parseValidationErrors(data['errors'])
        : <String, List<String>>{};

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Waktu koneksi habis. Silakan coba kembali.',
        isNetworkError: true,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message:
            'Tidak dapat terhubung ke server. Pastikan server Laravel aktif dan perangkat berada pada jaringan yang benar.',
        isNetworkError: true,
      );
    }

    final validationMessage = _firstValidationMessage(validationErrors);
    final message =
        validationMessage ?? serverMessage ?? _fallbackMessage(statusCode);

    return ApiException(
      message: message,
      statusCode: statusCode,
      validationErrors: validationErrors,
    );
  }

  /// Membaca error validasi Laravel menjadi Map bertipe aman.
  Map<String, List<String>> _parseValidationErrors(Object? errors) {
    if (errors is! Map<String, dynamic>) {
      return <String, List<String>>{};
    }

    return errors.map((key, value) {
      final messages = value is List
          ? value.map((item) => item.toString()).toList()
          : <String>[value.toString()];

      return MapEntry(key, messages);
    });
  }

  /// Mengambil pesan validasi pertama agar form dapat menampilkan error ringkas.
  String? _firstValidationMessage(Map<String, List<String>> errors) {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) {
        return messages.first;
      }
    }

    return null;
  }

  /// Menghasilkan pesan fallback berdasarkan status HTTP.
  String _fallbackMessage(int? statusCode) {
    return switch (statusCode) {
      400 => 'Permintaan tidak valid.',
      401 => 'Sesi Anda telah berakhir. Silakan login kembali.',
      403 => 'Anda tidak memiliki akses untuk aksi ini.',
      404 => 'Data tidak ditemukan.',
      409 => 'Data sedang tidak dapat diproses.',
      422 => 'Data yang diberikan tidak valid.',
      500 => 'Terjadi kesalahan pada server.',
      _ => 'Request belum dapat diproses.',
    };
  }
}
