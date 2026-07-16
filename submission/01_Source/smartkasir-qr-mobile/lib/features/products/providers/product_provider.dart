import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_message_mapper.dart';
import '../models/category_model.dart';
import '../models/create_product_input.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

/// Status pemuatan halaman produk.
enum ProductStatus {
  /// Data belum pernah dimuat.
  initial,

  /// Request awal sedang berjalan.
  loading,

  /// Produk berhasil dimuat.
  loaded,

  /// Request berhasil tetapi list kosong.
  empty,

  /// Request gagal tanpa data lama.
  failure,
}

/// Provider state untuk daftar, filter, dan detail produk.
class ProductProvider extends ChangeNotifier {
  /// Membuat provider produk dengan repository yang dapat diganti pada test.
  ProductProvider({required this.productRepository});

  /// Repository produk yang membaca REST API Laravel.
  final ProductRepository productRepository;

  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = const <ProductModel>[];
  List<CategoryModel> _categories = const <CategoryModel>[];
  ProductModel? _selectedProduct;
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool? _selectedAvailability;
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isLoadingDetail = false;
  bool _isUnauthorized = false;
  bool _isCreatingProduct = false;
  String? _createProductError;
  Map<String, List<String>> _createProductValidationErrors =
      const <String, List<String>>{};
  ProductModel? _createdProduct;
  int _requestSerial = 0;

  /// Status pemuatan daftar produk.
  ProductStatus get status => _status;

  /// Daftar produk hasil response backend.
  List<ProductModel> get products => _products;

  /// Daftar kategori untuk filter produk.
  List<CategoryModel> get categories => _categories;

  /// Detail produk yang sedang dipilih.
  ProductModel? get selectedProduct => _selectedProduct;

  /// Query pencarian aktif.
  String get searchQuery => _searchQuery;

  /// ID kategori aktif pada filter.
  int? get selectedCategoryId => _selectedCategoryId;

  /// Status ketersediaan aktif pada filter.
  bool? get selectedAvailability => _selectedAvailability;

  /// Pesan error aman untuk UI.
  String? get errorMessage => _errorMessage;

  /// Bernilai true saat refresh berjalan.
  bool get isRefreshing => _isRefreshing;

  /// Bernilai true saat detail produk sedang dimuat.
  bool get isLoadingDetail => _isLoadingDetail;

  /// Bernilai true saat API mengembalikan 401.
  bool get isUnauthorized => _isUnauthorized;

  /// Bernilai true saat submit produk sedang berjalan.
  bool get isCreatingProduct => _isCreatingProduct;

  /// Pesan error aman khusus form tambah produk.
  String? get createProductError => _createProductError;

  /// Error validasi field dari Laravel untuk form tambah produk.
  Map<String, List<String>> get createProductValidationErrors =>
      _createProductValidationErrors;

  /// Produk yang baru berhasil dibuat.
  ProductModel? get createdProduct => _createdProduct;

  /// Bernilai true jika filter atau pencarian sedang aktif.
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedAvailability != null;

  /// Memuat kategori dan produk pertama kali.
  ///
  /// Method ini memanggil `GET /categories` lalu `GET /products`. State menjadi
  /// loading selama request awal, lalu loaded/empty/failure sesuai hasil.
  Future<void> loadInitialData() async {
    await loadCategories();
    await loadProducts();
  }

  /// Memuat kategori dari REST API Laravel.
  ///
  /// Melempar error ke state provider tanpa navigasi jika request gagal.
  Future<void> loadCategories() async {
    try {
      _categories = await productRepository.fetchCategories();
      _isUnauthorized = false;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Kategori belum dapat dimuat.';
    } finally {
      notifyListeners();
    }
  }

  /// Memuat daftar produk sesuai filter aktif.
  ///
  /// Request lama diabaikan bila ada request lebih baru agar hasil pencarian
  /// cepat tidak saling menimpa.
  Future<void> loadProducts() async {
    if (_status == ProductStatus.loading || _isRefreshing) {
      return;
    }

    final serial = ++_requestSerial;
    _status = ProductStatus.loading;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await productRepository.fetchProducts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        available: _selectedAvailability,
      );

      if (serial != _requestSerial) {
        return;
      }

      _products = result;
      _status = result.isEmpty ? ProductStatus.empty : ProductStatus.loaded;
    } on ApiException catch (error) {
      if (serial != _requestSerial) {
        return;
      }

      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
      _status = ProductStatus.failure;
    } catch (_) {
      if (serial != _requestSerial) {
        return;
      }

      _errorMessage = 'Produk belum dapat dimuat.';
      _status = ProductStatus.failure;
    } finally {
      if (serial == _requestSerial) {
        notifyListeners();
      }
    }
  }

  /// Memuat ulang produk tanpa menghapus data lama saat refresh gagal.
  Future<void> refreshProducts() async {
    if (_isRefreshing || _status == ProductStatus.loading) {
      return;
    }

    if (_products.isEmpty) {
      await loadProducts();
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await productRepository.fetchProducts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        available: _selectedAvailability,
      );
      _products = result;
      _status = result.isEmpty ? ProductStatus.empty : ProductStatus.loaded;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Produk belum dapat dimuat ulang.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mencari produk berdasarkan [query] dan memuat ulang dari backend.
  Future<void> searchProducts(String query) async {
    final trimmed = query.trim();
    if (_searchQuery == trimmed && _status != ProductStatus.failure) {
      return;
    }

    _searchQuery = trimmed;
    await loadProducts();
  }

  /// Mengubah filter kategori dan memuat ulang produk dari backend.
  Future<void> setCategoryFilter(int? categoryId) async {
    if (_selectedCategoryId == categoryId) {
      return;
    }

    _selectedCategoryId = categoryId;
    await loadProducts();
  }

  /// Mengubah filter ketersediaan dan memuat ulang produk dari backend.
  Future<void> setAvailabilityFilter(bool? available) async {
    if (_selectedAvailability == available) {
      return;
    }

    _selectedAvailability = available;
    await loadProducts();
  }

  /// Menghapus seluruh filter dan memuat ulang produk.
  Future<void> clearFilters() async {
    if (!hasActiveFilters) {
      return;
    }

    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedAvailability = null;
    await loadProducts();
  }

  /// Memuat detail produk dari endpoint `/products/{productId}`.
  Future<void> loadProductDetail(int productId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _selectedProduct = await productRepository.fetchProductDetail(productId);
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _errorMessage = ErrorMessageMapper.fromApiException(error);
    } catch (_) {
      _errorMessage = 'Detail produk belum dapat dimuat.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Membuat produk baru melalui `POST /products`.
  ///
  /// [input] dikirim ke repository. State submit diisi agar form dapat
  /// menampilkan loading, error umum, validationErrors, dan produk hasil
  /// response. Mengembalikan true saat produk berhasil dibuat.
  Future<bool> createProduct(CreateProductInput input) async {
    if (_isCreatingProduct) {
      return false;
    }

    _isCreatingProduct = true;
    _createProductError = null;
    _createProductValidationErrors = const <String, List<String>>{};
    _createdProduct = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final product = await productRepository.createProduct(input);
      _createdProduct = product;
      _products = <ProductModel>[product, ..._products];
      _status = _products.isEmpty ? ProductStatus.empty : ProductStatus.loaded;
      return true;
    } on ApiException catch (error) {
      _isUnauthorized = error.isUnauthorized;
      _createProductError = ErrorMessageMapper.fromApiException(error);
      _createProductValidationErrors = error.validationErrors;
      return false;
    } catch (_) {
      _createProductError = 'Produk belum dapat disimpan.';
      return false;
    } finally {
      _isCreatingProduct = false;
      notifyListeners();
    }
  }

  /// Membersihkan state submit produk tanpa mengubah daftar produk.
  void clearCreateProductState() {
    _createProductError = null;
    _createProductValidationErrors = const <String, List<String>>{};
    _createdProduct = null;
    _isCreatingProduct = false;
    notifyListeners();
  }

  /// Menghapus produk terpilih dari state detail.
  void clearSelectedProduct() {
    _selectedProduct = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Menghapus pesan error tanpa mengubah data list.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mereset seluruh data produk saat logout atau pergantian akun.
  void reset() {
    _status = ProductStatus.initial;
    _products = const <ProductModel>[];
    _categories = const <CategoryModel>[];
    _selectedProduct = null;
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedAvailability = null;
    _errorMessage = null;
    _isRefreshing = false;
    _isLoadingDetail = false;
    _isUnauthorized = false;
    _isCreatingProduct = false;
    _createProductError = null;
    _createProductValidationErrors = const <String, List<String>>{};
    _createdProduct = null;
    _requestSerial++;
    notifyListeners();
  }
}
