import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';

/// Widget ringkasan status pesanan pada dashboard.
class OrderStatusSummary extends StatelessWidget {
  /// Membuat ringkasan pesanan dari [orders].
  ///
  /// Widget ini hanya menampilkan data yang sudah tersedia dari
  /// DashboardProvider dan tidak memicu request tambahan.
  const OrderStatusSummary({required this.orders, super.key});

  /// Data jumlah pesanan berdasarkan status.
  final OrderSummary orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pesanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(
                  label: 'Menunggu',
                  value: orders.pending,
                  color: Colors.orange,
                ),
                _StatusChip(
                  label: 'Dikonfirmasi',
                  value: orders.confirmed,
                  color: Colors.blue,
                ),
                _StatusChip(
                  label: 'Diproses',
                  value: orders.processing,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatusChip(
                  label: 'Siap',
                  value: orders.ready,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
