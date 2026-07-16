<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\RestaurantTable;
use App\Services\QrCodeService;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;

/**
 * Controller web untuk daftar dan cetak QR Code meja.
 */
class TableQrController extends Controller
{
    /**
     * Membuat instance controller QR meja.
     *
     * @param  QrCodeService  $qrCodeService  Service pembuat SVG QR Code.
     */
    public function __construct(private readonly QrCodeService $qrCodeService) {}

    /**
     * Menampilkan daftar QR Code meja aktif.
     *
     * @param  Request  $request  Request untuk menentukan host URL menu.
     * @return View Halaman daftar QR Code meja.
     */
    public function index(Request $request): View
    {
        return view('qr.index', [
            'tables' => $this->tablesWithQr($request),
        ]);
    }

    /**
     * Menampilkan halaman cetak QR Code meja aktif.
     *
     * @param  Request  $request  Request untuk menentukan host URL menu.
     * @return View Halaman cetak QR Code meja.
     */
    public function print(Request $request): View
    {
        return view('qr.print', [
            'tables' => $this->tablesWithQr($request),
        ]);
    }

    /**
     * Mengambil meja aktif dan menambahkan URL menu serta SVG QR.
     *
     * @param  Request  $request  Request saat ini untuk menentukan base URL.
     * @return Collection<int, RestaurantTable> Koleksi meja aktif dengan atribut menu_url dan qr_svg.
     */
    private function tablesWithQr(Request $request): Collection
    {
        return RestaurantTable::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(function (RestaurantTable $table) use ($request): RestaurantTable {
                $url = route('menu.show', ['qrToken' => $table->qr_token], true);

                if (config('app.url') === 'http://localhost') {
                    $url = $request->getSchemeAndHttpHost().route('menu.show', ['qrToken' => $table->qr_token], false);
                }

                $table->setAttribute('menu_url', $url);
                $table->setAttribute('qr_svg', $this->qrCodeService->svg($url));

                return $table;
            });
    }
}
