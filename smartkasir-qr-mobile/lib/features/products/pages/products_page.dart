import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'create_product_page.dart';
import 'product_detail_page.dart';

/// Halaman daftar produk yang terintegrasi dengan `GET /api/products`.
class ProductsPage extends StatefulWidget {
  /// Membuat halaman produk dengan lazy loading berdasarkan tab aktif.
  const ProductsPage({super.key, this.isActive = true});

  /// Bernilai true ketika tab Produk sedang aktif.
  final bool isActive;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  ProductProvider? _provider;
  bool _handledUnauthorized = false;
  bool _showingRefreshError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<ProductProvider>();

    if (_provider == nextProvider) {
      return;
    }

    _provider?.removeListener(_handleProviderChange);
    _provider = nextProvider..addListener(_handleProviderChange);
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
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
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (_searchController.text != provider.searchQuery) {
          _searchController.text = provider.searchQuery;
        }

        return switch (provider.status) {
          ProductStatus.initial when !widget.isActive =>
            const SizedBox.shrink(),
          ProductStatus.initial || ProductStatus.loading => const AppLoading(
            message: 'Memuat produk...',
          ),
          ProductStatus.failure when provider.products.isEmpty => AppErrorView(
            title: 'Produk belum dapat dimuat',
            message: provider.errorMessage ?? 'Produk belum dapat dimuat.',
            onRetry: provider.loadProducts,
          ),
          _ => _ProductListContent(
            provider: provider,
            searchController: _searchController,
            onOpenDetail: _openDetail,
            onCreateProduct: _openCreateProduct,
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

      final provider = context.read<ProductProvider>();
      if (provider.status == ProductStatus.initial) {
        provider.loadInitialData();
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
        final productProvider = context.read<ProductProvider>();
        await authProvider.expireSession(message: message);
        productProvider.reset();
      });
      return;
    }

    if (provider.products.isNotEmpty &&
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
        context.read<ProductProvider>().clearError();
        _showingRefreshError = false;
      });
    }
  }

  void _openDetail(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(productId: product.id),
      ),
    );
  }

  Future<void> _openCreateProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateProductPage()),
    );

    if (created == true && mounted) {
      await context.read<ProductProvider>().refreshProducts();
    }
  }
}

class _ProductListContent extends StatelessWidget {
  const _ProductListContent({
    required this.provider,
    required this.searchController,
    required this.onOpenDetail,
    required this.onCreateProduct,
  });

  final ProductProvider provider;
  final TextEditingController searchController;
  final ValueChanged<ProductModel> onOpenDetail;
  final VoidCallback onCreateProduct;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: provider.refreshProducts,
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
                  _ProductSearchAndFilters(
                    provider: provider,
                    controller: searchController,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onCreateProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Produk'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${provider.products.length} produk',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.products.isEmpty)
                    AppEmptyView(
                      icon: Icons.inventory_2_outlined,
                      title: 'Produk',
                      description: 'Belum ada produk yang sesuai.',
                      action: provider.hasActiveFilters
                          ? OutlinedButton.icon(
                              onPressed: provider.clearFilters,
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Hapus Filter'),
                            )
                          : null,
                    )
                  else
                    ...provider.products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductCard(
                          product: product,
                          onTap: () => onOpenDetail(product),
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

class _ProductSearchAndFilters extends StatelessWidget {
  const _ProductSearchAndFilters({
    required this.provider,
    required this.controller,
  });

  final ProductProvider provider;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Cari produk',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Cari produk',
              onPressed: () => provider.searchProducts(controller.text),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: provider.searchProducts,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownMenu<int?>(
              label: const Text('Kategori'),
              initialSelection: provider.selectedCategoryId,
              onSelected: provider.setCategoryFilter,
              dropdownMenuEntries: [
                const DropdownMenuEntry<int?>(value: null, label: 'Semua'),
                ...provider.categories.map(
                  (category) => DropdownMenuEntry<int?>(
                    value: category.id,
                    label: category.name,
                  ),
                ),
              ],
            ),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment<bool?>(value: null, label: Text('Semua')),
                ButtonSegment<bool?>(value: true, label: Text('Tersedia')),
                ButtonSegment<bool?>(
                  value: false,
                  label: Text('Tidak tersedia'),
                ),
              ],
              selected: <bool?>{provider.selectedAvailability},
              onSelectionChanged: (selection) {
                provider.setAvailabilityFilter(selection.first);
              },
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
