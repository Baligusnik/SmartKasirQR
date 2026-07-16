<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Model rincian produk pada transaksi pembayaran.
 *
 * @property int $id
 * @property int $transaction_id
 * @property int $product_id
 * @property int $quantity
 * @property int $price
 * @property int $subtotal
 */
class TransactionItem extends Model
{
    /**
     * Kolom item transaksi yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'transaction_id',
        'product_id',
        'quantity',
        'price',
        'subtotal',
    ];

    /**
     * Mengambil transaksi pemilik item ini.
     *
     * @return BelongsTo<Transaction, TransactionItem> Relasi transaksi.
     */
    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }

    /**
     * Mengambil produk pada item transaksi ini.
     *
     * @return BelongsTo<Product, TransactionItem> Relasi produk.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Mendefinisikan casting atribut TransactionItem.
     *
     * @return array<string, string> Daftar cast atribut item transaksi.
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
