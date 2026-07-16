<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\RestaurantTable;
use App\Support\ApiResponse;
use App\Support\CurrencyFormatter;
use Illuminate\Http\JsonResponse;

/**
 * Controller publik untuk menampilkan menu meja berdasarkan QR token.
 */
class PublicMenuController extends Controller
{
    /**
     * Menampilkan menu produk yang dapat dipesan dari meja aktif.
     *
     * @param  string  $qrToken  Token QR meja yang tidak mudah ditebak.
     * @return JsonResponse Data meja dan kategori produk yang tersedia.
     */
    public function show(string $qrToken): JsonResponse
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
            ->get()
            ->map(fn ($category) => [
                'id' => $category->id,
                'name' => $category->name,
                'products' => $category->products->map(fn ($product) => [
                    'id' => $product->id,
                    'name' => $product->name,
                    'description' => $product->description,
                    'price' => $product->price,
                    'price_formatted' => CurrencyFormatter::rupiah($product->price),
                    'stock' => $product->stock,
                    'unit' => $product->unit,
                ])->values(),
            ])
            ->values();

        return ApiResponse::success('Menu berhasil diambil.', [
            'table' => [
                'name' => $table->name,
                'code' => $table->code,
            ],
            'categories' => $categories,
        ]);
    }
}
