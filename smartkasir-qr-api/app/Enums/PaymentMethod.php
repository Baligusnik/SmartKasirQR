<?php

declare(strict_types=1);

namespace App\Enums;

/**
 * Enum metode pembayaran yang disimpan sebagai string agar tetap kompatibel dengan SQLite.
 */
enum PaymentMethod: string
{
    case Cash = 'cash';

    /**
     * Mengembalikan label metode pembayaran berbahasa Indonesia.
     *
     * @return string Label metode pembayaran untuk response API.
     */
    public function label(): string
    {
        return match ($this) {
            self::Cash => 'Tunai',
        };
    }
}
