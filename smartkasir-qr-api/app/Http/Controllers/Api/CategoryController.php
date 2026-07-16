<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Controller API untuk membaca kategori aktif produk.
 */
class CategoryController extends Controller
{
    /**
     * Menampilkan daftar kategori aktif untuk dropdown produk.
     *
     * @return JsonResponse Daftar kategori aktif yang sudah diurutkan berdasarkan nama.
     */
    public function index(): JsonResponse
    {
        $categories = Category::query()
            ->where('is_active', true)
            ->withCount('products')
            ->orderBy('name')
            ->get();

        return ApiResponse::success(
            'Daftar kategori berhasil diambil.',
            CategoryResource::collection($categories)->resolve(),
        );
    }
}
