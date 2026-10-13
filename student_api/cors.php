<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

$configuredOrigins = getenv('APP_ALLOWED_ORIGINS');
$allowedOrigins = array_filter(array_map(
  'trim',
  explode(',', $configuredOrigins ?: 'http://localhost:7357,http://127.0.0.1:7357')
));
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$isLocalDevelopmentOrigin = false;

if ($configuredOrigins === false || trim($configuredOrigins) === '') {
  $isLocalDevelopmentOrigin = preg_match(
    '/\Ahttps?:\/\/(?:localhost|127\.0\.0\.1)(?::([0-9]{1,5}))?\z/i',
    $origin,
    $matches
  ) === 1;

  if ($isLocalDevelopmentOrigin && isset($matches[1]) && (int)$matches[1] > 65535) {
    $isLocalDevelopmentOrigin = false;
  }
}

if (
  $origin !== '' &&
  !in_array($origin, $allowedOrigins, true) &&
  !$isLocalDevelopmentOrigin
) {
  http_response_code(403);
  echo json_encode(['error' => 'Origin is not allowed.']);
  exit;
}

if ($origin !== '') {
  header('Access-Control-Allow-Origin: ' . $origin);
  header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 600');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
  http_response_code(204);
  exit;
}

function api_json_response(array $payload, int $status = 200): never
{
  http_response_code($status);
  echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
  exit;
}
