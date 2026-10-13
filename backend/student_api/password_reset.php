<?php

declare(strict_types=1);

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/db.php';

header('Content-Type: text/html; charset=utf-8');
header('Referrer-Policy: no-referrer');
header('X-Frame-Options: DENY');
header("Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'");

function render_reset_page(string $message, ?string $token = null, int $status = 200): never
{
  http_response_code($status);
  $escapedMessage = htmlspecialchars($message, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
  $form = '';
  if ($token !== null) {
    $escapedToken = htmlspecialchars($token, ENT_QUOTES, 'UTF-8');
    $form = '<form method="post" action="password_reset.php">'
      . '<input type="hidden" name="token" value="' . $escapedToken . '">'
      . '<label for="new_password">New password</label>'
      . '<input id="new_password" name="new_password" type="password" '
      . 'autocomplete="new-password" minlength="12" maxlength="72" required>'
      . '<label for="confirm_password">Confirm new password</label>'
      . '<input id="confirm_password" name="confirm_password" type="password" '
      . 'autocomplete="new-password" minlength="12" maxlength="72" required>'
      . '<button type="submit">Set new password</button></form>';
  }

  echo '<!doctype html><html lang="en"><meta charset="utf-8">'
    . '<meta name="viewport" content="width=device-width,initial-scale=1">'
    . '<title>Password reset</title>'
    . '<style>body{margin:0;min-height:100vh;display:grid;place-items:center;'
    . 'background:#0b1220;color:#f8fafc;font:16px Arial,sans-serif}'
    . 'main{box-sizing:border-box;width:min(92vw,440px);padding:28px;'
    . 'background:#142033;border:1px solid #334155;border-radius:20px}'
    . 'h1{font-size:24px}p{line-height:1.5;color:#cbd5e1}'
    . 'label{display:block;margin:16px 0 7px;color:#cbd5e1}'
    . 'input{box-sizing:border-box;width:100%;padding:12px;border-radius:10px;'
    . 'border:1px solid #475569;background:#0b1220;color:#fff;font-size:16px}'
    . 'button{width:100%;margin-top:20px;padding:13px;border:0;border-radius:10px;'
    . 'background:#2dd4bf;color:#062521;font-weight:bold;font-size:16px;cursor:pointer}'
    . '</style><main><h1>Student Assistant</h1><p>' . $escapedMessage . '</p>'
    . $form . '</main></html>';
  exit;
}

$requestMethod = $_SERVER['REQUEST_METHOD'] ?? '';
if ($requestMethod === 'GET') {
  $token = (string)($_GET['token'] ?? '');
  if (!preg_match('/\A[a-f0-9]{64}\z/i', $token)) {
    render_reset_page('This password reset link is invalid or has expired.', null, 400);
  }
  $statement = $pdo->prepare(
    'SELECT id FROM auth_password_reset_tokens
         WHERE token_hash = :token_hash AND used_at IS NULL
           AND expires_at > UTC_TIMESTAMP() LIMIT 1'
  );
  $statement->execute([':token_hash' => hash('sha256', $token)]);
  if (!$statement->fetchColumn()) {
    render_reset_page('This password reset link is invalid or has expired.', null, 400);
  }
  render_reset_page('Choose a new password. Use at least 12 characters.', $token);
}

if ($requestMethod !== 'POST') {
  render_reset_page('Use the password reset link from your email.', null, 405);
}

if ((int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 4096) {
  render_reset_page('The request is too large. Please open a new reset link.', null, 413);
}

$token = (string)($_POST['token'] ?? '');
$password = (string)($_POST['new_password'] ?? '');
$confirmation = (string)($_POST['confirm_password'] ?? '');
if (
  !preg_match('/\A[a-f0-9]{64}\z/i', $token) ||
  strlen($password) < 12 ||
  strlen($password) > 72 ||
  !hash_equals($password, $confirmation)
) {
  render_reset_page(
    'The link or password is invalid. Passwords must match and be 12 to 72 bytes long.',
    preg_match('/\A[a-f0-9]{64}\z/i', $token) ? $token : null,
    422
  );
}

try {
  $pdo->beginTransaction();
  $statement = $pdo->prepare(
    'SELECT id, user_id FROM auth_password_reset_tokens
         WHERE token_hash = :token_hash AND used_at IS NULL
           AND expires_at > UTC_TIMESTAMP() LIMIT 1 FOR UPDATE'
  );
  $statement->execute([':token_hash' => hash('sha256', $token)]);
  $reset = $statement->fetch(PDO::FETCH_ASSOC);
  if (!$reset) {
    $pdo->rollBack();
    render_reset_page('This password reset link is invalid or has expired.', null, 400);
  }

  $updatePassword = $pdo->prepare(
    'UPDATE auth_users SET password_hash = :password_hash WHERE id = :user_id'
  );
  $updatePassword->execute([
    ':password_hash' => password_hash($password, PASSWORD_DEFAULT),
    ':user_id' => $reset['user_id'],
  ]);
  $revokeSessions = $pdo->prepare(
    'UPDATE auth_tokens SET revoked_at = UTC_TIMESTAMP()
         WHERE user_id = :user_id AND revoked_at IS NULL'
  );
  $revokeSessions->execute([':user_id' => $reset['user_id']]);
  $consumeToken = $pdo->prepare(
    'UPDATE auth_password_reset_tokens SET used_at = UTC_TIMESTAMP() WHERE id = :id'
  );
  $consumeToken->execute([':id' => $reset['id']]);
  $pdo->commit();
} catch (Throwable $exception) {
  if ($pdo->inTransaction()) {
    $pdo->rollBack();
  }
  error_log('[student_api_auth] password reset failed');
  render_reset_page('Password reset could not be completed. Please try again later.', null, 500);
}

render_reset_page('Your password has been changed. You can return to Student Assistant and sign in.');
