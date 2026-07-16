<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Product;
use App\Models\Transaction;
use App\Support\CurrencyFormatter;

/**
 * Service untuk menghitung ringkasan dashboard kasir.
 */
class DashboardService
{
    /**
     * Mengambil data dashboard kasir berdasarkan tanggal aplikasi.
     *
     * @return array<string, mixed> Ringkasan pesanan, transaksi hari ini, produk, dan pesanan terbaru.
     */
    public function summary(): array
    {
        $today = now()->toDateString();
        $todayRevenue = (int) Transaction::query()->whereDate('created_at', $today)->sum('total');

        $recentOrders = Order::query()
            ->with(['restaurantTable', 'items.product'])
            ->withCount('items')
            ->latest()
            ->limit(5)
            ->get();

        return [
            'orders' => [
                'pending' => $this->countOrders(OrderStatus::Pending),
                'confirmed' => $this->countOrders(OrderStatus::Confirmed),
                'processing' => $this->countOrders(OrderStatus::Processing),
                'ready' => $this->countOrders(OrderStatus::Ready),
            ],
            'today' => [
                'transactions' => Transaction::query()->whereDate('created_at', $today)->count(),
                'revenue' => $todayRevenue,
                'revenue_formatted' => CurrencyFormatter::rupiah($todayRevenue),
            ],
            'products' => [
                'total_active' => Product::query()->where('is_available', true)->count(),
                'low_stock' => Product::query()->where('stock', '<=', 5)->count(),
            ],
            'recent_orders' => OrderResource::collection($recentOrders)->resolve(),
        ];
    }

    /**
     * Menghitung jumlah pesanan berdasarkan status tertentu.
     *
     * @param  OrderStatus  $status  Status pesanan yang dihitung.
     * @return int Jumlah pesanan pada status tersebut.
     */
    private function countOrders(OrderStatus $status): int
    {
        return Order::query()->where('status', $status->value)->count();
    }
}
