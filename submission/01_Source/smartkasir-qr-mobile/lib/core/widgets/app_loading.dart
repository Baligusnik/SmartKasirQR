import 'package:flutter/material.dart';

/// Widget loading umum dengan pesan opsional.
class AppLoading extends StatelessWidget {
  /// Membuat tampilan loading untuk proses singkat.
  const AppLoading({super.key, this.message});

  /// Pesan loading yang ditampilkan di bawah indikator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
