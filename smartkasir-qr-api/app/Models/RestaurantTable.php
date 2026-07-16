<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Model meja restoran yang nantinya dipakai untuk pemesanan melalui QR.
 *
 * @property int $id
 * @property string $name
 * @property string $code
 * @property string $qr_token
 * @property bool $is_active
 */
class RestaurantTable extends Model
{
    /**
     * Kolom meja yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'code',
        'qr_token',
        'is_active',
    ];

    /**
     * Kolom sensitif yang tidak ditampilkan pada JSON model mentah.
     *
     * @var list<string>
     */
    protected $hidden = [
        'qr_token',
    ];

    /**
     * Mengambil semua pesanan dari meja ini.
     *
     * @return HasMany<Order> Relasi pesanan meja.
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Mendefinisikan casting atribut RestaurantTable.
     *
     * @return array<string, string> Daftar cast atribut meja.
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
