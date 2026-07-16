@extends('layouts.customer')

@section('title', 'Cetak QR Code Meja - SmartKasir QR')

@section('content')
    <main class="qr-print-page">
        <header class="page-header no-print">
            <a href="{{ route('qr.tables.index') }}" class="text-link">Kembali</a>
            <h1>Cetak QR Code Meja</h1>
            <button type="button" class="primary-btn" onclick="window.print()">Cetak Sekarang</button>
        </header>

        <section class="print-grid">
            @foreach ($tables as $table)
                <article class="print-card">
                    <h2>{{ $table->name }}</h2>
                    <p>{{ $table->code }}</p>
                    <div class="qr-box">{!! $table->qr_svg !!}</div>
                    <strong>Scan QR Code untuk memesan.</strong>
                    <small>{{ $table->menu_url }}</small>
                </article>
            @endforeach
        </section>
    </main>
@endsection
