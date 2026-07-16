import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Halaman detail transaksi yang membaca `GET /api/transactions/{id}`.
class TransactionDetailPage extends StatefulWidget {
  /// Membuat halaman detail untuk [transactionId].
  const TransactionDetailPage({required this.transactionId, super.key});

  /// ID transaksi yang dimuat dari backend.
  final int transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _requested = false;
  bool _handledUnauthorized = false;
  TransactionProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<TransactionProvider>();
  }

  @override
  void dispose() {
    _provider?.clearSelectedTransaction();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          _handleUnauthorized(provider);

          if (provider.isLoadingDetail &&
              provider.selectedTransaction == null) {
            return const AppLoading(message: 'Memuat detail transaksi...');
          }

          if (provider.selectedTransaction == null) {
            return AppErrorView(
              title: 'Detail transaksi belum dapat dimuat',
              message:
                  provider.errorMessage ??
                  'Detail transaksi belum dapat dimuat.',
              onRetry: _load,
            );
          }

          return _TransactionDetailContent(
            transaction: provider.selectedTransaction!,
          );
        },
      ),
    );
  }

  Future<void> _load() async {
    if (_requested &&
        context.read<TransactionProvider>().selectedTransaction != null) {
      return;
    }

    _requested = true;
    await context.read<TransactionProvider>().loadTransactionDetail(
      widget.transactionId,
    );
  }

  void _handleUnauthorized(TransactionProvider provider) {
    if (!provider.isUnauthorized || _handledUnauthorized) {
      return;
    }

    _handledUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final navigator = Navigator.of(context);

      await authProvider.expireSession(
        message:
            provider.errorMessage ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      transactionProvider.reset();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }
}

class _TransactionDetailContent extends StatelessWidget {
  const _TransactionDetailContent({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.transactionNumber,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Pesanan',
                          value:
                              transaction.orderNumber ?? 'Transaksi Langsung',
                        ),
                        _DetailRow(
                          label: 'Kasir',
                          value: transaction.cashierName,
                        ),
                        _DetailRow(
                          label: 'Total',
                          value: transaction.totalFormatted,
                        ),
                        _DetailRow(
                          label: 'Dibayar',
                          value: transaction.paidAmountFormatted,
                        ),
                        _DetailRow(
                          label: 'Kembalian',
                          value: transaction.changeAmountFormatted,
                        ),
                        _DetailRow(
                          label: 'Pembayaran',
                          value: transaction.paymentMethodLabel,
                        ),
                        _DetailRow(
                          label: 'Waktu',
                          value: transaction.createdAt == null
                              ? '-'
                              : DateFormatter.dateTime(
                                  transaction.createdAt!.toLocal(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Item Transaksi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...transaction.items.map(
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
