<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'db.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id)) {
    $user_id = $conn->real_escape_string($data->user_id);
    
    // Optional: fetch ic_image to delete the file
    $query_fetch = "SELECT ic_image FROM users WHERE id = '$user_id'";
    $result = $conn->query($query_fetch);
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        if (!empty($row['ic_image']) && file_exists($row['ic_image'])) {
            unlink($row['ic_image']);
        }
    }

    $query = "DELETE FROM users WHERE id = '$user_id'";
    if($conn->query($query)) {
        echo json_encode(["success" => true, "message" => "User deleted successfully."]);
    } else {
        echo json_encode(["success" => false, "message" => "Unable to delete user: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
