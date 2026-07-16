<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk membentuk data kategori yang aman dikonsumsi Flutter.
 *
 * @property int $id
 * @property string $name
 * @property string|null $description
 * @property bool $is_active
 */
class CategoryResource extends JsonResource
{
    /**
     * Mengubah model Category menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data kategori termasuk jumlah produk bila dimuat.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'products_count' => $this->whenCounted('products'),
        ];
    }
}
