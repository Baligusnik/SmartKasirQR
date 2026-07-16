<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

/**
 * Service untuk menangani autentikasi token kasir melalui Laravel Sanctum.
 */
class AuthService
{
    /**
     * Memvalidasi kredensial dan membuat Bearer Token Sanctum baru.
     *
     * Token lama dengan nama perangkat yang sama akan dihapus agar satu perangkat
     * tidak menyimpan banyak token aktif dari login berulang.
     *
     * @param  array{email: string, password: string, device_name?: string|null}  $credentials  Data login tervalidasi.
     * @return array{token: string, token_type: string, user: User}|null Data token dan user, atau null jika gagal.
     */
    public function login(array $credentials): ?array
    {
        $user = User::query()
            ->where('email', $credentials['email'])
            ->first();

        if (! $user instanceof User || ! $user->is_active) {
            return null;
        }

        if (! Hash::check($credentials['password'], $user->password)) {
            return null;
        }

        $tokenName = $credentials['device_name'] ?? 'smartkasir-flutter';

        $user->tokens()
            ->where('name', $tokenName)
            ->delete();

        $token = $user->createToken($tokenName);

        return [
            'token' => $token->plainTextToken,
            'token_type' => 'Bearer',
            'user' => $user,
        ];
    }

    /**
     * Menghapus token Sanctum yang sedang digunakan pengguna.
     *
     * @param  User  $user  Pengguna yang sedang terautentikasi.
     * @return void Tidak mengembalikan data, hanya menghapus token aktif dari database.
     */
    public function logout(User $user): void
    {
        $token = $user->currentAccessToken();

        if ($token !== null) {
            $token->delete();
        }
    }
}
