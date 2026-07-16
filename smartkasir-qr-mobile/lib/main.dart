import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/repositories/dashboard_repository.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/orders/repositories/order_repository.dart';
import 'features/products/providers/product_provider.dart';
import 'features/products/repositories/product_repository.dart';
import 'features/transactions/providers/transaction_provider.dart';
import 'features/transactions/repositories/transaction_repository.dart';

/// Menyiapkan dependency utama aplikasi dan menjalankan SmartKasir QR.
///
/// Fungsi ini membuat storage token, API client, repository, dan provider.
/// Efek sampingnya adalah binding Flutter aktif dan aplikasi mulai dirender.
/// Error inisialisasi dependency akan diteruskan oleh Flutter saat startup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final keyValueStore = FlutterSecureKeyValueStore();
  final tokenStorage = TokenStorage(keyValueStore);
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final authProvider = AuthProvider(authRepository: authRepository);
  final dashboardRepository = DashboardRepository(apiClient: apiClient);
  final dashboardProvider = DashboardProvider(
    dashboardRepository: dashboardRepository,
  );
  final productRepository = ProductRepository(apiClient: apiClient);
  final orderRepository = OrderRepository(apiClient: apiClient);
  final transactionRepository = TransactionRepository(apiClient: apiClient);
  final productProvider = ProductProvider(productRepository: productRepository);
  final orderProvider = OrderProvider(orderRepository: orderRepository);
  final transactionProvider = TransactionProvider(
    transactionRepository: transactionRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DashboardProvider>.value(
          value: dashboardProvider,
        ),
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
        ChangeNotifierProvider<TransactionProvider>.value(
          value: transactionProvider,
        ),
      ],
      child: const SmartKasirApp(),
    ),
  );
}
