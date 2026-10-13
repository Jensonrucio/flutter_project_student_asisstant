<?php

declare(strict_types=1);

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth_guard.php';

$user = require_auth_user($pdo);
$method = $_SERVER['REQUEST_METHOD'] ?? '';

try {
  if ($method === 'GET') {
    $statement = $pdo->prepare(
      'SELECT id, title, description, category, priority, due_date, is_completed
             FROM tasks WHERE user_id = :user_id ORDER BY due_date ASC'
    );
    $statement->execute([':user_id' => $user['id']]);
    api_json_response($statement->fetchAll(PDO::FETCH_ASSOC));
  }

  if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input') ?: '', true);
    if (!is_array($data)) {
      api_json_response(['error' => 'Request body must be valid JSON.'], 400);
    }
    $title = trim((string)($data['title'] ?? ''));
    $description = trim((string)($data['description'] ?? ''));
    $category = (string)($data['category'] ?? 'Homework');
    $priority = (string)($data['priority'] ?? 'Medium');
    if ($title === '' || strlen($title) > 255) {
      api_json_response(['error' => 'Task title is required and must be under 255 characters.'], 422);
    }
    if (
      !in_array($category, ['Homework', 'Exams', 'Projects'], true) ||
      !in_array($priority, ['High', 'Medium', 'Low'], true)
    ) {
      api_json_response(['error' => 'Invalid task category or priority.'], 422);
    }
    try {
      $dueDate = new DateTimeImmutable((string)($data['due_date'] ?? ''));
    } catch (Throwable $exception) {
      api_json_response(['error' => 'A valid due date is required.'], 422);
    }
    $statement = $pdo->prepare(
      'INSERT INTO tasks (user_id, title, description, category, priority, due_date)
             VALUES (:user_id, :title, :description, :category, :priority, :due_date)'
    );
    $statement->execute([
      ':user_id' => $user['id'],
      ':title' => $title,
      ':description' => $description,
      ':category' => $category,
      ':priority' => $priority,
      ':due_date' => $dueDate->format('Y-m-d H:i:s'),
    ]);
    api_json_response(['id' => (int)$pdo->lastInsertId()], 201);
  }

  if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input') ?: '', true);
    $taskId = filter_var($data['id'] ?? null, FILTER_VALIDATE_INT);
    if (!$taskId || !array_key_exists('is_completed', $data)) {
      api_json_response(['error' => 'Task id and completion status are required.'], 422);
    }
    $statement = $pdo->prepare(
      'UPDATE tasks SET is_completed = :is_completed
             WHERE id = :id AND user_id = :user_id'
    );
    $statement->execute([
      ':is_completed' => filter_var($data['is_completed'], FILTER_VALIDATE_BOOLEAN) ? 1 : 0,
      ':id' => $taskId,
      ':user_id' => $user['id'],
    ]);
    api_json_response(['status' => 'success']);
  }

  if ($method === 'DELETE') {
    $taskId = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
    if (!$taskId) {
      api_json_response(['error' => 'A valid task id is required.'], 422);
    }
    $statement = $pdo->prepare('DELETE FROM tasks WHERE id = :id AND user_id = :user_id');
    $statement->execute([':id' => $taskId, ':user_id' => $user['id']]);
    api_json_response(['status' => 'success']);
  }

  api_json_response(['error' => 'Method not allowed.'], 405);
} catch (Throwable $exception) {
  error_log('[student_api_tasks] request failed');
  api_json_response(['error' => 'Task service is temporarily unavailable.'], 500);
}
