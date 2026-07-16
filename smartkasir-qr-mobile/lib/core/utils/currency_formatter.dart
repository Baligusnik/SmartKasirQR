import 'package:intl/intl.dart';

/// Formatter mata uang rupiah Indonesia.
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Mengubah angka menjadi format rupiah untuk UI kasir.
  static String rupiah(num value) => _formatter.format(value);

  /// Mencegah pembuatan instance karena formatter bersifat statis.
  CurrencyFormatter._();
}
