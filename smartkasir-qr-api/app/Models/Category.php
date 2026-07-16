<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Model kategori produk yang mengelompokkan menu kasir.
 *
 * @property int $id
 * @property string $name
 * @property string|null $description
 * @property bool $is_active
 */
class Category extends Model
{
    /**
     * Kolom yang dapat diisi secara massal.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'description',
        'is_active',
    ];

    /**
     * Mengambil semua produk dalam kategori ini.
     *
     * @return HasMany<Product> Relasi produk kategori.
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Mendefinisikan casting atribut Category.
     *
     * @return array<string, string> Daftar cast atribut kategori.
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
