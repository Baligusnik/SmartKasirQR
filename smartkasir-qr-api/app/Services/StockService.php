<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Order;
use App\Models\Product;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Validation\ValidationException;

/**
 * Service terpusat untuk validasi, pengurangan, dan pengembalian stok produk.
 */
class StockService
{
    /**
     * Menggabungkan item dengan product_id sama agar kuantitas dihitung satu kali.
     *
     * @param  array<int, array<string, mixed>>  $items  Item request dari pelanggan atau kasir.
     * @return array<int, array{product_id: int, quantity: int, notes?: string|null}> Item yang sudah diagregasi.
     */
    public function aggregateItems(array $items): array
    {
        $aggregated = [];

        foreach ($items as $item) {
            $productId = (int) $item['product_id'];

            if (! isset($aggregated[$productId])) {
                $aggregated[$productId] = [
                    'product_id' => $productId,
                    'quantity' => 0,
                    'notes' => $item['notes'] ?? null,
                ];
            }

            $aggregated[$productId]['quantity'] += (int) $item['quantity'];
        }

        return array_values($aggregated);
    }

    /**
     * Memastikan semua produk tersedia, kategori aktif, dan stok cukup.
     *
     * @param  array<int, array{product_id: int, quantity: int}>  $items  Item yang sudah diagregasi.
     * @return Collection<int, Product> Produk yang diindeks berdasarkan ID.
     *
     * @throws ValidationException Ketika produk tidak tersedia atau stok tidak cukup.
     */
    public function validateAvailableProducts(array $items): Collection
    {
        $productIds = array_column($items, 'product_id');
        $products = Product::query()
            ->with('category')
            ->whereIn('id', $productIds)
            ->get()
            ->keyBy('id');

        foreach ($items as $item) {
            /** @var Product|null $product */
            $product = $products->get($item['product_id']);

            if ($product === null || ! $product->is_available || ! $product->category?->is_active) {
                throw ValidationException::withMessages([
                    'items' => ['Produk tidak tersedia untuk dipesan.'],
                ]);
            }

            if ($product->stock < $item['quantity']) {
                throw ValidationException::withMessages([
                    'items' => [sprintf('Stok %s hanya tersisa %d %s.', $product->name, $product->stock, $product->unit)],
                ]);
            }
        }

        return $products;
    }

    /**
     * Mengurangi stok produk secara atomik dan kompatibel dengan SQLite.
     *
     * @param  array<int, array{product_id: int, quantity: int}>  $items  Item yang stoknya akan dikurangi.
     * @return void Method ini mengubah kolom stock pada tabel products.
     *
     * @throws ValidationException Ketika stok tidak cukup saat update atomik dilakukan.
     */
    public function deduct(array $items): void
    {
        foreach ($items as $item) {
            $updatedRows = Product::query()
                ->whereKey($item['product_id'])
                ->where('is_available', true)
                ->where('stock', '>=', $item['quantity'])
                ->whereHas('category', fn ($query) => $query->where('is_active', true))
                ->decrement('stock', $item['quantity']);

            if ($updatedRows !== 1) {
                $product = Product::query()->find($item['product_id']);

                throw ValidationException::withMessages([
                    'items' => [sprintf(
                        'Stok %s hanya tersisa %d %s.',
                        $product?->name ?? 'produk',
                        $product?->stock ?? 0,
                        $product?->unit ?? 'item',
                    )],
                ]);
            }
        }
    }

    /**
     * Mengembalikan stok berdasarkan item pesanan yang pernah dikurangi.
     *
     * @param  Order  $order  Pesanan yang itemnya akan dikembalikan ke stok.
     * @return void Method ini menambah kolom stock pada tabel products.
     */
    public function restoreForOrder(Order $order): void
    {
        $order->loadMissing('items');

        foreach ($order->items as $item) {
            Product::query()
                ->whereKey($item->product_id)
                ->increment('stock', $item->quantity);
        }
    }
}
