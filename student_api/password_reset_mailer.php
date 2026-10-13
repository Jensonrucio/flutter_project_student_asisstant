<?php

declare(strict_types=1);

use PHPMailer\PHPMailer\PHPMailer;

function send_password_reset_email(array $user, string $token): void
{
  $autoload = __DIR__ . '/vendor/autoload.php';
  if (!is_file($autoload)) {
    throw new RuntimeException('PHPMailer is not installed.');
  }
  require_once $autoload;

  $smtpHost = trim((string)getenv('SMTP_HOST'));
  $smtpUsername = trim((string)getenv('SMTP_USERNAME'));
  $smtpPassword = (string)getenv('SMTP_PASSWORD');
  $fromEmail = trim((string)getenv('SMTP_FROM_EMAIL'));
  $fromName = trim((string)(getenv('SMTP_FROM_NAME') ?: 'Student Assistant'));
  $publicApiUrl = trim((string)getenv('APP_PUBLIC_API_URL'));
  $encryption = strtolower(trim((string)(getenv('SMTP_ENCRYPTION') ?: 'tls')));
  $smtpPort = (int)(getenv('SMTP_PORT') ?: ($encryption === 'ssl' ? 465 : 587));

  if (
    $smtpHost === '' ||
    $smtpUsername === '' ||
    $smtpPassword === '' ||
    !filter_var($fromEmail, FILTER_VALIDATE_EMAIL) ||
    !in_array($encryption, ['tls', 'ssl'], true) ||
    $smtpPort < 1 ||
    $smtpPort > 65535
  ) {
    throw new RuntimeException('SMTP settings are incomplete or invalid.');
  }

  $apiUrlParts = parse_url($publicApiUrl);
  if (
    filter_var($publicApiUrl, FILTER_VALIDATE_URL) === false ||
    !is_array($apiUrlParts) ||
    !in_array($apiUrlParts['scheme'] ?? '', ['http', 'https'], true) ||
    isset($apiUrlParts['user']) ||
    isset($apiUrlParts['pass']) ||
    isset($apiUrlParts['query']) ||
    isset($apiUrlParts['fragment'])
  ) {
    throw new RuntimeException('APP_PUBLIC_API_URL must be a valid API base URL.');
  }

  $resetUrl = rtrim($publicApiUrl, '/') . '/password_reset.php?token=' . rawurlencode($token);
  $name = htmlspecialchars((string)$user['name'], ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
  $mail = new PHPMailer(true);
  $mail->isSMTP();
  $mail->Host = $smtpHost;
  $mail->SMTPAuth = true;
  $mail->Username = $smtpUsername;
  $mail->Password = $smtpPassword;
  $mail->SMTPSecure = $encryption === 'ssl'
    ? PHPMailer::ENCRYPTION_SMTPS
    : PHPMailer::ENCRYPTION_STARTTLS;
  $mail->Port = $smtpPort;
  $mail->Timeout = 12;
  $mail->CharSet = PHPMailer::CHARSET_UTF8;
  $mail->setFrom($fromEmail, $fromName);
  $mail->addAddress((string)$user['email'], (string)$user['name']);
  $mail->isHTML(true);
  $mail->Subject = 'Reset your Student Assistant password';
  $mail->Body = '<!doctype html><html><body style="font-family:Arial,sans-serif;color:#172033">'
    . '<h2>Password reset request</h2><p>Hello ' . $name . ',</p>'
    . '<p>Use the button below to choose a new password. This link expires in 60 minutes '
    . 'and can only be used once.</p>'
    . '<p><a href="' . htmlspecialchars($resetUrl, ENT_QUOTES, 'UTF-8') . '" '
    . 'style="display:inline-block;padding:12px 18px;background:#0f9d91;color:#fff;'
    . 'text-decoration:none;border-radius:8px">Reset password</a></p>'
    . '<p>If you did not request this, you can ignore this email.</p></body></html>';
  $mail->AltBody = "Hello {$user['name']},\n\n"
    . "Reset your password using this one-time link (expires in 60 minutes):\n"
    . $resetUrl . "\n\nIf you did not request this, ignore this email.";
  $mail->send();
}
