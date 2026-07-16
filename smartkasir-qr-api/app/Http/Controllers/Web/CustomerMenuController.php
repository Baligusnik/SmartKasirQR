<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\RestaurantTable;
use App\Support\CurrencyFormatter;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Collection;

/**
 * Controller web untuk halaman menu pelanggan berdasarkan QR token meja.
 */
class CustomerMenuController extends Controller
{
    /**
     * Menampilkan halaman menu pelanggan berdasarkan QR token meja.
     *
     * @param  string  $qrToken  Token unik meja yang dipindai pelanggan.
     * @return View Halaman menu pelanggan mobile-first.
     */
    public function show(string $qrToken): View
    {
        $table = RestaurantTable::query()
            ->where('qr_token', $qrToken)
            ->where('is_active', true)
            ->firstOrFail();

        $categories = Category::query()
            ->where('is_active', true)
            ->whereHas('products', fn ($query) => $query
                ->where('is_available', true)
                ->where('stock', '>', 0))
            ->with(['products' => fn ($query) => $query
                ->where('is_available', true)
                ->where('stock', '>', 0)
                ->orderBy('name')])
            ->orderBy('name')
            ->get();

        return view('customer.menu', [
            'table' => $table,
            'categories' => $categories,
            'qrToken' => $qrToken,
            'productsPayload' => $this->productsPayload($categories->flatMap->products),
        ]);
    }

    /**
     * Menampilkan halaman keranjang pelanggan untuk meja tertentu.
     *
     * @param  string  $qrToken  Token unik meja yang dipindai pelanggan.
     * @return View Halaman keranjang dengan data menu untuk validasi tampilan.
     */
    public function cart(string $qrToken): View
    {
        $table = RestaurantTable::query()
            ->where('qr_token', $qrToken)
            ->where('is_active', true)
            ->firstOrFail();

        $products = Category::query()
            ->where('is_active', true)
            ->with(['products' => fn ($query) => $query
                ->where('is_available', true)
                ->where('stock', '>', 0)
                ->orderBy('name')])
            ->get()
            ->flatMap(fn ($category) => $category->products)
            ->values();

        return view('customer.cart', [
            'table' => $table,
            'products' => $products,
            'qrToken' => $qrToken,
            'productsPayload' => $this->productsPayload($products),
        ]);
    }

    /**
     * Membentuk payload produk aman untuk JavaScript keranjang.
     *
     * @param  Collection<int, mixed>  $products  Koleksi produk aktif yang tersedia.
     * @return array<int, array<string, mixed>> Data produk tanpa field sensitif.
     */
    private function productsPayload(Collection $products): array
    {
        return $products
            ->map(fn ($product) => [
                'id' => $product->id,
                'name' => $product->name,
                'category' => $product->category?->name,
                'price' => $product->price,
                'price_formatted' => CurrencyFormatter::rupiah($product->price),
                'stock' => $product->stock,
                'unit' => $product->unit,
            ])
            ->values()
            ->all();
    }
}
