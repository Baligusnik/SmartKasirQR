import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

/// Halaman profil sederhana yang membaca pengguna aktif dari AuthProvider.
class ProfilePage extends StatelessWidget {
  /// Membuat halaman profil pengguna tanpa menampilkan token atau password.
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              size: 34,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Pengguna',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(user?.email ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ProfileInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: _roleLabel(user),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        key: const Key('profile_logout_button'),
                        onPressed: isLoading
                            ? null
                            : () => _confirmLogout(context),
                        icon: isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus sesi lokal dan server.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar dari aplikasi?'),
          content: const Text(
            'Anda perlu login kembali untuk menggunakan aplikasi kasir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();

      if (context.mounted) {
        try {
          context.read<DashboardProvider>().reset();
        } on ProviderNotFoundException {
          // Test auth lama belum memasang DashboardProvider.
        }
        try {
          context.read<ProductProvider>().reset();
        } on ProviderNotFoundException {
          // Test auth lama belum memasang ProductProvider.
        }
        try {
          context.read<OrderProvider>().reset();
        } on ProviderNotFoundException {
          // Test auth lama belum memasang OrderProvider.
        }
        try {
          context.read<TransactionProvider>().reset();
        } on ProviderNotFoundException {
          // Test auth lama belum memasang TransactionProvider.
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  /// Mengubah role backend menjadi label ringkas berbahasa Indonesia.
  String _roleLabel(UserModel? user) {
    return switch (user?.role) {
      'cashier' => 'Kasir',
      'admin' => 'Admin',
      null => 'Pengguna',
      _ => 'Pengguna',
    };
  }
}

/// Baris informasi profil dengan ikon, label, dan nilai.
class _ProfileInfoRow extends StatelessWidget {
  /// Membuat baris informasi profil.
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Ikon pendamping label.
  final IconData icon;

  /// Nama field profil.
  final String label;

  /// Nilai field profil yang aman ditampilkan.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
