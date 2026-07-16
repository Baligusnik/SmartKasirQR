<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\Public\PublicMenuController;
use App\Http\Controllers\Api\Public\PublicOrderController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::prefix('public')->group(function (): void {
    Route::get('/tables/{qrToken}/menu', [PublicMenuController::class, 'show']);
    Route::post('/tables/{qrToken}/orders', [PublicOrderController::class, 'store']);
    Route::get('/orders/{orderNumber}/status', [PublicOrderController::class, 'status']);
});

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/dashboard', DashboardController::class);

    Route::get('/categories', [CategoryController::class, 'index']);
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{product}', [ProductController::class, 'show']);
    Route::post('/products', [ProductController::class, 'store']);

    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::patch('/orders/{order}/confirm', [OrderController::class, 'confirm']);
    Route::patch('/orders/{order}/process', [OrderController::class, 'process']);
    Route::patch('/orders/{order}/ready', [OrderController::class, 'ready']);
    Route::patch('/orders/{order}/cancel', [OrderController::class, 'cancel']);

    Route::get('/transactions', [TransactionController::class, 'index']);
    Route::get('/transactions/{transaction}', [TransactionController::class, 'show']);
    Route::post('/transactions', [TransactionController::class, 'store']);
});
