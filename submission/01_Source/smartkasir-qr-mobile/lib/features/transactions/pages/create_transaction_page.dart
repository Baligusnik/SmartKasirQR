import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../products/models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../models/cashier_cart_item.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Halaman transaksi kasir langsung yang mengirim `POST /api/transactions`.
class CreateTransactionPage extends StatefulWidget {
  /// Membuat halaman transaksi baru.
  const CreateTransactionPage({super.key});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _searchController = TextEditingController();
  final _paidController = TextEditingController();
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, TransactionProvider>(
      builder: (context, productProvider, transactionProvider, child) {
        final createdTransaction = transactionProvider.createdTransaction;

        return PopScope(
          canPop:
              _success ||
              (transactionProvider.cartItems.isEmpty &&
                  !transactionProvider.isCreatingTransaction),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            final leave = await _confirmLeave();
            if (leave && context.mounted) {
              transactionProvider.clearCart();
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Transaksi Baru')),
            body: _success && createdTransaction != null
                ? _TransactionSuccess(
                    transaction: createdTransaction,
                    onHistory: () => Navigator.of(context).pop(true),
                    onCreateAgain: () {
                      transactionProvider.clearCreateTransactionState();
                      _paidController.clear();
                      setState(() => _success = false);
                    },
                  )
                : _TransactionForm(
                    productProvider: productProvider,
                    transactionProvider: transactionProvider,
                    searchController: _searchController,
                    paidController: _paidController,
                    onSubmit: () => _submit(transactionProvider),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _ensureProducts() async {
    if (!mounted) {
      return;
    }

    final provider = context.read<ProductProvider>();
    if (provider.status == ProductStatus.initial) {
      await provider.loadInitialData();
    }
  }

  Future<void> _submit(TransactionProvider transactionProvider) async {
    final productProvider = context.read<ProductProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final authProvider = context.read<AuthProvider>();
    final success = await transactionProvider.createTransaction();
    if (!mounted) {
      return;
    }

    if (transactionProvider.isUnauthorized) {
      await authProvider.expireSession(
        message:
            transactionProvider.createTransactionError ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      transactionProvider.reset();
      productProvider.reset();
      return;
    }

    if (success) {
      await productProvider.refreshProducts();
      if (!mounted) {
        return;
      }
      await transactionProvider.refreshTransactions();
      if (!mounted) {
        return;
      }
      await dashboardProvider.refreshDashboard();
      if (mounted) {
        setState(() => _success = true);
      }
    }
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan transaksi?'),
        content: const Text('Keranjang akan dikosongkan jika keluar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tetap di sini'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    return result == true;
  }
}

class _TransactionForm extends StatelessWidget {
  const _TransactionForm({
    required this.productProvider,
    required this.transactionProvider,
    required this.searchController,
    required this.paidController,
    required this.onSubmit,
  });

  final ProductProvider productProvider;
  final TransactionProvider transactionProvider;
  final TextEditingController searchController;
  final TextEditingController paidController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final products = productProvider.products
        .where(
          (product) =>
              product.isAvailable && product.canBeOrdered && product.stock > 0,
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductPicker(
                  productProvider: productProvider,
                  products: products,
                  controller: searchController,
                  onAdd: transactionProvider.addProductToCart,
                ),
                const SizedBox(height: 18),
                _CartSection(
                  provider: transactionProvider,
                  paidController: paidController,
                  onSubmit: onSubmit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.productProvider,
    required this.products,
    required this.controller,
    required this.onAdd,
  });

  final ProductProvider productProvider;
  final List<ProductModel> products;
  final TextEditingController controller;
  final ValueChanged<ProductModel> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pilih Produk',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Cari produk',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Cari produk',
              onPressed: () => productProvider.searchProducts(controller.text),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: productProvider.searchProducts,
        ),
        const SizedBox(height: 10),
        if (productProvider.status == ProductStatus.loading)
          const LinearProgressIndicator()
        else if (products.isEmpty)
          const AppEmptyView(
            icon: Icons.inventory_2_outlined,
            title: 'Produk',
            description: 'Belum ada produk yang dapat dijual.',
          )
        else
          ...products
              .take(8)
              .map(
                (product) => _SelectableProductTile(
                  product: product,
                  onAdd: () => onAdd(product),
                ),
              ),
      ],
    );
  }
}

class _SelectableProductTile extends StatelessWidget {
  const _SelectableProductTile({required this.product, required this.onAdd});

  final ProductModel product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(product.name),
        subtitle: Text('${product.priceFormatted} | Stok ${product.stock}'),
        trailing: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
    );
  }
}

class _CartSection extends StatelessWidget {
  const _CartSection({
    required this.provider,
    required this.paidController,
    required this.onSubmit,
  });

  final TransactionProvider provider;
  final TextEditingController paidController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (paidController.text != provider.paidAmount.toString() &&
        provider.paidAmount > 0) {
      paidController.text = provider.paidAmount.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Keranjang',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (provider.createTransactionError != null) ...[
          _ErrorMessage(message: provider.createTransactionError!),
          const SizedBox(height: 10),
        ],
        if (provider.cartItems.isEmpty)
          const AppEmptyView(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang kosong',
            description: 'Pilih minimal satu produk.',
          )
        else
          ...provider.cartItems.map(
            (item) => _CartItemTile(provider: provider, item: item),
          ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Jenis produk',
          value: provider.cartItems.length.toString(),
        ),
        _SummaryRow(
          label: 'Jumlah item',
          value: provider.totalItems.toString(),
        ),
        _SummaryRow(
          label: 'Total sementara',
          value: CurrencyFormatter.rupiah(provider.previewTotal),
        ),
        TextField(
          controller: paidController,
          keyboardType: TextInputType.number,
          enabled: !provider.isCreatingTransaction,
          decoration: const InputDecoration(
            labelText: 'Uang dibayar',
            prefixText: 'Rp ',
          ),
          onChanged: (value) {
            provider.setPaidAmount(int.tryParse(value.trim()) ?? 0);
          },
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Kembalian sementara',
          value: CurrencyFormatter.rupiah(
            provider.previewChange < 0 ? 0 : provider.previewChange,
          ),
        ),
        const _SummaryRow(label: 'Metode pembayaran', value: 'Tunai'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: provider.canSubmit ? onSubmit : null,
          icon: provider.isCreatingTransaction
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.point_of_sale_outlined),
          label: Text(
            provider.isCreatingTransaction
                ? 'Menyimpan...'
                : 'Simpan Transaksi',
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.provider, required this.item});

  final TransactionProvider provider;
  final CashierCartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        title: Text(item.product.name),
        subtitle: Text(
          '${item.product.priceFormatted} | ${CurrencyFormatter.rupiah(item.subtotalPreview)}',
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Kurangi',
              onPressed: () => provider.decreaseQuantity(item.product.id),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(item.quantity.toString()),
            IconButton(
              tooltip: 'Tambah',
              onPressed: () => provider.increaseQuantity(item.product.id),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => provider.removeFromCart(item.product.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionSuccess extends StatelessWidget {
  const _TransactionSuccess({
    required this.transaction,
    required this.onHistory,
    required this.onCreateAgain,
  });

  final TransactionModel transaction;
  final VoidCallback onHistory;
  final VoidCallback onCreateAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                  'Transaksi berhasil',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _SummaryRow(
                  label: 'Nomor transaksi',
                  value: transaction.transactionNumber,
                ),
                _SummaryRow(label: 'Kasir', value: transaction.cashierName),
                _SummaryRow(label: 'Total', value: transaction.totalFormatted),
                _SummaryRow(
                  label: 'Dibayar',
                  value: transaction.paidAmountFormatted,
                ),
                _SummaryRow(
                  label: 'Kembalian',
                  value: transaction.changeAmountFormatted,
                ),
                _SummaryRow(
                  label: 'Pembayaran',
                  value: transaction.paymentMethodLabel,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Lihat Riwayat Transaksi'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onCreateAgain,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Transaksi Baru'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
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
