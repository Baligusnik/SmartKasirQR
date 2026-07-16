<?php

declare(strict_types=1);

namespace App\Support;

use Illuminate\Http\JsonResponse;

/**
 * Helper untuk membentuk response JSON API yang konsisten.
 */
final class ApiResponse
{
    /**
     * Membuat response sukses dengan format standar SmartKasir QR.
     *
     * @param  string  $message  Pesan yang aman ditampilkan kepada pengguna.
     * @param  mixed|null  $data  Data response, atau null bila tidak ada.
     * @param  int  $status  HTTP status code sukses.
     * @return JsonResponse Response JSON berisi success, message, dan data.
     */
    public static function success(string $message, mixed $data = null, int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    /**
     * Membuat response gagal dengan format standar SmartKasir QR.
     *
     * @param  string  $message  Pesan error yang aman ditampilkan kepada pengguna.
     * @param  int  $status  HTTP status code error.
     * @param  mixed|null  $data  Data tambahan error, atau null bila tidak ada.
     * @return JsonResponse Response JSON berisi success, message, dan data.
     */
    public static function error(string $message, int $status, mixed $data = null): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    /**
     * Membuat response validasi gagal dengan daftar error per field.
     *
     * @param  array<string, array<int, string>>  $errors  Daftar pesan validasi per field.
     * @param  string  $message  Pesan validasi yang aman ditampilkan kepada pengguna.
     * @return JsonResponse Response JSON validasi dengan status 422.
     */
    public static function validation(array $errors, string $message = 'Data yang diberikan tidak valid.'): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], 422);
    }
}
