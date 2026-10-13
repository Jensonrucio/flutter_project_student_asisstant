<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    if (!empty($data['topic']) && isset($data['score']) && isset($data['total_questions'])) {
        $percentage = ($data['score'] / $data['total_questions']) * 100;
        $stmt = $pdo->prepare("INSERT INTO quiz_logs (topic, score, total_questions, percentage) VALUES (:topic, :score, :total_questions, :percentage)");
        $stmt->execute([
            ':topic' => $data['topic'],
            ':score' => $data['score'],
            ':total_questions' => $data['total_questions'],
            ':percentage' => $percentage
        ]);
        echo json_encode(["status" => "success", "id" => $pdo->lastInsertId()]);
    } else {
        echo json_encode(["status" => "error", "message" => "Invalid payload"]);
    }
} elseif ($method === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM quiz_logs ORDER BY completed_at DESC");
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
}
?>