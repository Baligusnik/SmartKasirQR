<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Enums\OrderStatus;
use App\Support\CurrencyFormatter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk menampilkan data pesanan kasir dan publik secara aman.
 */
class OrderResource extends JsonResource
{
    /**
     * Mengubah model Order menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data pesanan beserta meja dan item bila dimuat.
     */
    public function toArray(Request $request): array
    {
        $status = OrderStatus::from($this->status);

        return [
            'id' => $this->id,
            'order_number' => $this->order_number,
            'table' => $this->whenLoaded('restaurantTable', fn () => $this->tableData()),
            'customer_name' => $this->customer_name,
            'status' => $status->value,
            'status_label' => $status->label(),
            'notes' => $this->notes,
            'total' => $this->total,
            'total_formatted' => CurrencyFormatter::rupiah($this->total),
            'stock_deducted' => $this->stock_deducted_at !== null,
            'items_count' => $this->whenCounted('items'),
            'items' => OrderItemResource::collection($this->whenLoaded('items'))->resolve(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Membentuk data meja tanpa menampilkan QR token.
     *
     * @return array<string, mixed>|null Data meja aman untuk response API.
     */
    private function tableData(): ?array
    {
        if ($this->restaurantTable === null) {
            return null;
        }

        return [
            'id' => $this->restaurantTable->id,
            'name' => $this->restaurantTable->name,
            'code' => $this->restaurantTable->code,
        ];
    }
}
