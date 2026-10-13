<?php

$host = "localhost";
$db_name = "student_todo_db";
$username = "root";
$password = "";

try {
    $pdo = new PDO("mysql:host=" . $host . ";dbname=" . $db_name, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $exception) {
    error_log('[db_connect_error] ' . $exception->getMessage());
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed."]);
    exit();
}
?>