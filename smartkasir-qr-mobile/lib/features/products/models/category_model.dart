import '../../../core/utils/json_readers.dart';

/// Model kategori produk dari endpoint `/categories`.
class CategoryModel {
  /// Membuat model kategori dengan data yang aman ditampilkan.
  const CategoryModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
    this.productsCount,
  });

  /// ID kategori dari backend.
  final int id;

  /// Nama kategori.
  final String name;

  /// Deskripsi kategori jika tersedia.
  final String? description;

  /// Status aktif kategori.
  final bool isActive;

  /// Jumlah produk pada kategori jika backend mengirim `products_count`.
  final int? productsCount;

  /// Membentuk [CategoryModel] dari JSON Laravel.
  ///
  /// Parameter [json] berasal dari satu item response `GET /api/categories`.
  /// Nilai angka dan boolean dibaca secara defensif agar model tetap aman.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final productsCount = json.containsKey('products_count')
        ? JsonReaders.asInt(json['products_count'])
        : null;

    return CategoryModel(
      id: JsonReaders.asInt(json['id']),
      name: JsonReaders.asString(json['name'], fallback: '-'),
      description: JsonReaders.asNullableString(json['description']),
      isActive: JsonReaders.asBool(json['is_active'], fallback: true),
      productsCount: productsCount,
    );
  }
}
