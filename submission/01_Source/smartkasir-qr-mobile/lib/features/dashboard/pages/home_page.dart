import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/order_status_summary.dart';
import '../widgets/recent_order_card.dart';

/// Halaman Home Dashboard kasir yang mengambil data dari REST API Laravel.
class HomePage extends StatefulWidget {
  /// Membuat halaman Home Dashboard Tahap 7.
  const HomePage({super.key, this.isActive = true});

  /// Bernilai true ketika tab Beranda sedang aktif.
  final bool isActive;

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State Home yang menjaga request dashboard tidak dipanggil dari build.
class _HomePageState extends State<HomePage> {
  DashboardProvider? _dashboardProvider;
  bool _didRequestInitialLoad = false;
  bool _isHandlingUnauthorized = false;
  bool _isShowingRefreshError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextProvider = context.read<DashboardProvider>();
    if (_dashboardProvider == nextProvider) {
      return;
    }

    _dashboardProvider?.removeListener(_handleDashboardChange);
    _dashboardProvider = nextProvider..addListener(_handleDashboardChange);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleInitialLoad();
  }

  @override
  void dispose() {
    _dashboardProvider?.removeListener(_handleDashboardChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleInitialLoad();

    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        return switch (dashboardProvider.status) {
          DashboardStatus.initial || DashboardStatus.loading =>
            const AppLoading(message: 'Memuat dashboard...'),
          DashboardStatus.failure when dashboardProvider.dashboard == null =>
            AppErrorView(
              title: 'Dashboard belum dapat dimuat',
              message:
                  dashboardProvider.errorMessage ??
                  'Dashboard belum dapat dimuat.',
              onRetry: dashboardProvider.loadDashboard,
            ),
          _ => _DashboardContent(
            userName: authProvider.currentUser?.name ?? 'Pengguna',
            dashboard: dashboardProvider.dashboard,
            isRefreshing: dashboardProvider.isRefreshing,
            onRefresh: dashboardProvider.refreshDashboard,
          ),
        };
      },
    );
  }

  /// Menjadwalkan request dashboard awal satu kali setelah Home dirender.
  ///
  /// Request tidak dijalankan di build secara langsung. Jika provider sudah
  /// memiliki data, method ini tidak melakukan request ulang.
  void _scheduleInitialLoad() {
    if (_didRequestInitialLoad || !widget.isActive) {
      return;
    }

    _didRequestInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<DashboardProvider>();
      if (provider.status == DashboardStatus.initial) {
        provider.loadDashboard();
      }
    });
  }

  /// Menangani error refresh dan sesi kedaluwarsa dari DashboardProvider.
  ///
  /// Jika dashboard menerima 401, AuthProvider diminta menghapus token dan
  /// DashboardProvider di-reset. Jika refresh gagal saat data lama tersedia,
  /// Snackbar singkat ditampilkan tanpa mengganti seluruh halaman menjadi error.
  void _handleDashboardChange() {
    final provider = _dashboardProvider;
    if (!mounted || provider == null) {
      return;
    }

    if (provider.isUnauthorized && !_isHandlingUnauthorized) {
      _isHandlingUnauthorized = true;
      final message =
          provider.errorMessage ??
          'Sesi Anda telah berakhir. Silakan login kembali.';

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }

        final authProvider = context.read<AuthProvider>();
        final dashboardProvider = context.read<DashboardProvider>();

        await authProvider.expireSession(message: message);
        dashboardProvider.reset();
      });

      return;
    }

    if (provider.dashboard != null &&
        provider.errorMessage != null &&
        !provider.isRefreshing &&
        !_isShowingRefreshError) {
      _isShowingRefreshError = true;
      final message = provider.errorMessage!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<DashboardProvider>().clearError();
        _isShowingRefreshError = false;
      });
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.userName,
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String userName;
  final DashboardModel? dashboard;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = dashboard;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: data == null
                ? const AppEmptyView(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard kosong',
                    description:
                        'Belum ada data dashboard yang dapat ditampilkan.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardHeader(
                        userName: userName,
                        isRefreshing: isRefreshing,
                        onRefresh: onRefresh,
                      ),
                      const SizedBox(height: 16),
                      OrderStatusSummary(orders: data.orders),
                      const SizedBox(height: 12),
                      DashboardSummaryCard(
                        title: 'Penjualan Hari Ini',
                        icon: Icons.payments_outlined,
                        items: [
                          DashboardSummaryItem(
                            label: 'Transaksi Hari Ini',
                            value: data.today.transactions.toString(),
                          ),
                          DashboardSummaryItem(
                            label: 'Pendapatan Hari Ini',
                            value: data.today.revenueFormatted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DashboardSummaryCard(
                        title: 'Produk',
                        icon: Icons.inventory_2_outlined,
                        items: [
                          DashboardSummaryItem(
                            label: 'Produk Aktif',
                            value: data.products.totalActive.toString(),
                          ),
                          DashboardSummaryItem(
                            label: 'Stok Menipis',
                            value: data.products.lowStock.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _RecentOrdersSection(dashboard: data),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String userName;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ringkasan Hari Ini',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.dateTime(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh dashboard',
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({required this.dashboard});

  final DashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final recentOrders = dashboard.recentOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pesanan Terbaru',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (recentOrders.isEmpty)
          const AppEmptyView(
            icon: Icons.inbox_outlined,
            title: 'Belum ada pesanan terbaru',
            description: 'Pesanan terbaru dari REST API akan muncul di sini.',
          )
        else
          ...recentOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecentOrderCard(order: order),
            ),
          ),
      ],
    );
  }
}
