import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/category_model.dart';
import '../models/create_product_input.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

/// Halaman form tambah produk yang mengirim `POST /api/products`.
class CreateProductPage extends StatefulWidget {
  /// Membuat halaman tambah produk.
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  int? _categoryId;
  String _unit = 'pcs';
  bool _isAvailable = true;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final createdProduct = provider.createdProduct;

          if (_success && createdProduct != null) {
            return _CreateProductSuccess(
              product: createdProduct,
              onBackToProducts: () => Navigator.of(context).pop(true),
              onCreateAgain: () {
                provider.clearCreateProductState();
                _clearForm();
                setState(() => _success = false);
              },
            );
          }

          return _CreateProductForm(
            formKey: _formKey,
            nameController: _nameController,
            skuController: _skuController,
            descriptionController: _descriptionController,
            priceController: _priceController,
            stockController: _stockController,
            categories: provider.categories,
            selectedCategoryId: _categoryId,
            selectedUnit: _unit,
            isAvailable: _isAvailable,
            isSubmitting: provider.isCreatingProduct,
            generalError: provider.createProductError,
            fieldError: _fieldError(provider),
            onCategoryChanged: (value) => setState(() => _categoryId = value),
            onUnitChanged: (value) => setState(() => _unit = value ?? 'pcs'),
            onAvailableChanged: (value) {
              if (value != null) {
                setState(() => _isAvailable = value);
              }
            },
            onRetryCategories: provider.loadCategories,
            onSubmit: () => _submit(provider),
          );
        },
      ),
    );
  }

  /// Memastikan kategori tersedia untuk dropdown form.
  Future<void> _ensureCategories() async {
    if (!mounted) {
      return;
    }

    final provider = context.read<ProductProvider>();
    if (provider.categories.isEmpty) {
      await provider.loadCategories();
    }
  }

  Future<void> _submit(ProductProvider provider) async {
    provider.clearCreateProductState();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final input = CreateProductInput(
      categoryId: _categoryId!,
      name: _nameController.text,
      sku: _skuController.text,
      description: _descriptionController.text,
      price: int.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      unit: _unit,
      isAvailable: _isAvailable,
    );

    final success = await provider.createProduct(input);
    if (!mounted) {
      return;
    }

    if (provider.isUnauthorized) {
      await context.read<AuthProvider>().expireSession(
        message:
            provider.createProductError ??
            'Sesi Anda telah berakhir. Silakan login kembali.',
      );
      provider.reset();
      return;
    }

    if (success) {
      await provider.refreshProducts();
      if (!mounted) {
        return;
      }
      await context.read<DashboardProvider>().refreshDashboard();
      if (mounted) {
        setState(() => _success = true);
      }
    }
  }

  String? Function(String) _fieldError(ProductProvider provider) {
    return (field) {
      final messages = provider.createProductValidationErrors[field];
      if (messages == null || messages.isEmpty) {
        return null;
      }

      return messages.first;
    };
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _skuController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    _categoryId = null;
    _unit = 'pcs';
    _isAvailable = true;
  }
}

class _CreateProductForm extends StatelessWidget {
  const _CreateProductForm({
    required this.formKey,
    required this.nameController,
    required this.skuController,
    required this.descriptionController,
    required this.priceController,
    required this.stockController,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedUnit,
    required this.isAvailable,
    required this.isSubmitting,
    required this.fieldError,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onAvailableChanged,
    required this.onRetryCategories,
    required this.onSubmit,
    this.generalError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final String selectedUnit;
  final bool isAvailable;
  final bool isSubmitting;
  final String? generalError;
  final String? Function(String field) fieldError;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<bool?> onAvailableChanged;
  final VoidCallback onRetryCategories;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return AppEmptyView(
        icon: Icons.category_outlined,
        title: 'Kategori belum tersedia',
        description: 'Muat kategori terlebih dahulu sebelum menambah produk.',
        action: FilledButton.icon(
          onPressed: onRetryCategories,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (generalError != null) ...[
                    _FormMessage(message: generalError!),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      errorText: fieldError('category_id'),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isSubmitting ? null : onCategoryChanged,
                    validator: (value) =>
                        value == null ? 'Kategori wajib dipilih.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Nama produk',
                      errorText: fieldError('name'),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: skuController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'SKU',
                      helperText: 'SKU akan dikirim dalam huruf kapital.',
                      errorText: fieldError('sku'),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    validator: _validateSku,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      errorText: fieldError('description'),
                    ),
                    minLines: 2,
                    maxLines: 4,
                    validator: _validateDescription,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextFormField(
                          controller: priceController,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            errorText: fieldError('price'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateRequiredNumber('Harga'),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextFormField(
                          controller: stockController,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Stok',
                            errorText: fieldError('stock'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateRequiredNumber('Stok'),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Satuan',
                            errorText: fieldError('unit'),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                            DropdownMenuItem(
                              value: 'porsi',
                              child: Text('porsi'),
                            ),
                            DropdownMenuItem(
                              value: 'gelas',
                              child: Text('gelas'),
                            ),
                            DropdownMenuItem(
                              value: 'botol',
                              child: Text('botol'),
                            ),
                          ],
                          onChanged: isSubmitting ? null : onUnitChanged,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Satuan wajib dipilih.'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isAvailable,
                    onChanged: isSubmitting ? null : onAvailableChanged,
                    title: const Text('Produk tersedia'),
                    subtitle: Text(
                      fieldError('is_available') ??
                          'Produk dapat dipilih jika stok tersedia.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSubmitting ? 'Menyimpan...' : 'Simpan Produk',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Nama produk wajib diisi.';
    }
    if (text.length > 150) {
      return 'Nama produk maksimal 150 karakter.';
    }
    return null;
  }

  String? _validateSku(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'SKU wajib diisi.';
    }
    if (text.length > 50) {
      return 'SKU maksimal 50 karakter.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 1000) {
      return 'Deskripsi maksimal 1000 karakter.';
    }
    return null;
  }

  String? Function(String?) _validateRequiredNumber(String label) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$label wajib diisi.';
      }
      final number = int.tryParse(text);
      if (number == null) {
        return '$label harus berupa angka.';
      }
      if (number < 0) {
        return '$label tidak boleh negatif.';
      }
      return null;
    };
  }
}

class _CreateProductSuccess extends StatelessWidget {
  const _CreateProductSuccess({
    required this.product,
    required this.onBackToProducts,
    required this.onCreateAgain,
  });

  final ProductModel product;
  final VoidCallback onBackToProducts;
  final VoidCallback onCreateAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Produk berhasil ditambahkan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _SuccessRow(label: 'Nama', value: product.name),
                _SuccessRow(label: 'SKU', value: product.sku),
                _SuccessRow(label: 'Harga', value: product.priceFormatted),
                _SuccessRow(
                  label: 'Stok',
                  value: '${product.stock} ${product.unit}',
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onBackToProducts,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Kembali ke Produk'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onCreateAgain,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk Lagi'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormMessage extends StatelessWidget {
  const _FormMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
