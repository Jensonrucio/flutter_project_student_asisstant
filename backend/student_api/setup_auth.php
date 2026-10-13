<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
  http_response_code(404);
  exit;
}

$_SERVER['REQUEST_METHOD'] = 'CLI';
require_once __DIR__ . '/db.php';

$pdo->exec(
  'CREATE TABLE IF NOT EXISTS tasks (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    category VARCHAR(64) NOT NULL DEFAULT "Homework",
    priority VARCHAR(32) NOT NULL DEFAULT "Medium",
    due_date DATETIME NOT NULL,
    is_completed TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tasks_user_due (user_id, due_date)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);
$pdo->exec(
  'CREATE TABLE IF NOT EXISTS quiz_logs (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    topic VARCHAR(500) NOT NULL,
    score INT UNSIGNED NOT NULL,
    total_questions INT UNSIGNED NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    completed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_quiz_logs_user_completed (user_id, completed_at)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);

$pdo->exec(
  'CREATE TABLE IF NOT EXISTS auth_users (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(254) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);
$pdo->exec(
  'CREATE TABLE IF NOT EXISTS auth_tokens (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL,
        token_hash CHAR(64) NOT NULL UNIQUE,
        expires_at DATETIME NOT NULL,
        revoked_at DATETIME NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_auth_tokens_user_expiry (user_id, expires_at),
        CONSTRAINT fk_auth_tokens_user FOREIGN KEY (user_id)
            REFERENCES auth_users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);
$pdo->exec(
  'CREATE TABLE IF NOT EXISTS auth_login_attempts (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email_hash CHAR(64) NOT NULL,
        ip_hash CHAR(64) NOT NULL,
        attempted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_auth_attempts_window (email_hash, ip_hash, attempted_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);
$pdo->exec(
  'CREATE TABLE IF NOT EXISTS auth_password_reset_requests (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email_hash CHAR(64) NOT NULL,
        ip_hash CHAR(64) NOT NULL,
        requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_password_reset_requests_window (email_hash, ip_hash, requested_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);
$pdo->exec(
  'CREATE TABLE IF NOT EXISTS auth_password_reset_tokens (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL,
        token_hash CHAR(64) NOT NULL UNIQUE,
        expires_at DATETIME NOT NULL,
        used_at DATETIME NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_password_reset_tokens_user (user_id, expires_at),
        CONSTRAINT fk_password_reset_tokens_user FOREIGN KEY (user_id)
            REFERENCES auth_users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
);

foreach (['tasks', 'quiz_logs'] as $table) {
  $columnCheck = $pdo->prepare(
    'SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :table_name AND COLUMN_NAME = :column_name'
  );
  $columnCheck->execute([':table_name' => $table, ':column_name' => 'user_id']);
  if ((int)$columnCheck->fetchColumn() === 0) {
    $pdo->exec("ALTER TABLE `$table` ADD COLUMN user_id BIGINT UNSIGNED NULL");
    $pdo->exec("CREATE INDEX idx_{$table}_user_id ON `$table` (user_id)");
  }
}

echo "Authentication schema is ready. Existing unowned tasks and quiz logs will be assigned to the first account created.\n";
