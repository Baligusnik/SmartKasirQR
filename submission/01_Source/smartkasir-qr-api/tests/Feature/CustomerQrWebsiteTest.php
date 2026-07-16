<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\RestaurantTable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature test tahap 4 untuk website pemesanan pelanggan melalui QR Code.
 */
class CustomerQrWebsiteTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Menyiapkan test website QR tanpa membutuhkan manifest Vite hasil build.
     *
     * @return void Tidak mengubah data aplikasi selain konfigurasi test runtime.
     */
    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutVite();
    }

    /** Memastikan halaman menu dapat dibuka dengan QR token meja aktif. */
    public function test_menu_page_can_be_opened_with_valid_qr_token(): void
    {
        $table = $this->table();
        $this->product(name: 'Kentang Goreng');

        $this->get(route('menu.show', ['qrToken' => $table->qr_token]))
            ->assertOk()
            ->assertSee('SmartKasir QR')
            ->assertSee('Kentang Goreng');
    }

    /** Memastikan QR token tidak valid menghasilkan 404. */
    public function test_invalid_qr_token_returns_not_found(): void
    {
        $this->get(route('menu.show', ['qrToken' => 'token-tidak-valid']))->assertNotFound();
    }

    /** Memastikan meja tidak aktif tidak dapat membuka halaman menu. */
    public function test_inactive_table_cannot_open_menu_page(): void
    {
        $table = $this->table(active: false);

        $this->get(route('menu.show', ['qrToken' => $table->qr_token]))->assertNotFound();
    }

    /** Memastikan halaman menu hanya menampilkan produk tersedia dan stok positif. */
    public function test_menu_page_only_shows_available_products_with_stock(): void
    {
        $table = $this->table();
        $this->product(name: 'Tampil', sku: 'SHOW-1', stock: 5);
        $this->product(name: 'Habis', sku: 'EMPTY-1', stock: 0);
        $this->product(name: 'Nonaktif', sku: 'OFF-1', available: false);

        $this->get(route('menu.show', ['qrToken' => $table->qr_token]))
            ->assertOk()
            ->assertSee('Tampil')
            ->assertDontSee('Habis')
            ->assertDontSee('Nonaktif');
    }

    /** Memastikan produk stok 0 tidak dapat dipesan melalui route web. */
    public function test_out_of_stock_product_cannot_be_ordered(): void
    {
        $table = $this->table();
        $product = $this->product(stock: 0);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan form pesanan web berhasil membuat order pending. */
    public function test_web_order_creates_pending_order(): void
    {
        $table = $this->table();
        $product = $this->product(price: 7000, stock: 10);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'customer_name' => 'Gus Nik',
            'items' => [['product_id' => $product->id, 'quantity' => 2, 'notes' => 'Tidak pedas']],
        ])->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['redirect_url', 'order_number']);

        $this->assertDatabaseHas('orders', [
            'restaurant_table_id' => $table->id,
            'status' => OrderStatus::Pending->value,
            'total' => 14000,
        ]);
    }

    /** Memastikan total pesanan web dihitung dari harga database. */
    public function test_web_order_total_is_calculated_from_database(): void
    {
        $table = $this->table();
        $product = $this->product(price: 8000, stock: 10);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'total' => 1,
            'items' => [['product_id' => $product->id, 'quantity' => 3]],
        ])->assertCreated();

        $this->assertDatabaseHas('orders', ['total' => 24000]);
    }

    /** Memastikan request browser tidak dapat memanipulasi harga item. */
    public function test_web_order_ignores_price_manipulation(): void
    {
        $table = $this->table();
        $product = $this->product(price: 9000, stock: 10);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'items' => [['product_id' => $product->id, 'quantity' => 2, 'price' => 1, 'subtotal' => 2]],
        ])->assertCreated();

        $order = Order::query()->with('items')->firstOrFail();

        $this->assertSame(18000, $order->total);
        $this->assertSame(9000, $order->items->first()->price);
        $this->assertSame(18000, $order->items->first()->subtotal);
    }

    /** Memastikan pesanan gagal jika item kosong. */
    public function test_web_order_fails_when_items_are_empty(): void
    {
        $table = $this->table();

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), ['items' => []])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan pesanan gagal jika stok tidak cukup. */
    public function test_web_order_fails_when_stock_is_not_enough(): void
    {
        $table = $this->table();
        $product = $this->product(stock: 1);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan submit pesanan tidak langsung mengurangi stok. */
    public function test_web_order_does_not_deduct_stock_immediately(): void
    {
        $table = $this->table();
        $product = $this->product(stock: 5);

        $this->postJson(route('menu.order.store', ['qrToken' => $table->qr_token]), [
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 5]);
        $this->assertNull(Order::query()->firstOrFail()->stock_deducted_at);
    }

    /** Memastikan halaman sukses menampilkan nomor pesanan dan tidak menampilkan QR token. */
    public function test_success_page_shows_order_number_without_qr_token(): void
    {
        $order = $this->order();

        $this->get(route('order.success', ['orderNumber' => $order->order_number]))
            ->assertOk()
            ->assertSee($order->order_number)
            ->assertDontSee($order->restaurantTable->qr_token);
    }

    /** Memastikan halaman status menampilkan status pesanan yang benar. */
    public function test_status_page_shows_current_order_status(): void
    {
        $order = $this->order(status: OrderStatus::Ready);

        $this->get(route('order.status', ['orderNumber' => $order->order_number]))
            ->assertOk()
            ->assertSee($order->order_number)
            ->assertSee('Siap');
    }

    /** Memastikan nomor pesanan tidak valid menghasilkan 404. */
    public function test_invalid_order_number_returns_not_found(): void
    {
        $this->get(route('order.status', ['orderNumber' => 'ORD-TIDAK-ADA']))->assertNotFound();
    }

    /** Memastikan halaman status tidak menampilkan QR token meja. */
    public function test_status_page_does_not_show_qr_token(): void
    {
        $order = $this->order();

        $this->get(route('order.status', ['orderNumber' => $order->order_number]))
            ->assertOk()
            ->assertDontSee($order->restaurantTable->qr_token);
    }

    /** Memastikan daftar QR hanya menampilkan meja aktif. */
    public function test_qr_table_page_shows_only_active_tables(): void
    {
        $active = $this->table(name: 'Meja Aktif', code: 'MEJA-AKTIF');
        $inactive = $this->table(name: 'Meja Nonaktif', code: 'MEJA-NONAKTIF', active: false);

        $this->get(route('qr.tables.index'))
            ->assertOk()
            ->assertSee($active->name)
            ->assertDontSee($inactive->name);
    }

    /** Memastikan QR mengarah ke route menu pelanggan, bukan endpoint JSON API. */
    public function test_qr_page_links_to_customer_menu_route(): void
    {
        $table = $this->table();

        $this->get(route('qr.tables.index'))
            ->assertOk()
            ->assertSee('/menu/'.$table->qr_token)
            ->assertDontSee('/api/public/tables/'.$table->qr_token.'/menu');
    }

    /** Memastikan route web utama tidak menampilkan data internal sensitif pelanggan. */
    public function test_customer_web_pages_do_not_show_internal_sensitive_data(): void
    {
        $table = $this->table();
        $order = $this->order(table: $table);

        $this->get(route('menu.show', ['qrToken' => $table->qr_token]))
            ->assertOk()
            ->assertDontSee('user_id')
            ->assertDontSee('stock_deducted_at');

        $this->get(route('order.status', ['orderNumber' => $order->order_number]))
            ->assertOk()
            ->assertDontSee('user_id')
            ->assertDontSee('stock_deducted_at')
            ->assertDontSee($table->qr_token);
    }

    /** Memastikan test website tetap memakai SQLite. */
    public function test_sqlite_is_used_for_feature_tests(): void
    {
        $this->assertSame('sqlite', config('database.default'));
        $this->assertSame(':memory:', config('database.connections.sqlite.database'));
    }

    /** Membuat kategori test. */
    private function category(bool $active = true): Category
    {
        return Category::query()->create([
            'name' => 'Kategori '.uniqid(),
            'description' => null,
            'is_active' => $active,
        ]);
    }

    /** Membuat produk test. */
    private function product(
        string $name = 'Produk Test',
        string $sku = 'SKU-TEST',
        int $price = 5000,
        int $stock = 10,
        bool $available = true,
        ?Category $category = null,
    ): Product {
        return Product::query()->create([
            'category_id' => ($category ?? $this->category())->id,
            'name' => $name,
            'sku' => $sku,
            'description' => 'Produk untuk test website QR.',
            'price' => $price,
            'stock' => $stock,
            'unit' => 'pcs',
            'is_available' => $available,
        ]);
    }

    /** Membuat meja restoran test. */
    private function table(
        string $name = 'Meja Test',
        ?string $code = null,
        bool $active = true,
    ): RestaurantTable {
        return RestaurantTable::query()->create([
            'name' => $name,
            'code' => $code ?? 'MEJA-'.uniqid(),
            'qr_token' => 'token-'.uniqid(),
            'is_active' => $active,
        ]);
    }

    /** Membuat pesanan test dengan satu item. */
    private function order(
        OrderStatus $status = OrderStatus::Pending,
        ?RestaurantTable $table = null,
    ): Order {
        $product = $this->product();
        $order = Order::query()->create([
            'restaurant_table_id' => ($table ?? $this->table())->id,
            'order_number' => 'ORD-'.uniqid(),
            'customer_name' => 'Pelanggan Test',
            'status' => $status->value,
            'notes' => null,
            'total' => $product->price,
            'stock_deducted_at' => null,
        ]);

        $order->items()->create([
            'product_id' => $product->id,
            'quantity' => 1,
            'price' => $product->price,
            'subtotal' => $product->price,
            'notes' => null,
        ]);

        return $order->load('restaurantTable');
    }
}
