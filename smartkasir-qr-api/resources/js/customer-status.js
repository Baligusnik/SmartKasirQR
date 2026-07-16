const statusPage = document.querySelector('[data-status-url]');
const statusUrl = statusPage?.dataset.statusUrl || '';
const statusLabel = document.querySelector('[data-status-label]');
const totalTarget = document.querySelector('[data-total]');
const tableTarget = document.querySelector('[data-table]');
const timeline = document.querySelector('[data-status]');
const errorBox = document.querySelector('[data-status-error]');
const refreshButton = document.querySelector('[data-refresh-status]');
let pollingTimer = null;

const statusText = {
    pending: 'Menunggu konfirmasi',
    confirmed: 'Dikonfirmasi',
    processing: 'Diproses',
    ready: 'Siap',
    completed: 'Selesai',
    cancelled: 'Dibatalkan',
};

/**
 * Mengubah angka harga menjadi format rupiah Indonesia.
 *
 * @param {number} value Harga numeric dari API status.
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
 * Menampilkan pesan error status pesanan.
 *
 * @param {string} message Pesan yang aman ditampilkan.
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
 * Menyembunyikan pesan error status pesanan.
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
 * Mengubah badge status sesuai status terbaru dari API.
 *
 * @param {string} status Status pesanan.
 * @returns {string} HTML badge status.
 */
function badgeHtml(status) {
    const label = statusText[status] || status;

    return `<span class="status-badge status-${status}">${label}</span>`;
}

/**
 * Memperbarui timeline status sederhana.
 *
 * @param {string} status Status pesanan terbaru.
 * @returns {void}
 */
function updateTimeline(status) {
    if (!timeline) {
        return;
    }

    timeline.dataset.status = status;
    timeline.querySelectorAll('[data-step]').forEach((step) => {
        step.classList.toggle('active', step.dataset.step === status);
    });
}

/**
 * Menghentikan polling jika pesanan sudah masuk status akhir.
 *
 * @param {string} status Status pesanan terbaru.
 * @returns {void}
 */
function stopPollingWhenFinal(status) {
    if ((status === 'completed' || status === 'cancelled') && pollingTimer) {
        window.clearInterval(pollingTimer);
        pollingTimer = null;
    }
}

/**
 * Menampilkan data status terbaru dari endpoint publik.
 *
 * @param {{status: string, status_label?: string, total: number, total_formatted?: string, table?: string}} order Data order dari API.
 * @returns {void}
 */
function renderStatus(order) {
    if (statusLabel) {
        statusLabel.innerHTML = badgeHtml(order.status);
    }

    if (totalTarget) {
        totalTarget.textContent = order.total_formatted || formatRupiah(order.total);
    }

    if (tableTarget && order.table) {
        tableTarget.textContent = order.table;
    }

    updateTimeline(order.status);
    stopPollingWhenFinal(order.status);
}

/**
 * Mengambil status pesanan terbaru melalui endpoint publik.
 *
 * @returns {Promise<void>} Promise selesai saat status dirender.
 */
async function refreshStatus() {
    if (!statusUrl) {
        return;
    }

    hideError();
    refreshButton.disabled = true;

    try {
        const response = await fetch(statusUrl, { headers: { Accept: 'application/json' } });
        const payload = await response.json();

        if (!response.ok) {
            showError(payload.message || 'Status belum dapat diperbarui.');
            return;
        }

        renderStatus(payload.data);
    } catch {
        showError('Koneksi bermasalah. Silakan perbarui kembali.');
    } finally {
        refreshButton.disabled = false;
    }
}

refreshButton?.addEventListener('click', refreshStatus);
updateTimeline(timeline?.dataset.status || 'pending');
pollingTimer = window.setInterval(refreshStatus, 15000);
