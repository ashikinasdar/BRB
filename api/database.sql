CREATE DATABASE IF NOT EXISTS himsak_db;
USE himsak_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    ic_image VARCHAR(255) NULL,
    status ENUM('Pending Verification', 'Approved', 'Rejected') DEFAULT 'Pending Verification',
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create default admin account (password: admin123)
INSERT IGNORE INTO users (full_name, email, password, role, status)
VALUES ('Admin', 'admin@himsak.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'Approved');

