<?php

declare(strict_types=1);

namespace App\Http\Requests\Order;

use App\Enums\OrderStatus;
use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

/**
 * Form Request untuk memvalidasi filter daftar pesanan.
 */
class OrderIndexRequest extends FormRequest
{
    /**
     * Mengizinkan kasir terautentikasi membaca pesanan.
     *
     * @return bool Selalu true karena autentikasi ditangani middleware Sanctum.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi filter pesanan.
     *
     * @return array<string, array<int, mixed>> Aturan validasi query pesanan.
     */
    public function rules(): array
    {
        return [
            'status' => ['nullable', Rule::in(array_column(OrderStatus::cases(), 'value'))],
            'search' => ['nullable', 'string', 'max:150'],
        ];
    }

    /**
     * Mengubah response validasi filter pesanan menjadi format API.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation($validator->errors()->toArray()));
    }
}
