<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Form Request untuk memvalidasi data login kasir.
 */
class LoginRequest extends FormRequest
{
    /**
     * Mengizinkan semua pengguna mengirim request login.
     *
     * @return bool Selalu true karena autentikasi belum tersedia saat login.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Mendefinisikan aturan validasi input login.
     *
     * @return array<string, array<int, string>> Daftar aturan validasi per field.
     */
    public function rules(): array
    {
        return [
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * Mendefinisikan pesan validasi berbahasa Indonesia.
     *
     * @return array<string, string> Daftar pesan validasi per rule.
     */
    public function messages(): array
    {
        return [
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
            'password.string' => 'Password harus berupa teks.',
            'device_name.string' => 'Nama perangkat harus berupa teks.',
            'device_name.max' => 'Nama perangkat maksimal 100 karakter.',
        ];
    }

    /**
     * Mengubah response validasi default Laravel menjadi format API standar.
     *
     * @param  Validator  $validator  Validator yang berisi error validasi.
     * @return never Method selalu menghentikan request dengan exception response.
     */
    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(ApiResponse::validation($validator->errors()->toArray()));
    }
}
