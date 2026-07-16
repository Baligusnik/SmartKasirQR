<?php

declare(strict_types=1);

namespace App\Http\Requests\Transaction;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

/**
 * Form Request untuk memvalidasi pembuatan transaksi kasir.
 */
class StoreTransactionRequest extends FormRequest
{
    /**
     * Mengizinkan kasir terautentikasi membuat transaksi.
     *
     * @return bool Selalu true karena autentikasi ditangani middleware Sanctum.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi transaksi langsung dan pembayaran pesanan QR.
     *
     * @return array<string, array<int, mixed>> Aturan validasi body request.
     */
    public function rules(): array
    {
        return [
            'order_id' => ['nullable', 'integer', 'exists:orders,id'],
            'paid_amount' => ['required', 'integer', 'min:0'],
            'payment_method' => ['required', Rule::in(['cash'])],
            'items' => ['nullable', 'array', 'min:1', 'max:30'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
        ];
    }

    /**
     * Menambahkan validasi kondisional untuk memilih order_id atau items.
     *
     * @return array<int, callable> Callback validator tambahan tanpa efek database.
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $hasOrder = $this->filled('order_id');
                $hasItems = $this->filled('items');

                if ($hasOrder && $hasItems) {
                    $validator->errors()->add('order_id', 'Pilih salah satu: bayar pesanan atau transaksi langsung.');
                    $validator->errors()->add('items', 'Item tidak boleh dikirim bersama pesanan QR.');
                }

                if (! $hasOrder && ! $hasItems) {
                    $validator->errors()->add('items', 'Pesanan atau item transaksi wajib diisi.');
                }
            },
        ];
    }

    /**
     * Mendefinisikan pesan validasi transaksi berbahasa Indonesia.
     *
     * @return array<string, string> Daftar pesan validasi per rule.
     */
    public function messages(): array
    {
        return [
            'paid_amount.required' => 'Jumlah pembayaran wajib diisi.',
            'paid_amount.min' => 'Jumlah pembayaran tidak boleh negatif.',
            'payment_method.required' => 'Metode pembayaran wajib diisi.',
            'payment_method.in' => 'Metode pembayaran tidak valid.',
        ];
    }

    /**
     * Mengubah response validasi transaksi menjadi format API.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation(
            $validator->errors()->toArray(),
            'Data transaksi tidak valid.',
        ));
    }
}
