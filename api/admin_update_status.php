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

if(!empty($data->user_id) && !empty($data->status)) {
    $user_id = $conn->real_escape_string($data->user_id);
    $status = $conn->real_escape_string($data->status);
    
    if (in_array($status, ['Approved', 'Rejected'])) {
        $query = "UPDATE users SET status = '$status' WHERE id = '$user_id'";
        if($conn->query($query)) {
            echo json_encode(["success" => true, "message" => "User status updated to $status."]);
        } else {
            echo json_encode(["success" => false, "message" => "Unable to update status: " . $conn->error]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Invalid status."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
