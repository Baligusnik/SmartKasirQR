<?php

declare(strict_types=1);

namespace App\Http\Requests\Product;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

/**
 * Form Request untuk memvalidasi query daftar produk.
 */
class ProductIndexRequest extends FormRequest
{
    /**
     * Mengizinkan pengguna terautentikasi membaca daftar produk.
     *
     * @return bool Selalu true karena middleware Sanctum menangani autentikasi.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi filter produk.
     *
     * @return array<string, array<int, mixed>> Daftar aturan validasi query.
     */
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:150'],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
            'available' => ['nullable', Rule::in(['1', '0', 'true', 'false'])],
        ];
    }

    /**
     * Mendefinisikan pesan validasi filter berbahasa Indonesia.
     *
     * @return array<string, string> Daftar pesan validasi per rule.
     */
    public function messages(): array
    {
        return [
            'search.string' => 'Pencarian harus berupa teks.',
            'search.max' => 'Pencarian maksimal 150 karakter.',
            'category_id.integer' => 'Kategori harus berupa angka.',
            'category_id.exists' => 'Kategori tidak ditemukan.',
            'available.in' => 'Filter ketersediaan tidak valid.',
        ];
    }

    /**
     * Mengubah response validasi default menjadi format API standar.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation($validator->errors()->toArray()));
    }
}
