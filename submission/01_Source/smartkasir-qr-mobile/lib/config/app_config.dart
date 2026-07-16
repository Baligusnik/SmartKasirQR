/// Konfigurasi aplikasi yang dapat diatur melalui dart-define.
class AppConfig {
  /// Base URL REST API Laravel.
  ///
  /// Default ini cocok untuk Android Emulator. Untuk Edge gunakan
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Mencegah pembuatan instance karena seluruh konfigurasi bersifat statis.
  AppConfig._();
}
