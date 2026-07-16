import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_message_mapper.dart';
import '../../orders/models/order_model.dart';
import '../../products/models/product_model.dart';
import '../models/cashier_cart_item.dart';
import '../models/create_order_payment_input.dart';
import '../models/create_transaction_input.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

/// Status pemuatan halaman transaksi.
enum TransactionStatusState {
  /// Data belum pernah dimuat.
  initial,

  /// Request awal sedang berjalan.
  loading,

  /// Transaksi berhasil dimuat.
  loaded,

  /// Request berhasil tetapi list kosong.
  empty,

  /// Request gagal tanpa data lama.
  failure,
}

/// Provider state untuk daftar, filter, dan detail transaksi.
class TransactionProvider extends ChangeNotifier {
  /// Membuat provider transaksi dengan repository yang dapat diganti saat test.
  TransactionProvider({required this.transactionRepository});

  /// Repository transaksi yang membaca REST API Laravel.
  final TransactionRepository transactionRepository;

  TransactionStatusState _status = TransactionStatusState.initial;
  List<TransactionModel> _transactions = const <TransactionModel>[];
  TransactionModel? _selectedTransaction;
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isLoadingDetail = false;
  bool _isUnauthorized = false;
  List<CashierCartItem> _cartItems = const <CashierCartItem>[];
  int _paidAmount = 0;
  bool _isCreatingTransaction = false;
  String? _createTransactionError;
  Map<String, List<String>> _createTransactionValidationErrors =
      const <String, List<String>>{};
  TransactionModel? _createdTransaction;
  bool _isPayingOrder = false;
  int? _payingOrderId;
  int _orderPaidAmount = 0;
  int _orderPaymentTotal = 0;
  String? _orderPaymentError;
  Map<String, List<String>> _orderPaymentValidationErrors =
      const <String, List<String>>{};
  TransactionModel? _paidOrderTransaction;
  int _requestSerial = 0;

  /// Status pemuatan daftar transaksi.
  TransactionStatusState get status => _status;

  /// Daftar transaksi dari backend.
  List<TransactionModel> get transactions => _transactions;

  /// Detail transaksi yang sedang dipilih.
  TransactionModel? get selectedTransaction => _selectedTransaction;

  /// Query pencarian aktif.
  String get searchQuery => _searchQuery;

  /// Tanggal filter aktif.
  DateTime? get selectedDate => _selectedDate;

  /// Pesan error aman untuk UI.
  String? get errorMessage => _errorMessage;

  /// Bernilai true saat refresh berjalan.
  bool get isRefreshing => _isRefreshing;

  /// Bernilai true saat detail sedang dimuat.
  bool get isLoadingDetail => _isLoadingDetail;

  /// Bernilai true saat API mengembalikan 401.
  bool get isUnauthorized => _isUnauthorized;

  /// Item keranjang transaksi kasir.
  List<CashierCartItem> get cartItems => _cartItems;

  /// Nominal uang dibayar untuk transaksi baru.
  int get paidAmount => _paidAmount;

  /// Bernilai true saat submit transaksi sedang berjalan.
  bool get isCreatingTransaction => _isCreatingTransaction;

  /// Pesan error aman khusus submit transaksi.
  String? get createTransactionError => _createTransactionError;

  /// Error validasi field dari Laravel untuk form transaksi.
  Map<String, List<String>> get createTransactionValidationErrors =>
      _createTransactionValidationErrors;

  /// Transaksi yang baru berhasil dibuat.
  TransactionModel? get createdTransaction => _createdTransaction;

  /// Bernilai true saat pembayaran pesanan QR sedang dikirim.
  bool get isPayingOrder => _isPayingOrder;

  /// ID pesanan yang sedang dibayar.
  int? get payingOrderId => _payingOrderId;

  /// Nominal uang dibayar untuk pesanan QR.
  int get orderPaidAmount => _orderPaidAmount;

  /// Pesan error aman khusus pembayaran pesanan.
  String? get orderPaymentError => _orderPaymentError;

  /// Error validasi field dari Laravel untuk pembayaran pesanan.
  Map<String, List<String>> get orderPaymentValidationErrors =>
      _orderPaymentValidationErrors;

  /// Transaksi hasil pembayaran pesanan QR.
  TransactionModel? get paidOrderTransaction => _paidOrderTransaction;

  /// Bernilai true jika pencarian atau filter tanggal aktif.
  bool get hasActiveFilters => _searchQuery.isNotEmpty || _selectedDate != null;

  /// Total sementara berdasarkan harga produk lokal untuk tampilan.
  int get previewTotal =>
      _cartItems.fold<int>(0, (total, item) => total + item.subtotalPreview);

  /// Kembalian sementara untuk tampilan.
  int get previewChange => _paidAmount - previewTotal;

  /// Kembalian sementara pembayaran pesanan QR untuk tampilan.
  int get previewOrderChange => _orderPaidAmount - _orderPaymentTotal;

  /// Jumlah seluruh item pada keranjang.
  int get totalItems =>
      _cartItems.fold<int>(0, (total, item) => total + item.quantity);

  /// Bernilai true jika keranjang belum berisi produk.
  bool get isCartEmpty => _cartItems.isEmpty;

  /// Bernilai true jika transaksi boleh disubmit menurut validasi lokal.
  bool get canSubmit =>
      !_isCreatingTransaction &&
      _cartItems.isNotEmpty &&
      _paidAmount >= previewTotal &&
      _cartItems.every(
        (item) =>
            item.quantity >= 1 &&
            item.quantity <= item.product.stock &&
            item.product.isAvailable &&
            item.product.canBeOrdered,
      );

  /// Bernilai true jika pembayaran order yang sedang disiapkan bisa disubmit.
  bool get canPayOrder =>
      !_isPayingOrder &&
      _payingOrderId != null &&
      _orderPaymentTotal > 0 &&
      _orderPaidAmount >= _orderPaymentTotal;

  /// Memuat daftar transaksi dari endpoint `/transactions`.
  ///
  /// Filter [searchQuery] dan [selectedDate] dikirim ke backend. Hasil request
  /// lama diabaikan jika ada request lebih baru.
  Future<void> loadTransactions() async {
    if (_status == TransactionStatusState.loading || _isRefreshing) {
      return;
    }

    final serial = ++_requestSerial;
    _status = TransactionStatusState.loading;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await transactionRepository.fetchTransactions(
        search: _searchQuery,
        date: _selectedDate,
      );

      if (serial != _requestSerial) {
        return;
      }

      _transactions = result;
      _status = result.isEmpty
          ? TransactionStatusState.empty
          : TransactionStatusState.loaded;
    } on ApiException catch (error) {
      if (serial != _requestSerial) {
        return;
      }

      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
      _status = TransactionStatusState.failure;
    } catch (_) {
      if (serial != _requestSerial) {
        return;
      }

      _errorMessage = 'Transaksi belum dapat dimuat.';
      _status = TransactionStatusState.failure;
    } finally {
      if (serial == _requestSerial) {
        notifyListeners();
      }
    }
  }

  /// Memuat ulang transaksi tanpa menghapus data lama saat refresh gagal.
  Future<void> refreshTransactions() async {
    if (_isRefreshing || _status == TransactionStatusState.loading) {
      return;
    }

    if (_transactions.isEmpty) {
      await loadTransactions();
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await transactionRepository.fetchTransactions(
        search: _searchQuery,
        date: _selectedDate,
      );
      _transactions = result;
      _status = result.isEmpty
          ? TransactionStatusState.empty
          : TransactionStatusState.loaded;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Transaksi belum dapat dimuat ulang.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mencari transaksi berdasarkan [query] dari backend.
  Future<void> searchTransactions(String query) async {
    final trimmed = query.trim();
    if (_searchQuery == trimmed && _status != TransactionStatusState.failure) {
      return;
    }

    _searchQuery = trimmed;
    await loadTransactions();
  }

  /// Mengubah filter tanggal transaksi dan memuat ulang dari backend.
  Future<void> setDateFilter(DateTime? date) async {
    if (_sameDate(_selectedDate, date)) {
      return;
    }

    _selectedDate = date;
    await loadTransactions();
  }

  /// Menghapus filter tanggal dan pencarian transaksi.
  Future<void> clearFilters() async {
    if (!hasActiveFilters) {
      return;
    }

    _searchQuery = '';
    _selectedDate = null;
    await loadTransactions();
  }

  /// Memuat detail transaksi dari endpoint `/transactions/{transactionId}`.
  Future<void> loadTransactionDetail(int transactionId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _selectedTransaction = await transactionRepository.fetchTransactionDetail(
        transactionId,
      );
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Detail transaksi belum dapat dimuat.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Menambahkan produk ke keranjang transaksi kasir.
  ///
  /// Produk yang stoknya kosong, tidak tersedia, atau tidak dapat dipesan akan
  /// ditolak dan pesan error diisi. Produk yang sudah ada akan dinaikkan
  /// quantity-nya selama tidak melebihi stok lokal.
  void addProductToCart(ProductModel product) {
    _createTransactionError = null;

    if (!product.isAvailable || !product.canBeOrdered || product.stock <= 0) {
      _createTransactionError = 'Produk tidak tersedia untuk transaksi.';
      notifyListeners();
      return;
    }

    final index = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index == -1) {
      _cartItems = <CashierCartItem>[
        ..._cartItems,
        CashierCartItem(product: product, quantity: 1),
      ];
      notifyListeners();
      return;
    }

    final current = _cartItems[index];
    if (current.quantity >= product.stock) {
      _createTransactionError = 'Stok produk tidak mencukupi.';
      notifyListeners();
      return;
    }

    _replaceCartItem(index, current.copyWith(quantity: current.quantity + 1));
  }

  /// Menaikkan jumlah produk berdasarkan [productId].
  void increaseQuantity(int productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = _cartItems[index];
    updateQuantity(productId, item.quantity + 1);
  }

  /// Menurunkan jumlah produk berdasarkan [productId].
  void decreaseQuantity(int productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = _cartItems[index];
    updateQuantity(productId, item.quantity - 1);
  }

  /// Mengubah quantity produk pada keranjang.
  ///
  /// Quantity kurang dari satu akan menghapus item. Quantity melebihi stok
  /// lokal akan ditolak agar kasir mendapat feedback cepat.
  void updateQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = _cartItems[index];
    _createTransactionError = null;

    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    if (quantity > item.product.stock) {
      _createTransactionError = 'Stok produk tidak mencukupi.';
      notifyListeners();
      return;
    }

    _replaceCartItem(index, item.copyWith(quantity: quantity));
  }

  /// Menghapus produk dari keranjang.
  void removeFromCart(int productId) {
    _cartItems = _cartItems
        .where((item) => item.product.id != productId)
        .toList(growable: false);
    notifyListeners();
  }

  /// Mengosongkan keranjang transaksi.
  void clearCart() {
    _cartItems = const <CashierCartItem>[];
    _paidAmount = 0;
    notifyListeners();
  }

  /// Mengubah nominal uang dibayar.
  void setPaidAmount(int amount) {
    _paidAmount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Menyiapkan state pembayaran untuk [order].
  ///
  /// Method ini tidak mengirim request. Nilai total dipakai hanya untuk
  /// validasi tampilan; backend tetap menghitung total final saat POST.
  void prepareOrderPayment(OrderModel order) {
    if (_payingOrderId == order.id && _orderPaymentTotal == order.total) {
      return;
    }

    _payingOrderId = order.id;
    _orderPaymentTotal = order.total;
    _orderPaidAmount = 0;
    _orderPaymentError = null;
    _orderPaymentValidationErrors = const <String, List<String>>{};
    _paidOrderTransaction = null;
    notifyListeners();
  }

  /// Mengubah nominal pembayaran pesanan QR.
  void setOrderPaidAmount(int amount) {
    _orderPaidAmount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Membuat transaksi langsung melalui `POST /transactions`.
  ///
  /// Request hanya membawa paid_amount, payment_method, dan items. Backend
  /// tetap menjadi sumber total, kembalian, stok, dan nomor transaksi.
  /// Mengembalikan true saat transaksi berhasil disimpan.
  Future<bool> createTransaction() async {
    if (_isCreatingTransaction) {
      return false;
    }

    _createTransactionError = _localTransactionError();
    _createTransactionValidationErrors = const <String, List<String>>{};
    _createdTransaction = null;

    if (_createTransactionError != null) {
      notifyListeners();
      return false;
    }

    _isCreatingTransaction = true;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final input = CreateTransactionInput(
        paidAmount: _paidAmount,
        paymentMethod: 'cash',
        items: _cartItems
            .map(
              (item) => CreateTransactionItemInput(
                productId: item.product.id,
                quantity: item.quantity,
              ),
            )
            .toList(growable: false),
      );
      final transaction = await transactionRepository.createTransaction(input);
      _createdTransaction = transaction;
      _transactions = <TransactionModel>[transaction, ..._transactions];
      _status = TransactionStatusState.loaded;
      _cartItems = const <CashierCartItem>[];
      _paidAmount = 0;
      return true;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _createTransactionError = ErrorMessageMapper.fromApiException(error);
      _createTransactionValidationErrors = error.validationErrors;
      return false;
    } catch (_) {
      _createTransactionError = 'Transaksi belum dapat disimpan.';
      return false;
    } finally {
      _isCreatingTransaction = false;
      notifyListeners();
    }
  }

  /// Membayar pesanan QR berstatus ready melalui `POST /transactions`.
  ///
  /// Request hanya membawa order_id, paid_amount, dan payment_method `cash`.
  /// Backend mengubah pesanan menjadi completed dan menghitung kembalian final.
  Future<bool> payOrder(OrderModel order) async {
    if (_isPayingOrder) {
      return false;
    }

    _payingOrderId = order.id;
    _orderPaymentTotal = order.total;
    _orderPaymentError = _localOrderPaymentError(order);
    _orderPaymentValidationErrors = const <String, List<String>>{};
    _paidOrderTransaction = null;

    if (_orderPaymentError != null) {
      notifyListeners();
      return false;
    }

    _isPayingOrder = true;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final transaction = await transactionRepository.createOrderPayment(
        CreateOrderPaymentInput(
          orderId: order.id,
          paidAmount: _orderPaidAmount,
          paymentMethod: 'cash',
        ),
      );
      _paidOrderTransaction = transaction;
      _transactions = <TransactionModel>[transaction, ..._transactions];
      _status = TransactionStatusState.loaded;
      _orderPaidAmount = 0;
      return true;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _orderPaymentError = ErrorMessageMapper.fromApiException(error);
      _orderPaymentValidationErrors = error.validationErrors;
      return false;
    } catch (_) {
      _orderPaymentError = 'Pembayaran pesanan belum dapat disimpan.';
      return false;
    } finally {
      _isPayingOrder = false;
      notifyListeners();
    }
  }

  /// Membersihkan state submit transaksi tanpa mengubah daftar transaksi.
  void clearCreateTransactionState() {
    _createTransactionError = null;
    _createTransactionValidationErrors = const <String, List<String>>{};
    _createdTransaction = null;
    _isCreatingTransaction = false;
    notifyListeners();
  }

  /// Membersihkan state pembayaran pesanan QR.
  void clearOrderPaymentState() {
    _isPayingOrder = false;
    _payingOrderId = null;
    _orderPaidAmount = 0;
    _orderPaymentTotal = 0;
    _orderPaymentError = null;
    _orderPaymentValidationErrors = const <String, List<String>>{};
    _paidOrderTransaction = null;
    notifyListeners();
  }

  /// Menghapus detail transaksi terpilih.
  void clearSelectedTransaction() {
    _selectedTransaction = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Menghapus pesan error tanpa menghapus data.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mereset seluruh data transaksi saat logout atau pergantian akun.
  void reset() {
    _status = TransactionStatusState.initial;
    _transactions = const <TransactionModel>[];
    _selectedTransaction = null;
    _searchQuery = '';
    _selectedDate = null;
    _errorMessage = null;
    _isRefreshing = false;
    _isLoadingDetail = false;
    _isUnauthorized = false;
    _cartItems = const <CashierCartItem>[];
    _paidAmount = 0;
    _isCreatingTransaction = false;
    _createTransactionError = null;
    _createTransactionValidationErrors = const <String, List<String>>{};
    _createdTransaction = null;
    _isPayingOrder = false;
    _payingOrderId = null;
    _orderPaidAmount = 0;
    _orderPaymentTotal = 0;
    _orderPaymentError = null;
    _orderPaymentValidationErrors = const <String, List<String>>{};
    _paidOrderTransaction = null;
    _requestSerial++;
    notifyListeners();
  }

  void _replaceCartItem(int index, CashierCartItem item) {
    final next = List<CashierCartItem>.of(_cartItems);
    next[index] = item;
    _cartItems = List<CashierCartItem>.unmodifiable(next);
    notifyListeners();
  }

  String? _localTransactionError() {
    if (_cartItems.isEmpty) {
      return 'Pilih minimal satu produk.';
    }

    for (final item in _cartItems) {
      if (item.quantity < 1) {
        return 'Jumlah produk tidak valid.';
      }

      if (item.quantity > item.product.stock) {
        return 'Stok ${item.product.name} tidak mencukupi.';
      }

      if (!item.product.isAvailable || !item.product.canBeOrdered) {
        return '${item.product.name} tidak tersedia.';
      }
    }

    if (_paidAmount < previewTotal) {
      return 'Uang dibayar masih kurang.';
    }

    return null;
  }

  String? _localOrderPaymentError(OrderModel order) {
    if (order.status != 'ready') {
      return 'Pesanan hanya dapat dibayar saat status siap.';
    }

    if (_orderPaidAmount <= 0) {
      return 'Uang dibayar wajib diisi.';
    }

    if (_orderPaidAmount < order.total) {
      return 'Uang dibayar masih kurang.';
    }

    return null;
  }

  bool _sameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) {
      return first == second;
    }

    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
