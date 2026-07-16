<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * Model akun pengguna aplikasi untuk kasir dan admin.
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $role
 * @property bool $is_active
 */
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Kolom yang aman diisi massal dari seeder atau form terkontrol.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
    ];

    /**
     * Kolom sensitif yang tidak boleh muncul pada JSON response.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Mengambil semua transaksi yang dibuat oleh pengguna ini.
     *
     * @return HasMany<Transaction> Relasi transaksi milik user.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Mendefinisikan casting atribut model User.
     *
     * @return array<string, string> Daftar cast untuk atribut tanggal, boolean, dan password.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_active' => 'boolean',
            'password' => 'hashed',
        ];
    }
}
