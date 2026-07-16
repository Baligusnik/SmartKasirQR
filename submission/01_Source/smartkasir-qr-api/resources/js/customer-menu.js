const page = document.querySelector('[data-cart-key]');
const products = page ? JSON.parse(page.dataset.products || '[]') : [];
const cartKey = page?.dataset.cartKey || '';
const searchInput = document.querySelector('#menu-search');
const categoryButtons = document.querySelectorAll('[data-category-filter]');
const productCards = document.querySelectorAll('[data-product-card]');
const cartSummary = document.querySelector('[data-cart-summary]');
const cartCount = document.querySelector('[data-cart-count]');
const cartTotal = document.querySelector('[data-cart-total]');
let activeCategory = 'all';

/**
 * Mengubah angka harga menjadi format rupiah Indonesia untuk tampilan pelanggan.
 *
 * @param {number} value Harga numeric dari data produk server.
 * @returns {string} Harga yang sudah diformat rupiah.
 */
function formatRupiah(value) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
    }).format(value);
}

/**
 * Mengambil isi keranjang dari localStorage untuk meja saat ini.
 *
 * @returns {Array<{product_id: number, quantity: number, notes: string}>} Item keranjang tersimpan.
 */
function readCart() {
    try {
        const parsed = JSON.parse(localStorage.getItem(cartKey) || '[]');

        return Array.isArray(parsed) ? parsed : [];
    } catch {
        return [];
    }
}

/**
 * Menyimpan isi keranjang meja saat ini ke localStorage.
 *
 * @param {Array<{product_id: number, quantity: number, notes: string}>} cart Item keranjang yang aman disimpan.
 * @returns {void}
 */
function writeCart(cart) {
    localStorage.setItem(cartKey, JSON.stringify(cart));
}

/**
 * Mencari produk berdasarkan ID dari data menu yang diberikan Laravel.
 *
 * @param {number} productId ID produk.
 * @returns {{id: number, name: string, price: number, stock: number}|undefined} Produk yang cocok.
 */
function findProduct(productId) {
    return products.find((product) => Number(product.id) === Number(productId));
}

/**
 * Menghitung jumlah item dan total sementara dari data produk server.
 *
 * @param {Array<{product_id: number, quantity: number, notes: string}>} cart Item keranjang.
 * @returns {{count: number, total: number}} Ringkasan keranjang untuk tampilan.
 */
function summarizeCart(cart) {
    return cart.reduce((summary, item) => {
        const product = findProduct(item.product_id);

        if (!product) {
            return summary;
        }

        return {
            count: summary.count + item.quantity,
            total: summary.total + product.price * item.quantity,
        };
    }, { count: 0, total: 0 });
}

/**
 * Memperbarui ringkasan keranjang sticky pada halaman menu.
 *
 * @returns {void}
 */
function renderCartSummary() {
    const summary = summarizeCart(readCart());

    if (!cartSummary || !cartCount || !cartTotal) {
        return;
    }

    cartSummary.hidden = summary.count === 0;
    cartCount.textContent = String(summary.count);
    cartTotal.textContent = formatRupiah(summary.total);
}

/**
 * Menambahkan satu produk ke keranjang tanpa melewati stok yang ditampilkan.
 *
 * @param {number} productId ID produk yang dipilih.
 * @returns {void}
 */
function addToCart(productId) {
    const product = findProduct(productId);

    if (!product || product.stock < 1) {
        return;
    }

    const cart = readCart();
    const existing = cart.find((item) => Number(item.product_id) === Number(productId));

    if (existing) {
        existing.quantity = Math.min(existing.quantity + 1, product.stock);
    } else {
        cart.push({ product_id: Number(productId), quantity: 1, notes: '' });
    }

    writeCart(cart);
    renderCartSummary();
}

/**
 * Menyaring kartu produk berdasarkan kata pencarian dan kategori aktif.
 *
 * @returns {void}
 */
function filterProducts() {
    const search = (searchInput?.value || '').trim().toLowerCase();

    productCards.forEach((card) => {
        const matchesSearch = card.dataset.productName?.includes(search) ?? true;
        const matchesCategory = activeCategory === 'all' || card.dataset.productCategory === activeCategory;

        card.hidden = !(matchesSearch && matchesCategory);
    });
}

document.querySelectorAll('[data-add-to-cart]').forEach((button) => {
    button.addEventListener('click', () => addToCart(Number(button.dataset.productId)));
});

searchInput?.addEventListener('input', filterProducts);

categoryButtons.forEach((button) => {
    button.addEventListener('click', () => {
        activeCategory = button.dataset.categoryFilter || 'all';
        categoryButtons.forEach((item) => item.classList.toggle('active', item === button));
        filterProducts();
    });
});

renderCartSummary();
