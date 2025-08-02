Config = {}

-- Framework settings
Config.Framework = 'qb-core' -- 'qb-core', 'esx', or 'standalone'
Config.Target = 'qb-target' -- 'qb-target', 'ox_target', or 'none'

-- Database settings
Config.UseOxMySQL = true

-- General settings
Config.Debug = false
Config.Locale = 'en'

-- UI Settings
Config.UI = {
    theme = 'blue', -- Mantine theme color
    shade = 6, -- Mantine shade (0-9)
    serverLogo = 'https://your-server.com/logo.png', -- Optional server logo URL
    showOverview = true, -- Enable/disable garage overview page
    maxDistance = 3.0, -- Maximum distance to interact with garages
    blipScale = 0.7,
    markerScale = { x = 2.0, y = 2.0, z = 1.0 },
}

-- Vehicle settings
Config.Vehicle = {
    despawnOnExit = true, -- Despawn vehicle when player exits
    despawnDelay = 60000, -- Delay before despawning (ms)
    transferFee = 500, -- Fee to transfer vehicles between garages
    renameFee = 100, -- Fee to rename vehicles
    locationRestricted = false, -- Globally enable/disable location restrictions
    saveFuelLevel = true, -- Save fuel level when storing
    saveVehicleHealth = true, -- Save vehicle health when storing
    returnToGarageOnDisconnect = true, -- Return owned vehicles to garage on disconnect
}

-- Impound settings
Config.Impound = {
    defaultFee = 1500, -- Default impound fee
    defaultReleaseTime = 30, -- Default release time in minutes
    canSelfRetrieve = true, -- Allow players to retrieve their own vehicles
    jobsCanImpound = { 'police', 'sheriff', 'highway' }, -- Jobs that can impound vehicles
    deleteAbandonedVehicles = true, -- Delete vehicles after certain time
    abandonedVehicleTime = 7 * 24 * 60, -- Time in minutes (7 days)
}

-- Spawner settings
Config.Spawner = {
    despawnOnJobChange = true, -- Despawn spawned vehicles when job changes
    maxSpawnedPerPlayer = 3, -- Maximum spawned vehicles per player
    fuelLevel = 100, -- Fuel level for spawned vehicles
    allowCustomization = false, -- Allow players to customize spawned vehicles
}

-- Housing integration
Config.Housing = {
    enabled = true, -- Enable housing garage integration
    script = 'qb-houses', -- Housing script name
    defaultCapacity = 5, -- Default garage capacity for houses
    createPrivateIfNotSupported = true, -- Create private garages if housing doesn't support
}

-- Staff permissions
Config.Staff = {
    groups = { 'god', 'admin', 'mod' }, -- Staff groups
    commands = {
        garage = 'garage', -- Admin garage command
        impound = 'impound', -- Admin impound command
        vehicle = 'veh', -- Vehicle management command
    },
    canBypassRestrictions = true, -- Staff can bypass all restrictions
}

-- Shared garage settings
Config.SharedGarage = {
    enabled = true,
    maxSharedAccess = 20, -- Maximum players with access to a shared garage
    allowPlayerManagement = true, -- Allow players to manage their own shared garages
    transferBetweenShared = true, -- Allow transferring vehicles between shared garages
}

-- Notification settings
Config.Notifications = {
    type = 'ox_lib', -- 'ox_lib', 'qb-core', 'esx', or 'custom'
    duration = 5000, -- Notification duration in ms
}

-- Economy settings
Config.Economy = {
    currency = 'cash', -- 'cash', 'bank', or custom
    useSocietyAccount = false, -- Use society accounts for job garages
}

-- Vehicle types and their properties
Config.VehicleTypes = {
    car = {
        label = 'Cars',
        class = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20 },
        spawnHeight = 1.0,
    },
    boat = {
        label = 'Boats',
        class = { 14 },
        spawnHeight = -0.5,
    },
    aircraft = {
        label = 'Aircraft',
        class = { 15, 16 },
        spawnHeight = 1.0,
    },
    motorcycle = {
        label = 'Motorcycles', 
        class = { 8 },
        spawnHeight = 1.0,
    },
}

-- Default vehicle lists for spawners
Config.DefaultVehicles = {
    police = {
        { model = 'police', label = 'Police Cruiser' },
        { model = 'police2', label = 'Police Buffalo' },
        { model = 'policeb', label = 'Police Bike' },
        { model = 'polmav', label = 'Police Maverick' },
    },
    ambulance = {
        { model = 'ambulance', label = 'Ambulance' },
        { model = 'firetruk', label = 'Fire Truck' },
        { model = 'lguard', label = 'Lifeguard' },
    },
    mechanic = {
        { model = 'towtruck', label = 'Tow Truck' },
        { model = 'towtruck2', label = 'Tow Truck 2' },
        { model = 'flatbed', label = 'Flatbed' },
    },
}

-- Blip settings
Config.Blips = {
    garage = {
        sprite = 357,
        color = 3,
        scale = 0.7,
        shortRange = true,
    },
    impound = {
        sprite = 68,
        color = 1,
        scale = 0.7,
        shortRange = true,
    },
    spawner = {
        sprite = 326,
        color = 2,
        scale = 0.7,
        shortRange = true,
    },
}

-- Marker settings
Config.Markers = {
    garage = {
        type = 36,
        color = { r = 0, g = 100, b = 255 },
        scale = { x = 2.0, y = 2.0, z = 1.0 },
        bobUpAndDown = true,
        rotate = true,
    },
    impound = {
        type = 36,
        color = { r = 255, g = 0, b = 0 },
        scale = { x = 2.0, y = 2.0, z = 1.0 },
        bobUpAndDown = true,
        rotate = true,
    },
    spawner = {
        type = 36,
        color = { r = 0, g = 255, b = 0 },
        scale = { x = 2.0, y = 2.0, z = 1.0 },
        bobUpAndDown = true,
        rotate = true,
    },
}

-- Keybinds
Config.Keybinds = {
    openGarage = 'E', -- Key to open garage menu
    storeVehicle = 'G', -- Key to store current vehicle
}

-- Debug settings
Config.DebugOptions = {
    showCoords = false, -- Show coordinates in garage menu
    showVehicleInfo = false, -- Show detailed vehicle info
    logQueries = false, -- Log database queries
}

-- Locale strings
Config.Locales = {
    en = {
        -- Garage
        garage_label = 'Garage',
        no_vehicles = 'No vehicles in garage',
        vehicle_spawned = 'Vehicle spawned',
        vehicle_stored = 'Vehicle stored',
        vehicle_not_owned = 'You don\'t own this vehicle',
        garage_full = 'Garage is full',
        vehicle_exists = 'Vehicle already exists in the world',
        
        -- Impound
        impound_label = 'Impound',
        vehicle_impounded = 'Vehicle impounded',
        vehicle_released = 'Vehicle released from impound',
        impound_fee_paid = 'Impound fee of $%s paid',
        insufficient_funds = 'Insufficient funds',
        cannot_retrieve = 'Cannot retrieve vehicle yet',
        
        -- Spawner
        spawner_label = 'Vehicle Spawner',
        vehicle_spawned_job = 'Job vehicle spawned',
        no_permission = 'No permission to use this spawner',
        
        -- Transfer
        vehicle_transferred = 'Vehicle transferred successfully',
        transfer_fee = 'Transfer fee: $%s',
        same_garage = 'Vehicle is already in this garage',
        
        -- Errors
        error_occurred = 'An error occurred',
        invalid_vehicle = 'Invalid vehicle',
        player_not_found = 'Player not found',
        garage_not_found = 'Garage not found',
    }
}