import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_readers.dart';
import '../models/category_model.dart';
import '../models/create_product_input.dart';
import '../models/product_model.dart';

/// Repository untuk membaca kategori dan produk dari REST API Laravel.
class ProductRepository {
  /// Membuat repository produk dengan [apiClient] yang sudah menangani token.
  const ProductRepository({required this.apiClient});

  /// Client REST API bersama yang otomatis memasang Bearer Token.
  final ApiClient apiClient;

  /// Mengambil daftar kategori produk dari endpoint `/categories`.
  ///
  /// Mengembalikan list [CategoryModel]. Melempar [ApiException] jika response
  /// gagal atau payload data bukan list.
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await apiClient.get(ApiEndpoints.categories);

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException(message: 'Data kategori tidak valid.');
    }

    return JsonReaders.asList(data)
        .map(JsonReaders.asMap)
        .map(CategoryModel.fromJson)
        .toList(growable: false);
  }

  /// Mengambil daftar produk dari endpoint `/products`.
  ///
  /// Parameter [search], [categoryId], dan [available] dikirim sebagai query
  /// hanya bila memiliki nilai. Melempar [ApiException] jika response gagal
  /// atau payload data bukan list.
  Future<List<ProductModel>> fetchProducts({
    String? search,
    int? categoryId,
    bool? available,
  }) async {
    final query = <String, Object?>{};
    final trimmedSearch = search?.trim();

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      query['search'] = trimmedSearch;
    }

    if (categoryId != null) {
      query['category_id'] = categoryId;
    }

    if (available != null) {
      query['available'] = available ? '1' : '0';
    }

    final response = await apiClient.get(
      ApiEndpoints.products,
      queryParameters: query,
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException(message: 'Data produk tidak valid.');
    }

    return JsonReaders.asList(
      data,
    ).map(JsonReaders.asMap).map(ProductModel.fromJson).toList(growable: false);
  }

  /// Mengambil detail produk dari endpoint `/products/{productId}`.
  ///
  /// Parameter [productId] adalah ID produk Laravel. Mengembalikan
  /// [ProductModel] detail dan melempar [ApiException] bila payload bukan
  /// object valid.
  Future<ProductModel> fetchProductDetail(int productId) async {
    final response = await apiClient.get(ApiEndpoints.productDetail(productId));

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Detail produk tidak valid.');
    }

    return ProductModel.fromJson(JsonReaders.asMap(data));
  }

  /// Mengirim produk baru ke endpoint `POST /products`.
  ///
  /// [input] berisi data produk yang sudah tervalidasi di UI. Repository hanya
  /// mengirim [CreateProductInput.toJson] dan membentuk [ProductModel] dari
  /// response. Melempar [ApiException] ketika validasi server gagal atau
  /// payload response bukan object.
  Future<ProductModel> createProduct(CreateProductInput input) async {
    final response = await apiClient.post(
      ApiEndpoints.products,
      data: input.toJson(),
    );

    if (!response.success) {
      throw ApiException(message: response.message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: 'Produk baru tidak valid.');
    }

    return ProductModel.fromJson(JsonReaders.asMap(data));
  }
}
