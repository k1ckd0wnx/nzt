Config = {}

-- General Settings
Config.Debug = true
Config.UseESX = false -- Set to true if using ESX framework

-- Commands
Config.Commands = {
    spawnVehicle = 'spawnveh',
    deleteVehicle = 'dv',
    openMenu = 'vehspawner'
}

-- Permissions
Config.AllowedGroups = {
    'admin',
    'mod',
    'superadmin'
}

-- Vehicle Categories
Config.VehicleCategories = {
    {
        name = 'Sports Cars',
        vehicles = {
            {name = 'Adder', model = 'adder'},
            {name = 'Zentorno', model = 'zentorno'},
            {name = 'T20', model = 't20'},
            {name = 'Osiris', model = 'osiris'},
            {name = 'Turismo R', model = 'turismor'}
        }
    },
    {
        name = 'Super Cars',
        vehicles = {
            {name = 'Bugatti Chiron', model = 'nero'},
            {name = 'McLaren P1', model = 'pfister811'},
            {name = 'Koenigsegg', model = 'prototipo'},
            {name = 'Lamborghini', model = 'reaper'}
        }
    },
    {
        name = 'Motorcycles',
        vehicles = {
            {name = 'Akuma', model = 'akuma'},
            {name = 'Bati 801', model = 'bati'},
            {name = 'Hakuchou', model = 'hakuchou'},
            {name = 'PCJ 600', model = 'pcj'}
        }
    },
    {
        name = 'Aircraft',
        vehicles = {
            {name = 'Buzzard', model = 'buzzard2'},
            {name = 'Hydra', model = 'hydra'},
            {name = 'Luxor', model = 'luxor'},
            {name = 'Maverick', model = 'maverick'}
        }
    },
    {
        name = 'Emergency',
        vehicles = {
            {name = 'Police Cruiser', model = 'police'},
            {name = 'Police Bike', model = 'policeb'},
            {name = 'Ambulance', model = 'ambulance'},
            {name = 'Fire Truck', model = 'firetruk'}
        }
    }
}

-- Spawn Settings
Config.SpawnSettings = {
    deleteOldVehicle = true,
    spawnInVehicle = true,
    spawnUpgraded = false,
    maxDistance = 5.0 -- Maximum distance to spawn vehicle from player
}

-- UI Settings
Config.UI = {
    openKey = 'F6',
    closeKey = 'ESC'
}