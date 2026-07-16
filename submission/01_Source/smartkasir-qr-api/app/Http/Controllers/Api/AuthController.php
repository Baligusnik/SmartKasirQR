<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuthService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller API untuk login, membaca profil, dan logout pengguna.
 */
class AuthController extends Controller
{
    /**
     * Membuat instance controller dengan dependency service autentikasi.
     *
     * @param  AuthService  $authService  Service yang menangani token Sanctum.
     */
    public function __construct(private readonly AuthService $authService) {}

    /**
     * Memvalidasi akun kasir dan menghasilkan Bearer Token.
     *
     * @param  LoginRequest  $request  Data email dan password yang telah divalidasi.
     * @return JsonResponse Respons pengguna dan token autentikasi.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $login = $this->authService->login($request->validated());

        if ($login === null) {
            return ApiResponse::error('Email atau password salah.', 401);
        }

        return ApiResponse::success('Login berhasil.', [
            'token' => $login['token'],
            'token_type' => $login['token_type'],
            'user' => (new UserResource($login['user']))->resolve(),
        ]);
    }

    /**
     * Mengambil data pengguna yang sedang login berdasarkan Bearer Token.
     *
     * @param  Request  $request  Request terautentikasi yang membawa user aktif.
     * @return JsonResponse Respons data pengguna login.
     */
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return ApiResponse::success('Data pengguna berhasil diambil.', [
            'user' => (new UserResource($user))->resolve(),
        ]);
    }

    /**
     * Menghapus token yang sedang digunakan untuk logout.
     *
     * @param  Request  $request  Request terautentikasi yang membawa token aktif.
     * @return JsonResponse Respons status logout berhasil.
     */
    public function logout(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $this->authService->logout($user);

        return ApiResponse::success('Logout berhasil.');
    }
}
