import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/transaction_model.dart';

/// Kartu ringkas transaksi pada daftar transaksi.
class TransactionCard extends StatelessWidget {
  /// Membuat kartu transaksi dengan aksi [onTap] untuk membuka detail.
  const TransactionCard({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  /// Transaksi yang ditampilkan.
  final TransactionModel transaction;

  /// Callback ketika kartu dipilih.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = transaction.createdAt;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.transactionNumber,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _Meta(
                icon: Icons.receipt_long_outlined,
                text: transaction.orderNumber ?? 'Transaksi Langsung',
              ),
              _Meta(icon: Icons.badge_outlined, text: transaction.cashierName),
              _Meta(
                icon: Icons.payments_outlined,
                text: transaction.paymentMethodLabel,
              ),
              _Meta(
                icon: Icons.shopping_bag_outlined,
                text: '${transaction.itemsCount} item',
              ),
              _Meta(
                icon: Icons.schedule_outlined,
                text: createdAt == null
                    ? '-'
                    : DateFormatter.dateTime(createdAt.toLocal()),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _Amount(label: 'Total', value: transaction.totalFormatted),
                  _Amount(
                    label: 'Dibayar',
                    value: transaction.paidAmountFormatted,
                  ),
                  _Amount(
                    label: 'Kembali',
                    value: transaction.changeAmountFormatted,
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

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}
