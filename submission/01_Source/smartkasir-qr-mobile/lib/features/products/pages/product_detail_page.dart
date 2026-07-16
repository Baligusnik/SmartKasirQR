import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

/// Halaman detail produk yang membaca `GET /api/products/{id}`.
class ProductDetailPage extends StatefulWidget {
  /// Membuat halaman detail untuk [productId].
  const ProductDetailPage({required this.productId, super.key});

  /// ID produk yang dimuat dari backend.
  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _requested = false;
  bool _handledUnauthorized = false;
  ProductProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ProductProvider>();
  }

  @override
  void dispose() {
    _provider?.clearSelectedProduct();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          _handleUnauthorized(provider);

          if (provider.isLoadingDetail && provider.selectedProduct == null) {
            return const AppLoading(message: 'Memuat detail produk...');
          }

          if (provider.selectedProduct == null) {
            return AppErrorView(
              title: 'Detail produk belum dapat dimuat',
              message:
                  provider.errorMessage ?? 'Detail produk belum dapat dimuat.',
              onRetry: _load,
            );
          }

          return _ProductDetailContent(product: provider.selectedProduct!);
        },
      ),
    );
  }

  Future<void> _load() async {
    if (_requested && context.read<ProductProvider>().selectedProduct != null) {
      return;
    }

    _requested = true;
    await context.read<ProductProvider>().loadProductDetail(widget.productId);
  }

  void _handleUnauthorized(ProductProvider provider) {
    if (!provider.isUnauthorized || _handledUnauthorized) {
      return;
    }

    _handledUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final productProvider = context.read<ProductProvider>();
      final navigator = Navigator.of(context);

      await authProvider.expireSession(
        message:
            provider.errorMessage ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      productProvider.reset();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(product.description ?? 'Tidak ada deskripsi.'),
                    const SizedBox(height: 18),
                    _DetailRow(label: 'Kategori', value: product.categoryName),
                    _DetailRow(label: 'SKU', value: product.sku),
                    _DetailRow(label: 'Harga', value: product.priceFormatted),
                    _DetailRow(
                      label: 'Stok',
                      value: '${product.stock} ${product.unit}',
                    ),
                    _DetailRow(
                      label: 'Status tersedia',
                      value: product.isAvailable
                          ? 'Tersedia'
                          : 'Tidak tersedia',
                    ),
                    _DetailRow(
                      label: 'Dapat dipesan',
                      value: product.canBeOrdered ? 'Ya' : 'Tidak',
                    ),
                    _DetailRow(
                      label: 'Dibuat',
                      value: product.createdAt == null
                          ? '-'
                          : DateFormatter.dateTime(
                              product.createdAt!.toLocal(),
                            ),
                    ),
                    _DetailRow(
                      label: 'Diperbarui',
                      value: product.updatedAt == null
                          ? '-'
                          : DateFormatter.dateTime(
                              product.updatedAt!.toLocal(),
                            ),
                    ),
                  ],
                ),
              ),
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
            width: 128,
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
