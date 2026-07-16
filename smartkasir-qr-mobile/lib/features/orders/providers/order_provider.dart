import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_message_mapper.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

/// Status pemuatan halaman pesanan.
enum OrderStatusState {
  /// Data belum pernah dimuat.
  initial,

  /// Request awal sedang berjalan.
  loading,

  /// Pesanan berhasil dimuat.
  loaded,

  /// Request berhasil tetapi list kosong.
  empty,

  /// Request gagal tanpa data lama.
  failure,
}

/// Provider state untuk daftar, filter, dan detail pesanan.
class OrderProvider extends ChangeNotifier {
  /// Membuat provider pesanan dengan repository yang dapat diganti saat test.
  OrderProvider({required this.orderRepository});

  /// Repository pesanan yang membaca REST API Laravel.
  final OrderRepository orderRepository;

  OrderStatusState _status = OrderStatusState.initial;
  List<OrderModel> _orders = const <OrderModel>[];
  OrderModel? _selectedOrder;
  String? _selectedStatus;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isLoadingDetail = false;
  bool _isUnauthorized = false;
  bool _isUpdatingOrder = false;
  int? _updatingOrderId;
  String? _orderAction;
  String? _actionError;
  Map<String, List<String>> _actionValidationErrors =
      const <String, List<String>>{};
  OrderModel? _updatedOrder;
  int _requestSerial = 0;

  /// Status pemuatan daftar pesanan.
  OrderStatusState get status => _status;

  /// Daftar pesanan dari backend.
  List<OrderModel> get orders => _orders;

  /// Detail pesanan yang sedang dipilih.
  OrderModel? get selectedOrder => _selectedOrder;

  /// Status pesanan yang sedang difilter.
  String? get selectedStatus => _selectedStatus;

  /// Query pencarian aktif.
  String get searchQuery => _searchQuery;

  /// Pesan error aman untuk UI.
  String? get errorMessage => _errorMessage;

  /// Bernilai true saat refresh berjalan.
  bool get isRefreshing => _isRefreshing;

  /// Bernilai true saat detail sedang dimuat.
  bool get isLoadingDetail => _isLoadingDetail;

  /// Bernilai true saat API mengembalikan 401.
  bool get isUnauthorized => _isUnauthorized;

  /// Bernilai true saat aksi status pesanan sedang diproses.
  bool get isUpdatingOrder => _isUpdatingOrder;

  /// ID pesanan yang sedang menjalankan aksi.
  int? get updatingOrderId => _updatingOrderId;

  /// Nama aksi yang sedang diproses.
  String? get orderAction => _orderAction;

  /// Pesan error aman khusus aksi pesanan.
  String? get actionError => _actionError;

  /// Error validasi backend untuk aksi pesanan.
  Map<String, List<String>> get actionValidationErrors =>
      _actionValidationErrors;

  /// Pesanan terbaru hasil aksi status.
  OrderModel? get updatedOrder => _updatedOrder;

  /// Bernilai true jika pencarian atau filter status aktif.
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedStatus != null;

  /// Memuat daftar pesanan dari endpoint `/orders`.
  ///
  /// Filter [selectedStatus] dan [searchQuery] dikirim ke backend. Hasil request
  /// lama diabaikan jika ada request lebih baru.
  Future<void> loadOrders() async {
    if (_status == OrderStatusState.loading || _isRefreshing) {
      return;
    }

    final serial = ++_requestSerial;
    _status = OrderStatusState.loading;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await orderRepository.fetchOrders(
        status: _selectedStatus,
        search: _searchQuery,
      );

      if (serial != _requestSerial) {
        return;
      }

      _orders = result;
      _status = result.isEmpty
          ? OrderStatusState.empty
          : OrderStatusState.loaded;
    } on ApiException catch (error) {
      if (serial != _requestSerial) {
        return;
      }

      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
      _status = OrderStatusState.failure;
    } catch (_) {
      if (serial != _requestSerial) {
        return;
      }

      _errorMessage = 'Pesanan belum dapat dimuat.';
      _status = OrderStatusState.failure;
    } finally {
      if (serial == _requestSerial) {
        notifyListeners();
      }
    }
  }

  /// Memuat ulang pesanan tanpa menghapus data lama saat refresh gagal.
  Future<void> refreshOrders() async {
    if (_isRefreshing || _status == OrderStatusState.loading) {
      return;
    }

    if (_orders.isEmpty) {
      await loadOrders();
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await orderRepository.fetchOrders(
        status: _selectedStatus,
        search: _searchQuery,
      );
      _orders = result;
      _status = result.isEmpty
          ? OrderStatusState.empty
          : OrderStatusState.loaded;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Pesanan belum dapat dimuat ulang.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mencari pesanan berdasarkan [query] dari backend.
  Future<void> searchOrders(String query) async {
    final trimmed = query.trim();
    if (_searchQuery == trimmed && _status != OrderStatusState.failure) {
      return;
    }

    _searchQuery = trimmed;
    await loadOrders();
  }

  /// Mengubah filter status pesanan dan memuat ulang dari backend.
  Future<void> setStatusFilter(String? status) async {
    if (_selectedStatus == status) {
      return;
    }

    _selectedStatus = status;
    await loadOrders();
  }

  /// Menghapus filter status dan pencarian pesanan.
  Future<void> clearFilters() async {
    if (!hasActiveFilters) {
      return;
    }

    _selectedStatus = null;
    _searchQuery = '';
    await loadOrders();
  }

  /// Memuat detail pesanan dari endpoint `/orders/{orderId}`.
  Future<void> loadOrderDetail(int orderId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _selectedOrder = await orderRepository.fetchOrderDetail(orderId);
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Detail pesanan belum dapat dimuat.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Mengonfirmasi pesanan pending melalui `PATCH /orders/{id}/confirm`.
  ///
  /// Backend mengurangi stok bila berhasil. State detail dan list diperbarui
  /// hanya setelah response backend valid.
  Future<bool> confirmOrder(int orderId) {
    return _runOrderAction(
      orderId: orderId,
      action: 'confirm',
      updater: orderRepository.confirmOrder,
    );
  }

  /// Mengubah pesanan confirmed menjadi processing melalui REST API.
  ///
  /// Tidak mengubah stok lokal dan mengembalikan true saat backend berhasil.
  Future<bool> processOrder(int orderId) {
    return _runOrderAction(
      orderId: orderId,
      action: 'process',
      updater: orderRepository.processOrder,
    );
  }

  /// Menandai pesanan processing menjadi ready melalui REST API.
  ///
  /// Tidak mengubah stok lokal dan memperbarui selectedOrder dari response.
  Future<bool> markOrderReady(int orderId) {
    return _runOrderAction(
      orderId: orderId,
      action: 'ready',
      updater: orderRepository.markOrderReady,
    );
  }

  /// Membatalkan pesanan melalui REST API.
  ///
  /// [reason] dikirim bila tidak kosong. Backend menjadi sumber final untuk
  /// status dan pengembalian stok.
  Future<bool> cancelOrder(int orderId, {String? reason}) {
    return _runOrderAction(
      orderId: orderId,
      action: 'cancel',
      updater: (id) => orderRepository.cancelOrder(orderId: id, reason: reason),
    );
  }

  /// Membersihkan state aksi pesanan tanpa menghapus daftar dan detail.
  void clearActionState() {
    _isUpdatingOrder = false;
    _updatingOrderId = null;
    _orderAction = null;
    _actionError = null;
    _actionValidationErrors = const <String, List<String>>{};
    _updatedOrder = null;
    notifyListeners();
  }

  /// Menghapus detail pesanan terpilih.
  void clearSelectedOrder() {
    _selectedOrder = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Menghapus pesan error tanpa menghapus data.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mereset seluruh data pesanan saat logout atau pergantian akun.
  void reset() {
    _status = OrderStatusState.initial;
    _orders = const <OrderModel>[];
    _selectedOrder = null;
    _selectedStatus = null;
    _searchQuery = '';
    _errorMessage = null;
    _isRefreshing = false;
    _isLoadingDetail = false;
    _isUnauthorized = false;
    _isUpdatingOrder = false;
    _updatingOrderId = null;
    _orderAction = null;
    _actionError = null;
    _actionValidationErrors = const <String, List<String>>{};
    _updatedOrder = null;
    _requestSerial++;
    notifyListeners();
  }

  Future<bool> _runOrderAction({
    required int orderId,
    required String action,
    required Future<OrderModel> Function(int orderId) updater,
  }) async {
    if (_isUpdatingOrder) {
      return false;
    }

    _isUpdatingOrder = true;
    _updatingOrderId = orderId;
    _orderAction = action;
    _actionError = null;
    _actionValidationErrors = const <String, List<String>>{};
    _updatedOrder = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final order = await updater(orderId);
      _updatedOrder = order;
      _selectedOrder = order;
      _replaceOrderInList(order);
      return true;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _actionError = ErrorMessageMapper.fromApiException(error);
      _actionValidationErrors = error.validationErrors;
      return false;
    } catch (_) {
      _actionError = 'Aksi pesanan belum dapat diproses.';
      return false;
    } finally {
      _isUpdatingOrder = false;
      _updatingOrderId = null;
      _orderAction = null;
      notifyListeners();
    }
  }

  void _replaceOrderInList(OrderModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index == -1) {
      _orders = <OrderModel>[order, ..._orders];
      _status = OrderStatusState.loaded;
      return;
    }

    final next = List<OrderModel>.of(_orders);
    next[index] = order;
    _orders = List<OrderModel>.unmodifiable(next);
  }
}
