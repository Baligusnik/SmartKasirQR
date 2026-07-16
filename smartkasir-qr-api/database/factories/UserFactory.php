<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Factory untuk membuat data dummy User pada test.
 *
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * Password default yang dipakai factory agar hashing tidak dibuat berulang.
     */
    protected static ?string $password;

    /**
     * Mendefinisikan state default model User untuk kebutuhan testing.
     *
     * @return array<string, mixed> Atribut default user dummy.
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => 'cashier',
            'is_active' => true,
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Menandai email user factory sebagai belum terverifikasi.
     *
     * @return static Factory dengan state email belum terverifikasi.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
