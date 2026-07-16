<?php

declare(strict_types=1);

namespace App\Support;

/**
 * Helper kecil untuk memformat nilai integer rupiah tanpa mengubah nilai database.
 */
final class CurrencyFormatter
{
    /**
     * Mengubah nilai integer menjadi format rupiah Indonesia.
     *
     * @param  int  $amount  Nilai uang dalam integer.
     * @return string Nilai uang dalam format Rp5.000.
     */
    public static function rupiah(int $amount): string
    {
        return 'Rp'.number_format($amount, 0, ',', '.');
    }
}
