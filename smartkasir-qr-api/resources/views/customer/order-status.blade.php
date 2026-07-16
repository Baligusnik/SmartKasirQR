@extends('layouts.customer')

@section('title', 'Status Pesanan - SmartKasir QR')

@section('content')
    <main class="status-page" data-status-url="{{ url('/api/public/orders/'.$order->order_number.'/status') }}">
        <section class="result-card">
            <p class="eyebrow">Status Pesanan</p>
            <h1>{{ $order->order_number }}</h1>
            <dl class="detail-list">
                <div><dt>Meja</dt><dd data-table>{{ $order->restaurantTable?->name }}</dd></div>
                <div><dt>Status</dt><dd data-status-label><x-status-badge :status="$status->value" :label="$status->label()" /></dd></div>
                <div><dt>Total</dt><dd data-total>{{ $totalFormatted }}</dd></div>
                <div><dt>Waktu</dt><dd>{{ $order->created_at?->format('d M Y H:i') }}</dd></div>
            </dl>
            <ol class="status-timeline" data-status="{{ $status->value }}">
                @foreach (['pending' => 'Menunggu konfirmasi kasir.', 'confirmed' => 'Pesanan telah dikonfirmasi.', 'processing' => 'Pesanan sedang diproses.', 'ready' => 'Pesanan siap diambil atau diantar.', 'completed' => 'Pesanan selesai.', 'cancelled' => 'Pesanan dibatalkan.'] as $step => $text)
                    <li data-step="{{ $step }}">{{ $text }}</li>
                @endforeach
            </ol>
            <div class="form-error" data-status-error hidden></div>
            <div class="button-row">
                <button type="button" class="primary-btn" data-refresh-status>Perbarui Status</button>
            </div>
        </section>
    </main>
@endsection

@push('scripts')
    @vite(['resources/js/customer-status.js'])
@endpush
