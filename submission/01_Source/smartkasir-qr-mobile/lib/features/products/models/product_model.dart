import '../../../core/utils/json_readers.dart';

/// Model produk kasir dari endpoint `/products`.
class ProductModel {
  /// Membuat model produk dengan data yang aman untuk UI.
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.sku,
    required this.price,
    required this.priceFormatted,
    required this.stock,
    required this.unit,
    required this.isAvailable,
    required this.canBeOrdered,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  /// ID produk dari backend.
  final int id;

  /// ID kategori produk, null jika backend tidak mengirim kategori valid.
  final int? categoryId;

  /// Nama kategori produk.
  final String categoryName;

  /// Nama produk.
  final String name;

  /// SKU produk.
  final String sku;

  /// Deskripsi produk jika tersedia.
  final String? description;

  /// Harga produk dalam angka.
  final int price;

  /// Harga produk dalam format rupiah dari backend.
  final String priceFormatted;

  /// Stok produk.
  final int stock;

  /// Satuan produk.
  final String unit;

  /// Status tersedia produk.
  final bool isAvailable;

  /// Status dapat dipesan berdasarkan stok dan kategori aktif.
  final bool canBeOrdered;

  /// Waktu produk dibuat.
  final DateTime? createdAt;

  /// Waktu produk diperbarui.
  final DateTime? updatedAt;

  /// Bernilai true jika stok produk menipis.
  bool get isLowStock => stock <= 5;

  /// Membentuk [ProductModel] dari JSON Laravel.
  ///
  /// Parameter [json] berasal dari response `GET /api/products` atau detail
  /// `/api/products/{id}`. Field `category` dapat null, sehingga category id
  /// dan nama diberi fallback aman.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = JsonReaders.asMap(json['category']);
    final price = JsonReaders.asInt(json['price']);

    return ProductModel(
      id: JsonReaders.asInt(json['id']),
      categoryId: category['id'] == null
          ? null
          : JsonReaders.asInt(category['id']),
      categoryName: JsonReaders.asString(
        category['name'],
        fallback: 'Tanpa Kategori',
      ),
      name: JsonReaders.asString(json['name'], fallback: '-'),
      sku: JsonReaders.asString(json['sku'], fallback: '-'),
      description: JsonReaders.asNullableString(json['description']),
      price: price,
      priceFormatted: JsonReaders.asString(
        json['price_formatted'],
        fallback: 'Rp$price',
      ),
      stock: JsonReaders.asInt(json['stock']),
      unit: JsonReaders.asString(json['unit'], fallback: 'pcs'),
      isAvailable: JsonReaders.asBool(json['is_available']),
      canBeOrdered: JsonReaders.asBool(json['can_be_ordered']),
      createdAt: JsonReaders.asDateTime(json['created_at']),
      updatedAt: JsonReaders.asDateTime(json['updated_at']),
    );
  }
}
