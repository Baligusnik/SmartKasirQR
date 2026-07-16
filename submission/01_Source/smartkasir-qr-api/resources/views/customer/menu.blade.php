@extends('layouts.customer')

@section('title', 'Menu '.$table->name.' - SmartKasir QR')

@section('content')
    <main
        class="menu-page"
        data-cart-key="smartkasir-cart-{{ $qrToken }}"
        data-cart-url="{{ route('menu.cart', ['qrToken' => $qrToken]) }}"
        data-products='@json($productsPayload)'
    >
        <header class="hero">
            <p class="eyebrow">SmartKasir QR</p>
            <h1>{{ $table->name }}</h1>
            <p>Silakan pilih menu dan kirim pesanan Anda.</p>
        </header>

        <section class="toolbar">
            <input id="menu-search" type="search" placeholder="Cari menu..." autocomplete="off">
            <div class="category-tabs" aria-label="Filter kategori">
                <button type="button" class="category-tab active" data-category-filter="all">Semua</button>
                @foreach ($categories as $category)
                    <button type="button" class="category-tab" data-category-filter="{{ $category->id }}">{{ $category->name }}</button>
                @endforeach
            </div>
        </section>

        @if ($categories->isEmpty())
            <x-empty-state title="Menu belum tersedia" message="Silakan panggil kasir untuk informasi menu hari ini." />
        @else
            <section class="product-grid">
                @foreach ($categories as $category)
                    @foreach ($category->products as $product)
                        <x-product-card :product="$product" :category="$category" />
                    @endforeach
                @endforeach
            </section>
        @endif

        <aside class="cart-summary" data-cart-summary hidden>
            <div>
                <strong><span data-cart-count>0</span> item</strong>
                <span data-cart-total>Rp0</span>
            </div>
            <a class="primary-btn" href="{{ route('menu.cart', ['qrToken' => $qrToken]) }}">Lihat Keranjang</a>
        </aside>
    </main>
@endsection

@push('scripts')
    @vite(['resources/js/customer-menu.js'])
@endpush
