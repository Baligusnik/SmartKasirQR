<?php

declare(strict_types=1);

namespace App\Http\Requests\PublicOrder;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Form Request untuk memvalidasi pesanan publik dari QR meja.
 */
class StorePublicOrderRequest extends FormRequest
{
    /**
     * Mengizinkan pelanggan publik mengirim pesanan meja.
     *
     * @return bool Selalu true karena endpoint publik memakai QR token sebagai konteks meja.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi pesanan publik.
     *
     * @return array<string, array<int, string>> Aturan validasi body request.
     */
    public function rules(): array
    {
        return [
            'customer_name' => ['nullable', 'string', 'max:100'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'items' => ['required', 'array', 'min:1', 'max:30'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }

    /**
     * Mengubah response validasi pesanan publik menjadi format API.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation(
            $validator->errors()->toArray(),
            'Data pesanan tidak valid.',
        ));
    }
}
