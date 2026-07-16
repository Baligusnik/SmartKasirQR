<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Controller API untuk ringkasan dashboard kasir.
 */
class DashboardController extends Controller
{
    /**
     * Membuat instance controller dashboard.
     *
     * @param  DashboardService  $dashboardService  Service penghitung data dashboard.
     */
    public function __construct(private readonly DashboardService $dashboardService) {}

    /**
     * Menampilkan data dashboard kasir.
     *
     * @return JsonResponse Ringkasan pesanan, transaksi hari ini, produk, dan pesanan terbaru.
     */
    public function __invoke(): JsonResponse
    {
        return ApiResponse::success('Data dashboard berhasil diambil.', $this->dashboardService->summary());
    }
}
