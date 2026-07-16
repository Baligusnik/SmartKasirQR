import 'package:flutter_test/flutter_test.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/features/auth/models/user_model.dart';
import 'package:smartkasir_qr_mobile/features/auth/providers/auth_provider.dart';
import 'package:smartkasir_qr_mobile/features/auth/repositories/auth_repository.dart';

/// Fake repository untuk menguji AuthProvider tanpa request jaringan.
class FakeAuthRepository implements AuthRepository {
  /// Membuat repository palsu dengan storage dan opsi gagal saat logout.
  FakeAuthRepository({required this.tokenStorage, this.logoutException})
    : apiClient = ApiClient(tokenStorage: tokenStorage);

  @override
  final ApiClient apiClient;

  @override
  final TokenStorage tokenStorage;

  /// Exception opsional yang dilempar setelah token lokal dihapus.
  final Exception? logoutException;

  /// Menandai apakah logout pernah dipanggil.
  bool logoutCalled = false;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await tokenStorage.saveToken('fake-token');

    return const UserModel(
      id: 1,
      name: 'Kasir SmartKasir',
      email: 'kasir@smartkasir.test',
      role: 'cashier',
    );
  }

  @override
  Future<UserModel?> fetchCurrentUser() async {
    return const UserModel(
      id: 1,
      name: 'Kasir SmartKasir',
      email: 'kasir@smartkasir.test',
      role: 'cashier',
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    await tokenStorage.deleteToken();

    if (logoutException != null) {
      throw logoutException!;
    }
  }
}

void main() {
  test('logout berhasil mengakhiri sesi dan membersihkan user', () async {
    final tokenStorage = TokenStorage(MemorySecureKeyValueStore());
    final repository = FakeAuthRepository(tokenStorage: tokenStorage);
    final provider = AuthProvider(authRepository: repository);

    await provider.login(email: 'kasir@smartkasir.test', password: 'password');
    final statuses = <AuthStatus>[];
    provider.addListener(() => statuses.add(provider.status));

    await provider.logout();

    expect(repository.logoutCalled, isTrue);
    expect(statuses, <AuthStatus>[
      AuthStatus.loading,
      AuthStatus.unauthenticated,
    ]);
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.currentUser, isNull);
    expect(provider.errorMessage, isNull);
    expect(await tokenStorage.hasToken(), isFalse);
  });

  test('logout API gagal tetap mengakhiri sesi lokal', () async {
    final tokenStorage = TokenStorage(MemorySecureKeyValueStore());
    final repository = FakeAuthRepository(
      tokenStorage: tokenStorage,
      logoutException: const ApiException(
        message: 'Logout dari server gagal.',
        statusCode: 500,
      ),
    );
    final provider = AuthProvider(authRepository: repository);

    await provider.login(email: 'kasir@smartkasir.test', password: 'password');
    final statuses = <AuthStatus>[];
    provider.addListener(() => statuses.add(provider.status));

    await provider.logout();

    expect(repository.logoutCalled, isTrue);
    expect(statuses.last, AuthStatus.unauthenticated);
    expect(statuses, isNot(contains(AuthStatus.failure)));
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.currentUser, isNull);
    expect(provider.errorMessage, 'Terjadi kesalahan pada server.');
    expect(await tokenStorage.hasToken(), isFalse);
  });

  test('logout error tidak dikenal tetap tidak meninggalkan loading', () async {
    final tokenStorage = TokenStorage(MemorySecureKeyValueStore());
    final repository = FakeAuthRepository(
      tokenStorage: tokenStorage,
      logoutException: Exception('server tidak tersedia'),
    );
    final provider = AuthProvider(authRepository: repository);

    await provider.login(email: 'kasir@smartkasir.test', password: 'password');

    await provider.logout();

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.currentUser, isNull);
    expect(
      provider.errorMessage,
      'Logout dari server gagal, tetapi sesi lokal telah dihapus.',
    );
    expect(await tokenStorage.hasToken(), isFalse);
  });
}
