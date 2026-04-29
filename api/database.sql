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
