@extends('layouts.customer')

@section('title', 'Pesanan Berhasil - SmartKasir QR')

@section('content')
    <main class="result-page">
        <section class="result-card">
            <div class="success-icon">&#10003;</div>
            <h1>Pesanan berhasil dikirim</h1>
            <p>Pesanan akan diproses setelah dikonfirmasi kasir.</p>
            <dl class="detail-list">
                <div><dt>Nomor pesanan</dt><dd>{{ $order->order_number }}</dd></div>
                <div><dt>Meja</dt><dd>{{ $order->restaurantTable?->name }}</dd></div>
                <div><dt>Total</dt><dd>{{ $totalFormatted }}</dd></div>
                <div><dt>Status</dt><dd><x-status-badge :status="$status->value" :label="$status->label()" /></dd></div>
                <div><dt>Waktu</dt><dd>{{ $order->created_at?->format('d M Y H:i') }}</dd></div>
            </dl>
            <p class="soft-note">Stok baru dikurangi setelah kasir mengonfirmasi pesanan.</p>
            <div class="button-row">
                <a class="primary-btn" href="{{ route('order.status', ['orderNumber' => $order->order_number]) }}">Cek Status</a>
                @if ($order->restaurantTable)
                    <a class="secondary-btn" href="{{ route('order.menu', ['orderNumber' => $order->order_number]) }}">Kembali ke Menu</a>
                @endif
            </div>
        </section>
    </main>
@endsection
