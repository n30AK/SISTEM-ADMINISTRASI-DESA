<?php
declare(strict_types=1);

/**
 * Serve the same Supabase-backed SAD application used by the GitHub Pages preview.
 * This entry point intentionally has no OpenSID/MySQL dependency.
 */
$application = dirname(__DIR__) . '/preview/index.html';
if (!is_file($application)) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Aplikasi SAD belum siap: berkas antarmuka tidak ditemukan.';
    exit;
}

header('Content-Type: text/html; charset=utf-8');
readfile($application);
