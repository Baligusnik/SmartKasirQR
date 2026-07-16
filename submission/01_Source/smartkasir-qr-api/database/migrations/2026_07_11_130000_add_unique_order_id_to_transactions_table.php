<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menambahkan unique index nullable untuk mencegah satu pesanan memiliki lebih dari satu transaksi.
 */
return new class extends Migration
{
    /**
     * Membuat unique index pada transactions.order_id.
     */
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table): void {
            $table->unique('order_id', 'transactions_order_id_unique');
        });
    }

    /**
     * Menghapus unique index pada transactions.order_id.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table): void {
            $table->dropUnique('transactions_order_id_unique');
        });
    }
};
