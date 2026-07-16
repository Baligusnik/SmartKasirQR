import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:smartkasir_qr_mobile/app.dart';
import 'package:smartkasir_qr_mobile/config/app_theme.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/features/auth/models/user_model.dart';
import 'package:smartkasir_qr_mobile/features/auth/pages/login_page.dart';
import 'package:smartkasir_qr_mobile/features/auth/providers/auth_provider.dart';
import 'package:smartkasir_qr_mobile/features/auth/repositories/auth_repository.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartkasir_qr_mobile/features/orders/providers/order_provider.dart';
import 'package:smartkasir_qr_mobile/features/orders/repositories/order_repository.dart';
import 'package:smartkasir_qr_mobile/features/profile/pages/profile_page.dart';
import 'package:smartkasir_qr_mobile/features/products/providers/product_provider.dart';
import 'package:smartkasir_qr_mobile/features/products/repositories/product_repository.dart';
import 'package:smartkasir_qr_mobile/features/transactions/providers/transaction_provider.dart';
import 'package:smartkasir_qr_mobile/features/transactions/repositories/transaction_repository.dart';
import 'package:smartkasir_qr_mobile/navigation/main_navigation_page.dart';

/// Membuat user kasir yang dipakai oleh fake repository.
const testUser = UserModel(
  id: 1,
  name: 'Kasir SmartKasir',
  email: 'kasir@smartkasir.test',
  role: 'cashier',
);

/// Client API palsu untuk menguji AuthRepository tanpa jaringan.
class FakeApiClient implements ApiClient {
  /// Membuat client palsu dengan callback request yang dapat diatur.
  FakeApiClient({
    required this.tokenStorage,
    this.postHandler,
    this.getHandler,
  });

  @override
  final TokenStorage tokenStorage;

  /// Callback untuk request POST.
  final Future<ApiResponseBody> Function(String path, Object? data)?
  postHandler;

  /// Callback untuk request GET.
  final Future<ApiResponseBody> Function(String path)? getHandler;

  /// Payload terakhir yang dikirim melalui POST.
  Object? lastPostData;

  /// Path terakhir yang dikirim melalui POST.
  String? lastPostPath;

  /// Jumlah request GET.
  int getCallCount = 0;

  @override
  Future<ApiResponseBody> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    getCallCount += 1;

    if (getHandler != null) {
      return getHandler!(path);
    }

    throw const ApiException(message: 'GET tidak disiapkan.');
  }

  @override
  Future<ApiResponseBody> patch(String path, {Object? data}) async {
    throw const ApiException(message: 'PATCH tidak disiapkan.');
  }

  @override
  Future<ApiResponseBody> post(String path, {Object? data}) async {
    lastPostPath = path;
    lastPostData = data;

    if (postHandler != null) {
      return postHandler!(path, data);
    }

    throw const ApiException(message: 'POST tidak disiapkan.');
  }
}

/// Repository palsu untuk menguji AuthProvider dan widget auth.
class FakeAuthRepository implements AuthRepository {
  /// Membuat fake repository dengan perilaku login, sesi, dan logout terkontrol.
  FakeAuthRepository({
    required this.tokenStorage,
    this.loginException,
    this.loginGate,
    this.currentUser = testUser,
    this.currentUserException,
    this.logoutException,
  }) : apiClient = ApiClient(tokenStorage: tokenStorage);

  @override
  final ApiClient apiClient;

  @override
  final TokenStorage tokenStorage;

  /// Exception opsional saat login.
  final Exception? loginException;

  /// Gerbang async opsional untuk menahan proses login pada widget test.
  final Completer<void>? loginGate;

  /// User yang dikembalikan saat login atau fetchCurrentUser sukses.
  final UserModel? currentUser;

  /// Exception opsional saat mengambil user aktif.
  final Exception? currentUserException;

  /// Exception opsional saat logout.
  final Exception? logoutException;

  /// Jumlah pemanggilan login.
  int loginCallCount = 0;

  /// Jumlah pemanggilan fetchCurrentUser.
  int fetchCurrentUserCallCount = 0;

  /// Jumlah pemanggilan logout.
  int logoutCallCount = 0;

  /// Email terakhir yang dikirim ke login.
  String? lastEmail;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    loginCallCount += 1;
    lastEmail = email;

    if (loginException != null) {
      throw loginException!;
    }

    if (loginGate != null) {
      await loginGate!.future;
    }

    await tokenStorage.saveToken('stage-six-token');

    return currentUser ?? testUser;
  }

  @override
  Future<UserModel?> fetchCurrentUser() async {
    fetchCurrentUserCallCount += 1;

    if (currentUserException != null) {
      throw currentUserException!;
    }

    return currentUser;
  }

  @override
  Future<void> logout() async {
    logoutCallCount += 1;
    await tokenStorage.deleteToken();

    if (logoutException != null) {
      throw logoutException!;
    }
  }
}

/// Membungkus widget dengan MaterialApp dan AuthProvider untuk widget test.
Widget authTestApp(AuthProvider provider, Widget child) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

/// Membuat response API sukses dengan token dan user kasir.
ApiResponseBody loginSuccessResponse() {
  return const ApiResponseBody(
    success: true,
    message: 'Login berhasil.',
    data: <String, Object>{
      'token': 'token-login',
      'token_type': 'Bearer',
      'user': <String, Object>{
        'id': 1,
        'name': 'Kasir SmartKasir',
        'email': 'kasir@smartkasir.test',
        'role': 'cashier',
      },
    },
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('AuthRepository login', () {
    test('login berhasil membaca token dan menyimpan token', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final apiClient = FakeApiClient(
        tokenStorage: storage,
        postHandler: (_, _) async => loginSuccessResponse(),
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      final user = await repository.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );

      expect(user.name, 'Kasir SmartKasir');
      expect(user.email, 'kasir@smartkasir.test');
      expect(await storage.readToken(), 'token-login');
      expect(apiClient.lastPostPath, '/login');
    });

    test(
      'login mengirim email dan password tanpa menyimpan password',
      () async {
        final storage = TokenStorage(MemorySecureKeyValueStore());
        final apiClient = FakeApiClient(
          tokenStorage: storage,
          postHandler: (_, _) async => loginSuccessResponse(),
        );
        final repository = AuthRepository(
          apiClient: apiClient,
          tokenStorage: storage,
        );

        await repository.login(
          email: 'kasir@smartkasir.test',
          password: 'password',
        );

        expect(apiClient.lastPostData, isA<Map<String, Object>>());
        expect(await storage.readToken(), isNot('password'));
      },
    );

    test('token tidak disimpan jika response tidak valid', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final apiClient = FakeApiClient(
        tokenStorage: storage,
        postHandler: (_, _) async {
          return const ApiResponseBody(
            success: true,
            message: 'Login berhasil.',
            data: <String, Object>{'token': 'token-login'},
          );
        },
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      expect(
        repository.login(email: 'kasir@smartkasir.test', password: 'password'),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.hasToken(), isFalse);
    });

    test('login gagal tidak menyimpan token', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final apiClient = FakeApiClient(
        tokenStorage: storage,
        postHandler: (_, _) async {
          throw const ApiException(
            message: 'Email atau password salah.',
            statusCode: 401,
          );
        },
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      expect(
        repository.login(email: 'kasir@smartkasir.test', password: 'salah'),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.hasToken(), isFalse);
    });

    test('fetchCurrentUser membaca data dari endpoint me', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final apiClient = FakeApiClient(
        tokenStorage: storage,
        getHandler: (_) async {
          return const ApiResponseBody(
            success: true,
            message: 'Data pengguna berhasil diambil.',
            data: <String, Object>{
              'user': <String, Object>{
                'id': 1,
                'name': 'Kasir SmartKasir',
                'email': 'kasir@smartkasir.test',
                'role': 'cashier',
              },
            },
          );
        },
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      final user = await repository.fetchCurrentUser();

      expect(user?.name, 'Kasir SmartKasir');
      expect(apiClient.getCallCount, 1);
    });
  });

  group('AuthProvider login dan sesi', () {
    test('login mengubah status menjadi loading lalu authenticated', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = FakeAuthRepository(tokenStorage: storage);
      final provider = AuthProvider(authRepository: repository);
      final statuses = <AuthStatus>[];
      provider.addListener(() => statuses.add(provider.status));

      await provider.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );

      expect(statuses, <AuthStatus>[
        AuthStatus.loading,
        AuthStatus.authenticated,
      ]);
      expect(provider.currentUser, testUser);
    });

    test('login gagal tidak membuat authenticated dan mengisi error', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        loginException: const ApiException(
          message: 'Email atau password salah.',
          statusCode: 401,
        ),
      );
      final provider = AuthProvider(authRepository: repository);

      await provider.login(email: 'kasir@smartkasir.test', password: 'salah');

      expect(provider.status, AuthStatus.failure);
      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, 'Email atau password salah.');
      expect(await storage.hasToken(), isFalse);
    });

    test('clearError menghapus pesan error', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        loginException: const ApiException(message: 'Gagal login.'),
      );
      final provider = AuthProvider(authRepository: repository);

      await provider.login(email: 'kasir@smartkasir.test', password: 'salah');
      provider.clearError();

      expect(provider.errorMessage, isNull);
    });

    test(
      'token tidak ada menghasilkan unauthenticated tanpa request me',
      () async {
        final storage = TokenStorage(MemorySecureKeyValueStore());
        final repository = FakeAuthRepository(tokenStorage: storage);
        final provider = AuthProvider(authRepository: repository);

        await provider.checkAuthentication();

        expect(provider.status, AuthStatus.unauthenticated);
        expect(repository.fetchCurrentUserCallCount, 0);
        expect(provider.hasCheckedAuthentication, isTrue);
      },
    );

    test('token valid dan me berhasil menghasilkan authenticated', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      await storage.saveToken('valid-token');
      final repository = FakeAuthRepository(tokenStorage: storage);
      final provider = AuthProvider(authRepository: repository);

      await provider.checkAuthentication();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.currentUser, testUser);
      expect(repository.fetchCurrentUserCallCount, 1);
    });

    test('token invalid 401 menghapus token', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      await storage.saveToken('invalid-token');
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        currentUserException: const ApiException(
          message: 'Unauthenticated.',
          statusCode: 401,
        ),
      );
      final provider = AuthProvider(authRepository: repository);

      await provider.checkAuthentication();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.currentUser, isNull);
      expect(await storage.hasToken(), isFalse);
    });

    test('me gagal tidak meninggalkan loading', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      await storage.saveToken('valid-token');
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        currentUserException: const ApiException(
          message: 'Tidak dapat terhubung ke server.',
          isNetworkError: true,
        ),
      );
      final provider = AuthProvider(authRepository: repository);

      await provider.checkAuthentication();

      expect(provider.status, AuthStatus.failure);
      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, 'Tidak dapat terhubung ke server.');
    });
  });

  group('LoginPage widget', () {
    testWidgets('input email dan password tampil', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );

      await tester.pumpWidget(authTestApp(provider, const LoginPage()));

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('password tersembunyi dan tombol mata mengubah visibilitas', (
      tester,
    ) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );

      await tester.pumpWidget(authTestApp(provider, const LoginPage()));

      TextField passwordField = tester.widget(
        find.descendant(
          of: find.byKey(const Key('login_password_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordField.obscureText, isTrue);

      await tester.tap(find.byKey(const Key('toggle_password_visibility')));
      await tester.pump();

      passwordField = tester.widget(
        find.descendant(
          of: find.byKey(const Key('login_password_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordField.obscureText, isFalse);
    });

    testWidgets('form kosong dan email salah menampilkan validasi', (
      tester,
    ) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );

      await tester.pumpWidget(authTestApp(provider, const LoginPage()));

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Password wajib diisi.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'email-salah',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Format email tidak valid.'), findsOneWidget);
    });

    testWidgets('tombol login terlindungi saat loading', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final loginGate = Completer<void>();
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        loginGate: loginGate,
      );
      final provider = AuthProvider(authRepository: repository);

      await tester.pumpWidget(authTestApp(provider, const LoginPage()));
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'kasir@smartkasir.test',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('login_submit_button')),
      );
      expect(button.onPressed, isNull);

      loginGate.complete();
      await tester.pump();
    });

    testWidgets('pesan error dapat ditampilkan', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = FakeAuthRepository(
        tokenStorage: storage,
        loginException: const ApiException(message: 'Email wajib diisi.'),
      );
      final provider = AuthProvider(authRepository: repository);

      await provider.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );
      await tester.pumpWidget(authTestApp(provider, const LoginPage()));

      expect(find.text('Email wajib diisi.'), findsOneWidget);
    });

    testWidgets('error jaringan login ditampilkan dengan pesan aman', (
      tester,
    ) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(
          tokenStorage: storage,
          loginException: const ApiException(
            message: 'Tidak dapat terhubung ke server.',
            isNetworkError: true,
          ),
        ),
      );

      await tester.pumpWidget(authTestApp(provider, const LoginPage()));
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'kasir@smartkasir.test',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
    });

    testWidgets('login berhasil menampilkan MainNavigationPage', (
      tester,
    ) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );
      final dashboardProvider = DashboardProvider(
        dashboardRepository: DashboardRepository(
          apiClient: FakeApiClient(
            tokenStorage: storage,
            getHandler: (_) async => const ApiResponseBody(
              success: true,
              message: 'OK',
              data: <String, dynamic>{
                'orders': <String, dynamic>{
                  'pending': 0,
                  'confirmed': 0,
                  'processing': 0,
                  'ready': 0,
                },
                'today': <String, dynamic>{
                  'transactions': 0,
                  'revenue': 0,
                  'revenue_formatted': 'Rp0',
                },
                'products': <String, dynamic>{
                  'total_active': 0,
                  'low_stock': 0,
                },
                'recent_orders': <dynamic>[],
              },
            ),
          ),
        ),
      );
      final featureApiClient = ApiClient(tokenStorage: storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: provider),
            ChangeNotifierProvider<DashboardProvider>.value(
              value: dashboardProvider,
            ),
            ChangeNotifierProvider<ProductProvider>.value(
              value: ProductProvider(
                productRepository: ProductRepository(
                  apiClient: featureApiClient,
                ),
              ),
            ),
            ChangeNotifierProvider<OrderProvider>.value(
              value: OrderProvider(
                orderRepository: OrderRepository(apiClient: featureApiClient),
              ),
            ),
            ChangeNotifierProvider<TransactionProvider>.value(
              value: TransactionProvider(
                transactionRepository: TransactionRepository(
                  apiClient: featureApiClient,
                ),
              ),
            ),
          ],
          child: const SmartKasirApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        ' kasir@smartkasir.test ',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MainNavigationPage), findsOneWidget);
      expect(provider.status, AuthStatus.authenticated);
      expect(
        (provider.authRepository as FakeAuthRepository).lastEmail,
        'kasir@smartkasir.test',
      );
    });
  });

  group('ProfilePage widget', () {
    testWidgets('nama, email, role, dan tombol logout tampil', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );

      await provider.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );
      await tester.pumpWidget(authTestApp(provider, const ProfilePage()));

      expect(find.text('Kasir SmartKasir'), findsOneWidget);
      expect(find.text('kasir@smartkasir.test'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
    });

    testWidgets('dialog konfirmasi logout tampil', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final provider = AuthProvider(
        authRepository: FakeAuthRepository(tokenStorage: storage),
      );

      await provider.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );
      await tester.pumpWidget(authTestApp(provider, const ProfilePage()));

      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari aplikasi?'), findsOneWidget);
      expect(
        find.text('Anda perlu login kembali untuk menggunakan aplikasi kasir.'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('konfirmasi logout menghapus sesi lokal', (tester) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = FakeAuthRepository(tokenStorage: storage);
      final provider = AuthProvider(authRepository: repository);

      await provider.login(
        email: 'kasir@smartkasir.test',
        password: 'password',
      );
      await tester.pumpWidget(authTestApp(provider, const ProfilePage()));

      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar').last);
      await tester.pump();

      expect(repository.logoutCallCount, 1);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.currentUser, isNull);
      expect(await storage.hasToken(), isFalse);
    });
  });
}
