<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Support\CurrencyFormatter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk menampilkan rincian item pesanan.
 */
class OrderItemResource extends JsonResource
{
    /**
     * Mengubah model OrderItem menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data item pesanan dengan snapshot harga.
     */
    public function toArray(Request $request): array
    {
        return [
            'product_id' => $this->product_id,
            'product_name' => $this->product?->name,
            'quantity' => $this->quantity,
            'price' => $this->price,
            'price_formatted' => CurrencyFormatter::rupiah($this->price),
            'subtotal' => $this->subtotal,
            'subtotal_formatted' => CurrencyFormatter::rupiah($this->subtotal),
            'notes' => $this->notes,
        ];
    }
}
