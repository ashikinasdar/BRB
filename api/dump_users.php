<?php
include_once 'db.php';
$result = $conn->query("SELECT id, full_name, ic_image FROM users");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " Name: " . $row['full_name'] . " IC: " . $row['ic_image'] . "\n";
}
?>
