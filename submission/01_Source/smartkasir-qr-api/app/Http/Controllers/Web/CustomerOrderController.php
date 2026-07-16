<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\PublicOrder\StorePublicOrderRequest;
use App\Models\Order;
use App\Models\RestaurantTable;
use App\Services\OrderService;
use App\Support\CurrencyFormatter;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Validation\ValidationException;

/**
 * Controller web untuk pembuatan pesanan pelanggan dan halaman status pesanan.
 */
class CustomerOrderController extends Controller
{
    /**
     * Membuat instance controller pesanan pelanggan.
     *
     * @param  OrderService  $orderService  Service pesanan yang menghitung harga dan membuat order_items.
     */
    public function __construct(private readonly OrderService $orderService) {}

    /**
     * Menyimpan pesanan pelanggan dari halaman QR.
     *
     * @param  StorePublicOrderRequest  $request  Data pesanan yang telah divalidasi.
     * @param  string  $qrToken  Token unik meja aktif.
     * @return JsonResponse|RedirectResponse Response JSON untuk fetch atau redirect untuk form biasa.
     */
    public function store(StorePublicOrderRequest $request, string $qrToken): JsonResponse|RedirectResponse
    {
        $table = RestaurantTable::query()
            ->where('qr_token', $qrToken)
            ->where('is_active', true)
            ->firstOrFail();

        try {
            $order = $this->orderService->createPublicOrder($table, $request->validated());
        } catch (ValidationException $exception) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan belum dapat dikirim. Silakan periksa kembali keranjang.',
                    'errors' => $exception->errors(),
                ], 422);
            }

            return back()->withErrors($exception->errors())->withInput();
        }

        $successUrl = route('order.success', ['orderNumber' => $order->order_number]);

        if ($request->expectsJson()) {
            return response()->json([
                'success' => true,
                'message' => 'Pesanan berhasil dikirim.',
                'redirect_url' => $successUrl,
                'order_number' => $order->order_number,
            ], 201);
        }

        return redirect()->to($successUrl);
    }

    /**
     * Menampilkan halaman sukses setelah pesanan dibuat.
     *
     * @param  string  $orderNumber  Nomor pesanan publik.
     * @return View Halaman sukses pesanan.
     */
    public function success(string $orderNumber): View
    {
        $order = Order::query()
            ->with('restaurantTable')
            ->where('order_number', $orderNumber)
            ->firstOrFail();

        return view('customer.order-success', [
            'order' => $order,
            'status' => OrderStatus::from($order->status),
            'totalFormatted' => CurrencyFormatter::rupiah($order->total),
        ]);
    }

    /**
     * Menampilkan halaman status pesanan pelanggan.
     *
     * @param  string  $orderNumber  Nomor pesanan publik.
     * @return View Halaman status pesanan.
     */
    public function status(string $orderNumber): View
    {
        $order = Order::query()
            ->with('restaurantTable')
            ->where('order_number', $orderNumber)
            ->firstOrFail();

        return view('customer.order-status', [
            'order' => $order,
            'status' => OrderStatus::from($order->status),
            'totalFormatted' => CurrencyFormatter::rupiah($order->total),
        ]);
    }

    /**
     * Mengarahkan pelanggan kembali ke menu meja dari halaman sukses pesanan.
     *
     * @param  string  $orderNumber  Nomor pesanan publik yang dipakai untuk menemukan meja.
     * @return RedirectResponse Redirect menuju menu meja atau root jika meja tidak tersedia.
     */
    public function menu(string $orderNumber): RedirectResponse
    {
        $order = Order::query()
            ->with('restaurantTable')
            ->where('order_number', $orderNumber)
            ->firstOrFail();

        if ($order->restaurantTable === null || ! $order->restaurantTable->is_active) {
            return redirect('/');
        }

        return redirect()->route('menu.show', ['qrToken' => $order->restaurantTable->qr_token]);
    }
}
