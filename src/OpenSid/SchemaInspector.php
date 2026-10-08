<?php
declare(strict_types=1);

namespace App\OpenSid;

use PDO;
use RuntimeException;

final class SchemaInspector
{
    public function __construct(private PDO $pdo) {}

    /** @return array<string, array<int, array<string, mixed>>> */
    public function inspect(array $tables): array
    {
        $result = [];
        foreach ($tables as $table) {
            if (!preg_match('/^[A-Za-z0-9_]+$/', $table)) {
                throw new RuntimeException('Invalid table identifier.');
            }

            $stmt = $this->pdo->prepare(
                'SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY, COLUMN_DEFAULT
                 FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
                 ORDER BY ORDINAL_POSITION'
            );
            $stmt->execute([$table]);
            $result[$table] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        return $result;
    }
}
