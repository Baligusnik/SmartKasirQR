<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\RestaurantTable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Service untuk daftar, pembuatan publik, dan perubahan status pesanan.
 */
class OrderService
{
    /**
     * Membuat instance service pesanan.
     *
     * @param  StockService  $stockService  Service stok terpusat.
     * @param  UniqueNumberService  $numberService  Service nomor unik.
     */
    public function __construct(
        private readonly StockService $stockService,
        private readonly UniqueNumberService $numberService,
    ) {}

    /**
     * Mengambil daftar pesanan dengan filter status dan pencarian.
     *
     * @param  array{status?: string|null, search?: string|null}  $filters  Filter daftar pesanan.
     * @return Collection<int, Order> Koleksi pesanan dengan relasi yang sudah dimuat.
     */
    public function list(array $filters): Collection
    {
        $query = Order::query()
            ->with(['restaurantTable', 'items.product'])
            ->withCount('items')
            ->latest();

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['search'])) {
            $search = trim((string) $filters['search']);

            $query->where(function ($query) use ($search): void {
                $query
                    ->where('order_number', 'like', "%{$search}%")
                    ->orWhere('customer_name', 'like', "%{$search}%")
                    ->orWhereHas('restaurantTable', function ($query) use ($search): void {
                        $query
                            ->where('name', 'like', "%{$search}%")
                            ->orWhere('code', 'like', "%{$search}%");
                    });
            });
        }

        return $query->get();
    }

    /**
     * Membuat pesanan publik berstatus pending tanpa mengurangi stok.
     *
     * @param  RestaurantTable  $table  Meja aktif yang berasal dari QR token.
     * @param  array<string, mixed>  $data  Data pesanan publik yang sudah divalidasi.
     * @return Order Pesanan baru dengan relasi item dan meja.
     *
     * @throws ValidationException Ketika produk tidak tersedia atau stok tidak cukup.
     */
    public function createPublicOrder(RestaurantTable $table, array $data): Order
    {
        return DB::transaction(function () use ($table, $data): Order {
            $items = $this->stockService->aggregateItems($data['items']);
            $products = $this->stockService->validateAvailableProducts($items);
            $total = 0;

            foreach ($items as $item) {
                $product = $products->get($item['product_id']);
                $total += $product->price * $item['quantity'];
            }

            $order = Order::query()->create([
                'restaurant_table_id' => $table->id,
                'order_number' => $this->numberService->orderNumber(),
                'customer_name' => $data['customer_name'] ?? null,
                'status' => OrderStatus::Pending->value,
                'notes' => $data['notes'] ?? null,
                'total' => $total,
                'stock_deducted_at' => null,
            ]);

            foreach ($items as $item) {
                $product = $products->get($item['product_id']);
                $order->items()->create([
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price,
                    'subtotal' => $product->price * $item['quantity'],
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            return $order->load(['restaurantTable', 'items.product']);
        });
    }

    /**
     * Mengonfirmasi pesanan pending dan mengurangi stok setiap produk secara atomik.
     *
     * @param  Order  $order  Pesanan berstatus pending yang akan dikonfirmasi.
     * @return Order Pesanan setelah berhasil dikonfirmasi.
     *
     * @throws ValidationException Ketika status pesanan atau stok tidak valid.
     */
    public function confirm(Order $order): Order
    {
        return DB::transaction(function () use ($order): Order {
            $order = Order::query()
                ->with(['restaurantTable', 'items.product'])
                ->whereKey($order->id)
                ->firstOrFail();

            $this->ensureStatus($order, OrderStatus::Pending, 'Pesanan hanya dapat dikonfirmasi saat menunggu.');

            if ($order->stock_deducted_at === null) {
                $items = $order->items
                    ->map(fn ($item) => ['product_id' => $item->product_id, 'quantity' => $item->quantity])
                    ->all();

                $this->stockService->deduct($items);
            }

            $order->forceFill([
                'status' => OrderStatus::Confirmed->value,
                'stock_deducted_at' => $order->stock_deducted_at ?? now(),
            ])->save();

            return $order->refresh()->load(['restaurantTable', 'items.product']);
        });
    }

    /**
     * Mengubah status pesanan sesuai alur yang diperbolehkan.
     *
     * @param  Order  $order  Pesanan yang akan diubah statusnya.
     * @param  OrderStatus  $next  Status tujuan.
     * @return Order Pesanan setelah status diperbarui.
     *
     * @throws ValidationException Ketika transisi status tidak valid.
     */
    public function transition(Order $order, OrderStatus $next): Order
    {
        return DB::transaction(function () use ($order, $next): Order {
            $order = Order::query()
                ->with(['restaurantTable', 'items.product'])
                ->whereKey($order->id)
                ->firstOrFail();

            $current = OrderStatus::from($order->status);

            if (! $current->canTransitionTo($next)) {
                throw ValidationException::withMessages([
                    'status' => [sprintf('Pesanan berstatus %s tidak dapat diubah menjadi %s.', $current->label(), $next->label())],
                ]);
            }

            $order->forceFill(['status' => $next->value])->save();

            return $order->refresh()->load(['restaurantTable', 'items.product']);
        });
    }

    /**
     * Membatalkan pesanan dan mengembalikan stok bila sebelumnya sudah dikurangi.
     *
     * @param  Order  $order  Pesanan yang akan dibatalkan.
     * @param  string|null  $reason  Alasan pembatalan opsional dari kasir.
     * @return Order Pesanan setelah dibatalkan.
     *
     * @throws ValidationException Ketika pesanan sudah selesai atau sudah dibatalkan.
     */
    public function cancel(Order $order, ?string $reason = null): Order
    {
        return DB::transaction(function () use ($order, $reason): Order {
            $order = Order::query()
                ->with(['restaurantTable', 'items.product'])
                ->whereKey($order->id)
                ->firstOrFail();

            $current = OrderStatus::from($order->status);

            if (! $current->canTransitionTo(OrderStatus::Cancelled)) {
                throw ValidationException::withMessages([
                    'status' => ['Pesanan tidak dapat dibatalkan.'],
                ]);
            }

            if ($order->stock_deducted_at !== null) {
                $this->stockService->restoreForOrder($order);
            }

            $notes = $order->notes;
            if ($reason !== null && $reason !== '') {
                $notes = trim((string) ($notes ? $notes."\n" : '').'Alasan pembatalan: '.$reason);
            }

            $order->forceFill([
                'status' => OrderStatus::Cancelled->value,
                'notes' => $notes,
                'stock_deducted_at' => null,
            ])->save();

            return $order->refresh()->load(['restaurantTable', 'items.product']);
        });
    }

    /**
     * Memastikan pesanan berada pada status yang diharapkan.
     *
     * @param  Order  $order  Pesanan yang diperiksa.
     * @param  OrderStatus  $expected  Status yang wajib dimiliki pesanan.
     * @param  string  $message  Pesan validasi jika status tidak sesuai.
     * @return void Tidak mengubah database.
     *
     * @throws ValidationException Ketika status pesanan tidak sesuai.
     */
    private function ensureStatus(Order $order, OrderStatus $expected, string $message): void
    {
        if ($order->status !== $expected->value) {
            throw ValidationException::withMessages(['status' => [$message]]);
        }
    }
}
