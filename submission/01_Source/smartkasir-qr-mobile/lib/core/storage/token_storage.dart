import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Interface sederhana untuk penyimpanan key-value yang dapat diganti saat test.
abstract class SecureKeyValueStore {
  /// Menulis [value] untuk [key] ke storage aman.
  Future<void> write({required String key, required String value});

  /// Membaca nilai berdasarkan [key] dan mengembalikan null jika belum ada.
  Future<String?> read({required String key});

  /// Menghapus nilai berdasarkan [key] dari storage.
  Future<void> delete({required String key});
}

/// Implementasi SecureKeyValueStore memakai flutter_secure_storage.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  /// Membuat storage aman dengan opsi default package.
  FlutterSecureKeyValueStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

/// Implementasi storage memori untuk unit test tanpa menyentuh secure storage asli.
class MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}

/// Penyimpanan Bearer Token kasir pada storage aman.
class TokenStorage {
  /// Membuat TokenStorage dengan store yang dapat diganti saat test.
  const TokenStorage(this._store);

  final SecureKeyValueStore _store;

  /// Menyimpan token login kasir secara aman.
  Future<void> saveToken(String token) {
    return _store.write(key: StorageKeys.authToken, value: token);
  }

  /// Membaca token login kasir dan mengembalikan null bila belum login.
  Future<String?> readToken() {
    return _store.read(key: StorageKeys.authToken);
  }

  /// Menghapus token saat logout atau sesi tidak valid.
  Future<void> deleteToken() {
    return _store.delete(key: StorageKeys.authToken);
  }

  /// Memeriksa apakah token tersedia di storage aman.
  Future<bool> hasToken() async {
    final token = await readToken();

    return token != null && token.isNotEmpty;
  }
}
