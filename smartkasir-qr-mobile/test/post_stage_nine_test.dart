import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartkasir_qr_mobile/config/app_theme.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/features/products/models/category_model.dart';
import 'package:smartkasir_qr_mobile/features/products/models/create_product_input.dart';
import 'package:smartkasir_qr_mobile/features/products/models/product_model.dart';
import 'package:smartkasir_qr_mobile/features/products/pages/create_product_page.dart';
import 'package:smartkasir_qr_mobile/features/products/providers/product_provider.dart';
import 'package:smartkasir_qr_mobile/features/products/repositories/product_repository.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/cashier_cart_item.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_order_payment_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_transaction_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/transaction_model.dart';
import 'package:smartkasir_qr_mobile/features/transactions/pages/create_transaction_page.dart';
import 'package:smartkasir_qr_mobile/features/transactions/providers/transaction_provider.dart';
import 'package:smartkasir_qr_mobile/features/transactions/repositories/transaction_repository.dart';

Map<String, dynamic> _categoryJson() => const <String, dynamic>{
  'id': 1,
  'name': 'Makanan',
  'description': null,
  'is_active': true,
  'products_count': 1,
};

Map<String, dynamic> _productJson({
  int id = 7,
  String name = 'Nugget Goreng',
  String sku = 'MKN-007',
  int price = 5000,
  int stock = 25,
  bool isAvailable = true,
  bool canBeOrdered = true,
}) {
  return <String, dynamic>{
    'id': id,
    'category': const <String, dynamic>{'id': 1, 'name': 'Makanan'},
    'name': name,
    'sku': sku,
    'description': 'Nugget ayam goreng.',
    'price': price,
    'price_formatted': 'Rp$price',
    'stock': stock,
    'unit': 'pcs',
    'is_available': isAvailable,
    'can_be_ordered': canBeOrdered,
    'created_at': '2026-07-16T05:47:43+08:00',
    'updated_at': '2026-07-16T05:47:43+08:00',
  };
}

Map<String, dynamic> _transactionJson() => const <String, dynamic>{
  'id': 2,
  'transaction_number': 'TRX-20260716-OMRSCC',
  'order_number': null,
  'cashier': <String, dynamic>{'id': 1, 'name': 'Kasir SmartKasir'},
  'total': 5000,
  'total_formatted': 'Rp5.000',
  'paid_amount': 10000,
  'paid_amount_formatted': 'Rp10.000',
  'change_amount': 5000,
  'change_amount_formatted': 'Rp5.000',
  'payment_method': 'cash',
  'payment_method_label': 'Tunai',
  'items_count': 1,
  'items': <Object?>[
    <String, dynamic>{
      'product_id': 7,
      'product_name': 'Nugget Goreng',
      'quantity': 1,
      'price': 5000,
      'price_formatted': 'Rp5.000',
      'subtotal': 5000,
      'subtotal_formatted': 'Rp5.000',
    },
  ],
  'created_at': '2026-07-16T05:47:44+08:00',
  'updated_at': '2026-07-16T05:47:44+08:00',
};

class _FakeApiClient implements ApiClient {
  _FakeApiClient({required this.postHandler})
    : tokenStorage = TokenStorage(MemorySecureKeyValueStore());

  final Future<ApiResponseBody> Function(String path, Object? data) postHandler;

  @override
  final TokenStorage tokenStorage;

  String? lastPath;
  Object? lastData;

  @override
  Future<ApiResponseBody> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    throw const ApiException(message: 'GET tidak disiapkan.');
  }

  @override
  Future<ApiResponseBody> patch(String path, {Object? data}) {
    throw const ApiException(message: 'PATCH tidak disiapkan.');
  }

  @override
  Future<ApiResponseBody> post(String path, {Object? data}) async {
    lastPath = path;
    lastData = data;
    return postHandler(path, data);
  }
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository()
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  Exception? error;
  CreateProductInput? lastInput;
  int createCalls = 0;
  int productCalls = 0;

  @override
  Future<ProductModel> createProduct(CreateProductInput input) async {
    createCalls += 1;
    lastInput = input;
    if (error != null) throw error!;
    return ProductModel.fromJson(_productJson());
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    if (error != null) throw error!;
    return <CategoryModel>[CategoryModel.fromJson(_categoryJson())];
  }

  @override
  Future<ProductModel> fetchProductDetail(int productId) async {
    return ProductModel.fromJson(_productJson(id: productId));
  }

  @override
  Future<List<ProductModel>> fetchProducts({
    String? search,
    int? categoryId,
    bool? available,
  }) async {
    productCalls += 1;
    return <ProductModel>[ProductModel.fromJson(_productJson())];
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository({this.error})
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  Exception? error;
  CreateTransactionInput? lastInput;
  int createCalls = 0;

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
    createCalls += 1;
    lastInput = input;
    if (error != null) throw error!;
    return TransactionModel.fromJson(_transactionJson());
  }

  @override
  Future<TransactionModel> fetchTransactionDetail(int transactionId) async {
    return TransactionModel.fromJson(_transactionJson());
  }

  @override
  Future<List<TransactionModel>> fetchTransactions({
    String? search,
    DateTime? date,
  }) async {
    return <TransactionModel>[TransactionModel.fromJson(_transactionJson())];
  }
}

ProductModel _product({
  int id = 7,
  int stock = 5,
  bool isAvailable = true,
  bool canBeOrdered = true,
}) {
  return ProductModel.fromJson(
    _productJson(
      id: id,
      stock: stock,
      isAvailable: isAvailable,
      canBeOrdered: canBeOrdered,
    ),
  );
}

CreateProductInput _createProductInput() => const CreateProductInput(
  categoryId: 1,
  name: ' Nugget Goreng ',
  sku: ' mkn-007 ',
  description: ' Nugget ayam goreng. ',
  price: 5000,
  stock: 25,
  unit: ' pcs ',
  isAvailable: true,
);

Widget _productApp(ProductProvider provider) {
  return ChangeNotifierProvider<ProductProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const CreateProductPage(),
    ),
  );
}

Widget _transactionApp({
  required ProductProvider productProvider,
  required TransactionProvider transactionProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ChangeNotifierProvider<TransactionProvider>.value(
        value: transactionProvider,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const CreateTransactionPage(),
    ),
  );
}

void main() {
  group('Product post stage 9', () {
    test('CreateProductInput menghasilkan JSON aman', () {
      final json = _createProductInput().toJson();

      expect(json['category_id'], 1);
      expect(json['name'], 'Nugget Goreng');
      expect(json['sku'], 'MKN-007');
      expect(json['price'], 5000);
      expect(json['stock'], 25);
      expect(json['unit'], 'pcs');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('price_formatted'), isFalse);
    });

    test(
      'ProductRepository POST produk berhasil dan invalid ditolak',
      () async {
        final apiClient = _FakeApiClient(
          postHandler: (_, _) async => ApiResponseBody(
            success: true,
            message: 'Produk berhasil ditambahkan.',
            data: _productJson(),
          ),
        );
        final repository = ProductRepository(apiClient: apiClient);

        final product = await repository.createProduct(_createProductInput());
        expect(product.name, 'Nugget Goreng');
        expect(apiClient.lastPath, '/products');
        expect((apiClient.lastData as Map<String, dynamic>)['sku'], 'MKN-007');

        final invalid = ProductRepository(
          apiClient: _FakeApiClient(
            postHandler: (_, _) async =>
                const ApiResponseBody(success: true, message: 'OK', data: null),
          ),
        );
        expect(
          invalid.createProduct(_createProductInput()),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test(
      'ProductProvider create berhasil, gagal, unauthorized, reset',
      () async {
        final repository = _FakeProductRepository();
        final provider = ProductProvider(productRepository: repository);

        expect(await provider.createProduct(_createProductInput()), isTrue);
        expect(provider.createdProduct?.sku, 'MKN-007');
        expect(provider.isCreatingProduct, isFalse);
        expect(provider.products, isNotEmpty);

        repository.error = const ApiException(
          message: 'SKU sudah digunakan.',
          statusCode: 422,
          validationErrors: <String, List<String>>{
            'sku': <String>['SKU sudah digunakan.'],
          },
        );
        expect(await provider.createProduct(_createProductInput()), isFalse);
        expect(provider.createProductValidationErrors['sku'], isNotEmpty);
        expect(provider.products, isNotEmpty);

        repository.error = const ApiException(
          message: 'Unauthenticated.',
          statusCode: 401,
        );
        expect(await provider.createProduct(_createProductInput()), isFalse);
        expect(provider.isUnauthorized, isTrue);

        provider.reset();
        expect(provider.createdProduct, isNull);
        expect(provider.createProductError, isNull);
        expect(provider.createProductValidationErrors, isEmpty);
      },
    );

    testWidgets('CreateProductPage menampilkan field dan validasi kosong', (
      tester,
    ) async {
      final provider = ProductProvider(
        productRepository: _FakeProductRepository(),
      );
      await provider.loadCategories();

      await tester.pumpWidget(_productApp(provider));
      await tester.pump();

      expect(find.text('Tambah Produk'), findsOneWidget);
      expect(find.text('Nama produk'), findsOneWidget);
      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('Simpan Produk'), findsOneWidget);

      await tester.tap(find.text('Simpan Produk'));
      await tester.pump();
      expect(find.text('Kategori wajib dipilih.'), findsOneWidget);
      expect(find.text('Nama produk wajib diisi.'), findsOneWidget);
    });
  });

  group('Transaction post stage 9', () {
    test(
      'CreateTransactionInput tidak mengirim total, price, atau kembalian',
      () {
        const input = CreateTransactionInput(
          paidAmount: 10000,
          paymentMethod: 'cash',
          items: <CreateTransactionItemInput>[
            CreateTransactionItemInput(productId: 7, quantity: 2),
          ],
        );

        final json = input.toJson();
        expect(json['paid_amount'], 10000);
        expect(json['payment_method'], 'cash');
        expect(json['items'], hasLength(1));
        expect(json.containsKey('total'), isFalse);
        expect(json.containsKey('price'), isFalse);
        expect(json.containsKey('change_amount'), isFalse);
        expect(json.containsKey('transaction_number'), isFalse);
      },
    );

    test('CashierCartItem menghitung subtotal tampilan', () {
      final item = CashierCartItem(product: _product(), quantity: 2);
      expect(item.subtotalPreview, 10000);
      expect(item.copyWith(quantity: 3).quantity, 3);
    });

    test('TransactionRepository POST berhasil dan invalid ditolak', () async {
      final apiClient = _FakeApiClient(
        postHandler: (_, _) async => ApiResponseBody(
          success: true,
          message: 'Transaksi berhasil disimpan.',
          data: _transactionJson(),
        ),
      );
      final repository = TransactionRepository(apiClient: apiClient);
      const input = CreateTransactionInput(
        paidAmount: 10000,
        paymentMethod: 'cash',
        items: <CreateTransactionItemInput>[
          CreateTransactionItemInput(productId: 7, quantity: 1),
        ],
      );

      final transaction = await repository.createTransaction(input);
      expect(transaction.transactionNumber, 'TRX-20260716-OMRSCC');
      expect(apiClient.lastPath, '/transactions');
      expect(
        (apiClient.lastData as Map<String, dynamic>).containsKey('total'),
        isFalse,
      );

      final invalid = TransactionRepository(
        apiClient: _FakeApiClient(
          postHandler: (_, _) async =>
              const ApiResponseBody(success: true, message: 'OK', data: null),
        ),
      );
      expect(invalid.createTransaction(input), throwsA(isA<ApiException>()));
    });

    test('TransactionProvider keranjang dan submit bekerja', () async {
      final repository = _FakeTransactionRepository();
      final provider = TransactionProvider(transactionRepository: repository);
      final product = _product(stock: 2);

      provider.addProductToCart(product);
      provider.addProductToCart(product);
      provider.addProductToCart(product);
      expect(provider.cartItems.single.quantity, 2);
      expect(provider.createTransactionError, 'Stok produk tidak mencukupi.');

      provider.decreaseQuantity(product.id);
      expect(provider.cartItems.single.quantity, 1);
      provider.setPaidAmount(1000);
      expect(provider.canSubmit, isFalse);
      provider.setPaidAmount(10000);
      expect(provider.previewTotal, 5000);
      expect(provider.previewChange, 5000);
      expect(provider.canSubmit, isTrue);

      expect(await provider.createTransaction(), isTrue);
      expect(provider.createdTransaction?.transactionNumber, isNotEmpty);
      expect(provider.cartItems, isEmpty);
      expect(repository.lastInput?.toJson().containsKey('total'), isFalse);
    });

    test(
      'TransactionProvider gagal tidak menghapus keranjang dan reset bersih',
      () async {
        final repository = _FakeTransactionRepository(
          error: const ApiException(
            message: 'Jumlah pembayaran kurang dari total transaksi.',
            statusCode: 422,
            validationErrors: <String, List<String>>{
              'paid_amount': <String>[
                'Jumlah pembayaran kurang dari total transaksi.',
              ],
            },
          ),
        );
        final provider = TransactionProvider(transactionRepository: repository);
        provider.addProductToCart(_product());
        provider.setPaidAmount(10000);

        expect(await provider.createTransaction(), isFalse);
        expect(provider.cartItems, isNotEmpty);
        expect(
          provider.createTransactionValidationErrors['paid_amount'],
          isNotEmpty,
        );

        provider.reset();
        expect(provider.cartItems, isEmpty);
        expect(provider.createdTransaction, isNull);
        expect(provider.createTransactionError, isNull);
      },
    );

    test('TransactionProvider unauthorized dikenali', () async {
      final repository = _FakeTransactionRepository(
        error: const ApiException(message: 'Unauthenticated.', statusCode: 401),
      );
      final provider = TransactionProvider(transactionRepository: repository);
      provider.addProductToCart(_product());
      provider.setPaidAmount(10000);

      expect(await provider.createTransaction(), isFalse);
      expect(provider.isUnauthorized, isTrue);
    });

    testWidgets('CreateTransactionPage menampilkan produk dan keranjang', (
      tester,
    ) async {
      final productProvider = ProductProvider(
        productRepository: _FakeProductRepository(),
      );
      final transactionProvider = TransactionProvider(
        transactionRepository: _FakeTransactionRepository(),
      );

      await productProvider.loadInitialData();
      await tester.pumpWidget(
        _transactionApp(
          productProvider: productProvider,
          transactionProvider: transactionProvider,
        ),
      );
      await tester.pump();

      expect(find.text('Pilih Produk'), findsOneWidget);
      expect(find.text('Keranjang kosong'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);

      await tester.tap(find.text('Tambah'));
      await tester.pump();
      expect(find.text('Keranjang'), findsOneWidget);
      expect(find.text('Simpan Transaksi'), findsOneWidget);
    });
  });
}
