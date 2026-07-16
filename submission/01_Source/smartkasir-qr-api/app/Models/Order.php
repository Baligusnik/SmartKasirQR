<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Model pesanan pelanggan dari kasir atau meja QR.
 *
 * @property int $id
 * @property int|null $restaurant_table_id
 * @property string $order_number
 * @property string $status
 * @property int $total
 */
class Order extends Model
{
    /**
     * Status pesanan yang disiapkan untuk tahap aplikasi berikutnya.
     *
     * @var list<string>
     */
    public const STATUSES = [
        'pending',
        'confirmed',
        'processing',
        'ready',
        'completed',
        'cancelled',
    ];

    /**
     * Kolom pesanan yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'restaurant_table_id',
        'order_number',
        'customer_name',
        'status',
        'notes',
        'total',
        'stock_deducted_at',
    ];

    /**
     * Mengambil meja restoran bila pesanan berasal dari QR.
     *
     * @return BelongsTo<RestaurantTable, Order> Relasi meja pesanan.
     */
    public function restaurantTable(): BelongsTo
    {
        return $this->belongsTo(RestaurantTable::class);
    }

    /**
     * Mengambil semua item dalam pesanan.
     *
     * @return HasMany<OrderItem> Relasi item pesanan.
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Mengambil transaksi yang dibuat dari pesanan ini.
     *
     * @return HasOne<Transaction> Relasi transaksi pesanan.
     */
    public function transaction(): HasOne
    {
        return $this->hasOne(Transaction::class);
    }

    /**
     * Mendefinisikan casting atribut Order.
     *
     * @return array<string, string> Daftar cast atribut pesanan.
     */
    protected function casts(): array
    {
        return [
            'total' => 'integer',
            'stock_deducted_at' => 'datetime',
        ];
    }
}
