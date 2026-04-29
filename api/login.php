<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request for CORS (Flutter Web)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'db.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email) && !empty($data->password)) {
    $email = $conn->real_escape_string($data->email);
    $password = $data->password;
    
    $query = "SELECT * FROM users WHERE email = '$email'";
    $result = $conn->query($query);
    
    if($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        if(password_verify($password, $user['password'])) {
            $status = isset($user['status']) ? $user['status'] : 'Approved'; // Default for old users
            $role = isset($user['role']) ? $user['role'] : 'user';
            
            if ($role === 'user' && $status !== 'Approved') {
                echo json_encode(["success" => false, "message" => "Account is $status."]);
            } else {
                echo json_encode(["success" => true, "message" => "Login successful.", "user" => ["id" => (string)$user['id'], "fullName" => $user['full_name'], "email" => $user['email'], "status" => $status, "role" => $role]]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Incorrect password."]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Email not found."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
