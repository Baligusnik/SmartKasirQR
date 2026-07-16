<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Order;
use App\Models\Transaction;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Service untuk membuat nomor unik yang mudah dibaca untuk order dan transaksi.
 */
class UniqueNumberService
{
    /**
     * Membuat nomor order unik dengan retry terbatas.
     *
     * @return string Nomor order dengan format ORD-YYYYMMDD-XXXXXX.
     *
     * @throws RuntimeException Ketika nomor unik gagal dibuat setelah beberapa percobaan.
     */
    public function orderNumber(): string
    {
        return $this->generate('ORD', Order::class, 'order_number');
    }

    /**
     * Membuat nomor transaksi unik dengan retry terbatas.
     *
     * @return string Nomor transaksi dengan format TRX-YYYYMMDD-XXXXXX.
     *
     * @throws RuntimeException Ketika nomor unik gagal dibuat setelah beberapa percobaan.
     */
    public function transactionNumber(): string
    {
        return $this->generate('TRX', Transaction::class, 'transaction_number');
    }

    /**
     * Membuat nomor unik berdasarkan prefix dan model target.
     *
     * @param  class-string  $modelClass  Nama class model yang akan diperiksa.
     * @param  string  $column  Kolom unique number pada model.
     * @return string Nomor unik yang belum ada di database.
     *
     * @throws RuntimeException Ketika retry habis karena collision.
     */
    private function generate(string $prefix, string $modelClass, string $column): string
    {
        for ($attempt = 0; $attempt < 10; $attempt++) {
            $number = sprintf('%s-%s-%s', $prefix, now()->format('Ymd'), Str::upper(Str::random(6)));

            if (! $modelClass::query()->where($column, $number)->exists()) {
                return $number;
            }
        }

        throw new RuntimeException('Nomor unik gagal dibuat.');
    }
}
