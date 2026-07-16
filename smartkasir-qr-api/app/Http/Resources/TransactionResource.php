<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Enums\PaymentMethod;
use App\Support\CurrencyFormatter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk menampilkan data transaksi pembayaran.
 */
class TransactionResource extends JsonResource
{
    /**
     * Mengubah model Transaction menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data transaksi, kasir, pesanan, dan item bila dimuat.
     */
    public function toArray(Request $request): array
    {
        $paymentMethod = PaymentMethod::from($this->payment_method);

        return [
            'id' => $this->id,
            'transaction_number' => $this->transaction_number,
            'order_number' => $this->order?->order_number,
            'cashier' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ]),
            'total' => $this->total,
            'total_formatted' => CurrencyFormatter::rupiah($this->total),
            'paid_amount' => $this->paid_amount,
            'paid_amount_formatted' => CurrencyFormatter::rupiah($this->paid_amount),
            'change_amount' => $this->change_amount,
            'change_amount_formatted' => CurrencyFormatter::rupiah($this->change_amount),
            'payment_method' => $paymentMethod->value,
            'payment_method_label' => $paymentMethod->label(),
            'items_count' => $this->whenCounted('items'),
            'items' => TransactionItemResource::collection($this->whenLoaded('items'))->resolve(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
