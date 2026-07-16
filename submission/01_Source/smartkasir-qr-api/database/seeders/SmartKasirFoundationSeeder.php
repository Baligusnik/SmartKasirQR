<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\RestaurantTable;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Seeder data awal SmartKasir QR untuk tahap fondasi backend.
 */
class SmartKasirFoundationSeeder extends Seeder
{
    /**
     * Menjalankan seluruh proses seed akun, kategori, produk, dan meja.
     *
     * @return void Method ini membuat atau memperbarui data awal pada database.
     */
    public function run(): void
    {
        $this->seedCashier();
        $categories = $this->seedCategories();
        $this->seedProducts($categories);
        $this->seedRestaurantTables();
        $this->seedOrdersAndTransactions();
    }

    /**
     * Membuat atau memperbarui akun kasir default.
     *
     * @return void Method ini menulis satu record user kasir ke database.
     */
    private function seedCashier(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'kasir@smartkasir.test'],
            [
                'name' => 'Kasir SmartKasir',
                'password' => Hash::make('password'),
                'role' => 'cashier',
                'is_active' => true,
            ],
        );
    }

    /**
     * Membuat kategori contoh dan mengembalikan modelnya untuk relasi produk.
     *
     * @return array<string, Category> Kategori yang diindeks berdasarkan nama.
     */
    private function seedCategories(): array
    {
        $categories = [];

        foreach (['Makanan', 'Minuman', 'Snack'] as $name) {
            $categories[$name] = Category::query()->updateOrCreate(
                ['name' => $name],
                [
                    'description' => null,
                    'is_active' => true,
                ],
            );
        }

        return $categories;
    }

    /**
     * Membuat enam produk contoh dengan harga dan stok wajar.
     *
     * @param  array<string, Category>  $categories  Kategori yang sudah dibuat.
     * @return void Method ini menulis data produk contoh ke database.
     */
    private function seedProducts(array $categories): void
    {
        $products = [
            ['category' => 'Snack', 'name' => 'Piscok', 'sku' => 'SNK-PISCOK', 'price' => 3000, 'stock' => 50],
            ['category' => 'Snack', 'name' => 'Kentang Goreng', 'sku' => 'SNK-KENTANG', 'price' => 8000, 'stock' => 40],
            ['category' => 'Makanan', 'name' => 'Sempol', 'sku' => 'MKN-SEMPOL', 'price' => 2000, 'stock' => 80],
            ['category' => 'Minuman', 'name' => 'Pop Ice', 'sku' => 'MNM-POPICE', 'price' => 5000, 'stock' => 60],
            ['category' => 'Minuman', 'name' => 'Marimas', 'sku' => 'MNM-MARIMAS', 'price' => 3000, 'stock' => 70],
            ['category' => 'Minuman', 'name' => 'Teh Sisri', 'sku' => 'MNM-TEHSISRI', 'price' => 3000, 'stock' => 70],
        ];

        foreach ($products as $product) {
            Product::query()->updateOrCreate(
                ['sku' => $product['sku']],
                [
                    'category_id' => $categories[$product['category']]->id,
                    'name' => $product['name'],
                    'description' => null,
                    'price' => $product['price'],
                    'stock' => $product['stock'],
                    'unit' => 'pcs',
                    'is_available' => true,
                ],
            );
        }
    }

    /**
     * Membuat lima meja contoh dengan token QR acak yang stabil setelah dibuat.
     *
     * @return void Method ini menulis data meja contoh ke database.
     */
    private function seedRestaurantTables(): void
    {
        for ($number = 1; $number <= 5; $number++) {
            $table = RestaurantTable::query()->firstOrNew([
                'code' => sprintf('MEJA-%02d', $number),
            ]);

            $table->fill([
                'name' => 'Meja '.$number,
                'is_active' => true,
            ]);

            if (! $table->exists) {
                $table->qr_token = Str::random(48);
            }

            $table->save();
        }
    }

    /**
     * Membuat pesanan dan transaksi contoh dengan stok akhir yang deterministik.
     *
     * @return void Method ini menulis order, order_items, transaction, dan transaction_items contoh.
     */
    private function seedOrdersAndTransactions(): void
    {
        $cashier = User::query()->where('email', 'kasir@smartkasir.test')->firstOrFail();
        $tableOne = RestaurantTable::query()->where('code', 'MEJA-01')->firstOrFail();
        $tableTwo = RestaurantTable::query()->where('code', 'MEJA-02')->firstOrFail();
        $tableThree = RestaurantTable::query()->where('code', 'MEJA-03')->firstOrFail();

        $piscok = Product::query()->where('sku', 'SNK-PISCOK')->firstOrFail();
        $kentang = Product::query()->where('sku', 'SNK-KENTANG')->firstOrFail();
        $sempol = Product::query()->where('sku', 'MKN-SEMPOL')->firstOrFail();
        $marimas = Product::query()->where('sku', 'MNM-MARIMAS')->firstOrFail();

        $pending = $this->upsertOrder('ORD-DEMO-PENDING', $tableOne->id, 'Gus Nik', 'pending', 3000, null);
        $this->upsertOrderItem($pending, $piscok, 1);

        $confirmed = $this->upsertOrder('ORD-DEMO-CONFIRMED', $tableTwo->id, 'Rika', 'confirmed', 8000, now());
        $this->upsertOrderItem($confirmed, $kentang, 1);

        $ready = $this->upsertOrder('ORD-DEMO-READY', $tableThree->id, 'Dosen Penguji', 'ready', 4000, now());
        $this->upsertOrderItem($ready, $sempol, 2);

        $transaction = Transaction::query()->updateOrCreate(
            ['transaction_number' => 'TRX-DEMO-001'],
            [
                'order_id' => null,
                'user_id' => $cashier->id,
                'total' => 6000,
                'paid_amount' => 10000,
                'change_amount' => 4000,
                'payment_method' => 'cash',
            ],
        );

        $transaction->items()->updateOrCreate(
            ['product_id' => $marimas->id],
            [
                'quantity' => 2,
                'price' => $marimas->price,
                'subtotal' => $marimas->price * 2,
            ],
        );

        $kentang->forceFill(['stock' => 39])->save();
        $sempol->forceFill(['stock' => 78])->save();
        $marimas->forceFill(['stock' => 68])->save();
    }

    /**
     * Membuat atau memperbarui pesanan contoh.
     *
     * @param  string  $orderNumber  Nomor pesanan contoh yang stabil.
     * @param  int  $tableId  ID meja restoran.
     * @param  string  $customerName  Nama pelanggan contoh.
     * @param  string  $status  Status pesanan.
     * @param  int  $total  Total pesanan.
     * @param  mixed  $stockDeductedAt  Waktu pengurangan stok atau null.
     * @return Order Pesanan contoh yang tersimpan.
     */
    private function upsertOrder(
        string $orderNumber,
        int $tableId,
        string $customerName,
        string $status,
        int $total,
        mixed $stockDeductedAt,
    ): Order {
        return Order::query()->updateOrCreate(
            ['order_number' => $orderNumber],
            [
                'restaurant_table_id' => $tableId,
                'customer_name' => $customerName,
                'status' => $status,
                'notes' => 'Data contoh untuk demo UAS.',
                'total' => $total,
                'stock_deducted_at' => $stockDeductedAt,
            ],
        );
    }

    /**
     * Membuat atau memperbarui item pesanan contoh.
     *
     * @param  Order  $order  Pesanan pemilik item.
     * @param  Product  $product  Produk yang dipakai sebagai snapshot item.
     * @param  int  $quantity  Jumlah item pesanan.
     * @return void Method ini menulis order_items contoh.
     */
    private function upsertOrderItem(Order $order, Product $product, int $quantity): void
    {
        $order->items()->updateOrCreate(
            ['product_id' => $product->id],
            [
                'quantity' => $quantity,
                'price' => $product->price,
                'subtotal' => $product->price * $quantity,
                'notes' => null,
            ],
        );
    }
}
