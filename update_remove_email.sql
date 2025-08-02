-- Migration Script: Remove Email Column
-- Run this if you have an existing casino_users table with email column

-- Check if email column exists and remove it
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'casino_users' 
AND COLUMN_NAME = 'email';

SET @sql = IF(@col_exists > 0, 
    'ALTER TABLE casino_users DROP COLUMN email', 
    'SELECT "Email column does not exist, no changes needed" as message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;