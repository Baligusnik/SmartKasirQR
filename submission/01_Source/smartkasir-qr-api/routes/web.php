<?php

declare(strict_types=1);

use App\Http\Controllers\Web\CustomerMenuController;
use App\Http\Controllers\Web\CustomerOrderController;
use App\Http\Controllers\Web\TableQrController;
use Illuminate\Support\Facades\Route;

/**
 * Mengarahkan halaman root ke daftar QR meja agar pengunjung dapat memilih meja.
 */
Route::get('/', function () {
    return redirect()->route('qr.tables.index');
});

Route::get('/menu/{qrToken}', [CustomerMenuController::class, 'show'])->name('menu.show');
Route::get('/menu/{qrToken}/cart', [CustomerMenuController::class, 'cart'])->name('menu.cart');
Route::post('/menu/{qrToken}/orders', [CustomerOrderController::class, 'store'])->name('menu.order.store');
Route::get('/order/success/{orderNumber}', [CustomerOrderController::class, 'success'])->name('order.success');
Route::get('/order/success/{orderNumber}/menu', [CustomerOrderController::class, 'menu'])->name('order.menu');
Route::get('/order/status/{orderNumber}', [CustomerOrderController::class, 'status'])->name('order.status');
Route::get('/qr/tables', [TableQrController::class, 'index'])->name('qr.tables.index');
Route::get('/qr/tables/print', [TableQrController::class, 'print'])->name('qr.tables.print');
