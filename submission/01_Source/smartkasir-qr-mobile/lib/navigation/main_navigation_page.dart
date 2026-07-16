import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/pages/home_page.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../features/orders/pages/orders_page.dart';
import '../features/products/pages/products_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/transactions/pages/transactions_page.dart';

/// Container navigasi utama dengan destination kasir.
class MainNavigationPage extends StatefulWidget {
  /// Membuat halaman navigasi utama final dengan empat menu UAS.
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

/// State navigasi utama yang menyimpan indeks halaman aktif.
class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Beranda',
    'Pesanan',
    'Produk',
    'Transaksi',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              );
            },
            icon: CircleAvatar(
              radius: 15,
              child: Text(_initials(user?.name ?? 'P')),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(isActive: _selectedIndex == 0),
          OrdersPage(isActive: _selectedIndex == 1),
          ProductsPage(isActive: _selectedIndex == 2),
          TransactionsPage(isActive: _selectedIndex == 3),
        ],
      ),
      bottomNavigationBar: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          final pendingOrders =
              dashboardProvider.dashboard?.orders.pending ?? 0;

          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: _PendingBadge(
                  count: pendingOrders,
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: _PendingBadge(
                  count: pendingOrders,
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Pesanan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Produk',
              ),
              const NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'Transaksi',
              ),
            ],
          );
        },
      ),
    );
  }

  /// Mengambil inisial nama pengguna untuk avatar kecil pada AppBar.
  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return 'P';
    }

    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }

    return Badge(
      label: Text(count > 99 ? '99+' : count.toString()),
      child: child,
    );
  }
}
