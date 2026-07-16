import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Halaman login kasir untuk autentikasi ke REST API Laravel.
class LoginPage extends StatefulWidget {
  /// Membuat halaman login final Tahap 6.
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// State form login yang menyimpan controller dan pilihan visibilitas password.
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.point_of_sale,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SmartKasir QR',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk untuk mengelola produk, pesanan, dan transaksi.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('login_email_field'),
                          controller: _emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login_password_field'),
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              key: const Key('toggle_password_visibility'),
                              tooltip: _obscurePassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) => _submit(authProvider),
                          validator: _validatePassword,
                        ),
                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _LoginErrorPanel(message: authProvider.errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('login_submit_button'),
                          onPressed: isLoading
                              ? null
                              : () => _submit(authProvider),
                          child: isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Masuk'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terhubung ke sistem kasir SmartKasir QR.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Memvalidasi email lokal sebelum request login dikirim.
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    if (email.length > 255) {
      return 'Email maksimal 255 karakter.';
    }

    final isValidEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    if (!isValidEmail) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  /// Memvalidasi password lokal tanpa menampilkan isi password.
  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (password.length < 6) {
      return 'Password minimal 6 karakter.';
    }

    if (password.length > 255) {
      return 'Password maksimal 255 karakter.';
    }

    return null;
  }

  /// Mengirim kredensial ke AuthProvider setelah form valid.
  ///
  /// Method ini menutup keyboard, memangkas email, dan tidak menyimpan password
  /// di luar controller form.
  Future<void> _submit(AuthProvider authProvider) async {
    FocusScope.of(context).unfocus();
    authProvider.clearError();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }
}

/// Panel kecil untuk menampilkan error login yang aman bagi pengguna.
class _LoginErrorPanel extends StatelessWidget {
  /// Membuat panel error dengan pesan bahasa Indonesia.
  const _LoginErrorPanel({required this.message});

  /// Pesan error yang sudah dipetakan oleh AuthProvider.
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
