<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\RestaurantTable;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature test tahap 3 untuk dashboard, pesanan, transaksi, dan sinkronisasi stok.
 */
class StageThreeApiTest extends TestCase
{
    use RefreshDatabase;

    /** Memastikan dashboard berhasil dengan token. */
    public function test_dashboard_succeeds_with_token(): void
    {
        $this->withBearerToken()->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('message', 'Data dashboard berhasil diambil.');
    }

    /** Memastikan dashboard gagal tanpa token. */
    public function test_dashboard_fails_without_token(): void
    {
        $this->getJson('/api/dashboard')->assertUnauthorized();
    }

    /** Memastikan dashboard menghitung transaksi hari ini. */
    public function test_dashboard_counts_today_transactions(): void
    {
        $cashier = User::factory()->create();
        Transaction::query()->create([
            'user_id' => $cashier->id,
            'transaction_number' => 'TRX-TODAY-1',
            'total' => 15000,
            'paid_amount' => 20000,
            'change_amount' => 5000,
            'payment_method' => 'cash',
            'created_at' => now(),
        ]);

        $this->withBearerToken()->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.today.transactions', 1)
            ->assertJsonPath('data.today.revenue', 15000);
    }

    /** Memastikan dashboard menghitung pesanan berdasarkan status. */
    public function test_dashboard_counts_orders_by_status(): void
    {
        $product = $this->product();
        $this->order(OrderStatus::Pending, $product);
        $this->order(OrderStatus::Confirmed, $product, stockDeducted: true);

        $this->withBearerToken()->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.orders.pending', 1)
            ->assertJsonPath('data.orders.confirmed', 1);
    }

    /** Memastikan menu meja aktif berhasil diambil. */
    public function test_public_menu_succeeds_for_active_table(): void
    {
        $table = $this->table();
        $this->product();

        $this->getJson('/api/public/tables/'.$table->qr_token.'/menu')
            ->assertOk()
            ->assertJsonPath('message', 'Menu berhasil diambil.')
            ->assertJsonPath('data.table.name', 'Meja Test')
            ->assertJsonMissingPath('data.table.qr_token');
    }

    /** Memastikan QR token tidak valid menghasilkan 404. */
    public function test_public_menu_invalid_qr_token_returns_404(): void
    {
        $this->getJson('/api/public/tables/salah/menu')->assertNotFound();
    }

    /** Memastikan meja tidak aktif tidak dapat digunakan. */
    public function test_public_menu_inactive_table_returns_404(): void
    {
        $table = $this->table(active: false);

        $this->getJson('/api/public/tables/'.$table->qr_token.'/menu')->assertNotFound();
    }

    /** Memastikan pesanan publik berhasil dibuat. */
    public function test_public_order_can_be_created(): void
    {
        $table = $this->table();
        $product = $this->product(price: 7000, stock: 10);

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', [
            'customer_name' => 'Gus Nik',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.total', 14000);
    }

    /** Memastikan harga dan total pesanan publik dihitung dari database. */
    public function test_public_order_total_is_calculated_from_database(): void
    {
        $table = $this->table();
        $product = $this->product(price: 8000, stock: 10);

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', [
            'total' => 1,
            'items' => [['product_id' => $product->id, 'quantity' => 3]],
        ])->assertCreated()
            ->assertJsonPath('data.total', 24000);
    }

    /** Memastikan pesanan publik gagal dengan item kosong. */
    public function test_public_order_fails_with_empty_items(): void
    {
        $table = $this->table();

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', ['items' => []])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan pesanan publik gagal jika produk tidak tersedia. */
    public function test_public_order_fails_when_product_is_unavailable(): void
    {
        $table = $this->table();
        $product = $this->product(available: false);

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', [
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan pesanan publik gagal jika stok tidak cukup. */
    public function test_public_order_fails_when_stock_is_not_enough(): void
    {
        $table = $this->table();
        $product = $this->product(stock: 1);

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', [
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan pesanan publik tidak langsung mengurangi stok. */
    public function test_public_order_does_not_deduct_stock_immediately(): void
    {
        $table = $this->table();
        $product = $this->product(stock: 5);

        $this->postJson('/api/public/tables/'.$table->qr_token.'/orders', [
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 5]);
        $this->assertNull(Order::query()->firstOrFail()->stock_deducted_at);
    }

    /** Memastikan status publik hanya menampilkan data aman. */
    public function test_public_order_status_only_returns_safe_data(): void
    {
        $product = $this->product();
        $order = $this->order(OrderStatus::Pending, $product);

        $this->getJson('/api/public/orders/'.$order->order_number.'/status')
            ->assertOk()
            ->assertJsonPath('data.order_number', $order->order_number)
            ->assertJsonMissingPath('data.user_id')
            ->assertJsonMissingPath('data.qr_token');
    }

    /** Memastikan daftar pesanan berhasil dengan token. */
    public function test_orders_can_be_listed_with_token(): void
    {
        $this->order(OrderStatus::Pending, $this->product());

        $this->withBearerToken()->getJson('/api/orders')
            ->assertOk()
            ->assertJsonPath('message', 'Daftar pesanan berhasil diambil.');
    }

    /** Memastikan daftar pesanan gagal tanpa token. */
    public function test_orders_fail_without_token(): void
    {
        $this->getJson('/api/orders')->assertUnauthorized();
    }

    /** Memastikan filter status pesanan bekerja. */
    public function test_order_status_filter_works(): void
    {
        $product = $this->product();
        $this->order(OrderStatus::Pending, $product);
        $this->order(OrderStatus::Confirmed, $product, stockDeducted: true);

        $this->withBearerToken()->getJson('/api/orders?status=confirmed')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', 'confirmed');
    }

    /** Memastikan pencarian nomor pesanan bekerja. */
    public function test_order_search_by_number_works(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product(), orderNumber: 'ORD-SEARCH-1');

        $this->withBearerToken()->getJson('/api/orders?search='.$order->order_number)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.order_number', 'ORD-SEARCH-1');
    }

    /** Memastikan detail pesanan menyertakan item. */
    public function test_order_detail_includes_items(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product());

        $this->withBearerToken()->getJson('/api/orders/'.$order->id)
            ->assertOk()
            ->assertJsonPath('data.items.0.quantity', 2);
    }

    /** Memastikan pesanan pending dapat dikonfirmasi. */
    public function test_pending_order_can_be_confirmed(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product(stock: 5));

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')
            ->assertOk()
            ->assertJsonPath('data.status', 'confirmed');
    }

    /** Memastikan konfirmasi mengurangi stok. */
    public function test_confirm_order_deducts_stock(): void
    {
        $product = $this->product(stock: 5);
        $order = $this->order(OrderStatus::Pending, $product);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')->assertOk();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 3]);
    }

    /** Memastikan konfirmasi mengisi stock_deducted_at. */
    public function test_confirm_order_sets_stock_deducted_at(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product(stock: 5));

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')->assertOk();

        $this->assertNotNull($order->refresh()->stock_deducted_at);
    }

    /** Memastikan konfirmasi ganda ditolak. */
    public function test_confirm_order_twice_is_rejected(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product(stock: 5));
        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')->assertOk();

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')
            ->assertUnprocessable();
    }

    /** Memastikan konfirmasi gagal jika stok kurang. */
    public function test_confirm_order_fails_when_stock_is_low(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product(stock: 1));

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan kegagalan satu item membatalkan seluruh perubahan stok. */
    public function test_confirm_order_rolls_back_all_stock_when_one_item_fails(): void
    {
        $first = $this->product(name: 'Produk Aman', sku: 'SKU-1', stock: 5);
        $second = $this->product(name: 'Produk Kurang', sku: 'SKU-2', stock: 1);
        $order = $this->order(OrderStatus::Pending, $first);
        $this->addOrderItem($order, $second, 2);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/confirm')
            ->assertUnprocessable();

        $this->assertDatabaseHas('products', ['id' => $first->id, 'stock' => 5]);
        $this->assertDatabaseHas('products', ['id' => $second->id, 'stock' => 1]);
    }

    /** Memastikan confirmed dapat menjadi processing. */
    public function test_confirmed_order_can_be_processed(): void
    {
        $order = $this->order(OrderStatus::Confirmed, $this->product(), stockDeducted: true);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/process')
            ->assertOk()
            ->assertJsonPath('data.status', 'processing');
    }

    /** Memastikan processing dapat menjadi ready. */
    public function test_processing_order_can_be_marked_ready(): void
    {
        $order = $this->order(OrderStatus::Processing, $this->product(), stockDeducted: true);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/ready')
            ->assertOk()
            ->assertJsonPath('data.status', 'ready');
    }

    /** Memastikan perubahan status tidak sah ditolak. */
    public function test_invalid_order_transition_is_rejected(): void
    {
        $order = $this->order(OrderStatus::Pending, $this->product());

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/ready')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status']);
    }

    /** Memastikan pending dapat dibatalkan tanpa perubahan stok. */
    public function test_pending_order_can_be_cancelled_without_stock_change(): void
    {
        $product = $this->product(stock: 5);
        $order = $this->order(OrderStatus::Pending, $product);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 5]);
    }

    /** Memastikan confirmed dapat dibatalkan dan stok dikembalikan. */
    public function test_confirmed_order_cancel_restores_stock(): void
    {
        $product = $this->product(stock: 3);
        $order = $this->order(OrderStatus::Confirmed, $product, stockDeducted: true);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/cancel')->assertOk();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 5]);
    }

    /** Memastikan pembatalan ganda tidak menambah stok. */
    public function test_cancel_twice_does_not_restore_stock_twice(): void
    {
        $product = $this->product(stock: 3);
        $order = $this->order(OrderStatus::Confirmed, $product, stockDeducted: true);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/cancel')->assertOk();
        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/cancel')->assertUnprocessable();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 5]);
    }

    /** Memastikan completed tidak dapat dibatalkan. */
    public function test_completed_order_cannot_be_cancelled(): void
    {
        $order = $this->order(OrderStatus::Completed, $this->product(), stockDeducted: true);

        $this->withBearerToken()->patchJson('/api/orders/'.$order->id.'/cancel')
            ->assertUnprocessable();
    }

    /** Memastikan transaksi langsung berhasil. */
    public function test_direct_transaction_can_be_created(): void
    {
        $product = $this->product(price: 5000, stock: 5);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated()
            ->assertJsonPath('message', 'Transaksi berhasil disimpan.');
    }

    /** Memastikan transaksi langsung mengurangi stok. */
    public function test_direct_transaction_deducts_stock(): void
    {
        $product = $this->product(stock: 5);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 3]);
    }

    /** Memastikan total transaksi dihitung dari database. */
    public function test_direct_transaction_total_is_calculated_from_database(): void
    {
        $product = $this->product(price: 4000, stock: 5);

        $this->withBearerToken()->postJson('/api/transactions', [
            'total' => 1,
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated()
            ->assertJsonPath('data.total', 8000);
    }

    /** Memastikan kembalian transaksi dihitung dengan benar. */
    public function test_direct_transaction_change_is_calculated(): void
    {
        $product = $this->product(price: 4000, stock: 5);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated()
            ->assertJsonPath('data.change_amount', 2000);
    }

    /** Memastikan transaksi gagal jika pembayaran kurang. */
    public function test_direct_transaction_fails_when_paid_amount_is_not_enough(): void
    {
        $product = $this->product(price: 6000, stock: 5);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 5000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['paid_amount']);
    }

    /** Memastikan transaksi gagal jika stok tidak cukup. */
    public function test_direct_transaction_fails_when_stock_is_not_enough(): void
    {
        $product = $this->product(stock: 1);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    }

    /** Memastikan kegagalan satu item membatalkan seluruh transaksi. */
    public function test_direct_transaction_rolls_back_all_stock_when_one_item_fails(): void
    {
        $first = $this->product(name: 'Aman', sku: 'TRX-1', stock: 5);
        $second = $this->product(name: 'Kurang', sku: 'TRX-2', stock: 1);

        $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 50000,
            'payment_method' => 'cash',
            'items' => [
                ['product_id' => $first->id, 'quantity' => 2],
                ['product_id' => $second->id, 'quantity' => 2],
            ],
        ])->assertUnprocessable();

        $this->assertDatabaseHas('products', ['id' => $first->id, 'stock' => 5]);
        $this->assertDatabaseHas('products', ['id' => $second->id, 'stock' => 1]);
    }

    /** Memastikan user token disimpan sebagai kasir transaksi. */
    public function test_direct_transaction_uses_authenticated_user_as_cashier(): void
    {
        $user = User::factory()->create(['name' => 'Kasir Token']);
        $token = $user->createToken('test')->plainTextToken;
        $product = $this->product(stock: 5);

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])->assertCreated();

        $this->assertDatabaseHas('transactions', ['user_id' => $user->id]);
    }

    /** Memastikan pesanan ready dapat dibayar. */
    public function test_ready_order_can_be_paid(): void
    {
        $order = $this->readyOrder();

        $this->withBearerToken()->postJson('/api/transactions', [
            'order_id' => $order->id,
            'paid_amount' => 20000,
            'payment_method' => 'cash',
        ])->assertCreated()
            ->assertJsonPath('data.order_number', $order->order_number);
    }

    /** Memastikan pembayaran mengubah status pesanan menjadi completed. */
    public function test_order_payment_marks_order_completed(): void
    {
        $order = $this->readyOrder();

        $this->withBearerToken()->postJson('/api/transactions', [
            'order_id' => $order->id,
            'paid_amount' => 20000,
            'payment_method' => 'cash',
        ])->assertCreated();

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'completed']);
    }

    /** Memastikan pembayaran pesanan tidak mengurangi stok untuk kedua kali. */
    public function test_order_payment_does_not_deduct_stock_again(): void
    {
        $product = $this->product(stock: 3);
        $order = $this->order(OrderStatus::Ready, $product, stockDeducted: true);

        $this->withBearerToken()->postJson('/api/transactions', [
            'order_id' => $order->id,
            'paid_amount' => 20000,
            'payment_method' => 'cash',
        ])->assertCreated();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock' => 3]);
    }

    /** Memastikan pembayaran ganda ditolak. */
    public function test_order_payment_twice_is_rejected(): void
    {
        $order = $this->readyOrder();
        $payload = ['order_id' => $order->id, 'paid_amount' => 20000, 'payment_method' => 'cash'];

        $this->withBearerToken()->postJson('/api/transactions', $payload)->assertCreated();
        $this->withBearerToken()->postJson('/api/transactions', $payload)->assertUnprocessable();
    }

    /** Memastikan pesanan yang belum ready tidak dapat dibayar. */
    public function test_order_payment_fails_when_order_is_not_ready(): void
    {
        $order = $this->order(OrderStatus::Confirmed, $this->product(), stockDeducted: true);

        $this->withBearerToken()->postJson('/api/transactions', [
            'order_id' => $order->id,
            'paid_amount' => 20000,
            'payment_method' => 'cash',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['order_id']);
    }

    /** Memastikan daftar transaksi berhasil. */
    public function test_transactions_can_be_listed(): void
    {
        $this->transaction();

        $this->withBearerToken()->getJson('/api/transactions')
            ->assertOk()
            ->assertJsonPath('message', 'Daftar transaksi berhasil diambil.');
    }

    /** Memastikan daftar transaksi gagal tanpa token. */
    public function test_transactions_fail_without_token(): void
    {
        $this->getJson('/api/transactions')->assertUnauthorized();
    }

    /** Memastikan detail transaksi menyertakan items. */
    public function test_transaction_detail_includes_items(): void
    {
        $transaction = $this->transaction();

        $this->withBearerToken()->getJson('/api/transactions/'.$transaction->id)
            ->assertOk()
            ->assertJsonPath('data.items.0.quantity', 1);
    }

    /** Memastikan filter tanggal transaksi bekerja. */
    public function test_transaction_date_filter_works(): void
    {
        $this->transaction(number: 'TRX-TODAY', createdAt: now());
        $this->transaction(number: 'TRX-YESTERDAY', createdAt: now()->subDay());

        $this->withBearerToken()->getJson('/api/transactions?date='.now()->toDateString())
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.transaction_number', 'TRX-TODAY');
    }

    /** Memastikan nomor transaksi unik ketika membuat transaksi. */
    public function test_transaction_numbers_are_unique(): void
    {
        $first = $this->product(name: 'Satu', sku: 'UNIQ-1', stock: 5);
        $second = $this->product(name: 'Dua', sku: 'UNIQ-2', stock: 5);

        $one = $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $first->id, 'quantity' => 1]],
        ])->json('data.transaction_number');

        $two = $this->withBearerToken()->postJson('/api/transactions', [
            'paid_amount' => 10000,
            'payment_method' => 'cash',
            'items' => [['product_id' => $second->id, 'quantity' => 1]],
        ])->json('data.transaction_number');

        $this->assertNotSame($one, $two);
    }

    /** Membuat request test dengan Bearer Token. */
    private function withBearerToken(): self
    {
        $user = User::factory()->create();

        return $this->withHeader('Authorization', 'Bearer '.$user->createToken('test')->plainTextToken);
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
            'description' => 'Produk test.',
            'price' => $price,
            'stock' => $stock,
            'unit' => 'pcs',
            'is_available' => $available,
        ]);
    }

    /** Membuat meja restoran test. */
    private function table(bool $active = true): RestaurantTable
    {
        return RestaurantTable::query()->create([
            'name' => 'Meja Test',
            'code' => 'MEJA-'.uniqid(),
            'qr_token' => 'token-'.uniqid(),
            'is_active' => $active,
        ]);
    }

    /** Membuat pesanan test dengan satu item default. */
    private function order(
        OrderStatus $status,
        Product $product,
        bool $stockDeducted = false,
        ?string $orderNumber = null,
    ): Order {
        $order = Order::query()->create([
            'restaurant_table_id' => $this->table()->id,
            'order_number' => $orderNumber ?? 'ORD-'.uniqid(),
            'customer_name' => 'Pelanggan Test',
            'status' => $status->value,
            'notes' => null,
            'total' => $product->price * 2,
            'stock_deducted_at' => $stockDeducted ? now() : null,
        ]);

        $this->addOrderItem($order, $product, 2);

        return $order;
    }

    /** Menambahkan item pada pesanan test. */
    private function addOrderItem(Order $order, Product $product, int $quantity): void
    {
        $order->items()->create([
            'product_id' => $product->id,
            'quantity' => $quantity,
            'price' => $product->price,
            'subtotal' => $product->price * $quantity,
            'notes' => null,
        ]);

        $order->forceFill(['total' => $order->items()->sum('subtotal')])->save();
    }

    /** Membuat pesanan ready yang stoknya sudah dianggap dikurangi. */
    private function readyOrder(): Order
    {
        return $this->order(OrderStatus::Ready, $this->product(stock: 3), stockDeducted: true);
    }

    /** Membuat transaksi test beserta itemnya. */
    private function transaction(string $number = 'TRX-TEST', mixed $createdAt = null): Transaction
    {
        $user = User::factory()->create(['name' => 'Kasir Test']);
        $product = $this->product(sku: $number.'-SKU');

        $transaction = Transaction::query()->create([
            'user_id' => $user->id,
            'transaction_number' => $number,
            'total' => $product->price,
            'paid_amount' => $product->price,
            'change_amount' => 0,
            'payment_method' => 'cash',
        ]);

        $transaction->forceFill(['created_at' => $createdAt ?? now()])->save();

        $transaction->items()->create([
            'product_id' => $product->id,
            'quantity' => 1,
            'price' => $product->price,
            'subtotal' => $product->price,
        ]);

        return $transaction;
    }
}
