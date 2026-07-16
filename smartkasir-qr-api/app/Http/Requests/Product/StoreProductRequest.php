<?php

declare(strict_types=1);

namespace App\Http\Requests\Product;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

/**
 * Form Request untuk memvalidasi data pembuatan produk baru.
 */
class StoreProductRequest extends FormRequest
{
    /**
     * Mengizinkan pengguna terautentikasi menambah produk.
     *
     * @return bool Selalu true karena middleware Sanctum menangani autentikasi.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Menormalisasi input sebelum validasi dijalankan.
     *
     * @return void Method ini mengubah SKU menjadi huruf kapital dan memangkas spasi berlebih.
     */
    protected function prepareForValidation(): void
    {
        $sku = $this->input('sku');

        if (is_string($sku)) {
            $this->merge([
                'sku' => strtoupper(trim(preg_replace('/\s+/', ' ', $sku) ?? $sku)),
            ]);
        }
    }

    /**
     * Mendefinisikan aturan validasi data produk baru.
     *
     * @return array<string, array<int, mixed>> Daftar aturan validasi per field.
     */
    public function rules(): array
    {
        return [
            'category_id' => [
                'required',
                'integer',
                Rule::exists('categories', 'id')->where('is_active', true),
            ],
            'name' => ['required', 'string', 'max:150'],
            'sku' => ['required', 'string', 'max:50', 'unique:products,sku'],
            'description' => ['nullable', 'string', 'max:1000'],
            'price' => ['required', 'integer', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'unit' => ['required', 'string', 'max:30'],
            'is_available' => ['required', 'boolean'],
        ];
    }

    /**
     * Mendefinisikan pesan validasi produk berbahasa Indonesia.
     *
     * @return array<string, string> Daftar pesan validasi per rule.
     */
    public function messages(): array
    {
        return [
            'category_id.required' => 'Kategori wajib dipilih.',
            'category_id.integer' => 'Kategori harus berupa angka.',
            'category_id.exists' => 'Kategori tidak ditemukan atau tidak aktif.',
            'name.required' => 'Nama produk wajib diisi.',
            'name.string' => 'Nama produk harus berupa teks.',
            'name.max' => 'Nama produk maksimal 150 karakter.',
            'sku.required' => 'SKU wajib diisi.',
            'sku.string' => 'SKU harus berupa teks.',
            'sku.max' => 'SKU maksimal 50 karakter.',
            'sku.unique' => 'SKU sudah digunakan.',
            'description.string' => 'Deskripsi harus berupa teks.',
            'description.max' => 'Deskripsi maksimal 1000 karakter.',
            'price.required' => 'Harga wajib diisi.',
            'price.integer' => 'Harga harus berupa angka.',
            'price.min' => 'Harga tidak boleh negatif.',
            'stock.required' => 'Stok wajib diisi.',
            'stock.integer' => 'Stok harus berupa angka.',
            'stock.min' => 'Stok tidak boleh negatif.',
            'unit.required' => 'Satuan wajib diisi.',
            'unit.string' => 'Satuan harus berupa teks.',
            'unit.max' => 'Satuan maksimal 30 karakter.',
            'is_available.required' => 'Status ketersediaan wajib diisi.',
            'is_available.boolean' => 'Status ketersediaan harus bernilai benar atau salah.',
        ];
    }

    /**
     * Mengubah response validasi default menjadi pesan khusus produk.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Data produk tidak valid.',
            'errors' => $validator->errors()->toArray(),
        ], 422));
    }
}
