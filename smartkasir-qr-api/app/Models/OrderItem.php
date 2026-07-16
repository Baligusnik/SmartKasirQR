<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Model rincian produk pada sebuah pesanan.
 *
 * @property int $id
 * @property int $order_id
 * @property int $product_id
 * @property int $quantity
 * @property int $price
 * @property int $subtotal
 */
class OrderItem extends Model
{
    /**
     * Kolom item pesanan yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'order_id',
        'product_id',
        'quantity',
        'price',
        'subtotal',
        'notes',
    ];

    /**
     * Mengambil pesanan pemilik item ini.
     *
     * @return BelongsTo<Order, OrderItem> Relasi pesanan.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Mengambil produk pada item pesanan ini.
     *
     * @return BelongsTo<Product, OrderItem> Relasi produk.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Mendefinisikan casting atribut OrderItem.
     *
     * @return array<string, string> Daftar cast atribut item pesanan.
     */
    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'price' => 'integer',
            'subtotal' => 'integer',
        ];
    }
}
