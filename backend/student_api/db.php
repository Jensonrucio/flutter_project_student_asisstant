<?php

declare(strict_types=1);

$dbHost = '127.0.0.1';
$dbName = 'stundent_todo_db';
$dbUser = 'auth_user';
$dbPass = '';
$dbPort = 3306;

$dsn = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName};charset=utf8mb4";

$options = [
  PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
  $pdo = new PDO($dsn, $dbUser, $dbPass, $options);
} catch (\PDOException $e) {
  error_log('[db_connect_error] ' . $e->getMessage());
  api_json_response(['error' => 'Database connection failed.'], 500);
  exit;
}
