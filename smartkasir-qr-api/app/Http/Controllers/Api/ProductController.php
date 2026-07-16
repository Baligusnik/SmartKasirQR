<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Product\ProductIndexRequest;
use App\Http\Requests\Product\StoreProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Services\ProductService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Controller API untuk membaca dan menambahkan produk.
 */
class ProductController extends Controller
{
    /**
     * Membuat instance controller dengan dependency service produk.
     *
     * @param  ProductService  $productService  Service yang menangani query dan pembuatan produk.
     */
    public function __construct(private readonly ProductService $productService) {}

    /**
     * Menampilkan daftar produk beserta kategori dan status ketersediaannya.
     *
     * @param  ProductIndexRequest  $request  Data filter pencarian produk yang telah divalidasi.
     * @return JsonResponse Daftar produk yang berhasil ditemukan.
     */
    public function index(ProductIndexRequest $request): JsonResponse
    {
        $products = $this->productService->list($request->validated());

        return ApiResponse::success(
            'Daftar produk berhasil diambil.',
            ProductResource::collection($products)->resolve(),
        );
    }

    /**
     * Menampilkan detail satu produk berdasarkan route model binding.
     *
     * @param  Product  $product  Produk yang ditemukan oleh Laravel route model binding.
     * @return JsonResponse Detail produk beserta kategori.
     */
    public function show(Product $product): JsonResponse
    {
        $product->load('category');

        return ApiResponse::success(
            'Detail produk berhasil diambil.',
            (new ProductResource($product))->resolve(),
        );
    }

    /**
     * Menambahkan produk baru menggunakan data tervalidasi.
     *
     * @param  StoreProductRequest  $request  Data produk baru yang telah divalidasi.
     * @return JsonResponse Produk yang berhasil dibuat dengan status HTTP 201.
     */
    public function store(StoreProductRequest $request): JsonResponse
    {
        $product = $this->productService->create($request->validated());

        return ApiResponse::success(
            'Produk berhasil ditambahkan.',
            (new ProductResource($product))->resolve(),
            201,
        );
    }
}
