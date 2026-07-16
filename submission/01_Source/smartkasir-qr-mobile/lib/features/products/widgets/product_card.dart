import 'package:flutter/material.dart';

import '../models/product_model.dart';

/// Kartu ringkas produk pada daftar produk.
class ProductCard extends StatelessWidget {
  /// Membuat kartu produk dengan aksi [onTap] untuk membuka detail.
  const ProductCard({required this.product, required this.onTap, super.key});

  /// Produk yang ditampilkan.
  final ProductModel product;

  /// Callback ketika kartu dipilih.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${product.categoryName} • SKU ${product.sku}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label: product.priceFormatted,
                        ),
                        _InfoChip(
                          icon: Icons.inventory_outlined,
                          label: '${product.stock} ${product.unit}',
                        ),
                        _StatusChip(
                          label: product.isAvailable
                              ? 'Tersedia'
                              : 'Tidak tersedia',
                          color: product.isAvailable
                              ? Colors.green
                              : colorScheme.error,
                        ),
                        if (product.isLowStock)
                          const _StatusChip(
                            label: 'Stok menipis',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}
