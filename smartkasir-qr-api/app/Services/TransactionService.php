<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Models\Order;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Service untuk daftar, detail, dan pembuatan transaksi kasir.
 */
class TransactionService
{
    /**
     * Membuat instance service transaksi.
     *
     * @param  StockService  $stockService  Service stok terpusat.
     * @param  UniqueNumberService  $numberService  Service nomor unik.
     */
    public function __construct(
        private readonly StockService $stockService,
        private readonly UniqueNumberService $numberService,
    ) {}

    /**
     * Mengambil daftar transaksi dengan filter pencarian dan tanggal.
     *
     * @param  array{search?: string|null, date?: string|null}  $filters  Filter daftar transaksi.
     * @return Collection<int, Transaction> Koleksi transaksi dengan relasi yang sudah dimuat.
     */
    public function list(array $filters): Collection
    {
        $query = Transaction::query()
            ->with(['order', 'user', 'items.product'])
            ->withCount('items')
            ->latest();

        if (! empty($filters['search'])) {
            $search = trim((string) $filters['search']);

            $query->where(function ($query) use ($search): void {
                $query
                    ->where('transaction_number', 'like', "%{$search}%")
                    ->orWhereHas('order', fn ($query) => $query->where('order_number', 'like', "%{$search}%"))
                    ->orWhereHas('user', fn ($query) => $query->where('name', 'like', "%{$search}%"));
            });
        }

        if (! empty($filters['date'])) {
            $start = Carbon::parse($filters['date'], config('app.timezone'))->startOfDay();
            $end = Carbon::parse($filters['date'], config('app.timezone'))->endOfDay();

            $query->whereBetween('created_at', [$start, $end]);
        }

        return $query->get();
    }

    /**
     * Membuat transaksi langsung atau pembayaran pesanan QR.
     *
     * @param  User  $cashier  Kasir yang berasal dari Bearer Token.
     * @param  array<string, mixed>  $data  Data transaksi tervalidasi.
     * @return Transaction Transaksi baru dengan relasi lengkap.
     *
     * @throws ValidationException Ketika stok, status pesanan, atau pembayaran tidak valid.
     */
    public function create(User $cashier, array $data): Transaction
    {
        if (isset($data['order_id'])) {
            return $this->createFromOrder($cashier, (int) $data['order_id'], (int) $data['paid_amount']);
        }

        return $this->createDirect($cashier, $data);
    }

    /**
     * Membuat transaksi langsung kasir dan langsung mengurangi stok.
     *
     * @param  User  $cashier  Kasir yang membuat transaksi.
     * @param  array<string, mixed>  $data  Data transaksi langsung tervalidasi.
     * @return Transaction Transaksi langsung yang baru dibuat.
     *
     * @throws ValidationException Ketika stok tidak cukup atau pembayaran kurang.
     */
    private function createDirect(User $cashier, array $data): Transaction
    {
        return DB::transaction(function () use ($cashier, $data): Transaction {
            $items = $this->stockService->aggregateItems($data['items']);
            $products = $this->stockService->validateAvailableProducts($items);
            $total = 0;

            foreach ($items as $item) {
                $product = $products->get($item['product_id']);
                $total += $product->price * $item['quantity'];
            }

            $this->ensurePaidEnough((int) $data['paid_amount'], $total);
            $this->stockService->deduct($items);

            $transaction = Transaction::query()->create([
                'order_id' => null,
                'user_id' => $cashier->id,
                'transaction_number' => $this->numberService->transactionNumber(),
                'total' => $total,
                'paid_amount' => $data['paid_amount'],
                'change_amount' => (int) $data['paid_amount'] - $total,
                'payment_method' => PaymentMethod::Cash->value,
            ]);

            foreach ($items as $item) {
                $product = $products->get($item['product_id']);
                $transaction->items()->create([
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price,
                    'subtotal' => $product->price * $item['quantity'],
                ]);
            }

            return $transaction->load(['order', 'user', 'items.product'])->loadCount('items');
        });
    }

    /**
     * Membuat transaksi pembayaran dari pesanan QR yang sudah siap.
     *
     * @param  User  $cashier  Kasir yang menerima pembayaran.
     * @param  int  $orderId  ID pesanan yang dibayar.
     * @param  int  $paidAmount  Jumlah uang yang dibayarkan.
     * @return Transaction Transaksi pembayaran pesanan QR.
     *
     * @throws ValidationException Ketika pesanan belum siap, sudah dibayar, atau pembayaran kurang.
     */
    private function createFromOrder(User $cashier, int $orderId, int $paidAmount): Transaction
    {
        return DB::transaction(function () use ($cashier, $orderId, $paidAmount): Transaction {
            $order = Order::query()
                ->with(['items.product', 'transaction'])
                ->whereKey($orderId)
                ->firstOrFail();

            if ($order->status !== OrderStatus::Ready->value) {
                throw ValidationException::withMessages([
                    'order_id' => ['Pesanan hanya dapat dibayar ketika berstatus siap.'],
                ]);
            }

            if ($order->stock_deducted_at === null) {
                throw ValidationException::withMessages([
                    'order_id' => ['Stok pesanan belum dikurangi sehingga belum dapat dibayar.'],
                ]);
            }

            if ($order->transaction !== null) {
                throw ValidationException::withMessages([
                    'order_id' => ['Pesanan ini sudah memiliki transaksi.'],
                ]);
            }

            $this->ensurePaidEnough($paidAmount, $order->total);

            $transaction = Transaction::query()->create([
                'order_id' => $order->id,
                'user_id' => $cashier->id,
                'transaction_number' => $this->numberService->transactionNumber(),
                'total' => $order->total,
                'paid_amount' => $paidAmount,
                'change_amount' => $paidAmount - $order->total,
                'payment_method' => PaymentMethod::Cash->value,
            ]);

            foreach ($order->items as $item) {
                $transaction->items()->create([
                    'product_id' => $item->product_id,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'subtotal' => $item->subtotal,
                ]);
            }

            $order->forceFill(['status' => OrderStatus::Completed->value])->save();

            return $transaction->load(['order', 'user', 'items.product'])->loadCount('items');
        });
    }

    /**
     * Memastikan pembayaran cukup terhadap total transaksi.
     *
     * @param  int  $paidAmount  Jumlah pembayaran dari request.
     * @param  int  $total  Total yang dihitung server.
     * @return void Tidak mengubah database.
     *
     * @throws ValidationException Ketika pembayaran kurang dari total.
     */
    private function ensurePaidEnough(int $paidAmount, int $total): void
    {
        if ($paidAmount < $total) {
            throw ValidationException::withMessages([
                'paid_amount' => ['Jumlah pembayaran kurang dari total transaksi.'],
            ]);
        }
    }
}
