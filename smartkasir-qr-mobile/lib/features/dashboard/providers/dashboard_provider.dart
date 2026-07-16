import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_message_mapper.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

/// Status pemuatan dashboard kasir.
enum DashboardStatus {
  /// Belum pernah memuat dashboard.
  initial,

  /// Request dashboard pertama sedang berjalan.
  loading,

  /// Dashboard berhasil dimuat.
  loaded,

  /// Request selesai tetapi dashboard tidak berisi data utama.
  empty,

  /// Request gagal dan tidak ada data lama yang aman ditampilkan.
  failure,
}

/// Provider state untuk Home Dashboard.
class DashboardProvider extends ChangeNotifier {
  /// Membuat provider dashboard dengan repository yang dapat diganti saat test.
  DashboardProvider({required this.dashboardRepository});

  /// Repository yang mengambil data dashboard dari Laravel.
  final DashboardRepository dashboardRepository;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardModel? _dashboard;
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isUnauthorized = false;

  /// Status pemuatan dashboard saat ini.
  DashboardStatus get status => _status;

  /// Data dashboard terakhir yang berhasil dimuat.
  DashboardModel? get dashboard => _dashboard;

  /// Pesan error aman untuk UI.
  String? get errorMessage => _errorMessage;

  /// Bernilai true saat pull-to-refresh atau tombol refresh sedang berjalan.
  bool get isRefreshing => _isRefreshing;

  /// Bernilai true saat API mengembalikan 401 dan sesi harus diakhiri.
  bool get isUnauthorized => _isUnauthorized;

  /// Memuat dashboard pertama kali dari REST API Laravel.
  ///
  /// Method ini mengubah state menjadi loading, lalu loaded jika berhasil.
  /// Jika request gagal tanpa data lama, state menjadi failure. [ApiException]
  /// 401 ditandai melalui [isUnauthorized] agar layer UI dapat meminta
  /// AuthProvider membersihkan sesi tanpa dependency cycle.
  Future<void> loadDashboard() async {
    if (_status == DashboardStatus.loading || _isRefreshing) {
      return;
    }

    _status = DashboardStatus.loading;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _dashboard = await dashboardRepository.fetchDashboard();
      _status = _dashboard == null
          ? DashboardStatus.empty
          : DashboardStatus.loaded;
      _errorMessage = null;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
      _status = DashboardStatus.failure;
    } catch (_) {
      _errorMessage = 'Dashboard belum dapat dimuat.';
      _status = DashboardStatus.failure;
    } finally {
      notifyListeners();
    }
  }

  /// Memuat ulang dashboard melalui pull-to-refresh atau tombol refresh.
  ///
  /// Jika refresh gagal dan [dashboard] lama tersedia, data lama tetap
  /// dipertahankan dan [errorMessage] diisi untuk Snackbar. Jika belum ada data,
  /// method ini berperilaku seperti [loadDashboard].
  Future<void> refreshDashboard() async {
    if (_isRefreshing || _status == DashboardStatus.loading) {
      return;
    }

    if (_dashboard == null) {
      await loadDashboard();
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _dashboard = await dashboardRepository.fetchDashboard();
      _status = DashboardStatus.loaded;
      _errorMessage = null;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Dashboard belum dapat dimuat ulang.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Menghapus pesan error refresh tanpa mengubah data dashboard.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Menghapus data dashboard saat logout atau pergantian akun.
  ///
  /// State dikembalikan ke initial agar user berikutnya tidak melihat data lama.
  void reset() {
    _status = DashboardStatus.initial;
    _dashboard = null;
    _errorMessage = null;
    _isRefreshing = false;
    _isUnauthorized = false;
    notifyListeners();
  }
}
