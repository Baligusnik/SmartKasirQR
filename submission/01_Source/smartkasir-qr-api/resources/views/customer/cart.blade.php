@extends('layouts.customer')

@section('title', 'Keranjang '.$table->name.' - SmartKasir QR')

@section('content')
    <main
        class="cart-page"
        data-cart-key="smartkasir-cart-{{ $qrToken }}"
        data-order-url="{{ route('menu.order.store', ['qrToken' => $qrToken]) }}"
        data-menu-url="{{ route('menu.show', ['qrToken' => $qrToken]) }}"
        data-products='@json($productsPayload)'
    >
        <header class="page-header">
            <a href="{{ route('menu.show', ['qrToken' => $qrToken]) }}" class="text-link">Kembali ke menu</a>
            <h1>Keranjang {{ $table->name }}</h1>
            <p>Periksa pesanan sebelum dikirim ke kasir.</p>
        </header>

        <section class="cart-list" data-cart-list></section>
        <x-empty-state title="Keranjang kosong" message="Tambahkan menu terlebih dahulu." />

        <form class="checkout-form" data-order-form>
            @csrf
            <label>
                Nama pelanggan <span>opsional</span>
                <input name="customer_name" type="text" maxlength="100" placeholder="Contoh: Gus Nik">
            </label>
            <label>
                Catatan pesanan <span>opsional</span>
                <textarea name="notes" maxlength="1000" placeholder="Contoh: Pesanan meja 1."></textarea>
            </label>
            <div class="checkout-total">
                <span>Total sementara</span>
                <strong data-cart-total>Rp0</strong>
            </div>
            <div class="form-error" data-form-error hidden></div>
            <button type="submit" class="primary-btn wide" data-submit-order>Kirim Pesanan</button>
        </form>
    </main>
@endsection

@push('scripts')
    @vite(['resources/js/customer-cart.js'])
@endpush
