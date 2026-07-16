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
import 'package:smartkasir_qr_mobile/features/dashboard/models/dashboard_model.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/models/recent_order_model.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/pages/home_page.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartkasir_qr_mobile/features/orders/pages/orders_page.dart';
import 'package:smartkasir_qr_mobile/features/orders/providers/order_provider.dart';
import 'package:smartkasir_qr_mobile/features/orders/repositories/order_repository.dart';
import 'package:smartkasir_qr_mobile/features/profile/pages/profile_page.dart';
import 'package:smartkasir_qr_mobile/features/products/pages/products_page.dart';
import 'package:smartkasir_qr_mobile/features/products/providers/product_provider.dart';
import 'package:smartkasir_qr_mobile/features/products/repositories/product_repository.dart';
import 'package:smartkasir_qr_mobile/features/transactions/pages/transactions_page.dart';
import 'package:smartkasir_qr_mobile/features/transactions/providers/transaction_provider.dart';
import 'package:smartkasir_qr_mobile/features/transactions/repositories/transaction_repository.dart';
import 'package:smartkasir_qr_mobile/navigation/main_navigation_page.dart';

const _testUser = UserModel(
  id: 1,
  name: 'Kasir SmartKasir',
  email: 'kasir@smartkasir.test',
  role: 'cashier',
);

Map<String, dynamic> _dashboardJson({
  Object? recentOrders = const <Object?>[
    <String, dynamic>{
      'id': 5,
      'order_number': 'ORD-20260711-GWVQXW',
      'table': <String, dynamic>{'id': 1, 'name': 'Meja 1', 'code': 'MEJA-01'},
      'customer_name': 'gusnik',
      'status': 'pending',
      'status_label': 'Menunggu',
      'total': 18000,
      'total_formatted': 'Rp18.000',
      'items_count': 4,
      'created_at': '2026-07-11T21:37:48+08:00',
    },
  ],
}) {
  return <String, dynamic>{
    'orders': <String, dynamic>{
      'pending': 3,
      'confirmed': 1,
      'processing': 0,
      'ready': 1,
    },
    'today': <String, dynamic>{
      'transactions': 0,
      'revenue': 0,
      'revenue_formatted': 'Rp0',
    },
    'products': <String, dynamic>{'total_active': 6, 'low_stock': 0},
    'recent_orders': recentOrders,
  };
}

DashboardModel _dashboardModel({Object? recentOrders}) {
  return DashboardModel.fromJson(
    _dashboardJson(
      recentOrders:
          recentOrders ??
          const <Object?>[
            <String, dynamic>{
              'id': 5,
              'order_number': 'ORD-20260711-GWVQXW',
              'table': <String, dynamic>{
                'id': 1,
                'name': 'Meja 1',
                'code': 'MEJA-01',
              },
              'customer_name': 'gusnik',
              'status': 'pending',
              'status_label': 'Menunggu',
              'total': 18000,
              'total_formatted': 'Rp18.000',
              'items_count': 4,
              'created_at': '2026-07-11T21:37:48+08:00',
            },
          ],
    ),
  );
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient({required this.tokenStorage, required this.getHandler});

  @override
  final TokenStorage tokenStorage;

  final Future<ApiResponseBody> Function(String path) getHandler;

  int getCallCount = 0;
  String? lastGetPath;

  @override
  Future<ApiResponseBody> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    getCallCount += 1;
    lastGetPath = path;

    return getHandler(path);
  }

  @override
  Future<ApiResponseBody> patch(String path, {Object? data}) async {
    throw const ApiException(message: 'PATCH tidak disiapkan.');
  }

  @override
  Future<ApiResponseBody> post(String path, {Object? data}) async {
    throw const ApiException(message: 'POST tidak disiapkan.');
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository({required this.handler})
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;

  Future<DashboardModel> Function() handler;

  int callCount = 0;

  @override
  Future<DashboardModel> fetchDashboard() async {
    callCount += 1;

    return handler();
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.tokenStorage})
    : apiClient = ApiClient(tokenStorage: tokenStorage);

  @override
  final ApiClient apiClient;

  @override
  final TokenStorage tokenStorage;

  @override
  Future<UserModel?> fetchCurrentUser() async => _testUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await tokenStorage.saveToken('token-test');

    return _testUser;
  }

  @override
  Future<void> logout() async {
    await tokenStorage.deleteToken();
  }
}

Widget _dashboardTestApp({
  required AuthProvider authProvider,
  required DashboardProvider dashboardProvider,
  required Widget child,
}) {
  final storage = TokenStorage(MemorySecureKeyValueStore());
  final apiClient = ApiClient(tokenStorage: storage);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
      ChangeNotifierProvider<ProductProvider>.value(
        value: ProductProvider(
          productRepository: ProductRepository(apiClient: apiClient),
        ),
      ),
      ChangeNotifierProvider<OrderProvider>.value(
        value: OrderProvider(
          orderRepository: OrderRepository(apiClient: apiClient),
        ),
      ),
      ChangeNotifierProvider<TransactionProvider>.value(
        value: TransactionProvider(
          transactionRepository: TransactionRepository(apiClient: apiClient),
        ),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

Future<AuthProvider> _authenticatedProvider() async {
  final storage = TokenStorage(MemorySecureKeyValueStore());
  final provider = AuthProvider(
    authRepository: _FakeAuthRepository(tokenStorage: storage),
  );
  await provider.login(email: 'kasir@smartkasir.test', password: 'password');

  return provider;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('DashboardModel', () {
    test('membaca ringkasan orders, today, products, dan recent orders', () {
      final dashboard = DashboardModel.fromJson(_dashboardJson());

      expect(dashboard.orders.pending, 3);
      expect(dashboard.orders.confirmed, 1);
      expect(dashboard.today.transactions, 0);
      expect(dashboard.today.revenue, 0);
      expect(dashboard.today.revenueFormatted, 'Rp0');
      expect(dashboard.products.totalActive, 6);
      expect(dashboard.products.lowStock, 0);
      expect(dashboard.recentOrders.single.orderNumber, 'ORD-20260711-GWVQXW');
    });

    test('menangani recent_orders kosong', () {
      final dashboard = DashboardModel.fromJson(
        _dashboardJson(recentOrders: const <Object?>[]),
      );

      expect(dashboard.recentOrders, isEmpty);
    });

    test('menangani customer_name null dan table null', () {
      final order = RecentOrderModel.fromJson(const <String, dynamic>{
        'id': 1,
        'order_number': 'ORD-NULL',
        'table': null,
        'customer_name': null,
        'status': 'pending',
        'status_label': 'Menunggu',
        'total': 14000,
        'total_formatted': 'Rp14.000',
        'items_count': 2,
        'created_at': '2026-07-11T20:00:00+08:00',
      });

      expect(order.customerName, isNull);
      expect(order.tableName, 'Transaksi Langsung');
    });

    test('menangani angka dengan tipe aman', () {
      final dashboard = DashboardModel.fromJson(
        _dashboardJson(
          recentOrders: const <Object?>[
            <String, dynamic>{
              'id': '7',
              'order_number': 'ORD-SAFE',
              'table': <String, dynamic>{'name': 'Meja 7', 'code': 'M7'},
              'status': 'ready',
              'status_label': 'Siap',
              'total': 12500.5,
              'items_count': '3',
              'created_at': 'tanggal-salah',
            },
          ],
        ),
      );

      expect(dashboard.recentOrders.single.id, 7);
      expect(dashboard.recentOrders.single.total, 12500);
      expect(dashboard.recentOrders.single.itemsCount, 3);
      expect(dashboard.recentOrders.single.createdAt, isNull);
    });
  });

  group('DashboardRepository', () {
    test('GET dashboard berhasil membentuk DashboardModel', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final apiClient = _FakeApiClient(
        tokenStorage: storage,
        getHandler: (_) async => ApiResponseBody(
          success: true,
          message: 'Data dashboard berhasil diambil.',
          data: _dashboardJson(),
        ),
      );
      final repository = DashboardRepository(apiClient: apiClient);

      final dashboard = await repository.fetchDashboard();

      expect(apiClient.lastGetPath, '/dashboard');
      expect(dashboard.orders.pending, 3);
      expect(dashboard.recentOrders.single.totalFormatted, 'Rp18.000');
    });

    test('response tanpa data menghasilkan ApiException', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = DashboardRepository(
        apiClient: _FakeApiClient(
          tokenStorage: storage,
          getHandler: (_) async =>
              const ApiResponseBody(success: true, message: 'OK', data: null),
        ),
      );

      expect(repository.fetchDashboard, throwsA(isA<ApiException>()));
    });

    test('response data bukan object menghasilkan ApiException', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final repository = DashboardRepository(
        apiClient: _FakeApiClient(
          tokenStorage: storage,
          getHandler: (_) async => const ApiResponseBody(
            success: true,
            message: 'OK',
            data: <Object?>[],
          ),
        ),
      );

      expect(repository.fetchDashboard, throwsA(isA<ApiException>()));
    });

    test('repository tidak menyimpan token atau data lokal', () async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      await storage.saveToken('token-awal');
      final repository = DashboardRepository(
        apiClient: _FakeApiClient(
          tokenStorage: storage,
          getHandler: (_) async => ApiResponseBody(
            success: true,
            message: 'OK',
            data: _dashboardJson(),
          ),
        ),
      );

      await repository.fetchDashboard();

      expect(await storage.readToken(), 'token-awal');
    });
  });

  group('DashboardProvider', () {
    test('state awal initial', () {
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );

      expect(provider.status, DashboardStatus.initial);
    });

    test(
      'loadDashboard menjadi loading lalu loaded dan menyimpan data',
      () async {
        final completer = Completer<DashboardModel>();
        final provider = DashboardProvider(
          dashboardRepository: _FakeDashboardRepository(
            handler: () => completer.future,
          ),
        );
        final statuses = <DashboardStatus>[];
        provider.addListener(() => statuses.add(provider.status));

        final future = provider.loadDashboard();
        expect(provider.status, DashboardStatus.loading);
        completer.complete(_dashboardModel());
        await future;

        expect(statuses, contains(DashboardStatus.loading));
        expect(provider.status, DashboardStatus.loaded);
        expect(provider.dashboard?.orders.pending, 3);
      },
    );

    test('load gagal menjadi failure dan tidak meninggalkan loading', () async {
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => throw const ApiException(
            message: 'Server gagal.',
            statusCode: 500,
          ),
        ),
      );

      await provider.loadDashboard();

      expect(provider.status, DashboardStatus.failure);
      expect(provider.errorMessage, 'Terjadi kesalahan pada server.');
    });

    test('refresh berhasil memperbarui data', () async {
      var pending = 3;
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async {
            return DashboardModel.fromJson(
              _dashboardJson()
                ..['orders'] = <String, dynamic>{
                  'pending': pending,
                  'confirmed': 1,
                  'processing': 0,
                  'ready': 1,
                },
            );
          },
        ),
      );

      await provider.loadDashboard();
      pending = 8;
      await provider.refreshDashboard();

      expect(provider.dashboard?.orders.pending, 8);
    });

    test('refresh gagal mempertahankan data lama', () async {
      var fail = false;
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async {
            if (fail) {
              throw const ApiException(message: 'Jaringan gagal.');
            }

            return _dashboardModel();
          },
        ),
      );

      await provider.loadDashboard();
      fail = true;
      await provider.refreshDashboard();

      expect(provider.status, DashboardStatus.loaded);
      expect(provider.dashboard?.orders.pending, 3);
      expect(provider.errorMessage, 'Jaringan gagal.');
    });

    test('reset menghapus data dashboard', () async {
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );

      await provider.loadDashboard();
      provider.reset();

      expect(provider.status, DashboardStatus.initial);
      expect(provider.dashboard, isNull);
    });

    test('unauthorized dapat dikenali', () async {
      final provider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => throw const ApiException(
            message: 'Unauthenticated.',
            statusCode: 401,
          ),
        ),
      );

      await provider.loadDashboard();

      expect(provider.isUnauthorized, isTrue);
      expect(
        provider.errorMessage,
        'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    });
  });

  group('HomePage', () {
    testWidgets('menampilkan loading', (tester) async {
      final authProvider = await _authenticatedProvider();
      final completer = Completer<DashboardModel>();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () => completer.future,
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const HomePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Memuat dashboard...'), findsOneWidget);
      completer.complete(_dashboardModel());
    });

    testWidgets('menampilkan sapaan, ringkasan, dan pesanan terbaru', (
      tester,
    ) async {
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const HomePage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(find.text('Kasir SmartKasir'), findsOneWidget);
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('Produk Aktif'), findsOneWidget);
      expect(find.text('Stok Menipis'), findsOneWidget);
      expect(find.text('ORD-20260711-GWVQXW'), findsOneWidget);
    });

    testWidgets('menampilkan empty state jika recent orders kosong', (
      tester,
    ) async {
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(recentOrders: const <Object?>[]),
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const HomePage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Belum ada pesanan terbaru'), findsOneWidget);
    });

    testWidgets('menampilkan error dan tombol coba lagi', (tester) async {
      var fail = true;
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async {
            if (fail) {
              throw const ApiException(message: 'Server mati.');
            }

            return _dashboardModel();
          },
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const HomePage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Dashboard belum dapat dimuat'), findsOneWidget);
      expect(find.text('Server mati.'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();

      expect(find.text('ORD-20260711-GWVQXW'), findsOneWidget);
    });

    testWidgets('tombol refresh bekerja tanpa request ganda', (tester) async {
      final refreshCompleter = Completer<DashboardModel>();
      final authProvider = await _authenticatedProvider();
      final repository = _FakeDashboardRepository(
        handler: () {
          if (refreshCompleter.isCompleted) {
            return Future<DashboardModel>.value(_dashboardModel());
          }

          return Future<DashboardModel>.value(_dashboardModel());
        },
      );
      final dashboardProvider = DashboardProvider(
        dashboardRepository: repository,
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const HomePage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      repository.handler = () => refreshCompleter.future;
      await tester.tap(find.byTooltip('Refresh dashboard'));
      await tester.pump();
      await tester.tap(find.byTooltip('Refresh dashboard'));
      await tester.pump();

      expect(repository.callCount, 2);
      refreshCompleter.complete(_dashboardModel());
      await tester.pump();
    });
  });

  group('Bottom Navigation', () {
    testWidgets('menampilkan empat menu dan berpindah tab', (tester) async {
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const MainNavigationPage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Pesanan'), findsWidgets);
      expect(find.text('Produk'), findsWidgets);
      expect(find.text('Transaksi'), findsWidgets);

      await tester.tap(find.text('Pesanan').last);
      await tester.pumpAndSettle();
      expect(find.byType(OrdersPage), findsOneWidget);

      await tester.tap(find.text('Produk').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProductsPage), findsOneWidget);

      await tester.tap(find.text('Transaksi').last);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsPage), findsOneWidget);
    });

    testWidgets('profil dapat dibuka dari AppBar', (tester) async {
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const MainNavigationPage(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Profil'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('kasir@smartkasir.test'), findsOneWidget);
    });

    testWidgets('Bottom Navigation tidak tampil ketika unauthenticated', (
      tester,
    ) async {
      final storage = TokenStorage(MemorySecureKeyValueStore());
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(tokenStorage: storage),
      );
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );
      final apiClient = ApiClient(tokenStorage: storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<DashboardProvider>.value(
              value: dashboardProvider,
            ),
            ChangeNotifierProvider<ProductProvider>.value(
              value: ProductProvider(
                productRepository: ProductRepository(apiClient: apiClient),
              ),
            ),
            ChangeNotifierProvider<OrderProvider>.value(
              value: OrderProvider(
                orderRepository: OrderRepository(apiClient: apiClient),
              ),
            ),
            ChangeNotifierProvider<TransactionProvider>.value(
              value: TransactionProvider(
                transactionRepository: TransactionRepository(
                  apiClient: apiClient,
                ),
              ),
            ),
          ],
          child: const SmartKasirApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('logout membersihkan dashboard', (tester) async {
      final authProvider = await _authenticatedProvider();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: _FakeDashboardRepository(
          handler: () async => _dashboardModel(),
        ),
      );
      await dashboardProvider.loadDashboard();

      await tester.pumpWidget(
        _dashboardTestApp(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
          child: const ProfilePage(),
        ),
      );
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar').last);
      await tester.pump();

      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(dashboardProvider.dashboard, isNull);
    });
  });
}
