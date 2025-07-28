local playerPermissions = {}

-- ESX Support
if Config.UseESX then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

-- Utility Functions
function debugPrint(message)
    if Config.Debug then
        print("[VehicleSpawner-Server] " .. tostring(message))
    end
end

function getPlayerName(source)
    return GetPlayerName(source) or "Unknown"
end

function getPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.match(identifier, "steam:") then
            return identifier
        end
    end
    return "unknown"
end

function hasPermission(source)
    -- Basic admin check - you can modify this based on your server's permission system
    local playerName = getPlayerName(source)
    local playerId = source
    
    -- Check if player is admin (this is a basic example)
    if IsPlayerAceAllowed(source, "vehiclespawner.use") then
        return true
    end
    
    -- Check if using ESX and player has admin job
    if Config.UseESX and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, group in ipairs(Config.AllowedGroups) do
                if xPlayer.getGroup() == group then
                    return true
                end
            end
        end
    end
    
    -- For development/testing - allow everyone (remove this in production)
    return true
end

function logVehicleSpawn(source, vehicleModel)
    local playerName = getPlayerName(source)
    local identifier = getPlayerIdentifier(source)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    local logMessage = string.format(
        "[%s] Player: %s (%s) spawned vehicle: %s",
        timestamp,
        playerName,
        identifier,
        vehicleModel
    )
    
    debugPrint(logMessage)
    
    -- You can implement file logging here if needed
    -- Example: Save to logs/vehicle_spawns.log
end

-- Events
RegisterNetEvent('vehiclespawner:checkPermission')
AddEventHandler('vehiclespawner:checkPermission', function()
    local source = source
    local hasPerms = hasPermission(source)
    
    playerPermissions[source] = hasPerms
    
    TriggerClientEvent('vehiclespawner:permissionResult', source, hasPerms)
    
    if hasPerms then
        debugPrint("Player " .. getPlayerName(source) .. " has permission to use vehicle spawner")
    else
        debugPrint("Player " .. getPlayerName(source) .. " denied permission to use vehicle spawner")
    end
end)

RegisterNetEvent('vehiclespawner:requestSpawn')
AddEventHandler('vehiclespawner:requestSpawn', function(vehicleModel)
    local source = source
    
    if not hasPermission(source) then
        TriggerClientEvent('vehiclespawner:showNotification', source, "You don't have permission to spawn vehicles!", "error")
        return
    end
    
    -- Validate vehicle model
    if not vehicleModel or vehicleModel == "" then
        TriggerClientEvent('vehiclespawner:showNotification', source, "Invalid vehicle model!", "error")
        return
    end
    
    -- Log the spawn
    logVehicleSpawn(source, vehicleModel)
    
    -- Trigger client event to spawn vehicle
    TriggerClientEvent('vehiclespawner:spawnVehicle', source, vehicleModel)
    
    debugPrint("Spawning vehicle " .. vehicleModel .. " for player " .. getPlayerName(source))
end)

RegisterNetEvent('vehiclespawner:deleteVehicle')
AddEventHandler('vehiclespawner:deleteVehicle', function()
    local source = source
    
    if not hasPermission(source) then
        TriggerClientEvent('vehiclespawner:showNotification', source, "You don't have permission to delete vehicles!", "error")
        return
    end
    
    TriggerClientEvent('vehiclespawner:deleteCurrentVehicle', source)
    debugPrint("Player " .. getPlayerName(source) .. " deleted their vehicle")
end)

-- Commands
RegisterCommand('givecar', function(source, args, rawCommand)
    if source == 0 then -- Console command
        if #args < 2 then
            print("Usage: givecar [player_id] [vehicle_model]")
            return
        end
        
        local targetId = tonumber(args[1])
        local vehicleModel = args[2]
        
        if not targetId or not GetPlayerName(targetId) then
            print("Invalid player ID")
            return
        end
        
        TriggerClientEvent('vehiclespawner:spawnVehicle', targetId, vehicleModel)
        print("Spawned " .. vehicleModel .. " for player " .. GetPlayerName(targetId))
        
    else -- Player command
        if not hasPermission(source) then
            TriggerClientEvent('vehiclespawner:showNotification', source, "You don't have permission to use this command!", "error")
            return
        end
        
        if #args < 2 then
            TriggerClientEvent('vehiclespawner:showNotification', source, "Usage: /givecar [player_id] [vehicle_model]", "error")
            return
        end
        
        local targetId = tonumber(args[1])
        local vehicleModel = args[2]
        
        if not targetId or not GetPlayerName(targetId) then
            TriggerClientEvent('vehiclespawner:showNotification', source, "Invalid player ID", "error")
            return
        end
        
        TriggerClientEvent('vehiclespawner:spawnVehicle', targetId, vehicleModel)
        TriggerClientEvent('vehiclespawner:showNotification', source, "Spawned " .. vehicleModel .. " for " .. GetPlayerName(targetId), "success")
        
        logVehicleSpawn(source, vehicleModel .. " (given to " .. GetPlayerName(targetId) .. ")")
    end
end, true)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if playerPermissions[source] then
        playerPermissions[source] = nil
        debugPrint("Cleaned up permissions for disconnected player: " .. getPlayerName(source))
    end
end)

-- Resource start/stop events
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugPrint("Vehicle Spawner script started successfully!")
        
        -- Print available commands
        print("^2[VehicleSpawner]^7 Available commands:")
        print("^3/" .. Config.Commands.spawnVehicle .. " [model]^7 - Spawn a vehicle")
        print("^3/" .. Config.Commands.deleteVehicle .. "^7 - Delete current vehicle")
        print("^3/" .. Config.Commands.openMenu .. "^7 - Open vehicle menu")
        print("^3/givecar [id] [model]^7 - Give vehicle to player")
        print("^3F6^7 - Toggle vehicle menu")
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugPrint("Vehicle Spawner script stopped")
        playerPermissions = {}
    end
end)

-- Admin commands for managing the script
RegisterCommand('vehspawner_reload', function(source, args, rawCommand)
    if source ~= 0 and not hasPermission(source) then
        TriggerClientEvent('vehiclespawner:showNotification', source, "You don't have permission to use this command!", "error")
        return
    end
    
    -- Reload the resource
    ExecuteCommand('refresh')
    ExecuteCommand('restart ' .. GetCurrentResourceName())
    
    if source == 0 then
        print("Vehicle Spawner reloaded")
    else
        TriggerClientEvent('vehiclespawner:showNotification', source, "Vehicle Spawner reloaded", "success")
    end
end, true)

RegisterCommand('vehspawner_status', function(source, args, rawCommand)
    if source ~= 0 and not hasPermission(source) then
        TriggerClientEvent('vehiclespawner:showNotification', source, "You don't have permission to use this command!", "error")
        return
    end
    
    local playerCount = 0
    local permissionCount = 0
    
    for playerId in pairs(playerPermissions) do
        playerCount = playerCount + 1
        if playerPermissions[playerId] then
            permissionCount = permissionCount + 1
        end
    end
    
    local statusMessage = string.format(
        "Vehicle Spawner Status:\nPlayers online: %d\nPlayers with permissions: %d\nESX Enabled: %s",
        playerCount,
        permissionCount,
        Config.UseESX and "Yes" or "No"
    )
    
    if source == 0 then
        print(statusMessage)
    else
        TriggerClientEvent('vehiclespawner:showNotification', source, statusMessage, "info")
    end
end, true)