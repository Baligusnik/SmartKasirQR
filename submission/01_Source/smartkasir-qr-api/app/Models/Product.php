<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Model produk yang dijual melalui kasir SmartKasir QR.
 *
 * @property int $id
 * @property int $category_id
 * @property string $name
 * @property string $sku
 * @property int $price
 * @property int $stock
 * @property string $unit
 * @property bool $is_available
 */
class Product extends Model
{
    /**
     * Kolom produk yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'category_id',
        'name',
        'sku',
        'description',
        'price',
        'stock',
        'unit',
        'is_available',
    ];

    /**
     * Mengambil kategori pemilik produk.
     *
     * @return BelongsTo<Category, Product> Relasi kategori produk.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Mengambil item pesanan yang memakai produk ini.
     *
     * @return HasMany<OrderItem> Relasi item pesanan produk.
     */
    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Mengambil item transaksi yang memakai produk ini.
     *
     * @return HasMany<TransactionItem> Relasi item transaksi produk.
     */
    public function transactionItems(): HasMany
    {
        return $this->hasMany(TransactionItem::class);
    }

    /**
     * Mendefinisikan casting atribut Product.
     *
     * @return array<string, string> Daftar cast atribut produk.
     */
    protected function casts(): array
    {
        return [
            'price' => 'integer',
            'stock' => 'integer',
            'is_available' => 'boolean',
        ];
    }
}
