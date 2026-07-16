<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Membuat tabel dasar untuk katalog, meja, pesanan, dan transaksi SmartKasir QR.
 */
return new class extends Migration
{
    /**
     * Membuat tabel fondasi beserta relasi foreign key.
     */
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->unique();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('products', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('category_id')->constrained()->restrictOnDelete();
            $table->string('name')->index();
            $table->string('sku')->unique();
            $table->text('description')->nullable();
            $table->unsignedInteger('price');
            $table->unsignedInteger('stock')->default(0);
            $table->string('unit')->default('pcs');
            $table->boolean('is_available')->default(true)->index();
            $table->timestamps();

            $table->index(['category_id', 'is_available']);
        });

        Schema::create('restaurant_tables', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('code')->unique();
            $table->string('qr_token', 80)->unique();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('restaurant_table_id')->nullable()->constrained('restaurant_tables')->nullOnDelete();
            $table->string('order_number')->unique();
            $table->string('customer_name')->nullable();
            $table->string('status')->default('pending')->index();
            $table->text('notes')->nullable();
            $table->unsignedInteger('total')->default(0);
            $table->timestamp('stock_deducted_at')->nullable();
            $table->timestamps();

            $table->index(['restaurant_table_id', 'status']);
        });

        Schema::create('order_items', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('price');
            $table->unsignedInteger('subtotal');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'product_id']);
        });

        Schema::create('transactions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->string('transaction_number')->unique();
            $table->unsignedInteger('total');
            $table->unsignedInteger('paid_amount');
            $table->unsignedInteger('change_amount');
            $table->string('payment_method')->default('cash')->index();
            $table->timestamps();

            $table->index(['user_id', 'payment_method']);
        });

        Schema::create('transaction_items', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('transaction_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('price');
            $table->unsignedInteger('subtotal');
            $table->timestamps();

            $table->index(['transaction_id', 'product_id']);
        });
    }

    /**
     * Menghapus tabel fondasi dengan urutan yang aman terhadap foreign key.
     */
    public function down(): void
    {
        Schema::dropIfExists('transaction_items');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('restaurant_tables');
        Schema::dropIfExists('products');
        Schema::dropIfExists('categories');
    }
};
