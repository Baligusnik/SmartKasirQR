<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Product;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Service untuk pencarian dan pembuatan produk SmartKasir QR.
 */
class ProductService
{
    /**
     * Mengambil daftar produk dengan filter pencarian, kategori, dan ketersediaan.
     *
     * @param  array{search?: string|null, category_id?: int|string|null, available?: string|null}  $filters  Filter tervalidasi dari query.
     * @return Collection<int, Product> Koleksi produk dengan relasi kategori yang sudah dimuat.
     */
    public function list(array $filters): Collection
    {
        $query = Product::query()
            ->with('category')
            ->orderBy('name')
            ->orderBy('sku');

        if (! empty($filters['search'])) {
            $search = trim((string) $filters['search']);

            $query->where(function ($query) use ($search): void {
                $query
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('sku', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['category_id'])) {
            $query->where('category_id', (int) $filters['category_id']);
        }

        if (array_key_exists('available', $filters) && $filters['available'] !== null) {
            $available = in_array($filters['available'], ['1', 'true'], true);

            if ($available) {
                $query
                    ->where('is_available', true)
                    ->where('stock', '>', 0)
                    ->whereHas('category', fn ($query) => $query->where('is_active', true));
            } else {
                $query->where(function ($query): void {
                    $query
                        ->where('is_available', false)
                        ->orWhere('stock', '<=', 0)
                        ->orWhereHas('category', fn ($query) => $query->where('is_active', false));
                });
            }
        }

        return $query->get();
    }

    /**
     * Menyimpan produk baru menggunakan data validasi yang sudah dinormalisasi.
     *
     * @param  array<string, mixed>  $data  Data produk tervalidasi dari StoreProductRequest.
     * @return Product Produk baru dengan relasi kategori yang sudah dimuat.
     */
    public function create(array $data): Product
    {
        return DB::transaction(function () use ($data): Product {
            $product = Product::query()->create([
                'category_id' => $data['category_id'],
                'name' => trim((string) $data['name']),
                'sku' => trim((string) $data['sku']),
                'description' => $data['description'] ?? null,
                'price' => $data['price'],
                'stock' => $data['stock'],
                'unit' => trim((string) $data['unit']),
                'is_available' => $data['is_available'],
            ]);

            return $product->load('category');
        });
    }
}
