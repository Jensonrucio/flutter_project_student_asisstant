<?php

declare(strict_types=1);

function require_auth_user(PDO $pdo): array
{
  $authorization = trim((string)($_SERVER['HTTP_AUTHORIZATION'] ?? ''));
  if ($authorization === '') {
    $authorization = trim((string)($_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? ''));
  }
  if ($authorization === '' && function_exists('getallheaders')) {
    foreach (getallheaders() as $name => $value) {
      if (strcasecmp((string)$name, 'Authorization') === 0) {
        $authorization = trim((string)$value);
        break;
      }
    }
  }

  if (!preg_match('/\ABearer ([a-f0-9]{64})\z/i', $authorization, $matches)) {
    api_json_response(['error' => 'Authentication is required.'], 401);
  }

  $tokenHash = hash('sha256', $matches[1]);
  $statement = $pdo->prepare(
    'SELECT u.id, u.name, u.email
         FROM auth_tokens t
         INNER JOIN auth_users u ON u.id = t.user_id
         WHERE t.token_hash = :token_hash
           AND t.revoked_at IS NULL
           AND t.expires_at > UTC_TIMESTAMP()
         LIMIT 1'
  );
  $statement->execute([':token_hash' => $tokenHash]);
  $user = $statement->fetch(PDO::FETCH_ASSOC);

  if (!$user) {
    api_json_response(['error' => 'Your session has expired. Please sign in again.'], 401);
  }

  return $user;
}
