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

if(!empty($data->full_name) && !empty($data->email) && !empty($data->password) && !empty($data->ic_image)) {
    $full_name = $conn->real_escape_string($data->full_name);
    $email = $conn->real_escape_string($data->email);
    $password = password_hash($data->password, PASSWORD_BCRYPT);
    $ic_image_base64 = $data->ic_image;
    
    $check_email = $conn->query("SELECT * FROM users WHERE email = '$email'");
    if($check_email->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "Email already registered."]);
    } else {
        // Handle IC Image upload
        $image_parts = explode(";base64,", $ic_image_base64);
        $image_type_aux = explode("image/", $image_parts[0]);
        $image_type = isset($image_type_aux[1]) ? $image_type_aux[1] : 'png';
        $image_base64 = base64_decode($image_parts[1] ?? $image_parts[0]);
        $file_name = uniqid() . '.' . $image_type;
        $upload_dir = 'uploads/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        $file_path = $upload_dir . $file_name;
        
        if (file_put_contents($file_path, $image_base64)) {
            $query = "INSERT INTO users (full_name, email, password, ic_image, status, role) VALUES ('$full_name', '$email', '$password', '$file_path', 'Pending Verification', 'user')";
            if($conn->query($query)) {
                $user_id = $conn->insert_id;
                echo json_encode(["success" => true, "message" => "Registration successful. Pending admin verification.", "user" => ["id" => (string)$user_id, "fullName" => $full_name, "email" => $email, "status" => "Pending Verification", "role" => "user"]]);
            } else {
                echo json_encode(["success" => false, "message" => "Unable to register user: " . $conn->error]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Failed to save IC image."]);
        }
    }
} else {
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
