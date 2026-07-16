<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

/**
 * Seeder utama aplikasi yang memanggil seluruh data awal SmartKasir QR.
 */
class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Menjalankan seeder fondasi aplikasi.
     *
     * @return void Method ini menulis data awal aplikasi ke database.
     */
    public function run(): void
    {
        $this->call(SmartKasirFoundationSeeder::class);
    }
}
