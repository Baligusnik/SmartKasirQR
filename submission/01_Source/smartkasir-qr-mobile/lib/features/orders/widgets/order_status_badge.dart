import 'package:flutter/material.dart';

/// Badge status pesanan dengan warna konsisten.
class OrderStatusBadge extends StatelessWidget {
  /// Membuat badge status dari [status] dan [label].
  const OrderStatusBadge({
    required this.status,
    required this.label,
    super.key,
  });

  /// Status teknis backend.
  final String status;

  /// Label status berbahasa Indonesia.
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => Colors.orange,
      'confirmed' => Colors.blue,
      'processing' => Theme.of(context).colorScheme.primary,
      'ready' => Colors.green,
      'completed' => Colors.teal,
      'cancelled' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.outline,
    };

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
