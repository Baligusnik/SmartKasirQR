<?php

declare(strict_types=1);

namespace App\Http\Requests\Order;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Form Request untuk memvalidasi alasan pembatalan pesanan.
 */
class CancelOrderRequest extends FormRequest
{
    /**
     * Mengizinkan kasir terautentikasi membatalkan pesanan.
     *
     * @return bool Selalu true karena autentikasi ditangani middleware Sanctum.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi alasan pembatalan.
     *
     * @return array<string, array<int, string>> Aturan validasi body request.
     */
    public function rules(): array
    {
        return [
            'reason' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * Mengubah response validasi pembatalan menjadi format API.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation($validator->errors()->toArray()));
    }
}
