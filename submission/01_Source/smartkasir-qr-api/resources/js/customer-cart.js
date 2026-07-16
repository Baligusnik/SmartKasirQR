const page = document.querySelector('[data-cart-key]');
const products = page ? JSON.parse(page.dataset.products || '[]') : [];
const cartKey = page?.dataset.cartKey || '';
const orderUrl = page?.dataset.orderUrl || '';
const menuUrl = page?.dataset.menuUrl || '';
const cartList = document.querySelector('[data-cart-list]');
const emptyState = document.querySelector('.empty-state');
const orderForm = document.querySelector('[data-order-form]');
const submitButton = document.querySelector('[data-submit-order]');
const totalTarget = document.querySelector('[data-cart-total]');
const errorBox = document.querySelector('[data-form-error]');

/**
 * Mengubah angka harga menjadi format rupiah Indonesia.
 *
 * @param {number} value Harga numeric dari data produk server.
 * @returns {string} Harga yang sudah diformat.
 */
function formatRupiah(value) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
    }).format(value);
}

/**
 * Mengambil keranjang meja saat ini dari localStorage.
 *
 * @returns {Array<{product_id: number, quantity: number, notes: string}>} Item keranjang aman.
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
 * Menyimpan keranjang meja saat ini ke localStorage.
 *
 * @param {Array<{product_id: number, quantity: number, notes: string}>} cart Item keranjang aman.
 * @returns {void}
 */
function writeCart(cart) {
    localStorage.setItem(cartKey, JSON.stringify(cart));
}

/**
 * Menghapus keranjang meja saat ini dari localStorage.
 *
 * @returns {void}
 */
function clearCart() {
    localStorage.removeItem(cartKey);
}

/**
 * Mencari produk berdasarkan ID.
 *
 * @param {number} productId ID produk.
 * @returns {{id: number, name: string, price: number, stock: number, unit: string}|undefined} Produk yang cocok.
 */
function findProduct(productId) {
    return products.find((product) => Number(product.id) === Number(productId));
}

/**
 * Membersihkan keranjang dari produk yang tidak tersedia pada menu terbaru.
 *
 * @param {Array<{product_id: number, quantity: number, notes: string}>} cart Item keranjang.
 * @returns {Array<{product_id: number, quantity: number, notes: string}>} Item valid untuk ditampilkan.
 */
function normalizeCart(cart) {
    return cart
        .map((item) => {
            const product = findProduct(item.product_id);

            if (!product || product.stock < 1) {
                return null;
            }

            return {
                product_id: Number(item.product_id),
                quantity: Math.max(1, Math.min(Number(item.quantity) || 1, product.stock)),
                notes: String(item.notes || '').slice(0, 500),
            };
        })
        .filter(Boolean);
}

/**
 * Menghitung total sementara dari harga produk yang diberikan Laravel.
 *
 * @param {Array<{product_id: number, quantity: number, notes: string}>} cart Item keranjang.
 * @returns {number} Total sementara untuk tampilan.
 */
function cartTotal(cart) {
    return cart.reduce((total, item) => {
        const product = findProduct(item.product_id);

        return product ? total + product.price * item.quantity : total;
    }, 0);
}

/**
 * Menampilkan pesan error form dalam bahasa Indonesia.
 *
 * @param {string} message Pesan yang aman ditampilkan ke pelanggan.
 * @returns {void}
 */
function showError(message) {
    if (!errorBox) {
        return;
    }

    errorBox.textContent = message;
    errorBox.hidden = false;
}

/**
 * Menyembunyikan pesan error form.
 *
 * @returns {void}
 */
function hideError() {
    if (errorBox) {
        errorBox.hidden = true;
        errorBox.textContent = '';
    }
}

/**
 * Mengubah quantity satu item keranjang dengan batas stok.
 *
 * @param {number} productId ID produk.
 * @param {number} delta Perubahan quantity.
 * @returns {void}
 */
function changeQuantity(productId, delta) {
    const cart = normalizeCart(readCart());
    const item = cart.find((entry) => Number(entry.product_id) === Number(productId));
    const product = findProduct(productId);

    if (!item || !product) {
        return;
    }

    item.quantity = Math.max(1, Math.min(item.quantity + delta, product.stock));
    writeCart(cart);
    renderCart();
}

/**
 * Menghapus satu item dari keranjang.
 *
 * @param {number} productId ID produk.
 * @returns {void}
 */
function removeItem(productId) {
    writeCart(normalizeCart(readCart()).filter((item) => Number(item.product_id) !== Number(productId)));
    renderCart();
}

/**
 * Menyimpan catatan item keranjang.
 *
 * @param {number} productId ID produk.
 * @param {string} notes Catatan pelanggan untuk item.
 * @returns {void}
 */
function updateItemNotes(productId, notes) {
    const cart = normalizeCart(readCart());
    const item = cart.find((entry) => Number(entry.product_id) === Number(productId));

    if (!item) {
        return;
    }

    item.notes = notes.slice(0, 500);
    writeCart(cart);
}

/**
 * Membuat elemen HTML untuk satu item keranjang.
 *
 * @param {{product_id: number, quantity: number, notes: string}} item Item keranjang.
 * @returns {HTMLElement} Elemen item keranjang.
 */
function cartItemElement(item) {
    const product = findProduct(item.product_id);
    const article = document.createElement('article');

    article.className = 'cart-item';
    article.innerHTML = `
        <div>
            <h2></h2>
            <p></p>
            <textarea maxlength="500" placeholder="Catatan item, contoh: jangan pedas"></textarea>
        </div>
        <div class="qty-control">
            <button type="button" data-qty-minus>-</button>
            <strong>${item.quantity}</strong>
            <button type="button" data-qty-plus>+</button>
            <button type="button" class="danger-btn" data-remove-item>Hapus</button>
        </div>
    `;

    article.querySelector('h2').textContent = product.name;
    article.querySelector('p').textContent = `${product.price_formatted || formatRupiah(product.price)} x ${item.quantity} ${product.unit}`;
    article.querySelector('textarea').value = item.notes || '';
    article.querySelector('[data-qty-minus]').addEventListener('click', () => changeQuantity(item.product_id, -1));
    article.querySelector('[data-qty-plus]').addEventListener('click', () => changeQuantity(item.product_id, 1));
    article.querySelector('[data-remove-item]').addEventListener('click', () => removeItem(item.product_id));
    article.querySelector('textarea').addEventListener('input', (event) => updateItemNotes(item.product_id, event.target.value));

    return article;
}

/**
 * Merender daftar keranjang, empty state, dan total sementara.
 *
 * @returns {void}
 */
function renderCart() {
    const cart = normalizeCart(readCart());
    writeCart(cart);

    if (!cartList || !emptyState || !totalTarget || !submitButton) {
        return;
    }

    cartList.replaceChildren(...cart.map(cartItemElement));
    emptyState.hidden = cart.length > 0;
    orderForm.hidden = cart.length === 0;
    totalTarget.textContent = formatRupiah(cartTotal(cart));
    submitButton.disabled = cart.length === 0;
}

/**
 * Mengambil token CSRF dari form atau meta tag layout.
 *
 * @returns {string} Nilai CSRF token.
 */
function csrfToken() {
    return document.querySelector('input[name="_token"]')?.value || document.querySelector('meta[name="csrf-token"]')?.content || '';
}

/**
 * Mengubah response JSON error Laravel menjadi pesan singkat.
 *
 * @param {{message?: string, errors?: Record<string, string[]>}} payload Response JSON Laravel.
 * @returns {string} Pesan error untuk pelanggan.
 */
function errorMessage(payload) {
    const firstError = payload.errors ? Object.values(payload.errors).flat()[0] : null;

    return firstError || payload.message || 'Pesanan belum dapat dikirim. Silakan periksa kembali keranjang.';
}

/**
 * Mengirim pesanan ke route web memakai CSRF dan item aman dari keranjang.
 *
 * @param {SubmitEvent} event Event submit form.
 * @returns {Promise<void>} Promise selesai saat request selesai atau redirect dilakukan.
 */
async function submitOrder(event) {
    event.preventDefault();
    hideError();

    const cart = normalizeCart(readCart());

    if (cart.length === 0) {
        showError('Keranjang masih kosong.');
        return;
    }

    if (!window.confirm('Kirim pesanan ini ke kasir?')) {
        return;
    }

    submitButton.disabled = true;
    submitButton.textContent = 'Mengirim...';

    try {
        const formData = new FormData(orderForm);
        const response = await fetch(orderUrl, {
            method: 'POST',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': csrfToken(),
            },
            body: JSON.stringify({
                customer_name: formData.get('customer_name') || null,
                notes: formData.get('notes') || null,
                items: cart,
            }),
        });
        const payload = await response.json();

        if (!response.ok) {
            showError(errorMessage(payload));
            return;
        }

        clearCart();
        window.location.assign(payload.redirect_url || menuUrl);
    } catch {
        showError('Koneksi bermasalah. Silakan coba kirim ulang pesanan.');
    } finally {
        submitButton.disabled = false;
        submitButton.textContent = 'Kirim Pesanan';
    }
}

orderForm?.addEventListener('submit', submitOrder);
renderCart();
