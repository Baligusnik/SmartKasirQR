import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

/// Halaman pembayaran pesanan QR menggunakan `POST /api/transactions`.
class OrderPaymentPage extends StatefulWidget {
  /// Membuat halaman pembayaran untuk [order] berstatus ready.
  const OrderPaymentPage({required this.order, super.key});

  /// Pesanan QR yang akan dibayar.
  final OrderModel order;

  @override
  State<OrderPaymentPage> createState() => _OrderPaymentPageState();
}

class _OrderPaymentPageState extends State<OrderPaymentPage> {
  final _paidController = TextEditingController();
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().prepareOrderPayment(widget.order);
      }
    });
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transaction = provider.paidOrderTransaction;

        return Scaffold(
          appBar: AppBar(title: const Text('Pembayaran Pesanan')),
          body: _success && transaction != null
              ? _PaymentSuccess(
                  transaction: transaction,
                  onBackToOrders: () => Navigator.of(context).pop(true),
                  onViewTransactions: () => Navigator.of(context).pop(true),
                )
              : _PaymentForm(
                  order: widget.order,
                  provider: provider,
                  paidController: _paidController,
                  onSubmit: () => _submit(provider),
                ),
        );
      },
    );
  }

  Future<void> _submit(TransactionProvider transactionProvider) async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final productProvider = context.read<ProductProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    final success = await transactionProvider.payOrder(widget.order);
    if (!mounted) {
      return;
    }

    if (transactionProvider.isUnauthorized) {
      await authProvider.expireSession(
        message:
            transactionProvider.orderPaymentError ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      orderProvider.reset();
      productProvider.reset();
      transactionProvider.reset();
      dashboardProvider.reset();
      return;
    }

    if (!success) {
      return;
    }

    await orderProvider.loadOrderDetail(widget.order.id);
    await orderProvider.refreshOrders();
    await transactionProvider.refreshTransactions();
    await dashboardProvider.refreshDashboard();
    await productProvider.refreshProducts();

    if (mounted) {
      setState(() => _success = true);
    }
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.order,
    required this.provider,
    required this.paidController,
    required this.onSubmit,
  });

  final OrderModel order;
  final TransactionProvider provider;
  final TextEditingController paidController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (paidController.text != provider.orderPaidAmount.toString() &&
        provider.orderPaidAmount > 0) {
      paidController.text = provider.orderPaidAmount.toString();
    }

    final change = provider.previewOrderChange < 0
        ? 0
        : provider.previewOrderChange;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Meja', value: order.tableName),
                          _InfoRow(
                            label: 'Pelanggan',
                            value: order.customerName ?? 'Pelanggan',
                          ),
                          _InfoRow(label: 'Total', value: order.totalFormatted),
                          const _InfoRow(label: 'Pembayaran', value: 'Tunai'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Item Pesanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text(
                          '${item.quantity} x ${item.priceFormatted}',
                        ),
                        trailing: Text(
                          item.subtotalFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.orderPaymentError != null) ...[
                    _ErrorMessage(message: provider.orderPaymentError!),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: paidController,
                    enabled: !provider.isPayingOrder,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Uang dibayar',
                      prefixText: 'Rp ',
                    ),
                    onChanged: (value) {
                      provider.setOrderPaidAmount(
                        int.tryParse(value.trim()) ?? 0,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Kembalian sementara',
                    value: CurrencyFormatter.rupiah(change),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: provider.canPayOrder ? onSubmit : null,
                    icon: provider.isPayingOrder
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: Text(
                      provider.isPayingOrder
                          ? 'Menyimpan...'
                          : 'Simpan Pembayaran',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSuccess extends StatelessWidget {
  const _PaymentSuccess({
    required this.transaction,
    required this.onBackToOrders,
    required this.onViewTransactions,
  });

  final TransactionModel transaction;
  final VoidCallback onBackToOrders;
  final VoidCallback onViewTransactions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Pembayaran berhasil',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    label: 'Nomor transaksi',
                    value: transaction.transactionNumber,
                  ),
                  _InfoRow(
                    label: 'Nomor pesanan',
                    value: transaction.orderNumber ?? '-',
                  ),
                  _InfoRow(label: 'Total', value: transaction.totalFormatted),
                  _InfoRow(
                    label: 'Dibayar',
                    value: transaction.paidAmountFormatted,
                  ),
                  _InfoRow(
                    label: 'Kembalian',
                    value: transaction.changeAmountFormatted,
                  ),
                  _InfoRow(label: 'Kasir', value: transaction.cashierName),
                  _InfoRow(
                    label: 'Pembayaran',
                    value: transaction.paymentMethodLabel,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onBackToOrders,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Kembali ke Pesanan'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onViewTransactions,
                    icon: const Icon(Icons.history),
                    label: const Text('Lihat Transaksi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
