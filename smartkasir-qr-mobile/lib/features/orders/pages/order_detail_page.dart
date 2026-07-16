import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../products/providers/product_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';
import 'order_payment_page.dart';

/// Halaman detail pesanan yang membaca `GET /api/orders/{id}`.
class OrderDetailPage extends StatefulWidget {
  /// Membuat halaman detail untuk [orderId].
  const OrderDetailPage({required this.orderId, super.key});

  /// ID pesanan yang dimuat dari backend.
  final int orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _requested = false;
  bool _handledUnauthorized = false;
  OrderProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<OrderProvider>();
  }

  @override
  void dispose() {
    _provider?.clearSelectedOrder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          _handleUnauthorized(provider);

          if (provider.isLoadingDetail && provider.selectedOrder == null) {
            return const AppLoading(message: 'Memuat detail pesanan...');
          }

          if (provider.selectedOrder == null) {
            return AppErrorView(
              title: 'Detail pesanan belum dapat dimuat',
              message:
                  provider.errorMessage ?? 'Detail pesanan belum dapat dimuat.',
              onRetry: _load,
            );
          }

          return _OrderDetailContent(
            order: provider.selectedOrder!,
            provider: provider,
            onConfirm: () => _confirmOrder(provider.selectedOrder!),
            onProcess: () => _processOrder(provider.selectedOrder!),
            onReady: () => _markReady(provider.selectedOrder!),
            onCancel: () => _cancelOrder(provider.selectedOrder!),
            onPay: () => _openPayment(provider.selectedOrder!),
          );
        },
      ),
    );
  }

  Future<void> _load() async {
    if (_requested && context.read<OrderProvider>().selectedOrder != null) {
      return;
    }

    _requested = true;
    await context.read<OrderProvider>().loadOrderDetail(widget.orderId);
  }

  void _handleUnauthorized(OrderProvider provider) {
    if (!provider.isUnauthorized || _handledUnauthorized) {
      return;
    }

    _handledUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      final productProvider = context.read<ProductProvider>();
      final dashboardProvider = context.read<DashboardProvider>();
      final navigator = Navigator.of(context);

      await authProvider.expireSession(
        message:
            provider.errorMessage ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      orderProvider.reset();
      productProvider.reset();
      dashboardProvider.reset();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _confirmOrder(OrderModel order) async {
    final confirmed = await _confirmDialog(
      title: 'Konfirmasi pesanan?',
      message: 'Stok produk akan dikurangi setelah pesanan dikonfirmasi.',
      confirmLabel: 'Konfirmasi',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final provider = context.read<OrderProvider>();
    final success = await provider.confirmOrder(order.id);
    if (!mounted) {
      return;
    }

    if (success) {
      await _refreshAfterAction(refreshProducts: true);
      _showSnack('Pesanan berhasil dikonfirmasi.');
    }
  }

  Future<void> _processOrder(OrderModel order) async {
    final confirmed = await _confirmDialog(
      title: 'Mulai proses pesanan?',
      message: 'Pesanan akan ditandai sedang diproses.',
      confirmLabel: 'Mulai Proses',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final success = await context.read<OrderProvider>().processOrder(order.id);
    if (!mounted) {
      return;
    }

    if (success) {
      await _refreshAfterAction();
      _showSnack('Pesanan sedang diproses.');
    }
  }

  Future<void> _markReady(OrderModel order) async {
    final confirmed = await _confirmDialog(
      title: 'Pesanan sudah siap?',
      message: 'Pastikan seluruh item telah selesai dibuat.',
      confirmLabel: 'Tandai Siap',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final success = await context.read<OrderProvider>().markOrderReady(
      order.id,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      await _refreshAfterAction();
      _showSnack('Pesanan siap diserahkan.');
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final reason = await _cancelDialog(order);
    if (reason == null || !mounted) {
      return;
    }

    final success = await context.read<OrderProvider>().cancelOrder(
      order.id,
      reason: reason,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      await _refreshAfterAction(refreshProducts: order.stockDeducted);
      _showSnack('Pesanan berhasil dibatalkan.');
    }
  }

  Future<void> _openPayment(OrderModel order) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => OrderPaymentPage(order: order)),
    );

    if (result == true && mounted) {
      await _refreshAfterAction(refreshProducts: true, refreshDetail: true);
    }
  }

  Future<void> _refreshAfterAction({
    bool refreshProducts = false,
    bool refreshDetail = false,
  }) async {
    final orderProvider = context.read<OrderProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final productProvider = context.read<ProductProvider>();
    if (refreshDetail) {
      await orderProvider.loadOrderDetail(widget.orderId);
    }
    await orderProvider.refreshOrders();
    await dashboardProvider.refreshDashboard();
    if (refreshProducts) {
      await productProvider.refreshProducts();
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<String?> _cancelDialog(OrderModel order) async {
    final controller = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pesanan yang dibatalkan tidak dapat diaktifkan kembali.',
            ),
            if (order.stockDeducted) ...[
              const SizedBox(height: 8),
              const Text(
                'Stok produk akan dikembalikan setelah pembatalan berhasil.',
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan',
                hintText: 'Opsional',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.provider,
    required this.onConfirm,
    required this.onProcess,
    required this.onReady,
    required this.onCancel,
    required this.onPay,
  });

  final OrderModel order;
  final OrderProvider provider;
  final VoidCallback onConfirm;
  final VoidCallback onProcess;
  final VoidCallback onReady;
  final VoidCallback onCancel;
  final VoidCallback onPay;

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.orderNumber,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            OrderStatusBadge(
                              status: order.status,
                              label: order.statusLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(label: 'Meja', value: order.tableName),
                        _DetailRow(
                          label: 'Pelanggan',
                          value: order.customerName ?? 'Pelanggan',
                        ),
                        _DetailRow(label: 'Total', value: order.totalFormatted),
                        _DetailRow(
                          label: 'Waktu',
                          value: order.createdAt == null
                              ? '-'
                              : DateFormatter.dateTime(
                                  order.createdAt!.toLocal(),
                                ),
                        ),
                        _DetailRow(
                          label: 'Status stok',
                          value: order.stockDeducted
                              ? 'Stok sudah dikurangi'
                              : 'Stok belum dikurangi',
                        ),
                        if (order.notes != null)
                          _DetailRow(label: 'Catatan', value: order.notes!),
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
                        '${item.quantity} x ${item.priceFormatted}'
                        '${item.notes == null ? '' : '\nCatatan: ${item.notes}'}',
                      ),
                      trailing: Text(
                        item.subtotalFormatted,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _OrderActions(
                  order: order,
                  provider: provider,
                  onConfirm: onConfirm,
                  onProcess: onProcess,
                  onReady: onReady,
                  onCancel: onCancel,
                  onPay: onPay,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.provider,
    required this.onConfirm,
    required this.onProcess,
    required this.onReady,
    required this.onCancel,
    required this.onPay,
  });

  final OrderModel order;
  final OrderProvider provider;
  final VoidCallback onConfirm;
  final VoidCallback onProcess;
  final VoidCallback onReady;
  final VoidCallback onCancel;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final isBusy =
        provider.isUpdatingOrder && provider.updatingOrderId == order.id;
    final buttons = <Widget>[];

    switch (order.status) {
      case 'pending':
        buttons.add(
          _ActionButton(
            label: 'Konfirmasi Pesanan',
            icon: Icons.check_circle_outline,
            onPressed: onConfirm,
            isBusy: isBusy && provider.orderAction == 'confirm',
          ),
        );
        buttons.add(_CancelButton(onPressed: onCancel, disabled: isBusy));
        break;
      case 'confirmed':
        buttons.add(
          _ActionButton(
            label: 'Mulai Proses',
            icon: Icons.restaurant_outlined,
            onPressed: onProcess,
            isBusy: isBusy && provider.orderAction == 'process',
          ),
        );
        buttons.add(_CancelButton(onPressed: onCancel, disabled: isBusy));
        break;
      case 'processing':
        buttons.add(
          _ActionButton(
            label: 'Tandai Siap',
            icon: Icons.task_alt,
            onPressed: onReady,
            isBusy: isBusy && provider.orderAction == 'ready',
          ),
        );
        buttons.add(_CancelButton(onPressed: onCancel, disabled: isBusy));
        break;
      case 'ready':
        buttons.add(
          _ActionButton(
            label: 'Terima Pembayaran',
            icon: Icons.payments_outlined,
            onPressed: onPay,
            isBusy: false,
          ),
        );
        buttons.add(_CancelButton(onPressed: onCancel, disabled: isBusy));
        break;
      case 'completed':
        buttons.add(
          const _StatusNote(message: 'Pesanan sudah selesai dibayar.'),
        );
        break;
      case 'cancelled':
        buttons.add(const _StatusNote(message: 'Pesanan telah dibatalkan.'));
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tindakan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (provider.actionError != null) ...[
              Text(
                provider.actionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => provider.loadOrderDetail(order.id),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
              ),
              const SizedBox(height: 10),
            ],
            ...buttons.map(
              (button) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isBusy,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(isBusy ? 'Memproses...' : label),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed, required this.disabled});

  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: disabled ? null : onPressed,
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Batalkan Pesanan'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
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
