import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'create_transaction_page.dart';
import 'transaction_detail_page.dart';

/// Halaman daftar transaksi yang terintegrasi dengan `GET /api/transactions`.
class TransactionsPage extends StatefulWidget {
  /// Membuat halaman transaksi dengan lazy loading berdasarkan tab aktif.
  const TransactionsPage({super.key, this.isActive = true});

  /// Bernilai true ketika tab Transaksi sedang aktif.
  final bool isActive;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  TransactionProvider? _provider;
  bool _handledUnauthorized = false;
  bool _showingRefreshError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<TransactionProvider>();

    if (_provider == nextProvider) {
      return;
    }

    _provider?.removeListener(_handleProviderChange);
    _provider = nextProvider..addListener(_handleProviderChange);
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(covariant TransactionsPage oldWidget) {
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
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (_searchController.text != provider.searchQuery) {
          _searchController.text = provider.searchQuery;
        }

        return switch (provider.status) {
          TransactionStatusState.initial when !widget.isActive =>
            const SizedBox.shrink(),
          TransactionStatusState.initial || TransactionStatusState.loading =>
            const AppLoading(message: 'Memuat transaksi...'),
          TransactionStatusState.failure when provider.transactions.isEmpty =>
            AppErrorView(
              title: 'Transaksi belum dapat dimuat',
              message: provider.errorMessage ?? 'Transaksi belum dapat dimuat.',
              onRetry: provider.loadTransactions,
            ),
          _ => _TransactionListContent(
            provider: provider,
            searchController: _searchController,
            onOpenDetail: _openDetail,
            onCreateTransaction: _openCreateTransaction,
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

      final provider = context.read<TransactionProvider>();
      if (provider.status == TransactionStatusState.initial) {
        provider.loadTransactions();
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
        final transactionProvider = context.read<TransactionProvider>();
        await authProvider.expireSession(message: message);
        transactionProvider.reset();
      });
      return;
    }

    if (provider.transactions.isNotEmpty &&
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
        context.read<TransactionProvider>().clearError();
        _showingRefreshError = false;
      });
    }
  }

  void _openDetail(TransactionModel transaction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailPage(transactionId: transaction.id),
      ),
    );
  }

  Future<void> _openCreateTransaction() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateTransactionPage()),
    );

    if (created == true && mounted) {
      await context.read<TransactionProvider>().refreshTransactions();
    }
  }
}

class _TransactionListContent extends StatelessWidget {
  const _TransactionListContent({
    required this.provider,
    required this.searchController,
    required this.onOpenDetail,
    required this.onCreateTransaction,
  });

  final TransactionProvider provider;
  final TextEditingController searchController;
  final ValueChanged<TransactionModel> onOpenDetail;
  final VoidCallback onCreateTransaction;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: provider.refreshTransactions,
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
                  _TransactionSearchAndFilters(
                    provider: provider,
                    controller: searchController,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onCreateTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Transaksi Baru'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${provider.transactions.length} transaksi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.transactions.isEmpty)
                    AppEmptyView(
                      icon: Icons.point_of_sale_outlined,
                      title: 'Transaksi',
                      description: 'Belum ada transaksi yang sesuai.',
                      action: provider.hasActiveFilters
                          ? OutlinedButton.icon(
                              onPressed: provider.clearFilters,
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Hapus Filter'),
                            )
                          : null,
                    )
                  else
                    ...provider.transactions.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionCard(
                          transaction: transaction,
                          onTap: () => onOpenDetail(transaction),
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

class _TransactionSearchAndFilters extends StatelessWidget {
  const _TransactionSearchAndFilters({
    required this.provider,
    required this.controller,
  });

  final TransactionProvider provider;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final selectedDate = provider.selectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Cari transaksi',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Cari transaksi',
              onPressed: () => provider.searchTransactions(controller.text),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: provider.searchTransactions,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: selectedDate ?? DateTime.now(),
                );

                if (picked != null) {
                  await provider.setDateFilter(picked);
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                selectedDate == null
                    ? 'Filter tanggal'
                    : DateFormatter.apiDate(selectedDate),
              ),
            ),
            if (provider.hasActiveFilters)
              OutlinedButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Hapus Filter'),
              ),
          ],
        ),
      ],
    );
  }
}
