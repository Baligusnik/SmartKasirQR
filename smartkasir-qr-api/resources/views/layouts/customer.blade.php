<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'SmartKasir QR')</title>
    @vite(['resources/css/customer.css'])
</head>
<body>
    <div class="customer-shell">
        @if (session('success'))
            <x-alert type="success" :message="session('success')" />
        @endif

        @if ($errors->any())
            <x-alert type="error" message="Pesanan belum dapat diproses. Silakan periksa kembali data Anda." />
        @endif

        @yield('content')
    </div>

    @stack('scripts')
</body>
</html>
