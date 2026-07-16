<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Transaction\StoreTransactionRequest;
use App\Http\Requests\Transaction\TransactionIndexRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use App\Models\User;
use App\Services\TransactionService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

/**
 * Controller API untuk daftar, detail, dan pembuatan transaksi.
 */
class TransactionController extends Controller
{
    /**
     * Membuat instance controller transaksi.
     *
     * @param  TransactionService  $transactionService  Service yang menangani transaksi dan stok.
     */
    public function __construct(private readonly TransactionService $transactionService) {}

    /**
     * Menampilkan daftar transaksi dengan filter pencarian dan tanggal.
     *
     * @param  TransactionIndexRequest  $request  Query filter transaksi yang sudah divalidasi.
     * @return JsonResponse Daftar transaksi terbaru.
     */
    public function index(TransactionIndexRequest $request): JsonResponse
    {
        $transactions = $this->transactionService->list($request->validated());

        return ApiResponse::success(
            'Daftar transaksi berhasil diambil.',
            TransactionResource::collection($transactions)->resolve(),
        );
    }

    /**
     * Menampilkan detail transaksi beserta item dan kasir.
     *
     * @param  Transaction  $transaction  Transaksi dari route model binding.
     * @return JsonResponse Detail transaksi.
     */
    public function show(Transaction $transaction): JsonResponse
    {
        $transaction->load(['order', 'user', 'items.product'])->loadCount('items');

        return ApiResponse::success(
            'Detail transaksi berhasil diambil.',
            (new TransactionResource($transaction))->resolve(),
        );
    }

    /**
     * Membuat transaksi langsung atau pembayaran pesanan QR.
     *
     * @param  StoreTransactionRequest  $request  Data transaksi yang sudah divalidasi dan membawa user autentikasi.
     * @return JsonResponse Transaksi baru dengan status HTTP 201.
     */
    public function store(StoreTransactionRequest $request): JsonResponse
    {
        /** @var User $cashier */
        $cashier = $request->user();

        try {
            $transaction = $this->transactionService->create($cashier, $request->validated());
        } catch (ValidationException $exception) {
            return ApiResponse::validation($exception->errors(), 'Transaksi tidak dapat disimpan.');
        }

        return ApiResponse::success(
            'Transaksi berhasil disimpan.',
            (new TransactionResource($transaction))->resolve(),
            201,
        );
    }
}
