import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_message_mapper.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Status autentikasi aplikasi kasir.
enum AuthStatus {
  /// Status awal sebelum pemeriksaan token.
  initial,

  /// Proses autentikasi sedang berjalan.
  loading,

  /// User sudah login dan profil tersedia.
  authenticated,

  /// User belum login.
  unauthenticated,

  /// Proses autentikasi gagal dengan pesan error.
  failure,
}

/// Provider state autentikasi untuk login, cek sesi, dan logout.
class AuthProvider extends ChangeNotifier {
  /// Membuat provider autentikasi dengan repository yang dapat diganti saat test.
  AuthProvider({required this.authRepository});

  /// Repository yang menangani komunikasi API autentikasi.
  final AuthRepository authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _hasCheckedAuthentication = false;

  /// Status autentikasi saat ini.
  AuthStatus get status => _status;

  /// User aktif bila sudah authenticated.
  UserModel? get currentUser => _currentUser;

  /// Pesan error terakhir yang aman ditampilkan.
  String? get errorMessage => _errorMessage;

  /// Bernilai true setelah pemeriksaan token awal selesai.
  bool get hasCheckedAuthentication => _hasCheckedAuthentication;

  /// Memeriksa apakah token tersimpan masih valid melalui endpoint /me.
  ///
  /// Mengubah state menjadi authenticated jika user ditemukan, unauthenticated
  /// jika tidak ada token atau user, dan failure jika terjadi error selain sesi.
  Future<void> checkAuthentication() async {
    _setLoading();

    try {
      final hasToken = await authRepository.tokenStorage.hasToken();

      if (!hasToken) {
        _setUnauthenticated(hasCheckedAuthentication: true);
        return;
      }

      final user = await authRepository.fetchCurrentUser();

      if (user == null) {
        _setUnauthenticated(hasCheckedAuthentication: true);
        return;
      }

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _hasCheckedAuthentication = true;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await authRepository.tokenStorage.deleteToken();
        _setUnauthenticated(hasCheckedAuthentication: true);
        return;
      }

      _setFailure(
        ErrorMessageMapper.fromApiException(error),
        hasCheckedAuthentication: true,
      );
    } catch (_) {
      _setFailure(
        'Sesi belum dapat diperiksa.',
        hasCheckedAuthentication: true,
      );
    }
  }

  /// Melakukan login kasir menggunakan email dan password.
  ///
  /// Pada Tahap 5 method ini disiapkan untuk Tahap 6. Dapat melempar error
  /// yang sudah dipetakan ke state failure jika API menolak kredensial.
  Future<void> login({required String email, required String password}) async {
    _setLoading();

    try {
      _currentUser = await authRepository.login(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _hasCheckedAuthentication = true;
      notifyListeners();
    } on ApiException catch (error) {
      _setFailure(
        error.isUnauthorized
            ? error.message
            : ErrorMessageMapper.fromApiException(error),
      );
    } catch (_) {
      _setFailure('Login belum dapat diproses.');
    }
  }

  /// Logout user aktif dan menghapus token lokal.
  ///
  /// State dikembalikan menjadi unauthenticated setelah token dihapus.
  Future<void> logout() async {
    _setLoading();

    String? logoutWarning;

    try {
      await authRepository.logout();
    } on ApiException catch (error) {
      logoutWarning = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      logoutWarning =
          'Logout dari server gagal, tetapi sesi lokal telah dihapus.';
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = logoutWarning;
      _hasCheckedAuthentication = true;
      notifyListeners();
    }
  }

  /// Mengakhiri sesi lokal ketika token dinyatakan tidak valid oleh API lain.
  ///
  /// Method ini dipakai oleh fitur selain auth, misalnya dashboard yang menerima
  /// HTTP 401. Token lokal dihapus, user dikosongkan, status menjadi
  /// unauthenticated, dan pesan sesi kedaluwarsa disimpan tanpa melakukan
  /// navigasi langsung.
  Future<void> expireSession({
    String message = 'Sesi Anda telah berakhir. Silakan login kembali.',
  }) async {
    await authRepository.tokenStorage.deleteToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = message;
    _hasCheckedAuthentication = true;
    notifyListeners();
  }

  /// Menghapus pesan error tanpa mengubah status autentikasi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mengubah status menjadi loading.
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mengubah status menjadi unauthenticated dan membersihkan user.
  void _setUnauthenticated({bool hasCheckedAuthentication = false}) {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _hasCheckedAuthentication =
        _hasCheckedAuthentication || hasCheckedAuthentication;
    notifyListeners();
  }

  /// Mengubah status menjadi failure dengan pesan yang aman.
  void _setFailure(String message, {bool hasCheckedAuthentication = false}) {
    _currentUser = null;
    _status = AuthStatus.failure;
    _errorMessage = message;
    _hasCheckedAuthentication =
        _hasCheckedAuthentication || hasCheckedAuthentication;
    notifyListeners();
  }
}
