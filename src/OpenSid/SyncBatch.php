<?php
declare(strict_types=1);

namespace App\OpenSid;

final class SyncBatch
{
    public const RECEIVED = 'RECEIVED';
    public const VALIDATED = 'VALIDATED';
    public const APPLIED = 'APPLIED';
    public const PARTIAL = 'PARTIAL';
    public const REJECTED = 'REJECTED';

    public static function validateStatus(string $status): string
    {
        $allowed = [self::RECEIVED, self::VALIDATED, self::APPLIED, self::PARTIAL, self::REJECTED];
        if (!in_array($status, $allowed, true)) {
            throw new \InvalidArgumentException('Invalid sync batch status.');
        }
        return $status;
    }
}
