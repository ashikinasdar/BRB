<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'db.php';

$query = "SELECT id, full_name, email, ic_image, status, created_at FROM users WHERE role = 'user' ORDER BY created_at DESC";
$result = $conn->query($query);

$users = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'];
        $base_dir = dirname($_SERVER['SCRIPT_NAME']);
        if (!empty($row['ic_image'])) {
            $row['ic_image_url'] = $protocol . "://" . $host . $base_dir . "/" . $row['ic_image'];
        } else {
            $row['ic_image_url'] = null;
        }
        $users[] = $row;
    }
}

echo json_encode(["success" => true, "users" => $users]);
?>
