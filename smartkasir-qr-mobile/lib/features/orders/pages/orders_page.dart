import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import 'order_detail_page.dart';

/// Halaman daftar pesanan yang terintegrasi dengan `GET /api/orders`.
class OrdersPage extends StatefulWidget {
  /// Membuat halaman pesanan dengan lazy loading berdasarkan tab aktif.
  const OrdersPage({super.key, this.isActive = true});

  /// Bernilai true ketika tab Pesanan sedang aktif.
  final bool isActive;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _searchController = TextEditingController();
  OrderProvider? _provider;
  bool _handledUnauthorized = false;
  bool _showingRefreshError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<OrderProvider>();

    if (_provider == nextProvider) {
      return;
    }

    _provider?.removeListener(_handleProviderChange);
    _provider = nextProvider..addListener(_handleProviderChange);
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleInitialLoad();
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (_searchController.text != provider.searchQuery) {
          _searchController.text = provider.searchQuery;
        }

        return switch (provider.status) {
          OrderStatusState.initial when !widget.isActive =>
            const SizedBox.shrink(),
          OrderStatusState.initial || OrderStatusState.loading =>
            const AppLoading(message: 'Memuat pesanan...'),
          OrderStatusState.failure when provider.orders.isEmpty => AppErrorView(
            title: 'Pesanan belum dapat dimuat',
            message: provider.errorMessage ?? 'Pesanan belum dapat dimuat.',
            onRetry: provider.loadOrders,
          ),
          _ => _OrderListContent(
            provider: provider,
            searchController: _searchController,
            onOpenDetail: _openDetail,
          ),
        };
      },
    );
  }

  void _scheduleInitialLoad() {
    if (!widget.isActive) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<OrderProvider>();
      if (provider.status == OrderStatusState.initial) {
        provider.loadOrders();
      }
    });
  }

  void _handleProviderChange() {
    final provider = _provider;
    if (!mounted || provider == null) {
      return;
    }

    if (provider.isUnauthorized && !_handledUnauthorized) {
      _handledUnauthorized = true;
      final message =
          provider.errorMessage ??
          'Sesi Anda telah berakhir. Silakan login kembali.';

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }

        final authProvider = context.read<AuthProvider>();
        final orderProvider = context.read<OrderProvider>();
        await authProvider.expireSession(message: message);
        orderProvider.reset();
      });
      return;
    }

    if (provider.orders.isNotEmpty &&
        provider.errorMessage != null &&
        !provider.isRefreshing &&
        !_showingRefreshError) {
      _showingRefreshError = true;
      final message = provider.errorMessage!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<OrderProvider>().clearError();
        _showingRefreshError = false;
      });
    }
  }

  void _openDetail(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailPage(orderId: order.id),
      ),
    );
  }
}

class _OrderListContent extends StatelessWidget {
  const _OrderListContent({
    required this.provider,
    required this.searchController,
    required this.onOpenDetail,
  });

  final OrderProvider provider;
  final TextEditingController searchController;
  final ValueChanged<OrderModel> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: provider.refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderSearchAndFilters(
                    provider: provider,
                    controller: searchController,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${provider.orders.length} pesanan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.orders.isEmpty)
                    AppEmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Pesanan',
                      description: 'Belum ada pesanan yang sesuai.',
                      action: provider.hasActiveFilters
                          ? OutlinedButton.icon(
                              onPressed: provider.clearFilters,
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Hapus Filter'),
                            )
                          : null,
                    )
                  else
                    ...provider.orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderCard(
                          order: order,
                          onTap: () => onOpenDetail(order),
                        ),
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

class _OrderSearchAndFilters extends StatelessWidget {
  const _OrderSearchAndFilters({
    required this.provider,
    required this.controller,
  });

  final OrderProvider provider;
  final TextEditingController controller;

  static const statuses = <String?, String>{
    null: 'Semua',
    'pending': 'Menunggu',
    'confirmed': 'Dikonfirmasi',
    'processing': 'Diproses',
    'ready': 'Siap',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };

  static const descriptions = <String?, String>{
    null:
        'Menunggu, dikonfirmasi, diproses, dan siap adalah status perlu tindakan.',
    'pending': 'Menunggu: perlu dikonfirmasi.',
    'confirmed': 'Dikonfirmasi: siap diproses.',
    'processing': 'Diproses: sedang dibuat.',
    'ready': 'Siap: menunggu pembayaran.',
    'completed': 'Selesai: sudah dibayar.',
    'cancelled': 'Dibatalkan: tidak diproses.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Cari pesanan',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Cari pesanan',
              onPressed: () => provider.searchOrders(controller.text),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: provider.searchOrders,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownMenu<String?>(
              label: const Text('Status'),
              initialSelection: provider.selectedStatus,
              onSelected: provider.setStatusFilter,
              dropdownMenuEntries: statuses.entries
                  .map(
                    (entry) => DropdownMenuEntry<String?>(
                      value: entry.key,
                      label: entry.value,
                    ),
                  )
                  .toList(growable: false),
            ),
            if (provider.hasActiveFilters)
              OutlinedButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Hapus Filter'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          descriptions[provider.selectedStatus] ?? descriptions[null]!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
