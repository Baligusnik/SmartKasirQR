import 'package:intl/intl.dart';

/// Formatter tanggal dan jam Indonesia untuk tampilan kasir.
class DateFormatter {
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// Mengubah DateTime menjadi teks tanggal dan jam.
  static String dateTime(DateTime value) => _dateTime.format(value);

  /// Mengubah DateTime menjadi format tanggal query backend.
  static String apiDate(DateTime value) => _apiDate.format(value);

  /// Mencegah pembuatan instance karena formatter bersifat statis.
  DateFormatter._();
}
