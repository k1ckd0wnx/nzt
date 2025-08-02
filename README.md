# Advanced Garage System

A comprehensive FiveM garage script with advanced features including garages, impounds, spawners, shared access, housing integration, and a beautiful Mantine-themed UI.

## Features

### 🚗 **Garages**
- **Public Garages**: Accessible to all players
- **Job Garages**: Restricted to specific jobs with grade requirements
- **Gang Garages**: Exclusive access for gang members
- **Player Garages**: Private garages for individual players
- **Housing Garages**: Seamless integration with housing scripts
- **Shared Garages**: Multiple players can access with configurable permissions

### 🚔 **Impound System**
- **Public Impounds**: Players can retrieve vehicles after time/fee
- **Job-Restricted Impounds**: Only specific jobs can release vehicles
- **Configurable Release Times**: Set custom time delays
- **Configurable Fees**: Set custom retrieval fees
- **Self-Retrieval Options**: Players can pay to get vehicles back
- **Admin Force Release**: Staff can instantly release any vehicle

### 🛻 **Vehicle Spawners**
- **Job Spawners**: Pre-configured vehicles for specific jobs
- **Gang Spawners**: Exclusive vehicle access for gangs
- **Donator Spawners**: Special vehicles for donators
- **Grade Requirements**: Limit access by job/gang grade
- **Automatic Cleanup**: Vehicles despawn on job change

### 🏠 **Housing Integration**
- **Easy Integration**: Two simple exports for housing scripts
- **Automatic Garage Creation**: Garages created when houses are bought
- **Private Fallback**: Creates private garages if housing doesn't support
- **Owner Management**: Automatically updates garage ownership

### 🎨 **User Interface**
- **Mantine Theme**: Beautiful blue (shade 6) themed interface
- **Responsive Design**: Works on all screen sizes
- **Search & Filter**: Find vehicles quickly
- **Vehicle Management**: Rename, favorite, and transfer vehicles
- **Real-time Updates**: Live fuel, health, and status indicators

### ⚙️ **Advanced Features**
- **Location Restrictions**: Vehicles can only be retrieved from storage location
- **Transfer System**: Move vehicles between garages for a fee
- **Favorite System**: Mark frequently used vehicles
- **Vehicle Nicknames**: Custom names for your vehicles
- **Health Tracking**: Engine and body damage monitoring
- **Fuel Integration**: Compatible with multiple fuel systems

### 👨‍💼 **Staff Tools**
- **In-Game Admin Panel**: Manage everything through UI
- **Console Commands**: Complete command-line management
- **Vehicle Management**: Add, remove, transfer, and modify vehicles
- **Garage Management**: Create, delete, and modify garages
- **Impound Management**: Full impound system control
- **Real-time Monitoring**: Track all system activities

## Installation

### Prerequisites
- **ox_lib**: Required for UI and utilities
- **oxmysql**: Required for database operations
- **qb-core** or **es_extended**: Supported frameworks

### Steps

1. **Download and Extract**
   ```bash
   cd resources
   git clone https://github.com/your-repo/advanced-garage.git
   ```

2. **Install Dependencies**
   ```bash
   cd advanced-garage/web
   npm install
   npm run build
   ```

3. **Database Setup**
   - Import `database.sql` into your database
   - Default garages and impounds will be created automatically

4. **Configuration**
   - Edit `config.lua` to match your server setup
   - Configure framework, target system, and other settings

5. **Start Resource**
   ```lua
   ensure ox_lib
   ensure oxmysql
   ensure advanced-garage
   ```

## Configuration

### Framework Setup
```lua
Config.Framework = 'qb-core' -- 'qb-core', 'esx', or 'standalone'
Config.Target = 'qb-target'   -- 'qb-target', 'ox_target', or 'none'
```

### UI Customization
```lua
Config.UI = {
    theme = 'blue',           -- Mantine theme color
    shade = 6,                -- Mantine shade (0-9)
    serverLogo = 'url',       -- Optional server logo
    showOverview = true,      -- Enable garage overview
    maxDistance = 3.0,        -- Interaction distance
}
```

### Vehicle Settings
```lua
Config.Vehicle = {
    despawnOnExit = true,     -- Auto-despawn vehicles
    despawnDelay = 60000,     -- Despawn delay (ms)
    transferFee = 500,        -- Transfer fee between garages
    renameFee = 100,          -- Fee to rename vehicles
    locationRestricted = false, -- Global location restrictions
}
```

## Usage

### For Players

#### Garage Interaction
1. **Approach** any garage marker
2. **Press E** to open the garage menu
3. **Browse** your vehicles with search and filters
4. **Spawn** vehicles with a single click
5. **Manage** vehicles (rename, favorite, transfer)

#### Storing Vehicles
1. **Drive** to any garage location
2. **Press G** while in/near vehicle to store it
3. **Automatic** detection of nearest compatible garage

#### Vehicle Management
- **Rename**: Give custom names to your vehicles
- **Favorite**: Mark frequently used vehicles
- **Transfer**: Move vehicles between garages (fee applies)
- **Health Monitoring**: View engine and body condition

### For Staff

#### Console Commands
```lua
/garage create <name> [type] [job/gang]  -- Create garage at current position
/garage delete <name>                    -- Delete garage
/garage list                             -- List all garages
/garage give <player_id> <model> [garage] -- Give vehicle to player
/garage remove <plate>                   -- Remove vehicle
/garage plate <old> <new>                -- Change vehicle plate
/garage return <plate> [garage]          -- Return vehicle to garage

/impound create <name> [type] [job]      -- Create impound at current position
/impound vehicle <plate> <impound> [reason] -- Impound a vehicle
/impound release <plate>                 -- Release from impound
/impound list                            -- List impounded vehicles

/veh info <plate>                        -- Get vehicle information
/veh owner <player_id>                   -- List player's vehicles
/veh transfer <plate> <new_owner_id>     -- Transfer ownership
/veh delete <plate>                      -- Delete vehicle
/veh fix <plate>                         -- Repair vehicle

/garageadmin                             -- Open admin panel UI
```

#### Admin Panel
Access the full admin panel with `/garageadmin` for:
- Garage management
- Vehicle management  
- Impound management
- Player vehicle monitoring
- System statistics

## Housing Integration

### For Housing Script Developers

The system provides simple exports for easy integration:

```lua
-- Create housing garage
exports['advanced-garage']:CreateHousingGarage(houseId, owner, coords, spawn_coords, heading, capacity)

-- Remove housing garage
exports['advanced-garage']:RemoveHousingGarage(houseId)

-- Update garage owner
exports['advanced-garage']:UpdateHousingGarageOwner(houseId, newOwner)

-- Check if player owns housing garage
local owns = exports['advanced-garage']:PlayerOwnsHousingGarage(identifier, houseId)

-- Get player's housing garages
local garages = exports['advanced-garage']:GetPlayerHousingGarages(identifier)
```

### Example Integration (QB-Houses)
```lua
-- When house is purchased
RegisterNetEvent('qb-houses:server:buyHouse', function(houseId, coords)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player then
        exports['advanced-garage']:CreateHousingGarage(
            houseId, 
            Player.PlayerData.citizenid,
            { x = coords.x + 5, y = coords.y + 5, z = coords.z },
            { x = coords.x + 8, y = coords.y + 8, z = coords.z },
            0.0,
            5
        )
    end
end)
```

## API Reference

### Server Exports
```lua
-- Vehicle Management
exports['advanced-garage']:GetPlayerVehicles(identifier, garage)
exports['advanced-garage']:AddVehicleToGarage(identifier, vehicleData, garage)
exports['advanced-garage']:RemoveVehicleFromGarage(plate)

-- Impound System
exports['advanced-garage']:ImpoundVehicle(plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
exports['advanced-garage']:ReleaseVehicle(plate, coords, heading, forcedRelease)

-- Garage Management
exports['advanced-garage']:CreateGarage(garageData)
exports['advanced-garage']:DeleteGarage(garageName)

-- Housing Integration
exports['advanced-garage']:CreateHousingGarage(houseId, owner, coords, spawn_coords, heading, capacity)
exports['advanced-garage']:RemoveHousingGarage(houseId)
```

### Client Exports
```lua
-- Vehicle Management
exports['advanced-garage']:GetPlayerVehicles(identifier, garage)
exports['advanced-garage']:AddVehicleToGarage(identifier, vehicleData, garage)
exports['advanced-garage']:RemoveVehicleFromGarage(plate)
```

## Fuel System Compatibility

The system automatically detects and supports:
- **LegacyFuel**
- **ps-fuel**  
- **ox_fuel**
- **Native GTA fuel**

## Performance

- **Optimized Database Queries**: Efficient MySQL operations
- **Client-Side Caching**: Reduced server load
- **Smart Proximity Detection**: Only checks nearby interactions
- **Async Operations**: Non-blocking database operations
- **Memory Efficient**: Minimal resource usage

## Support

For support, questions, or feature requests:
- **GitHub Issues**: [Create an issue](https://github.com/your-repo/advanced-garage/issues)
- **Discord**: Join our support server
- **Documentation**: Check the wiki for detailed guides

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- **ox_lib**: For UI framework and utilities
- **Mantine**: For the beautiful React components
- **Tabler Icons**: For the icon set
- **Community**: For feedback and testing

---

**Advanced Garage System** - The most comprehensive garage solution for FiveM servers.