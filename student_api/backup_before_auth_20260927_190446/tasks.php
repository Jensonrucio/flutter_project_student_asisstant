<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $stmt = $pdo->prepare("SELECT * FROM tasks ORDER BY due_date ASC");
        $stmt->execute();
        $tasks = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($tasks);
        break;

    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);
        if(!empty($data['title']) && !empty($data['due_date'])) {
            $stmt = $pdo->prepare("INSERT INTO tasks (title, description, category, priority, due_date) VALUES (:title, :description, :category, :priority, :due_date)");
            $stmt->execute([
                ':title' => $data['title'],
                ':description' => $data['description'] ?? '',
                ':category' => $data['category'] ?? 'Homework',
                ':priority' => $data['priority'] ?? 'Medium',
                ':due_date' => $data['due_date']
            ]);
            echo json_encode(["status" => "success", "id" => $pdo->lastInsertId()]);
        } else {
            echo json_encode(["status" => "error", "message" => "Incomplete task parameters"]);
        }
        break;

    case 'PUT':
        $data = json_decode(file_get_contents("php://input"), true);
        if(isset($data['id'])) {
            $stmt = $pdo->prepare("UPDATE tasks SET is_completed = :is_completed WHERE id = :id");
            $stmt->execute([
                ':is_completed' => $data['is_completed'] ? 1 : 0,
                ':id' => $data['id']
            ]);
            echo json_encode(["status" => "success"]);
        }
        break;

    case 'DELETE':
        $id = $_GET['id'] ?? null;
        if($id) {
            $stmt = $pdo->prepare("DELETE FROM tasks WHERE id = :id");
            $stmt->execute([':id' => $id]);
            echo json_encode(["status" => "success"]);
        }
        break;
}
?>