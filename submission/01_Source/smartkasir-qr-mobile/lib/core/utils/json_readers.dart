/// Helper kecil untuk membaca JSON API Laravel secara defensif.
class JsonReaders {
  /// Mengubah [value] menjadi Map string-key.
  ///
  /// Mengembalikan Map kosong jika [value] bukan object. Method ini tidak
  /// melakukan request API dan dipakai model/repository agar parsing JSON
  /// tetap typed dan konsisten.
  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }

    return <String, dynamic>{};
  }

  /// Mengubah [value] menjadi List object.
  ///
  /// Mengembalikan list kosong jika [value] bukan list dari response API.
  static List<Object?> asList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }

    return const <Object?>[];
  }

  /// Membaca [value] sebagai int dengan fallback aman.
  static int asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Membaca [value] sebagai bool dengan fallback aman.
  static bool asBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    if (text == 'true' || text == '1') {
      return true;
    }

    if (text == 'false' || text == '0') {
      return false;
    }

    return fallback;
  }

  /// Membaca [value] sebagai String yang sudah di-trim.
  static String asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  /// Membaca [value] sebagai String nullable yang sudah di-trim.
  static String? asNullableString(Object? value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  /// Membaca [value] sebagai DateTime nullable.
  static DateTime? asDateTime(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  /// Mencegah pembuatan instance karena helper bersifat statis.
  JsonReaders._();
}
