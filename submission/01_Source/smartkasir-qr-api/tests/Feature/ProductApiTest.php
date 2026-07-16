<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature test untuk endpoint kategori dan produk tahap kedua SmartKasir QR.
 */
class ProductApiTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Memastikan daftar kategori aktif dapat diambil dengan Bearer Token.
     *
     * @return void Test ini membuat kategori aktif dan membaca endpoint kategori.
     */
    public function test_categories_can_be_listed_with_token(): void
    {
        $token = $this->token();

        $category = $this->createCategory('Makanan');
        $this->createProduct($category, ['name' => 'Piscok', 'sku' => 'MKN-001']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/categories');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Daftar kategori berhasil diambil.')
            ->assertJsonPath('data.0.name', 'Makanan')
            ->assertJsonPath('data.0.products_count', 1);
    }

    /**
     * Memastikan daftar kategori tidak dapat diakses tanpa Bearer Token.
     *
     * @return void Test ini tidak mengubah database.
     */
    public function test_categories_fail_without_token(): void
    {
        $this->getJson('/api/categories')
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Tidak terautentikasi.');
    }

    /**
     * Memastikan daftar produk dapat diambil dengan Bearer Token.
     *
     * @return void Test ini membuat produk dan membaca endpoint produk.
     */
    public function test_products_can_be_listed_with_token(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Snack');
        $this->createProduct($category, ['name' => 'Kentang Goreng', 'sku' => 'SNK-001']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Daftar produk berhasil diambil.')
            ->assertJsonPath('data.0.name', 'Kentang Goreng');
    }

    /**
     * Memastikan daftar produk menyertakan data kategori.
     *
     * @return void Test ini membuat kategori dan produk lalu memeriksa struktur response.
     */
    public function test_products_include_category_data(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Minuman');
        $this->createProduct($category, ['name' => 'Pop Ice', 'sku' => 'MNM-001']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products');

        $response
            ->assertOk()
            ->assertJsonPath('data.0.category.id', $category->id)
            ->assertJsonPath('data.0.category.name', 'Minuman')
            ->assertJsonPath('data.0.price_formatted', 'Rp5.000')
            ->assertJsonPath('data.0.can_be_ordered', true);
    }

    /**
     * Memastikan daftar produk mendukung pencarian berdasarkan nama.
     *
     * @return void Test ini membuat dua produk dan memfilter berdasarkan nama.
     */
    public function test_products_can_be_searched_by_name(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Minuman');
        $this->createProduct($category, ['name' => 'Pop Ice', 'sku' => 'MNM-001']);
        $this->createProduct($category, ['name' => 'Teh Sisri', 'sku' => 'MNM-002']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products?search=pop');

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Pop Ice');
    }

    /**
     * Memastikan daftar produk mendukung pencarian berdasarkan SKU.
     *
     * @return void Test ini membuat dua produk dan memfilter berdasarkan SKU.
     */
    public function test_products_can_be_searched_by_sku(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Snack');
        $this->createProduct($category, ['name' => 'Piscok', 'sku' => 'SNK-PISCOK']);
        $this->createProduct($category, ['name' => 'Sempol', 'sku' => 'MKN-SEMPOL']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products?search=SEMPOL');

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.sku', 'MKN-SEMPOL');
    }

    /**
     * Memastikan daftar produk mendukung filter kategori.
     *
     * @return void Test ini membuat dua kategori dan memfilter berdasarkan category_id.
     */
    public function test_products_can_be_filtered_by_category(): void
    {
        $token = $this->token();
        $food = $this->createCategory('Makanan');
        $drink = $this->createCategory('Minuman');
        $this->createProduct($food, ['name' => 'Sempol', 'sku' => 'MKN-001']);
        $this->createProduct($drink, ['name' => 'Marimas', 'sku' => 'MNM-001']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products?category_id='.$drink->id);

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Marimas');
    }

    /**
     * Memastikan daftar produk mendukung filter ketersediaan.
     *
     * @return void Test ini membuat produk bisa dipesan dan tidak bisa dipesan.
     */
    public function test_products_can_be_filtered_by_availability(): void
    {
        $token = $this->token();
        $activeCategory = $this->createCategory('Snack');
        $inactiveCategory = $this->createCategory('Arsip', false);
        $this->createProduct($activeCategory, ['name' => 'Piscok', 'sku' => 'SNK-001', 'stock' => 10]);
        $this->createProduct($activeCategory, ['name' => 'Stok Kosong', 'sku' => 'SNK-002', 'stock' => 0]);
        $this->createProduct($inactiveCategory, ['name' => 'Produk Arsip', 'sku' => 'ARS-001', 'stock' => 10]);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products?available=1');

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Piscok')
            ->assertJsonPath('data.0.can_be_ordered', true);
    }

    /**
     * Memastikan detail produk dapat diambil dengan kategori.
     *
     * @return void Test ini membuat produk lalu membaca endpoint detail.
     */
    public function test_product_detail_can_be_shown(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');
        $product = $this->createProduct($category, ['name' => 'Nugget Goreng', 'sku' => 'MKN-007']);

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products/'.$product->id);

        $response
            ->assertOk()
            ->assertJsonPath('message', 'Detail produk berhasil diambil.')
            ->assertJsonPath('data.name', 'Nugget Goreng')
            ->assertJsonPath('data.category.name', 'Makanan');
    }

    /**
     * Memastikan detail produk yang tidak ada menghasilkan HTTP 404.
     *
     * @return void Test ini membaca ID produk yang tidak tersimpan.
     */
    public function test_missing_product_returns_not_found(): void
    {
        $token = $this->token();

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/products/999')
            ->assertNotFound()
            ->assertJsonPath('message', 'Data tidak ditemukan.');
    }

    /**
     * Memastikan produk baru dapat ditambahkan melalui POST.
     *
     * @return void Test ini menulis satu produk baru ke database.
     */
    public function test_product_can_be_stored(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $this->validPayload($category));

        $response
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Produk berhasil ditambahkan.')
            ->assertJsonPath('data.name', 'Nugget Goreng')
            ->assertJsonPath('data.price_formatted', 'Rp5.000');
    }

    /**
     * Memastikan tambah produk ditolak tanpa Bearer Token.
     *
     * @return void Test ini tidak menulis produk karena autentikasi gagal.
     */
    public function test_product_store_fails_without_token(): void
    {
        $category = $this->createCategory('Makanan');

        $this
            ->postJson('/api/products', $this->validPayload($category))
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Tidak terautentikasi.');
    }

    /**
     * Memastikan produk tidak dapat dibuat pada kategori tidak aktif.
     *
     * @return void Test ini membuat kategori nonaktif dan memastikan validasi gagal.
     */
    public function test_product_store_fails_when_category_is_inactive(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Arsip', false);

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $this->validPayload($category))
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Data produk tidak valid.')
            ->assertJsonValidationErrors(['category_id']);
    }

    /**
     * Memastikan produk tidak dapat dibuat dengan SKU duplikat.
     *
     * @return void Test ini membuat produk awal lalu mencoba SKU yang sama.
     */
    public function test_product_store_fails_when_sku_is_duplicate(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');
        $this->createProduct($category, ['name' => 'Produk Lama', 'sku' => 'MKN-007']);

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $this->validPayload($category))
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Data produk tidak valid.')
            ->assertJsonValidationErrors(['sku']);
    }

    /**
     * Memastikan harga negatif ditolak oleh validasi produk.
     *
     * @return void Test ini mengirim payload dengan harga negatif dan tidak menulis produk.
     */
    public function test_product_store_fails_when_price_is_negative(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');
        $payload = $this->validPayload($category, ['price' => -1]);

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['price']);
    }

    /**
     * Memastikan stok negatif ditolak oleh validasi produk.
     *
     * @return void Test ini mengirim payload dengan stok negatif dan tidak menulis produk.
     */
    public function test_product_store_fails_when_stock_is_negative(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');
        $payload = $this->validPayload($category, ['stock' => -1]);

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['stock']);
    }

    /**
     * Memastikan produk yang berhasil dibuat benar-benar tersimpan di database.
     *
     * @return void Test ini menulis produk lalu memeriksa tabel products.
     */
    public function test_stored_product_is_persisted_in_database(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $this->validPayload($category))
            ->assertCreated();

        $this->assertDatabaseHas('products', [
            'category_id' => $category->id,
            'name' => 'Nugget Goreng',
            'sku' => 'MKN-007',
            'price' => 5000,
            'stock' => 25,
        ]);
    }

    /**
     * Memastikan SKU produk dinormalisasi menjadi huruf kapital sebelum disimpan.
     *
     * @return void Test ini mengirim SKU kecil dengan spasi dan memeriksa hasil penyimpanan.
     */
    public function test_product_sku_is_normalized_to_uppercase(): void
    {
        $token = $this->token();
        $category = $this->createCategory('Makanan');

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/products', $this->validPayload($category, ['sku' => '  mkn-009  ']));

        $response
            ->assertCreated()
            ->assertJsonPath('data.sku', 'MKN-009');

        $this->assertDatabaseHas('products', ['sku' => 'MKN-009']);
    }

    /**
     * Membuat token Sanctum untuk pengguna kasir test.
     *
     * @return string Token Bearer yang dapat dipakai pada header Authorization.
     */
    private function token(): string
    {
        $user = User::factory()->create([
            'role' => 'cashier',
            'is_active' => true,
        ]);

        return $user->createToken('feature-test')->plainTextToken;
    }

    /**
     * Membuat kategori test dengan status aktif yang dapat diatur.
     *
     * @param  string  $name  Nama kategori yang akan dibuat.
     * @param  bool  $active  Status aktif kategori.
     * @return Category Kategori yang tersimpan di database testing.
     */
    private function createCategory(string $name, bool $active = true): Category
    {
        return Category::query()->create([
            'name' => $name,
            'description' => 'Kategori '.$name,
            'is_active' => $active,
        ]);
    }

    /**
     * Membuat produk test dengan nilai default yang dapat dioverride.
     *
     * @param  Category  $category  Kategori pemilik produk.
     * @param  array<string, mixed>  $overrides  Nilai atribut produk yang ingin diganti.
     * @return Product Produk yang tersimpan di database testing.
     */
    private function createProduct(Category $category, array $overrides = []): Product
    {
        return Product::query()->create(array_merge([
            'category_id' => $category->id,
            'name' => 'Produk Test',
            'sku' => 'PRD-001',
            'description' => 'Produk untuk test.',
            'price' => 5000,
            'stock' => 20,
            'unit' => 'pcs',
            'is_available' => true,
        ], $overrides));
    }

    /**
     * Membuat payload valid untuk endpoint tambah produk.
     *
     * @param  Category  $category  Kategori aktif yang dipilih produk.
     * @param  array<string, mixed>  $overrides  Nilai request yang ingin diganti.
     * @return array<string, mixed> Payload request produk yang siap dikirim.
     */
    private function validPayload(Category $category, array $overrides = []): array
    {
        return array_merge([
            'category_id' => $category->id,
            'name' => 'Nugget Goreng',
            'sku' => 'MKN-007',
            'description' => 'Nugget ayam goreng.',
            'price' => 5000,
            'stock' => 25,
            'unit' => 'porsi',
            'is_available' => true,
        ], $overrides);
    }
}
