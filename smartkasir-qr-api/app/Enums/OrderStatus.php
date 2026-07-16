<?php

declare(strict_types=1);

namespace App\Enums;

/**
 * Enum status pesanan yang disimpan sebagai string agar tetap kompatibel dengan SQLite.
 */
enum OrderStatus: string
{
    case Pending = 'pending';
    case Confirmed = 'confirmed';
    case Processing = 'processing';
    case Ready = 'ready';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    /**
     * Mengembalikan label status pesanan berbahasa Indonesia.
     *
     * @return string Label status untuk response API.
     */
    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Menunggu',
            self::Confirmed => 'Dikonfirmasi',
            self::Processing => 'Diproses',
            self::Ready => 'Siap',
            self::Completed => 'Selesai',
            self::Cancelled => 'Dibatalkan',
        };
    }

    /**
     * Memeriksa apakah status dapat berpindah ke status berikutnya.
     *
     * @param  OrderStatus  $next  Status tujuan yang ingin diterapkan.
     * @return bool True bila transisi status diperbolehkan.
     */
    public function canTransitionTo(OrderStatus $next): bool
    {
        return in_array($next, match ($this) {
            self::Pending => [self::Confirmed, self::Cancelled],
            self::Confirmed => [self::Processing, self::Cancelled],
            self::Processing => [self::Ready, self::Cancelled],
            self::Ready => [self::Completed, self::Cancelled],
            self::Completed, self::Cancelled => [],
        }, true);
    }
}
