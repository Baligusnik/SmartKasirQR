import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/recent_order_model.dart';

/// Kartu pesanan terbaru pada Home Dashboard.
class RecentOrderCard extends StatelessWidget {
  /// Membuat kartu pesanan terbaru dari [order].
  ///
  /// Kartu ini menampilkan ringkasan saja. Detail pesanan belum dibuka pada
  /// Tahap 7 karena integrasi detail pesanan akan dikerjakan pada tahap
  /// berikutnya.
  const RecentOrderCard({required this.order, super.key});

  /// Data pesanan terbaru yang ditampilkan.
  final RecentOrderModel order;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, order.status);
    final createdAt = order.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.tableCode.isEmpty
                            ? order.tableName
                            : '${order.tableName} (${order.tableCode})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: order.statusLabel, color: color),
              ],
            ),
            const SizedBox(height: 12),
            _OrderMetaRow(
              icon: Icons.person_outline,
              text: order.customerName ?? 'Pelanggan',
            ),
            const SizedBox(height: 8),
            _OrderMetaRow(
              icon: Icons.shopping_bag_outlined,
              text: '${order.itemsCount} item',
            ),
            const SizedBox(height: 8),
            _OrderMetaRow(
              icon: Icons.schedule_outlined,
              text: createdAt == null
                  ? '-'
                  : DateFormatter.dateTime(createdAt.toLocal()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Detail pesanan tersedia pada tahap berikutnya.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
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
    );
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'confirmed' => Colors.blue,
      'processing' => Theme.of(context).colorScheme.primary,
      'ready' => Colors.green,
      'completed' => Colors.teal,
      'cancelled' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.outline,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
