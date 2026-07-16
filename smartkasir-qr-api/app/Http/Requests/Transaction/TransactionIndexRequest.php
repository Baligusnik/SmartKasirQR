<?php

declare(strict_types=1);

namespace App\Http\Requests\Transaction;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Form Request untuk memvalidasi filter daftar transaksi.
 */
class TransactionIndexRequest extends FormRequest
{
    /**
     * Mengizinkan kasir terautentikasi membaca transaksi.
     *
     * @return bool Selalu true karena autentikasi ditangani middleware Sanctum.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi filter transaksi.
     *
     * @return array<string, array<int, string>> Aturan validasi query transaksi.
     */
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:150'],
            'date' => ['nullable', 'date_format:Y-m-d'],
        ];
    }

    /**
     * Mengubah response validasi filter transaksi menjadi format API.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation($validator->errors()->toArray()));
    }
}
