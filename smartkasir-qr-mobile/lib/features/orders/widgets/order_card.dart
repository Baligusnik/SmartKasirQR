import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/order_model.dart';
import 'order_status_badge.dart';

/// Kartu ringkas pesanan pada daftar pesanan.
class OrderCard extends StatelessWidget {
  /// Membuat kartu pesanan dengan aksi [onTap] untuk membuka detail.
  const OrderCard({required this.order, required this.onTap, super.key});

  /// Pesanan yang ditampilkan.
  final OrderModel order;

  /// Callback ketika kartu dipilih.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  OrderStatusBadge(
                    status: order.status,
                    label: order.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Meta(
                icon: Icons.table_restaurant_outlined,
                text: order.tableName,
              ),
              _Meta(
                icon: Icons.person_outline,
                text: order.customerName ?? 'Pelanggan',
              ),
              _Meta(
                icon: Icons.shopping_bag_outlined,
                text: '${order.itemsCount} item',
              ),
              _Meta(
                icon: Icons.schedule_outlined,
                text: createdAt == null
                    ? '-'
                    : DateFormatter.dateTime(createdAt.toLocal()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (order.stockDeducted)
                    const Chip(
                      label: Text('Stok dikurangi'),
                      visualDensity: VisualDensity.compact,
                    ),
                  const Spacer(),
                  Text(
                    order.totalFormatted,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
