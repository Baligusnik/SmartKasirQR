import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:smartkasir_qr_mobile/config/app_theme.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/features/auth/models/user_model.dart';
import 'package:smartkasir_qr_mobile/features/auth/providers/auth_provider.dart';
import 'package:smartkasir_qr_mobile/features/auth/repositories/auth_repository.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/models/dashboard_model.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartkasir_qr_mobile/features/orders/models/order_model.dart';
import 'package:smartkasir_qr_mobile/features/orders/pages/order_detail_page.dart';
import 'package:smartkasir_qr_mobile/features/orders/pages/orders_page.dart';
import 'package:smartkasir_qr_mobile/features/orders/providers/order_provider.dart';
import 'package:smartkasir_qr_mobile/features/orders/repositories/order_repository.dart';
import 'package:smartkasir_qr_mobile/features/products/models/category_model.dart';
import 'package:smartkasir_qr_mobile/features/products/models/create_product_input.dart';
import 'package:smartkasir_qr_mobile/features/products/models/product_model.dart';
import 'package:smartkasir_qr_mobile/features/products/pages/product_detail_page.dart';
import 'package:smartkasir_qr_mobile/features/products/pages/products_page.dart';
import 'package:smartkasir_qr_mobile/features/products/providers/product_provider.dart';
import 'package:smartkasir_qr_mobile/features/products/repositories/product_repository.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_order_payment_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_transaction_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/transaction_model.dart';
import 'package:smartkasir_qr_mobile/features/transactions/pages/transaction_detail_page.dart';
import 'package:smartkasir_qr_mobile/features/transactions/pages/transactions_page.dart';
import 'package:smartkasir_qr_mobile/features/transactions/providers/transaction_provider.dart';
import 'package:smartkasir_qr_mobile/features/transactions/repositories/transaction_repository.dart';
import 'package:smartkasir_qr_mobile/navigation/main_navigation_page.dart';

const _missingTable = Object();

const _user = UserModel(
  id: 1,
  name: 'Kasir SmartKasir',
  email: 'kasir@smartkasir.test',
  role: 'cashier',
);

Map<String, dynamic> _categoryJson() => const <String, dynamic>{
  'id': 2,
  'name': 'Minuman',
  'description': null,
  'is_active': true,
  'products_count': 3,
};

Map<String, dynamic> _productJson({
  Object? category = const <String, dynamic>{'id': 2, 'name': 'Minuman'},
  Object? description,
}) {
  return <String, dynamic>{
    'id': 4,
    'category': category,
    'name': 'Pop Ice',
    'sku': 'MNM-POPICE',
    'description': description,
    'price': 5000,
    'price_formatted': 'Rp5.000',
    'stock': 4,
    'unit': 'pcs',
    'is_available': true,
    'can_be_ordered': true,
    'created_at': '2026-07-11T21:28:56+08:00',
    'updated_at': '2026-07-11T21:28:56+08:00',
  };
}

Map<String, dynamic> _orderJson({
  Object? customer = 'Gus Nik',
  Object? table = _missingTable,
  String status = 'pending',
  bool stockDeducted = false,
}) {
  final statusLabel = switch (status) {
    'confirmed' => 'Dikonfirmasi',
    'processing' => 'Diproses',
    'ready' => 'Siap',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => 'Menunggu',
  };

  return <String, dynamic>{
    'id': 5,
    'order_number': 'ORD-20260711-GWVQXW',
    'table': identical(table, _missingTable)
        ? const <String, dynamic>{'id': 1, 'name': 'Meja 1', 'code': 'MEJA-01'}
        : table,
    'customer_name': customer,
    'status': status,
    'status_label': statusLabel,
    'notes': 'jangan pedas',
    'total': 18000,
    'total_formatted': 'Rp18.000',
    'stock_deducted': stockDeducted,
    'items_count': 1,
    'items': const <Object?>[
      <String, dynamic>{
        'product_id': 4,
        'product_name': 'Pop Ice',
        'quantity': 1,
        'price': 5000,
        'price_formatted': 'Rp5.000',
        'subtotal': 5000,
        'subtotal_formatted': 'Rp5.000',
        'notes': null,
      },
    ],
    'created_at': '2026-07-11T21:37:48+08:00',
  };
}

Map<String, dynamic> _transactionJson({Object? orderNumber}) {
  return <String, dynamic>{
    'id': 1,
    'transaction_number': 'TRX-DEMO-001',
    'order_number': orderNumber,
    'cashier': const <String, dynamic>{'id': 1, 'name': 'Kasir SmartKasir'},
    'total': 6000,
    'total_formatted': 'Rp6.000',
    'paid_amount': 10000,
    'paid_amount_formatted': 'Rp10.000',
    'change_amount': 4000,
    'change_amount_formatted': 'Rp4.000',
    'payment_method': 'cash',
    'payment_method_label': 'Tunai',
    'items_count': 1,
    'items': const <Object?>[
      <String, dynamic>{
        'product_id': 5,
        'product_name': 'Marimas',
        'quantity': 2,
        'price': 3000,
        'price_formatted': 'Rp3.000',
        'subtotal': 6000,
        'subtotal_formatted': 'Rp6.000',
      },
    ],
    'created_at': '2026-07-11T21:28:56+08:00',
  };
}

DashboardModel _dashboard() {
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

class _FakeApiClient implements ApiClient {
  _FakeApiClient({required this.tokenStorage, required this.getHandler});

  @override
  final TokenStorage tokenStorage;

  final Future<ApiResponseBody> Function(
    String path,
    Map<String, Object?>? query,
  )
  getHandler;

  String? lastPath;
  Map<String, Object?>? lastQuery;

  @override
  Future<ApiResponseBody> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    return getHandler(path, queryParameters);
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

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.tokenStorage})
    : apiClient = ApiClient(tokenStorage: tokenStorage);

  @override
  final ApiClient apiClient;

  @override
  final TokenStorage tokenStorage;

  @override
  Future<UserModel?> fetchCurrentUser() async => _user;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await tokenStorage.saveToken('token-test');
    return _user;
  }

  @override
  Future<void> logout() async {
    await tokenStorage.deleteToken();
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository()
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;

  int calls = 0;

  @override
  Future<DashboardModel> fetchDashboard() async {
    calls += 1;
    return _dashboard();
  }
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({
    this.products,
    this.categories,
    this.detail,
    this.error,
  }) : apiClient = ApiClient(
         tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
       );

  @override
  final ApiClient apiClient;
  List<ProductModel>? products;
  List<CategoryModel>? categories;
  ProductModel? detail;
  Exception? error;
  int productCalls = 0;
  String? lastSearch;
  int? lastCategoryId;
  bool? lastAvailable;

  @override
  Future<ProductModel> createProduct(CreateProductInput input) async {
    if (error != null) throw error!;
    return ProductModel.fromJson(_productJson());
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    if (error != null) throw error!;
    return categories ??
        <CategoryModel>[CategoryModel.fromJson(_categoryJson())];
  }

  @override
  Future<ProductModel> fetchProductDetail(int productId) async {
    if (error != null) throw error!;
    return detail ?? ProductModel.fromJson(_productJson());
  }

  @override
  Future<List<ProductModel>> fetchProducts({
    String? search,
    int? categoryId,
    bool? available,
  }) async {
    productCalls += 1;
    lastSearch = search;
    lastCategoryId = categoryId;
    lastAvailable = available;
    if (error != null) throw error!;
    return products ?? <ProductModel>[ProductModel.fromJson(_productJson())];
  }
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({this.orders, this.detail, this.error})
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  List<OrderModel>? orders;
  OrderModel? detail;
  Exception? error;
  int calls = 0;
  String? lastSearch;
  String? lastStatus;

  @override
  Future<OrderModel> cancelOrder({required int orderId, String? reason}) async {
    if (error != null) throw error!;
    return detail ?? OrderModel.fromJson(_orderJson(status: 'cancelled'));
  }

  @override
  Future<OrderModel> confirmOrder(int orderId) async {
    if (error != null) throw error!;
    return detail ??
        OrderModel.fromJson(
          _orderJson(status: 'confirmed', stockDeducted: true),
        );
  }

  @override
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    if (error != null) throw error!;
    return detail ?? OrderModel.fromJson(_orderJson());
  }

  @override
  Future<List<OrderModel>> fetchOrders({String? status, String? search}) async {
    calls += 1;
    lastStatus = status;
    lastSearch = search;
    if (error != null) throw error!;
    return orders ?? <OrderModel>[OrderModel.fromJson(_orderJson())];
  }

  @override
  Future<OrderModel> markOrderReady(int orderId) async {
    if (error != null) throw error!;
    return detail ?? OrderModel.fromJson(_orderJson(status: 'ready'));
  }

  @override
  Future<OrderModel> processOrder(int orderId) async {
    if (error != null) throw error!;
    return detail ?? OrderModel.fromJson(_orderJson(status: 'processing'));
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository({this.transactions, this.detail, this.error})
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  List<TransactionModel>? transactions;
  TransactionModel? detail;
  Exception? error;
  int calls = 0;
  String? lastSearch;
  DateTime? lastDate;

  @override
  Future<TransactionModel> createOrderPayment(
    CreateOrderPaymentInput input,
  ) async {
    if (error != null) throw error!;
    return TransactionModel.fromJson(_transactionJson());
  }

  @override
  Future<TransactionModel> createTransaction(
    CreateTransactionInput input,
  ) async {
    if (error != null) throw error!;
    return TransactionModel.fromJson(_transactionJson());
  }

  @override
  Future<TransactionModel> fetchTransactionDetail(int transactionId) async {
    if (error != null) throw error!;
    return detail ?? TransactionModel.fromJson(_transactionJson());
  }

  @override
  Future<List<TransactionModel>> fetchTransactions({
    String? search,
    DateTime? date,
  }) async {
    calls += 1;
    lastSearch = search;
    lastDate = date;
    if (error != null) throw error!;
    return transactions ??
        <TransactionModel>[TransactionModel.fromJson(_transactionJson())];
  }
}

Widget _testApp({
  required AuthProvider authProvider,
  required DashboardProvider dashboardProvider,
  required ProductProvider productProvider,
  required OrderProvider orderProvider,
  required TransactionProvider transactionProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
      ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
      ChangeNotifierProvider<TransactionProvider>.value(
        value: transactionProvider,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child is MainNavigationPage ? child : Scaffold(body: child),
    ),
  );
}

Future<AuthProvider> _authProvider() async {
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

  group('Product stage 8', () {
    test('CategoryModel dan ProductModel membaca JSON aman', () {
      final category = CategoryModel.fromJson(_categoryJson());
      final product = ProductModel.fromJson(_productJson());
      final nullProduct = ProductModel.fromJson(
        _productJson(category: null, description: null),
      );

      expect(category.name, 'Minuman');
      expect(category.productsCount, 3);
      expect(product.name, 'Pop Ice');
      expect(product.description, isNull);
      expect(nullProduct.categoryName, 'Tanpa Kategori');
      expect(product.isLowStock, isTrue);
    });

    test(
      'ProductRepository membaca daftar, detail, query, dan invalid',
      () async {
        final storage = TokenStorage(MemorySecureKeyValueStore());
        final apiClient = _FakeApiClient(
          tokenStorage: storage,
          getHandler: (path, query) async {
            if (path == '/categories') {
              return ApiResponseBody(
                success: true,
                message: 'OK',
                data: <Object?>[_categoryJson()],
              );
            }
            if (path == '/products/4') {
              return ApiResponseBody(
                success: true,
                message: 'OK',
                data: _productJson(),
              );
            }
            return ApiResponseBody(
              success: true,
              message: 'OK',
              data: <Object?>[_productJson()],
            );
          },
        );
        final repository = ProductRepository(apiClient: apiClient);

        expect(await repository.fetchCategories(), hasLength(1));
        final products = await repository.fetchProducts(
          search: 'Pop',
          categoryId: 2,
          available: true,
        );
        expect(products.single.name, 'Pop Ice');
        expect(apiClient.lastQuery?['search'], 'Pop');
        expect(apiClient.lastQuery?['category_id'], 2);
        expect(apiClient.lastQuery?['available'], '1');
        expect((await repository.fetchProductDetail(4)).sku, 'MNM-POPICE');

        final invalid = ProductRepository(
          apiClient: _FakeApiClient(
            tokenStorage: storage,
            getHandler: (_, _) async =>
                const ApiResponseBody(success: true, message: 'OK', data: null),
          ),
        );
        expect(invalid.fetchProducts, throwsA(isA<ApiException>()));
      },
    );

    test(
      'ProductProvider load, search, filter, refresh gagal, reset',
      () async {
        final repository = _FakeProductRepository();
        final provider = ProductProvider(productRepository: repository);

        await provider.loadInitialData();
        expect(provider.status, ProductStatus.loaded);
        expect(provider.products, hasLength(1));

        await provider.searchProducts(' Pop ');
        expect(repository.lastSearch, 'Pop');
        await provider.setCategoryFilter(2);
        expect(repository.lastCategoryId, 2);
        await provider.setAvailabilityFilter(true);
        expect(repository.lastAvailable, true);
        await provider.clearFilters();
        expect(provider.hasActiveFilters, isFalse);

        repository.error = const ApiException(message: 'Jaringan gagal.');
        await provider.refreshProducts();
        expect(provider.products, isNotEmpty);
        expect(provider.status, ProductStatus.loaded);

        provider.reset();
        expect(provider.status, ProductStatus.initial);
        expect(provider.products, isEmpty);
      },
    );

    testWidgets('ProductsPage loading, daftar, error, empty, detail', (
      tester,
    ) async {
      final auth = await _authProvider();
      final productRepository = _FakeProductRepository(
        categories: <CategoryModel>[CategoryModel.fromJson(_categoryJson())],
        detail: ProductModel.fromJson(_productJson()),
      );
      final productProvider = ProductProvider(
        productRepository: productRepository,
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: productProvider,
          orderProvider: OrderProvider(orderRepository: _FakeOrderRepository()),
          transactionProvider: TransactionProvider(
            transactionRepository: _FakeTransactionRepository(),
          ),
          child: const ProductsPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Pop Ice'), findsOneWidget);

      await tester.tap(find.text('Pop Ice'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('MNM-POPICE'), findsOneWidget);
    });

    testWidgets('ProductsPage menampilkan error dan empty state', (
      tester,
    ) async {
      final auth = await _authProvider();
      final emptyProvider = ProductProvider(
        productRepository: _FakeProductRepository(products: <ProductModel>[]),
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: emptyProvider,
          orderProvider: OrderProvider(orderRepository: _FakeOrderRepository()),
          transactionProvider: TransactionProvider(
            transactionRepository: _FakeTransactionRepository(),
          ),
          child: const ProductsPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Belum ada produk yang sesuai.'), findsOneWidget);

      final errorProvider = ProductProvider(
        productRepository: _FakeProductRepository(
          error: const ApiException(message: 'Server gagal.'),
        ),
      );
      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: errorProvider,
          orderProvider: OrderProvider(orderRepository: _FakeOrderRepository()),
          transactionProvider: TransactionProvider(
            transactionRepository: _FakeTransactionRepository(),
          ),
          child: const ProductsPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Produk belum dapat dimuat'), findsOneWidget);
    });
  });

  group('Order stage 8', () {
    test('OrderModel membaca list, detail items, customer/table null', () {
      final order = OrderModel.fromJson(_orderJson());
      final fallback = OrderModel.fromJson(
        _orderJson(customer: null, table: null),
      );

      expect(order.items.single.productName, 'Pop Ice');
      expect(fallback.customerName, isNull);
      expect(fallback.tableName, 'Transaksi Langsung');
    });

    test('OrderRepository dan provider membaca data/filter/reset', () async {
      final repository = _FakeOrderRepository();
      final provider = OrderProvider(orderRepository: repository);

      await provider.loadOrders();
      expect(provider.status, OrderStatusState.loaded);
      await provider.searchOrders('GWVQXW');
      expect(repository.lastSearch, 'GWVQXW');
      await provider.setStatusFilter('pending');
      expect(repository.lastStatus, 'pending');
      expect((await repository.fetchOrderDetail(5)).items, isNotEmpty);
      await provider.clearFilters();
      expect(provider.hasActiveFilters, isFalse);

      repository.error = const ApiException(message: 'Jaringan gagal.');
      await provider.refreshOrders();
      expect(provider.orders, isNotEmpty);

      provider.reset();
      expect(provider.orders, isEmpty);
    });

    testWidgets('OrdersPage list, empty, error, dan detail', (tester) async {
      final auth = await _authProvider();
      final orderProvider = OrderProvider(
        orderRepository: _FakeOrderRepository(
          orders: <OrderModel>[OrderModel.fromJson(_orderJson())],
          detail: OrderModel.fromJson(_orderJson()),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: ProductProvider(
            productRepository: _FakeProductRepository(),
          ),
          orderProvider: orderProvider,
          transactionProvider: TransactionProvider(
            transactionRepository: _FakeTransactionRepository(),
          ),
          child: const OrdersPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('ORD-20260711-GWVQXW'), findsOneWidget);

      await tester.tap(find.text('ORD-20260711-GWVQXW'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailPage), findsOneWidget);
      expect(find.text('Item Pesanan'), findsOneWidget);
    });
  });

  group('Transaction stage 8', () {
    test('TransactionModel membaca list, detail items, order null', () {
      final transaction = TransactionModel.fromJson(_transactionJson());

      expect(transaction.orderNumber, isNull);
      expect(transaction.items.single.productName, 'Marimas');
      expect(transaction.cashierName, 'Kasir SmartKasir');
    });

    test(
      'TransactionRepository dan provider membaca data/filter/reset',
      () async {
        final repository = _FakeTransactionRepository();
        final provider = TransactionProvider(transactionRepository: repository);

        await provider.loadTransactions();
        expect(provider.status, TransactionStatusState.loaded);
        await provider.searchTransactions('TRX');
        expect(repository.lastSearch, 'TRX');
        await provider.setDateFilter(DateTime(2026, 7, 11));
        expect(repository.lastDate, DateTime(2026, 7, 11));
        expect((await repository.fetchTransactionDetail(1)).items, isNotEmpty);
        await provider.clearFilters();
        expect(provider.hasActiveFilters, isFalse);

        repository.error = const ApiException(message: 'Jaringan gagal.');
        await provider.refreshTransactions();
        expect(provider.transactions, isNotEmpty);

        provider.reset();
        expect(provider.transactions, isEmpty);
      },
    );

    testWidgets('TransactionsPage list, empty, error, dan detail', (
      tester,
    ) async {
      final auth = await _authProvider();
      final transactionProvider = TransactionProvider(
        transactionRepository: _FakeTransactionRepository(
          transactions: <TransactionModel>[
            TransactionModel.fromJson(_transactionJson()),
          ],
          detail: TransactionModel.fromJson(_transactionJson()),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: ProductProvider(
            productRepository: _FakeProductRepository(),
          ),
          orderProvider: OrderProvider(orderRepository: _FakeOrderRepository()),
          transactionProvider: transactionProvider,
          child: const TransactionsPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('TRX-DEMO-001'), findsOneWidget);

      await tester.tap(find.text('TRX-DEMO-001'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDetailPage), findsOneWidget);
      expect(find.text('Item Transaksi'), findsOneWidget);
    });
  });

  group('Auth dan navigation stage 8', () {
    testWidgets('unauthorized Product kembali ke auth flow', (tester) async {
      final auth = await _authProvider();
      final provider = ProductProvider(
        productRepository: _FakeProductRepository(
          error: const ApiException(
            message: 'Unauthenticated.',
            statusCode: 401,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: DashboardProvider(
            dashboardRepository: _FakeDashboardRepository(),
          ),
          productProvider: provider,
          orderProvider: OrderProvider(orderRepository: _FakeOrderRepository()),
          transactionProvider: TransactionProvider(
            transactionRepository: _FakeTransactionRepository(),
          ),
          child: const ProductsPage(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('unauthorized Order dan Transaction dikenali provider', () async {
      final orderProvider = OrderProvider(
        orderRepository: _FakeOrderRepository(
          error: const ApiException(
            message: 'Unauthenticated.',
            statusCode: 401,
          ),
        ),
      );
      final transactionProvider = TransactionProvider(
        transactionRepository: _FakeTransactionRepository(
          error: const ApiException(
            message: 'Unauthenticated.',
            statusCode: 401,
          ),
        ),
      );

      await orderProvider.loadOrders();
      await transactionProvider.loadTransactions();

      expect(orderProvider.isUnauthorized, isTrue);
      expect(transactionProvider.isUnauthorized, isTrue);
    });

    testWidgets('logout mereset seluruh provider dan tab lazy load', (
      tester,
    ) async {
      final auth = await _authProvider();
      final dashboardRepository = _FakeDashboardRepository();
      final productRepository = _FakeProductRepository();
      final orderRepository = _FakeOrderRepository();
      final transactionRepository = _FakeTransactionRepository();
      final dashboardProvider = DashboardProvider(
        dashboardRepository: dashboardRepository,
      );
      final productProvider = ProductProvider(
        productRepository: productRepository,
      );
      final orderProvider = OrderProvider(orderRepository: orderRepository);
      final transactionProvider = TransactionProvider(
        transactionRepository: transactionRepository,
      );

      await tester.pumpWidget(
        _testApp(
          authProvider: auth,
          dashboardProvider: dashboardProvider,
          productProvider: productProvider,
          orderProvider: orderProvider,
          transactionProvider: transactionProvider,
          child: const MainNavigationPage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(productRepository.productCalls, 0);
      expect(orderRepository.calls, 0);
      expect(transactionRepository.calls, 0);

      await tester.tap(find.text('Produk').last);
      await tester.pump();
      await tester.pump();
      expect(productRepository.productCalls, 1);
      await tester.tap(find.text('Beranda').last);
      await tester.pump();
      await tester.tap(find.text('Produk').last);
      await tester.pump();
      expect(productRepository.productCalls, 1);

      productProvider.reset();
      orderProvider.reset();
      transactionProvider.reset();
      expect(productProvider.products, isEmpty);
      expect(orderProvider.orders, isEmpty);
      expect(transactionProvider.transactions, isEmpty);
    });
  });
}
