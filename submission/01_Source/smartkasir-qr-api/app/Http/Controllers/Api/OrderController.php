<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Order\CancelOrderRequest;
use App\Http\Requests\Order\OrderIndexRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Services\OrderService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

/**
 * Controller API untuk daftar, detail, dan perubahan status pesanan.
 */
class OrderController extends Controller
{
    /**
     * Membuat instance controller pesanan.
     *
     * @param  OrderService  $orderService  Service yang menangani logika pesanan dan stok.
     */
    public function __construct(private readonly OrderService $orderService) {}

    /**
     * Menampilkan daftar pesanan dengan filter status dan pencarian.
     *
     * @param  OrderIndexRequest  $request  Query filter pesanan yang sudah divalidasi.
     * @return JsonResponse Daftar pesanan terbaru.
     */
    public function index(OrderIndexRequest $request): JsonResponse
    {
        $orders = $this->orderService->list($request->validated());

        return ApiResponse::success(
            'Daftar pesanan berhasil diambil.',
            OrderResource::collection($orders)->resolve(),
        );
    }

    /**
     * Menampilkan detail pesanan beserta item.
     *
     * @param  Order  $order  Pesanan dari route model binding.
     * @return JsonResponse Detail pesanan yang berhasil ditemukan.
     */
    public function show(Order $order): JsonResponse
    {
        $order->load(['restaurantTable', 'items.product'])->loadCount('items');

        return ApiResponse::success(
            'Detail pesanan berhasil diambil.',
            (new OrderResource($order))->resolve(),
        );
    }

    /**
     * Mengonfirmasi pesanan pending dan mengurangi stok.
     *
     * @param  Order  $order  Pesanan yang akan dikonfirmasi.
     * @return JsonResponse Detail pesanan setelah dikonfirmasi.
     */
    public function confirm(Order $order): JsonResponse
    {
        try {
            $order = $this->orderService->confirm($order)->loadCount('items');
        } catch (ValidationException $exception) {
            return ApiResponse::validation(
                $exception->errors(),
                $exception->errors()['items'] ?? false
                    ? 'Pesanan tidak dapat dikonfirmasi karena stok tidak mencukupi.'
                    : 'Pesanan tidak dapat dikonfirmasi.',
            );
        }

        return ApiResponse::success('Pesanan berhasil dikonfirmasi.', (new OrderResource($order))->resolve());
    }

    /**
     * Mengubah pesanan confirmed menjadi processing.
     *
     * @param  Order  $order  Pesanan yang akan diproses.
     * @return JsonResponse Detail pesanan setelah diproses.
     */
    public function process(Order $order): JsonResponse
    {
        return $this->transition($order, OrderStatus::Processing, 'Pesanan berhasil diproses.');
    }

    /**
     * Mengubah pesanan processing menjadi ready.
     *
     * @param  Order  $order  Pesanan yang ditandai siap.
     * @return JsonResponse Detail pesanan setelah siap.
     */
    public function ready(Order $order): JsonResponse
    {
        return $this->transition($order, OrderStatus::Ready, 'Pesanan berhasil ditandai siap.');
    }

    /**
     * Membatalkan pesanan dan mengembalikan stok bila diperlukan.
     *
     * @param  CancelOrderRequest  $request  Data alasan pembatalan yang sudah divalidasi.
     * @param  Order  $order  Pesanan yang akan dibatalkan.
     * @return JsonResponse Detail pesanan setelah dibatalkan.
     */
    public function cancel(CancelOrderRequest $request, Order $order): JsonResponse
    {
        try {
            $order = $this->orderService
                ->cancel($order, $request->validated('reason'))
                ->loadCount('items');
        } catch (ValidationException $exception) {
            return ApiResponse::validation($exception->errors(), 'Pesanan tidak dapat dibatalkan.');
        }

        return ApiResponse::success('Pesanan berhasil dibatalkan.', (new OrderResource($order))->resolve());
    }

    /**
     * Menjalankan transisi status pesanan yang tidak mengubah stok.
     *
     * @param  Order  $order  Pesanan yang akan diubah.
     * @param  OrderStatus  $status  Status tujuan.
     * @param  string  $message  Pesan sukses untuk response.
     * @return JsonResponse Response detail pesanan atau error validasi.
     */
    private function transition(Order $order, OrderStatus $status, string $message): JsonResponse
    {
        try {
            $order = $this->orderService->transition($order, $status)->loadCount('items');
        } catch (ValidationException $exception) {
            return ApiResponse::validation($exception->errors(), 'Pesanan tidak dapat diproses.');
        }

        return ApiResponse::success($message, (new OrderResource($order))->resolve());
    }
}
