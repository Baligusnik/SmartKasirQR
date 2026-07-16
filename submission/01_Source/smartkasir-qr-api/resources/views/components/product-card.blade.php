@props(['product', 'category'])

<article
    class="product-card"
    data-product-card
    data-product-name="{{ \Illuminate\Support\Str::lower($product->name) }}"
    data-product-category="{{ $category->id }}"
>
    <div>
        <p class="product-category">{{ $category->name }}</p>
        <h2>{{ $product->name }}</h2>
        @if ($product->description)
            <p class="product-description">{{ $product->description }}</p>
        @endif
    </div>
    <div class="product-card-footer">
        <div>
            <strong>{{ \App\Support\CurrencyFormatter::rupiah($product->price) }}</strong>
            <small>Stok: {{ $product->stock }} {{ $product->unit }}</small>
        </div>
        <button
            type="button"
            class="primary-btn compact"
            data-add-to-cart
            data-product-id="{{ $product->id }}"
            @disabled($product->stock <= 0)
        >
            {{ $product->stock > 0 ? 'Tambah' : 'Habis' }}
        </button>
    </div>
</article>
