import 'package:flutter/material.dart';

/// Widget umum untuk menampilkan error ramah pengguna.
class AppErrorView extends StatelessWidget {
  /// Membuat tampilan error dengan tombol coba lagi opsional.
  const AppErrorView({
    required this.message,
    super.key,
    this.title,
    this.onRetry,
  });

  /// Judul error opsional untuk konteks halaman.
  final String? title;

  /// Pesan error yang aman ditampilkan.
  final String message;

  /// Aksi opsional untuk mencoba ulang proses.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: title == null
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
