<?php
header('Content-Type: application/json; charset=utf-8');
$checks = ['runtime' => PHP_VERSION];
try {
    require __DIR__ . '/../app/db.php';
    db()->query('SELECT 1');
    $checks['opensid_database'] = 'ok';
} catch (Throwable $e) {
    $checks['opensid_database'] = 'not_configured';
}
echo json_encode(['status'=>'ok','service'=>'Sistem Administrasi Desa','checks'=>$checks], JSON_UNESCAPED_SLASHES);
