import 'package:flutter/material.dart';

/// Kartu ringkasan dashboard untuk menampilkan beberapa metrik terkait.
class DashboardSummaryCard extends StatelessWidget {
  /// Membuat kartu ringkasan dengan judul, ikon, dan item metrik.
  ///
  /// Parameter [items] berisi label dan nilai yang ditampilkan dalam grid kecil.
  /// Widget ini tidak melakukan request API dan hanya merender data dari model.
  const DashboardSummaryCard({
    required this.title,
    required this.icon,
    required this.items,
    super.key,
  });

  /// Judul kelompok ringkasan.
  final String title;

  /// Ikon kelompok ringkasan.
  final IconData icon;

  /// Item metrik yang ditampilkan pada kartu.
  final List<DashboardSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 430 ? 4 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 72,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Item metrik di dalam [DashboardSummaryCard].
class DashboardSummaryItem {
  /// Membuat pasangan label dan nilai ringkasan.
  const DashboardSummaryItem({required this.label, required this.value});

  /// Label metrik.
  final String label;

  /// Nilai metrik dalam format siap tampil.
  final String value;
}
