<?php

declare(strict_types=1);

namespace App\Services;

use Endroid\QrCode\Color\Color;
use Endroid\QrCode\Encoding\Encoding;
use Endroid\QrCode\ErrorCorrectionLevel;
use Endroid\QrCode\QrCode;
use Endroid\QrCode\RoundBlockSizeMode;
use Endroid\QrCode\Writer\SvgWriter;

/**
 * Service untuk membuat QR Code SVG lokal tanpa ketergantungan internet saat aplikasi berjalan.
 */
class QrCodeService
{
    /**
     * Membuat SVG QR Code dari URL tujuan.
     *
     * @param  string  $url  URL menu pelanggan yang akan dipindai.
     * @return string SVG QR Code yang siap ditampilkan di Blade.
     */
    public function svg(string $url): string
    {
        $qrCode = new QrCode(
            data: $url,
            encoding: new Encoding('UTF-8'),
            errorCorrectionLevel: ErrorCorrectionLevel::High,
            size: 260,
            margin: 14,
            roundBlockSizeMode: RoundBlockSizeMode::Margin,
            foregroundColor: new Color(15, 23, 42),
            backgroundColor: new Color(255, 255, 255),
        );

        return (new SvgWriter)->write($qrCode)->getString();
    }
}
