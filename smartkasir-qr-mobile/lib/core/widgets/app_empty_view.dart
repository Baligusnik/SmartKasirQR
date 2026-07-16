import 'package:flutter/material.dart';

/// Widget umum untuk kondisi data kosong.
class AppEmptyView extends StatelessWidget {
  /// Membuat empty state dengan ikon, judul, deskripsi, dan aksi opsional.
  const AppEmptyView({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
    this.action,
  });

  /// Ikon yang mewakili halaman kosong.
  final IconData icon;

  /// Judul empty state.
  final String title;

  /// Deskripsi singkat untuk pengguna.
  final String description;

  /// Aksi opsional, misalnya tombol muat ulang.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
