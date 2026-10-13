<?php

declare(strict_types=1);

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/db.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
  api_json_response(['error' => 'Use POST for authentication requests.'], 405);
}

$contentLength = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
if ($contentLength > 16384) {
  api_json_response(['error' => 'Request is too large.'], 413);
}

$input = json_decode(file_get_contents('php://input') ?: '', true);
if (!is_array($input)) {
  api_json_response(['error' => 'Request body must be valid JSON.'], 400);
}

$action = $input['action'] ?? '';
$email = strtolower(trim((string)($input['email'] ?? '')));
$password = (string)($input['password'] ?? '');
$name = '';
$ip = (string)($_SERVER['REMOTE_ADDR'] ?? 'unknown');
$emailHash = hash('sha256', $email);
$ipHash = hash('sha256', $ip);

try {
  if (!in_array($action, ['login', 'register', 'logout', 'request_password_reset'], true)) {
    api_json_response(['error' => 'Unsupported authentication action.'], 400);
  }

  if ($action === 'request_password_reset') {
    $resetMessage = 'If that email address is linked to an account, a password reset link has been sent.';
    $normalizedEmail = strlen($email) <= 254 && filter_var($email, FILTER_VALIDATE_EMAIL)
      ? $email
      : '';
    $resetEmailHash = hash('sha256', $normalizedEmail);

    $pdo->prepare(
      'DELETE FROM auth_password_reset_requests
           WHERE requested_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)'
    )->execute();
    $pdo->prepare(
      'INSERT INTO auth_password_reset_requests (email_hash, ip_hash)
           VALUES (:email_hash, :ip_hash)'
    )->execute([':email_hash' => $resetEmailHash, ':ip_hash' => $ipHash]);

    $requestLimit = $pdo->prepare(
      'SELECT COUNT(*) FROM auth_password_reset_requests
           WHERE email_hash = :email_hash AND ip_hash = :ip_hash
             AND requested_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 15 MINUTE)'
    );
    $requestLimit->execute([':email_hash' => $resetEmailHash, ':ip_hash' => $ipHash]);
    if ((int)$requestLimit->fetchColumn() > 5 || $normalizedEmail === '') {
      api_json_response(['message' => $resetMessage]);
    }

    $userStatement = $pdo->prepare(
      'SELECT id, name, email FROM auth_users WHERE email = :email LIMIT 1'
    );
    $userStatement->execute([':email' => $normalizedEmail]);
    $resetUser = $userStatement->fetch(PDO::FETCH_ASSOC);
    if (!$resetUser) {
      api_json_response(['message' => $resetMessage]);
    }

    $resetToken = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $resetToken);
    $expiresAt = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
      ->add(new DateInterval('PT60M'));
    $pdo->prepare(
      'UPDATE auth_password_reset_tokens
           SET used_at = UTC_TIMESTAMP()
           WHERE user_id = :user_id AND used_at IS NULL'
    )->execute([':user_id' => $resetUser['id']]);
    $pdo->prepare(
      'INSERT INTO auth_password_reset_tokens (user_id, token_hash, expires_at)
           VALUES (:user_id, :token_hash, :expires_at)'
    )->execute([
      ':user_id' => $resetUser['id'],
      ':token_hash' => $tokenHash,
      ':expires_at' => $expiresAt->format('Y-m-d H:i:s'),
    ]);

    try {
      require_once __DIR__ . '/password_reset_mailer.php';
      send_password_reset_email($resetUser, $resetToken);
    } catch (Throwable $exception) {
      $pdo->prepare(
        'UPDATE auth_password_reset_tokens SET used_at = UTC_TIMESTAMP()
             WHERE token_hash = :token_hash'
      )->execute([':token_hash' => $tokenHash]);
      error_log('[student_api_auth] password reset email delivery failed');
      api_json_response(['message' => $resetMessage]);
    }

    error_log('[student_api_auth] password reset email sent');
    api_json_response(['message' => $resetMessage]);
  }

  if ($action === 'logout') {
    require_once __DIR__ . '/auth_guard.php';
    $user = require_auth_user($pdo);
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $headers['Authorization'] ?? '';
    preg_match('/\ABearer ([a-f0-9]{64})\z/i', trim($authorization), $matches);
    $statement = $pdo->prepare(
      'UPDATE auth_tokens SET revoked_at = UTC_TIMESTAMP() WHERE token_hash = :token_hash'
    );
    $statement->execute([':token_hash' => hash('sha256', $matches[1])]);
    error_log('[student_api_auth] logout success');
    api_json_response(['message' => 'Signed out.']);
  }

  if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 254) {
    api_json_response(['error' => 'Enter a valid email address.'], 422);
  }

  if ($action === 'register') {
    $name = trim((string)($input['name'] ?? ''));
    if ($name === '' || mb_strlen($name) > 100) {
      api_json_response(['error' => 'Enter a name up to 100 characters.'], 422);
    }
    if (strlen($password) < 12 || strlen($password) > 72) {
      api_json_response(['error' => 'Password must be 12 to 72 bytes long.'], 422);
    }
  } elseif ($password === '' || strlen($password) > 72) {
    api_json_response(['error' => 'Enter your password.'], 422);
  }

  $rateLimit = $pdo->prepare(
    'SELECT COUNT(*) FROM auth_login_attempts
         WHERE email_hash = :email_hash AND ip_hash = :ip_hash
           AND attempted_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 15 MINUTE)'
  );
  $rateLimit->execute([':email_hash' => $emailHash, ':ip_hash' => $ipHash]);
  if ((int)$rateLimit->fetchColumn() >= 8) {
    error_log('[student_api_auth] rate limit reached');
    api_json_response(['error' => 'Too many attempts. Wait 15 minutes and try again.'], 429);
  }

  if ($action === 'register') {
    $userCount = (int)$pdo->query('SELECT COUNT(*) FROM auth_users')->fetchColumn();
    $statement = $pdo->prepare(
      'INSERT INTO auth_users (name, email, password_hash)
             VALUES (:name, :email, :password_hash)'
    );
    try {
      $statement->execute([
        ':name' => $name,
        ':email' => $email,
        ':password_hash' => password_hash($password, PASSWORD_DEFAULT),
      ]);
    } catch (PDOException $exception) {
      if ($exception->getCode() === '23000') {
        api_json_response(['error' => 'An account with this email already exists.'], 409);
      }
      throw $exception;
    }
    $userId = (int)$pdo->lastInsertId();
    if ($userCount === 0) {
      $pdo->prepare('UPDATE tasks SET user_id = :user_id WHERE user_id IS NULL')
        ->execute([':user_id' => $userId]);
      $pdo->prepare('UPDATE quiz_logs SET user_id = :user_id WHERE user_id IS NULL')
        ->execute([':user_id' => $userId]);
    }
    $user = ['id' => $userId, 'name' => $name, 'email' => $email];
    error_log('[student_api_auth] account created');
  } else {
    $statement = $pdo->prepare(
      'SELECT id, name, email, password_hash FROM auth_users WHERE email = :email LIMIT 1'
    );
    $statement->execute([':email' => $email]);
    $record = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$record || !password_verify($password, $record['password_hash'])) {
      $attempt = $pdo->prepare(
        'INSERT INTO auth_login_attempts (email_hash, ip_hash) VALUES (:email_hash, :ip_hash)'
      );
      $attempt->execute([':email_hash' => $emailHash, ':ip_hash' => $ipHash]);
      error_log('[student_api_auth] login rejected');
      api_json_response(['error' => 'Email or password is incorrect.'], 401);
    }
    if (password_needs_rehash($record['password_hash'], PASSWORD_DEFAULT)) {
      $rehash = $pdo->prepare('UPDATE auth_users SET password_hash = :hash WHERE id = :id');
      $rehash->execute([
        ':hash' => password_hash($password, PASSWORD_DEFAULT),
        ':id' => $record['id'],
      ]);
    }
    $user = ['id' => (int)$record['id'], 'name' => $record['name'], 'email' => $record['email']];
    $pdo->prepare(
      'DELETE FROM auth_login_attempts WHERE email_hash = :email_hash AND ip_hash = :ip_hash'
    )->execute([':email_hash' => $emailHash, ':ip_hash' => $ipHash]);
    error_log('[student_api_auth] login success');
  }

  $token = bin2hex(random_bytes(32));
  $tokenHash = hash('sha256', $token);
  $expiresAt = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
    ->add(new DateInterval('PT24H'));
  $tokenStatement = $pdo->prepare(
    'INSERT INTO auth_tokens (user_id, token_hash, expires_at)
         VALUES (:user_id, :token_hash, :expires_at)'
  );
  $tokenStatement->execute([
    ':user_id' => $user['id'],
    ':token_hash' => $tokenHash,
    ':expires_at' => $expiresAt->format('Y-m-d H:i:s'),
  ]);

  api_json_response([
    'token' => $token,
    'expiresAt' => $expiresAt->format(DATE_ATOM),
    'user' => $user,
  ], $action === 'register' ? 201 : 200);
} catch (Throwable $exception) {
  error_log('[student_api_auth] internal error');
  api_json_response(['error' => 'Authentication service is temporarily unavailable.'], 500);
}
