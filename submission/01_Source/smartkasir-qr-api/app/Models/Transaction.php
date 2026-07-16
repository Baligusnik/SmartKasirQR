<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Model transaksi pembayaran yang dibuat oleh kasir.
 *
 * @property int $id
 * @property int|null $order_id
 * @property int $user_id
 * @property string $transaction_number
 * @property int $total
 * @property string $payment_method
 */
class Transaction extends Model
{
    /**
     * Metode pembayaran awal yang didukung.
     *
     * @var list<string>
     */
    public const PAYMENT_METHODS = [
        'cash',
    ];

    /**
     * Kolom transaksi yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'order_id',
        'user_id',
        'transaction_number',
        'total',
        'paid_amount',
        'change_amount',
        'payment_method',
    ];

    /**
     * Mengambil pesanan asal transaksi bila ada.
     *
     * @return BelongsTo<Order, Transaction> Relasi pesanan transaksi.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Mengambil kasir yang membuat transaksi.
     *
     * @return BelongsTo<User, Transaction> Relasi pengguna transaksi.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Mengambil semua item produk dalam transaksi.
     *
     * @return HasMany<TransactionItem> Relasi item transaksi.
     */
    public function items(): HasMany
    {
        return $this->hasMany(TransactionItem::class);
    }

    /**
     * Mendefinisikan casting atribut Transaction.
     *
     * @return array<string, string> Daftar cast atribut transaksi.
     */
    protected function casts(): array
    {
        return [
            'total' => 'integer',
            'paid_amount' => 'integer',
            'change_amount' => 'integer',
        ];
    }
}
