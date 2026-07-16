<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Feature test untuk endpoint autentikasi REST API SmartKasir QR.
 */
class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Memastikan login berhasil menghasilkan token Bearer dan data user aman.
     *
     * @return void Test ini membuat user aktif dan menulis token Sanctum baru.
     */
    public function test_login_successfully_returns_bearer_token(): void
    {
        $this->createCashier();

        $response = $this->postJson('/api/login', [
            'email' => 'kasir@smartkasir.test',
            'password' => 'password',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Login berhasil.')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.user.email', 'kasir@smartkasir.test')
            ->assertJsonMissingPath('data.user.password')
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'token_type',
                    'user' => ['id', 'name', 'email', 'role'],
                ],
            ]);
    }

    /**
     * Memastikan password salah ditolak dengan HTTP 401.
     *
     * @return void Test ini hanya membaca user dan tidak membuat token valid.
     */
    public function test_login_fails_when_password_is_wrong(): void
    {
        $this->createCashier();

        $response = $this->postJson('/api/login', [
            'email' => 'kasir@smartkasir.test',
            'password' => 'salah',
        ]);

        $response
            ->assertUnauthorized()
            ->assertJson([
                'success' => false,
                'message' => 'Email atau password salah.',
                'data' => null,
            ]);
    }

    /**
     * Memastikan request login kosong atau tidak valid ditolak dengan HTTP 422.
     *
     * @return void Test ini tidak mengubah database.
     */
    public function test_login_fails_when_validation_fails(): void
    {
        $response = $this->postJson('/api/login', [
            'email' => 'bukan-email',
            'password' => '',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Data yang diberikan tidak valid.')
            ->assertJsonValidationErrors(['email', 'password']);
    }

    /**
     * Memastikan endpoint me mengembalikan user saat token valid dikirim.
     *
     * @return void Test ini membuat token Sanctum dan membaca data user.
     */
    public function test_me_returns_authenticated_user_with_token(): void
    {
        $token = $this->loginAndGetToken();

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/me');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'kasir@smartkasir.test');
    }

    /**
     * Memastikan endpoint me menolak request tanpa Bearer Token.
     *
     * @return void Test ini tidak mengubah database.
     */
    public function test_me_fails_without_token(): void
    {
        $response = $this->getJson('/api/me');

        $response
            ->assertUnauthorized()
            ->assertJson([
                'success' => false,
                'message' => 'Tidak terautentikasi.',
                'data' => null,
            ]);
    }

    /**
     * Memastikan logout berhasil menghapus token yang sedang digunakan.
     *
     * @return void Test ini membuat lalu menghapus token Sanctum.
     */
    public function test_logout_successfully_deletes_current_token(): void
    {
        $token = $this->loginAndGetToken();

        $response = $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/logout');

        $response
            ->assertOk()
            ->assertJson([
                'success' => true,
                'message' => 'Logout berhasil.',
                'data' => null,
            ]);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    /**
     * Memastikan token yang sudah logout tidak dapat dipakai kembali.
     *
     * @return void Test ini membuat token, logout, lalu mencoba reuse token yang sama.
     */
    public function test_token_cannot_be_used_after_logout(): void
    {
        $token = $this->loginAndGetToken();

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/logout')
            ->assertOk();

        auth()->forgetGuards();

        $this
            ->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/me')
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Tidak terautentikasi.');
    }

    /**
     * Membuat akun kasir aktif untuk kebutuhan test.
     *
     * @return User User kasir yang tersimpan di database testing.
     */
    private function createCashier(): User
    {
        return User::factory()->create([
            'name' => 'Kasir SmartKasir',
            'email' => 'kasir@smartkasir.test',
            'password' => Hash::make('password'),
            'role' => 'cashier',
            'is_active' => true,
        ]);
    }

    /**
     * Melakukan login test dan mengambil token Bearer dari response.
     *
     * @return string Token Sanctum plain text yang baru dibuat.
     */
    private function loginAndGetToken(): string
    {
        $this->createCashier();

        $response = $this->postJson('/api/login', [
            'email' => 'kasir@smartkasir.test',
            'password' => 'password',
        ]);

        return (string) $response->json('data.token');
    }
}
