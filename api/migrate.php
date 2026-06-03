<?php
include_once 'db.php';

// Add ic_image column
$query = "ALTER TABLE users ADD COLUMN ic_image VARCHAR(255) NULL";
if ($conn->query($query)) {
    echo "Column ic_image added successfully.<br>";
} else {
    echo "Column ic_image might already exist: " . $conn->error . "<br>";
}

// Add status column
$query = "ALTER TABLE users ADD COLUMN status ENUM('Pending Verification', 'Approved', 'Rejected') DEFAULT 'Pending Verification'";
if ($conn->query($query)) {
    echo "Column status added successfully.<br>";
} else {
    echo "Column status might already exist: " . $conn->error . "<br>";
}

// Add role column
$query = "ALTER TABLE users ADD COLUMN role ENUM('user', 'admin') DEFAULT 'user'";
if ($conn->query($query)) {
    echo "Column role added successfully.<br>";
} else {
    echo "Column role might already exist: " . $conn->error . "<br>";
}

// Update existing users to be 'Approved' so they can login if they were created before this update
$query = "UPDATE users SET status = 'Approved' WHERE status IS NULL OR status = 'Pending Verification'";
$conn->query($query);
echo "Existing users updated to Approved.<br>";

// Optionally create an admin user
$query = "SELECT * FROM users WHERE role = 'admin'";
$result = $conn->query($query);
if ($result->num_rows == 0) {
    $password = password_hash('admin123', PASSWORD_BCRYPT);
    $query = "INSERT INTO users (full_name, email, password, role, status) VALUES ('Admin', 'admin@himsak.com', '$password', 'admin', 'Approved')";
    if ($conn->query($query)) {
        echo "Default admin account created (email: admin@himsak.com, password: admin123).<br>";
    }
} else {
    echo "Admin account already exists.<br>";
}

echo "Migration complete.";
?>
