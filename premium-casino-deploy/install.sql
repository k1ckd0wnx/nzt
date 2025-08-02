-- Premium Casino Database Schema
-- Run this SQL script to set up the database tables

CREATE TABLE IF NOT EXISTS `casino_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL UNIQUE,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `balance` DECIMAL(15,2) DEFAULT 0.00,
    `total_deposited` DECIMAL(15,2) DEFAULT 0.00,
    `total_withdrawn` DECIMAL(15,2) DEFAULT 0.00,
    `total_wagered` DECIMAL(15,2) DEFAULT 0.00,
    `total_won` DECIMAL(15,2) DEFAULT 0.00,
    `session_token` VARCHAR(255) NULL,
    `session_expires` BIGINT NULL,
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `is_active` BOOLEAN DEFAULT TRUE,
    `verification_level` ENUM('unverified', 'basic', 'verified') DEFAULT 'unverified',
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_username` (`username`),
    INDEX `idx_session_token` (`session_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `casino_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` ENUM('deposit', 'withdrawal', 'game_bet', 'game_win', 'game_loss') NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `balance_before` DECIMAL(15,2) NOT NULL,
    `balance_after` DECIMAL(15,2) NOT NULL,
    `game_type` VARCHAR(50) NULL,
    `game_data` JSON NULL,
    `transaction_hash` VARCHAR(64) NOT NULL UNIQUE,
    `status` ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    `bank_transaction_id` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `processed_at` TIMESTAMP NULL,
    `notes` TEXT NULL,
    FOREIGN KEY (`user_id`) REFERENCES `casino_users`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_type` (`type`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_transaction_hash` (`transaction_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `casino_game_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `game_type` VARCHAR(50) NOT NULL,
    `game_variant` VARCHAR(50) NULL,
    `bet_amount` DECIMAL(15,2) NOT NULL,
    `result_multiplier` DECIMAL(8,4) DEFAULT 0.0000,
    `payout_amount` DECIMAL(15,2) DEFAULT 0.00,
    `game_state` JSON NOT NULL,
    `result_data` JSON NULL,
    `session_hash` VARCHAR(64) NOT NULL UNIQUE,
    `server_seed` VARCHAR(64) NOT NULL,
    `client_seed` VARCHAR(64) NULL,
    `nonce` INT NOT NULL DEFAULT 1,
    `is_completed` BOOLEAN DEFAULT FALSE,
    `is_verified` BOOLEAN DEFAULT FALSE,
    `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `ip_address` VARCHAR(45) NULL,
    FOREIGN KEY (`user_id`) REFERENCES `casino_users`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_game_type` (`game_type`),
    INDEX `idx_session_hash` (`session_hash`),
    INDEX `idx_started_at` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `casino_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `citizenid` VARCHAR(50) NULL,
    `action` VARCHAR(100) NOT NULL,
    `category` ENUM('auth', 'banking', 'game', 'admin', 'security', 'system') NOT NULL,
    `level` ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info',
    `message` TEXT NOT NULL,
    `data` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` VARCHAR(500) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_category` (`category`),
    INDEX `idx_level` (`level`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create indexes for better performance
CREATE INDEX `idx_transactions_user_type` ON `casino_transactions` (`user_id`, `type`);
CREATE INDEX `idx_sessions_user_game` ON `casino_game_sessions` (`user_id`, `game_type`);
CREATE INDEX `idx_logs_category_level` ON `casino_logs` (`category`, `level`);

-- Create views for common queries
CREATE OR REPLACE VIEW `casino_user_stats` AS
SELECT 
    u.id,
    u.citizenid,
    u.username,
    u.balance,
    u.total_deposited,
    u.total_withdrawn,
    u.total_wagered,
    u.total_won,
    COUNT(DISTINCT t.id) as total_transactions,
    COUNT(DISTINCT gs.id) as total_games_played,
    (u.total_won - u.total_wagered) as net_profit,
    u.created_at,
    u.last_login
FROM casino_users u
LEFT JOIN casino_transactions t ON u.id = t.user_id
LEFT JOIN casino_game_sessions gs ON u.id = gs.user_id
WHERE u.is_active = TRUE
GROUP BY u.id;

-- Insert default admin user (optional)
-- Password: admin123 (hashed with bcrypt)
INSERT IGNORE INTO `casino_users` (
    `citizenid`, 
    `username`, 
    `email`, 
    `password_hash`, 
    `verification_level`
) VALUES (
    'ADMIN001', 
    'admin', 
    'admin@casino.local', 
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYOwfQ7eP4K6tUu', 
    'verified'
);