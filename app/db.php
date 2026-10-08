<?php
function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $c = require __DIR__ . '/../config/database.php';
    $pdo = new PDO(
        sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',$c['host'],$c['port'],$c['name']),
        $c['user'],$c['pass'],
        [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]
    );
    return $pdo;
}
function scalar(string $sql): int {
    try { return (int)db()->query($sql)->fetchColumn(); } catch(Throwable $e) { return 0; }
}
function rows(string $sql, array $params=[]): array {
    try { $s=db()->prepare($sql); $s->execute($params); return $s->fetchAll(); } catch(Throwable $e) { return []; }
}
