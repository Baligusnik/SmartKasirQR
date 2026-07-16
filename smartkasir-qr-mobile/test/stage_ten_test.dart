import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:smartkasir_qr_mobile/core/errors/api_exception.dart';
import 'package:smartkasir_qr_mobile/core/network/api_client.dart';
import 'package:smartkasir_qr_mobile/core/storage/token_storage.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartkasir_qr_mobile/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartkasir_qr_mobile/features/orders/models/order_model.dart';
import 'package:smartkasir_qr_mobile/features/orders/pages/order_detail_page.dart';
import 'package:smartkasir_qr_mobile/features/orders/providers/order_provider.dart';
import 'package:smartkasir_qr_mobile/features/orders/repositories/order_repository.dart';
import 'package:smartkasir_qr_mobile/features/products/providers/product_provider.dart';
import 'package:smartkasir_qr_mobile/features/products/repositories/product_repository.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_order_payment_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/create_transaction_input.dart';
import 'package:smartkasir_qr_mobile/features/transactions/models/transaction_model.dart';
import 'package:smartkasir_qr_mobile/features/transactions/providers/transaction_provider.dart';
import 'package:smartkasir_qr_mobile/features/transactions/repositories/transaction_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  test('CreateOrderPaymentInput hanya mengirim field pembayaran order', () {
    final json = const CreateOrderPaymentInput(
      orderId: 5,
      paidAmount: 20000,
      paymentMethod: 'cash',
    ).toJson();

    expect(json, <String, Object>{
      'order_id': 5,
      'paid_amount': 20000,
      'payment_method': 'cash',
    });
    expect(json.containsKey('items'), isFalse);
    expect(json.containsKey('total'), isFalse);
    expect(json.containsKey('change_amount'), isFalse);
    expect(json.containsKey('user_id'), isFalse);
    expect(json.containsKey('transaction_number'), isFalse);
  });

  test(
    'OrderProvider action berhasil dan gagal tidak mengubah status lokal',
    () async {
      final repository = _FakeOrderRepository();
      final provider = OrderProvider(orderRepository: repository);
      await provider.loadOrderDetail(5);

      expect(await provider.confirmOrder(5), isTrue);
      expect(provider.selectedOrder?.status, 'confirmed');
      expect(provider.selectedOrder?.stockDeducted, isTrue);

      repository.error = const ApiException(message: 'Status tidak sah.');
      expect(await provider.processOrder(5), isFalse);
      expect(provider.selectedOrder?.status, 'confirmed');
      expect(provider.actionError, 'Status tidak sah.');

      provider.reset();
      expect(provider.updatedOrder, isNull);
      expect(provider.actionError, isNull);
    },
  );

  test(
    'TransactionProvider pembayaran order validasi, sukses, dan unauthorized',
    () async {
      final repository = _FakeTransactionRepository();
      final provider = TransactionProvider(transactionRepository: repository);
      final order = _order(status: 'ready', total: 18000);

      provider.prepareOrderPayment(order);
      provider.setOrderPaidAmount(10000);
      expect(await provider.payOrder(order), isFalse);
      expect(provider.orderPaymentError, 'Uang dibayar masih kurang.');

      provider.setOrderPaidAmount(20000);
      expect(await provider.payOrder(order), isTrue);
      expect(provider.paidOrderTransaction, isNotNull);
      expect(repository.lastOrderPayment?.toJson()['order_id'], 5);

      repository.error = const ApiException(
        message: 'Unauthenticated.',
        statusCode: 401,
      );
      provider.setOrderPaidAmount(20000);
      expect(await provider.payOrder(order), isFalse);
      expect(provider.isUnauthorized, isTrue);

      provider.reset();
      expect(provider.paidOrderTransaction, isNull);
      expect(provider.orderPaidAmount, 0);
    },
  );

  testWidgets('OrderDetailPage menampilkan tombol sesuai status', (
    tester,
  ) async {
    await tester.pumpWidget(_detailApp(_order(status: 'ready')));
    await tester.pumpAndSettle();

    expect(find.text('Terima Pembayaran'), findsOneWidget);
    expect(find.text('Batalkan Pesanan'), findsOneWidget);
    expect(find.text('Konfirmasi Pesanan'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(_detailApp(_order(status: 'completed')));
    await tester.pumpAndSettle();

    expect(find.text('Pesanan sudah selesai dibayar.'), findsOneWidget);
    expect(find.text('Terima Pembayaran'), findsNothing);
    expect(find.text('Batalkan Pesanan'), findsNothing);
  });
}

Widget _detailApp(OrderModel order) {
  final tokenStorage = TokenStorage(MemorySecureKeyValueStore());
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OrderProvider>(
        create: (_) =>
            OrderProvider(orderRepository: _FakeOrderRepository(detail: order)),
      ),
      ChangeNotifierProvider<ProductProvider>(
        create: (_) => ProductProvider(
          productRepository: ProductRepository(apiClient: apiClient),
        ),
      ),
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => DashboardProvider(
          dashboardRepository: DashboardRepository(apiClient: apiClient),
        ),
      ),
      ChangeNotifierProvider<TransactionProvider>(
        create: (_) => TransactionProvider(
          transactionRepository: _FakeTransactionRepository(),
        ),
      ),
    ],
    child: const MaterialApp(home: OrderDetailPage(orderId: 5)),
  );
}

OrderModel _order({String status = 'pending', int total = 18000}) {
  final label = switch (status) {
    'confirmed' => 'Dikonfirmasi',
    'processing' => 'Diproses',
    'ready' => 'Siap',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => 'Menunggu',
  };

  return OrderModel.fromJson(<String, dynamic>{
    'id': 5,
    'order_number': 'ORD-STAGE-10',
    'table': const <String, dynamic>{
      'id': 1,
      'name': 'Meja 1',
      'code': 'MEJA-01',
    },
    'customer_name': 'Pelanggan',
    'status': status,
    'status_label': label,
    'notes': null,
    'total': total,
    'total_formatted': 'Rp18.000',
    'stock_deducted': status != 'pending',
    'items_count': 1,
    'items': const <Object>[
      <String, dynamic>{
        'product_id': 1,
        'product_name': 'Sempol',
        'quantity': 2,
        'price': 9000,
        'price_formatted': 'Rp9.000',
        'subtotal': 18000,
        'subtotal_formatted': 'Rp18.000',
        'notes': null,
      },
    ],
    'created_at': '2026-07-16T07:30:00+08:00',
  });
}

TransactionModel _transaction() {
  return TransactionModel.fromJson(const <String, dynamic>{
    'id': 9,
    'transaction_number': 'TRX-STAGE-10',
    'order_number': 'ORD-STAGE-10',
    'cashier': <String, dynamic>{'id': 1, 'name': 'Kasir SmartKasir'},
    'total': 18000,
    'total_formatted': 'Rp18.000',
    'paid_amount': 20000,
    'paid_amount_formatted': 'Rp20.000',
    'change_amount': 2000,
    'change_amount_formatted': 'Rp2.000',
    'payment_method': 'cash',
    'payment_method_label': 'Tunai',
    'items_count': 1,
    'items': <Object>[],
    'created_at': '2026-07-16T07:35:00+08:00',
  });
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({this.detail})
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  OrderModel? detail;
  Exception? error;

  @override
  Future<OrderModel> cancelOrder({required int orderId, String? reason}) async {
    if (error != null) throw error!;
    return _order(status: 'cancelled');
  }

  @override
  Future<OrderModel> confirmOrder(int orderId) async {
    if (error != null) throw error!;
    return _order(status: 'confirmed');
  }

  @override
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    if (error != null) throw error!;
    return detail ?? _order();
  }

  @override
  Future<List<OrderModel>> fetchOrders({String? status, String? search}) async {
    if (error != null) throw error!;
    return <OrderModel>[detail ?? _order()];
  }

  @override
  Future<OrderModel> markOrderReady(int orderId) async {
    if (error != null) throw error!;
    return _order(status: 'ready');
  }

  @override
  Future<OrderModel> processOrder(int orderId) async {
    if (error != null) throw error!;
    return _order(status: 'processing');
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository()
    : apiClient = ApiClient(
        tokenStorage: TokenStorage(MemorySecureKeyValueStore()),
      );

  @override
  final ApiClient apiClient;
  Exception? error;
  CreateOrderPaymentInput? lastOrderPayment;

  @override
  Future<TransactionModel> createOrderPayment(
    CreateOrderPaymentInput input,
  ) async {
    lastOrderPayment = input;
    if (error != null) throw error!;
    return _transaction();
  }

  @override
  Future<TransactionModel> createTransaction(
    CreateTransactionInput input,
  ) async {
    if (error != null) throw error!;
    return _transaction();
  }

  @override
  Future<TransactionModel> fetchTransactionDetail(int transactionId) async {
    if (error != null) throw error!;
    return _transaction();
  }

  @override
  Future<List<TransactionModel>> fetchTransactions({
    String? search,
    DateTime? date,
  }) async {
    if (error != null) throw error!;
    return <TransactionModel>[_transaction()];
  }
}
