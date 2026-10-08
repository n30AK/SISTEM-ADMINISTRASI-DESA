#!/usr/bin/env php
<?php
declare(strict_types=1);

require __DIR__ . '/../app/db.php';
require __DIR__ . '/../src/OpenSid/SchemaInspector.php';

use App\OpenSid\SchemaInspector;

$tables = array_slice($argv, 1);
if (!$tables) {
    $tables = [
        'tweb_penduduk','tweb_keluarga','tweb_desa_pamong',
        'surat_keluar','surat_masuk','permohonan_surat',
        'keuangan_master','pembangunan','inventaris_asset','dtks'
    ];
}

$inspector = new SchemaInspector(db());
echo json_encode($inspector->inspect($tables), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . PHP_EOL;
