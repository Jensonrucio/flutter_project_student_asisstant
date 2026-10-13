<?php

declare(strict_types=1);

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth_guard.php';

$user = require_auth_user($pdo);
$method = $_SERVER['REQUEST_METHOD'] ?? '';

try {
  if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input') ?: '', true);
    if (!is_array($data)) {
      api_json_response(['error' => 'Request body must be valid JSON.'], 400);
    }
    $topic = trim((string)($data['topic'] ?? ''));
    $score = filter_var($data['score'] ?? null, FILTER_VALIDATE_INT);
    $total = filter_var($data['total_questions'] ?? null, FILTER_VALIDATE_INT);
    if (
      $topic === '' || strlen($topic) > 500 || $score === false || $total === false ||
      $total < 1 || $score < 0 || $score > $total
    ) {
      api_json_response(['error' => 'Invalid quiz result.'], 422);
    }
    $percentage = ($score / $total) * 100;
    $statement = $pdo->prepare(
      'INSERT INTO quiz_logs (user_id, topic, score, total_questions, percentage)
             VALUES (:user_id, :topic, :score, :total, :percentage)'
    );
    $statement->execute([
      ':user_id' => $user['id'],
      ':topic' => $topic,
      ':score' => $score,
      ':total' => $total,
      ':percentage' => $percentage,
    ]);
    api_json_response(['id' => (int)$pdo->lastInsertId()], 201);
  }

  if ($method === 'GET') {
    $statement = $pdo->prepare(
      'SELECT id, topic, score, total_questions, percentage, completed_at
             FROM quiz_logs WHERE user_id = :user_id ORDER BY completed_at DESC'
    );
    $statement->execute([':user_id' => $user['id']]);
    api_json_response($statement->fetchAll(PDO::FETCH_ASSOC));
  }

  api_json_response(['error' => 'Method not allowed.'], 405);
} catch (Throwable $exception) {
  error_log('[student_api_quiz_logs] request failed');
  api_json_response(['error' => 'Quiz log service is temporarily unavailable.'], 500);
}
