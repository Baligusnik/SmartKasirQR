<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Support\CurrencyFormatter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk membentuk data produk beserta kategori dan status pemesanan.
 *
 * @property int $id
 * @property int $price
 * @property int $stock
 * @property bool $is_available
 */
class ProductResource extends JsonResource
{
    /**
     * Mengubah model Product menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data produk yang aman ditampilkan ke aplikasi.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category' => [
                'id' => $this->category?->id,
                'name' => $this->category?->name,
            ],
            'name' => $this->name,
            'sku' => $this->sku,
            'description' => $this->description,
            'price' => $this->price,
            'price_formatted' => CurrencyFormatter::rupiah($this->price),
            'stock' => $this->stock,
            'unit' => $this->unit,
            'is_available' => $this->is_available,
            'can_be_ordered' => $this->canBeOrdered(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Menentukan apakah produk bisa dipesan berdasarkan stok, status produk, dan kategori aktif.
     *
     * @return bool True bila produk aktif, stok tersedia, dan kategori aktif.
     */
    private function canBeOrdered(): bool
    {
        return $this->is_available && $this->stock > 0 && (bool) $this->category?->is_active;
    }
}
