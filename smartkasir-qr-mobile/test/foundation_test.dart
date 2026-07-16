import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:smartkasir_qr_mobile/config/app_config.dart';
import 'package:smartkasir_qr_mobile/config/app_theme.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/core/utils/currency_formatter.dart';
import 'package:smartkasir_qr_mobile/core/widgets/app_empty_view.dart';
import 'package:smartkasir_qr_mobile/core/widgets/app_error_view.dart';
import 'package:smartkasir_qr_mobile/core/widgets/app_loading.dart';
import 'package:smartkasir_qr_mobile/features/auth/providers/auth_provider.dart';
import 'package:smartkasir_qr_mobile/features/auth/repositories/auth_repository.dart';
import 'package:smartkasir_qr_mobile/features/auth/models/user_model.dart';
import 'package:smartkasir_qr_mobile/features/auth/pages/login_page.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/models/dashboard_model.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/pages/home_page.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/repositories/dashboard_repository.dart';

/// Membungkus widget dengan MaterialApp agar tema dan Material tersedia.
Widget testApp(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: child);
}

/// Repository auth palsu agar LoginPage final dapat dirender tanpa jaringan.
class FoundationAuthRepository implements AuthRepository {
  /// Membuat repository palsu untuk test fondasi.
  FoundationAuthRepository({required this.tokenStorage})
    : apiClient = ApiClient(tokenStorage: tokenStorage);

  @override
  final ApiClient apiClient;

  @override
  final TokenStorage tokenStorage;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return const UserModel(
      id: 1,
      name: 'Kasir SmartKasir',
      email: 'kasir@smartkasir.test',
      role: 'cashier',
    );
  }

  @override
  Future<UserModel?> fetchCurrentUser() async => null;

  @override
  Future<void> logout() async {}
}

/// Repository dashboard palsu agar HomePage dapat dirender tanpa jaringan.
class FoundationDashboardRepository implements DashboardRepository {
  /// Membuat repository palsu untuk test fondasi dashboard.
  FoundationDashboardRepository()
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;

  @override
  Future<DashboardModel> fetchDashboard() async {
    return DashboardModel.fromJson(const <String, dynamic>{
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
      'products': <String, dynamic>{'total_active': 0, 'low_stock': 0},
      'recent_orders': <dynamic>[],
    });
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  test('UserModel berhasil membaca JSON', () {
    final user = UserModel.fromJson(const <String, dynamic>{
      'id': 1,
      'name': 'Kasir SmartKasir',
      'email': 'kasir@smartkasir.test',
      'role': 'cashier',
    });

    expect(user.id, 1);
    expect(user.name, 'Kasir SmartKasir');
    expect(user.email, 'kasir@smartkasir.test');
  });

  test('UserModel menangani role', () {
    final user = UserModel.fromJson(const <String, dynamic>{
      'id': 2,
      'name': 'Admin',
      'email': 'admin@example.test',
      'role': 'cashier',
    });

    expect(user.role, 'cashier');
  });

  test('TokenStorage memiliki interface yang dapat diuji', () async {
    final storage = TokenStorage(MemorySecureKeyValueStore());

    expect(await storage.hasToken(), isFalse);
    await storage.saveToken('token-test');
    expect(await storage.readToken(), 'token-test');
    expect(await storage.hasToken(), isTrue);
    await storage.deleteToken();
    expect(await storage.hasToken(), isFalse);
  });

  test('ApiException menyimpan status dan pesan', () {
    const exception = ApiException(
      message: 'Data tidak valid.',
      statusCode: 422,
      validationErrors: <String, List<String>>{
        'email': <String>['Email wajib diisi.'],
      },
    );

    expect(exception.message, 'Data tidak valid.');
    expect(exception.statusCode, 422);
    expect(exception.validationErrors['email'], contains('Email wajib diisi.'));
    expect(exception.isUnauthorized, isFalse);
  });

  test('CurrencyFormatter menghasilkan format rupiah', () {
    expect(CurrencyFormatter.rupiah(8000), 'Rp8.000');
  });

  test('AppConfig membaca default URL', () {
    expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:8000/api');
  });

  testWidgets('LoginPage placeholder dapat dirender', (tester) async {
    final storage = TokenStorage(MemorySecureKeyValueStore());
    final repository = FoundationAuthRepository(tokenStorage: storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(authRepository: repository),
        child: testApp(const LoginPage()),
      ),
    );

    expect(find.text('SmartKasir QR'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('HomePage dashboard dapat dirender', (tester) async {
    final storage = TokenStorage(MemorySecureKeyValueStore());
    final authRepository = FoundationAuthRepository(tokenStorage: storage);
    final dashboardRepository = FoundationDashboardRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: AuthProvider(authRepository: authRepository),
          ),
          ChangeNotifierProvider<DashboardProvider>.value(
            value: DashboardProvider(dashboardRepository: dashboardRepository),
          ),
        ],
        child: testApp(const HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
  });

  testWidgets('AppLoading dapat dirender', (tester) async {
    await tester.pumpWidget(testApp(const AppLoading(message: 'Memuat...')));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat...'), findsOneWidget);
  });

  testWidgets('AppErrorView dapat dirender', (tester) async {
    await tester.pumpWidget(
      testApp(const Scaffold(body: AppErrorView(message: 'Gagal memuat.'))),
    );

    expect(find.text('Gagal memuat.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('AppEmptyView dapat dirender', (tester) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(
          body: AppEmptyView(
            icon: Icons.inbox_outlined,
            title: 'Kosong',
            description: 'Belum ada data.',
          ),
        ),
      ),
    );

    expect(find.text('Kosong'), findsOneWidget);
    expect(find.text('Belum ada data.'), findsOneWidget);
  });
}
