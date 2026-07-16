/// Input terstruktur untuk membuat produk baru melalui `POST /api/products`.
class CreateProductInput {
  /// Membuat input produk baru yang siap dikirim ke Laravel.
  ///
  /// Parameter teks akan di-trim saat [toJson] dipanggil. Harga dan stok
  /// dikirim sebagai integer tanpa format rupiah.
  const CreateProductInput({
    required this.categoryId,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.unit,
    required this.isAvailable,
    this.description,
  });

  /// ID kategori aktif yang dipilih kasir.
  final int categoryId;

  /// Nama produk baru.
  final String name;

  /// SKU produk baru.
  final String sku;

  /// Deskripsi produk, boleh null atau kosong.
  final String? description;

  /// Harga produk dalam integer.
  final int price;

  /// Stok awal produk.
  final int stock;

  /// Satuan produk.
  final String unit;

  /// Status ketersediaan produk.
  final bool isAvailable;

  /// Mengubah input menjadi JSON request Laravel.
  ///
  /// Tidak mengirim field turunan seperti id, category object,
  /// price_formatted, can_be_ordered, created_at, atau updated_at.
  Map<String, dynamic> toJson() {
    final trimmedDescription = description?.trim();

    return <String, dynamic>{
      'category_id': categoryId,
      'name': name.trim(),
      'sku': sku.trim().toUpperCase(),
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
      'price': price,
      'stock': stock,
      'unit': unit.trim(),
      'is_available': isAvailable,
    };
  }
}
