<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Public;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\PublicOrder\StorePublicOrderRequest;
use App\Models\Order;
use App\Models\RestaurantTable;
use App\Services\OrderService;
use App\Support\ApiResponse;
use App\Support\CurrencyFormatter;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

/**
 * Controller publik untuk membuat pesanan meja dan melihat status aman.
 */
class PublicOrderController extends Controller
{
    /**
     * Membuat instance controller pesanan publik.
     *
     * @param  OrderService  $orderService  Service yang membuat pesanan publik.
     */
    public function __construct(private readonly OrderService $orderService) {}

    /**
     * Membuat pesanan publik dari QR meja aktif.
     *
     * @param  StorePublicOrderRequest  $request  Data pesanan publik yang sudah divalidasi.
     * @param  string  $qrToken  Token QR meja.
     * @return JsonResponse Ringkasan pesanan baru dengan status HTTP 201.
     */
    public function store(StorePublicOrderRequest $request, string $qrToken): JsonResponse
    {
        $table = RestaurantTable::query()
            ->where('qr_token', $qrToken)
            ->where('is_active', true)
            ->firstOrFail();

        try {
            $order = $this->orderService->createPublicOrder($table, $request->validated());
        } catch (ValidationException $exception) {
            return ApiResponse::validation($exception->errors(), 'Data pesanan tidak valid.');
        }

        $status = OrderStatus::from($order->status);

        return ApiResponse::success('Pesanan berhasil dikirim dan menunggu konfirmasi kasir.', [
            'order_number' => $order->order_number,
            'table' => $order->restaurantTable?->name,
            'status' => $status->value,
            'status_label' => $status->label(),
            'total' => $order->total,
            'total_formatted' => CurrencyFormatter::rupiah($order->total),
        ], 201);
    }

    /**
     * Menampilkan status publik pesanan berdasarkan nomor pesanan.
     *
     * @param  string  $orderNumber  Nomor pesanan yang diberikan kepada pelanggan.
     * @return JsonResponse Data aman status pesanan publik.
     */
    public function status(string $orderNumber): JsonResponse
    {
        $order = Order::query()
            ->with('restaurantTable')
            ->where('order_number', $orderNumber)
            ->firstOrFail();

        $status = OrderStatus::from($order->status);

        return ApiResponse::success('Status pesanan berhasil diambil.', [
            'order_number' => $order->order_number,
            'table' => $order->restaurantTable?->name,
            'status' => $status->value,
            'status_label' => $status->label(),
            'total' => $order->total,
            'total_formatted' => CurrencyFormatter::rupiah($order->total),
            'created_at' => $order->created_at?->toIso8601String(),
        ]);
    }
}
