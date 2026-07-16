@extends('layouts.customer')

@section('title', 'QR Code Meja - SmartKasir QR')

@section('content')
    <main class="qr-page">
        <header class="page-header">
            <p class="eyebrow">SmartKasir QR</p>
            <h1>Daftar QR Code Meja</h1>
            <p>QR mengarah ke halaman menu pelanggan, bukan endpoint JSON API.</p>
            <a class="primary-btn" href="{{ route('qr.tables.print') }}">Buka Halaman Cetak</a>
        </header>

        <section class="qr-grid">
            @foreach ($tables as $table)
                <article class="qr-card">
                    <h2>{{ $table->name }}</h2>
                    <p>{{ $table->code }}</p>
                    <div class="qr-box">{!! $table->qr_svg !!}</div>
                    <code>{{ $table->menu_url }}</code>
                    <div class="button-row">
                        <a class="primary-btn compact" href="{{ $table->menu_url }}">Buka Menu</a>
                        <a class="secondary-btn compact" href="{{ route('qr.tables.print') }}">Cetak</a>
                    </div>
                </article>
            @endforeach
        </section>
    </main>
@endsection
