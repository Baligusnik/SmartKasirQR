import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'core/widgets/app_loading.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'navigation/main_navigation_page.dart';

/// Root MaterialApp untuk SmartKasir QR Mobile.
///
/// Widget ini memeriksa status autentikasi satu kali saat pertama dirender.
/// Nilai yang dikembalikan adalah MaterialApp dengan tema dan route utama.
/// Pemeriksaan autentikasi dapat mengubah state AuthProvider.
class SmartKasirApp extends StatefulWidget {
  /// Membuat root aplikasi SmartKasir QR.
  const SmartKasirApp({super.key});

  @override
  State<SmartKasirApp> createState() => _SmartKasirAppState();
}

/// State root aplikasi yang menjaga pemeriksaan autentikasi tidak berulang.
class _SmartKasirAppState extends State<SmartKasirApp> {
  bool _didCheckAuthentication = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didCheckAuthentication) {
      return;
    }

    _didCheckAuthentication = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthentication();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartKasir QR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) => const MainNavigationPage(),
      },
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.hasCheckedAuthentication ||
              authProvider.status == AuthStatus.initial) {
            return const AppLoading(message: 'Memeriksa sesi pengguna...');
          }

          if (authProvider.status == AuthStatus.authenticated ||
              (authProvider.status == AuthStatus.loading &&
                  authProvider.currentUser != null)) {
            return const MainNavigationPage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
