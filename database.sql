-- Advanced Garage System Database Schema

-- Garages table
CREATE TABLE IF NOT EXISTS `garages` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `type` enum('public', 'job', 'gang', 'player', 'housing', 'shared') NOT NULL DEFAULT 'public',
    `job` varchar(50) DEFAULT NULL,
    `gang` varchar(50) DEFAULT NULL,
    `owner` varchar(50) DEFAULT NULL,
    `shared_access` json DEFAULT NULL,
    `coords` json NOT NULL,
    `spawn_coords` json NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `vehicle_types` json NOT NULL DEFAULT '["car"]',
    `max_vehicles` int(11) NOT NULL DEFAULT 10,
    `blip` json DEFAULT NULL,
    `marker` json DEFAULT NULL,
    `location_restricted` tinyint(1) NOT NULL DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player vehicles table
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner` varchar(50) NOT NULL,
    `plate` varchar(15) NOT NULL,
    `vehicle` varchar(50) NOT NULL,
    `hash` int(11) NOT NULL,
    `mods` longtext NOT NULL DEFAULT '{}',
    `garage` varchar(50) DEFAULT NULL,
    `state` enum('out', 'garaged', 'impounded') NOT NULL DEFAULT 'garaged',
    `fuel` int(11) NOT NULL DEFAULT 100,
    `engine` float NOT NULL DEFAULT 1000.0,
    `body` float NOT NULL DEFAULT 1000.0,
    `nickname` varchar(50) DEFAULT NULL,
    `favorite` tinyint(1) NOT NULL DEFAULT 0,
    `last_coords` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    KEY `owner` (`owner`),
    KEY `garage` (`garage`),
    KEY `state` (`state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Impounds table
CREATE TABLE IF NOT EXISTS `impounds` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `type` enum('public', 'job') NOT NULL DEFAULT 'public',
    `job` varchar(50) DEFAULT NULL,
    `coords` json NOT NULL,
    `spawn_coords` json NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `retrieval_fee` int(11) NOT NULL DEFAULT 500,
    `release_time` int(11) NOT NULL DEFAULT 60,
    `blip` json DEFAULT NULL,
    `marker` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Impounded vehicles table
CREATE TABLE IF NOT EXISTS `impounded_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(15) NOT NULL,
    `impound` varchar(50) NOT NULL,
    `reason` varchar(255) DEFAULT NULL,
    `impounded_by` varchar(50) NOT NULL,
    `impounded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `release_at` timestamp NULL DEFAULT NULL,
    `fee` int(11) NOT NULL DEFAULT 0,
    `can_self_retrieve` tinyint(1) NOT NULL DEFAULT 1,
    `retrieved` tinyint(1) NOT NULL DEFAULT 0,
    `retrieved_by` varchar(50) DEFAULT NULL,
    `retrieved_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    KEY `impound` (`impound`),
    KEY `impounded_by` (`impounded_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Spawners table
CREATE TABLE IF NOT EXISTS `spawners` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `type` enum('job', 'gang', 'donator') NOT NULL,
    `job` varchar(50) DEFAULT NULL,
    `gang` varchar(50) DEFAULT NULL,
    `grade` int(11) DEFAULT NULL,
    `coords` json NOT NULL,
    `spawn_coords` json NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `vehicles` json NOT NULL DEFAULT '[]',
    `vehicle_types` json NOT NULL DEFAULT '["car"]',
    `blip` json DEFAULT NULL,
    `marker` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Shared garage access table
CREATE TABLE IF NOT EXISTS `shared_garage_access` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `garage` varchar(50) NOT NULL,
    `identifier` varchar(50) NOT NULL,
    `access_type` enum('player', 'job', 'gang') NOT NULL,
    `permissions` json NOT NULL DEFAULT '["view", "store", "retrieve"]',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `garage_identifier` (`garage`, `identifier`),
    KEY `garage` (`garage`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Transfer history table
CREATE TABLE IF NOT EXISTS `vehicle_transfers` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(15) NOT NULL,
    `from_garage` varchar(50) NOT NULL,
    `to_garage` varchar(50) NOT NULL,
    `transferred_by` varchar(50) NOT NULL,
    `fee` int(11) NOT NULL DEFAULT 0,
    `transferred_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `transferred_by` (`transferred_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default garages
INSERT IGNORE INTO `garages` (`name`, `label`, `type`, `coords`, `spawn_coords`, `heading`, `vehicle_types`, `blip`, `marker`) VALUES
('legion_garage', 'Legion Square Garage', 'public', '{"x": 215.9499, "y": -810.0537, "z": 30.7369}', '{"x": 229.7, "y": -800.1, "z": 30.6}', 157.5, '["car"]', '{"sprite": 357, "color": 3, "scale": 0.7}', '{"type": 36, "color": {"r": 0, "g": 100, "b": 255}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}'),
('airport_garage', 'Airport Garage', 'public', '{"x": -796.6, "y": -2024.6, "z": 8.9}', '{"x": -800.0, "y": -2016.0, "z": 9.0}', 135.0, '["car"]', '{"sprite": 357, "color": 3, "scale": 0.7}', '{"type": 36, "color": {"r": 0, "g": 100, "b": 255}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}'),
('boat_marina', 'Marina Boat Garage', 'public', '{"x": -794.8, "y": -1510.4, "z": 1.6}', '{"x": -798.0, "y": -1518.0, "z": 0.1}', 110.0, '["boat"]', '{"sprite": 356, "color": 3, "scale": 0.7}', '{"type": 36, "color": {"r": 0, "g": 100, "b": 255}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}'),
('airport_hangar', 'Airport Hangar', 'public', '{"x": -1617.49, "y": -3142.3, "z": 13.99}', '{"x": -1629.0, "y": -3104.0, "z": 13.9}', 329.0, '["aircraft"]', '{"sprite": 359, "color": 3, "scale": 0.7}', '{"type": 36, "color": {"r": 0, "g": 100, "b": 255}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}');

-- Insert default impounds
INSERT IGNORE INTO `impounds` (`name`, `label`, `type`, `coords`, `spawn_coords`, `heading`, `retrieval_fee`, `release_time`, `blip`, `marker`) VALUES
('misson_row_impound', 'Mission Row Impound', 'public', '{"x": 408.9, "y": -1625.1, "z": 29.3}', '{"x": 391.0, "y": -1619.0, "z": 29.3}', 231.0, 1500, 30, '{"sprite": 68, "color": 1, "scale": 0.7}', '{"type": 36, "color": {"r": 255, "g": 0, "b": 0}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}'),
('police_impound', 'Police Impound', 'job', '{"x": 409.3, "y": -1623.0, "z": 29.3}', '{"x": 391.0, "y": -1619.0, "z": 29.3}', 231.0, 0, 0, NULL, '{"type": 36, "color": {"r": 255, "g": 0, "b": 0}, "scale": {"x": 2.0, "y": 2.0, "z": 1.0}}');

UPDATE `impounds` SET `job` = 'police' WHERE `name` = 'police_impound';