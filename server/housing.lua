-- Advanced Garage System - Housing Integration
local HousingSystem = {}

-- Create housing garage
function CreateHousingGarage(houseId, owner, coords, spawn_coords, heading, capacity)
    if not Config.Housing.enabled then
        return false
    end
    
    local garageName = 'house_' .. houseId
    capacity = capacity or Config.Housing.defaultCapacity
    heading = heading or 0.0
    
    -- Check if garage already exists
    local existing = MySQL.single.await('SELECT name FROM garages WHERE name = ?', { garageName })
    if existing then
        Utils.Log(('Housing garage %s already exists'):format(garageName), 'WARN')
        return false
    end
    
    -- Create garage data
    local garageData = {
        name = garageName,
        label = 'House Garage #' .. houseId,
        type = 'housing',
        owner = owner,
        coords = coords,
        spawn_coords = spawn_coords,
        heading = heading,
        vehicle_types = {'car'},
        max_vehicles = capacity,
        location_restricted = 1,
        blip = nil, -- No blip for housing garages
        marker = {
            type = 36,
            color = { r = 0, g = 150, b = 255 },
            scale = { x = 1.5, y = 1.5, z = 1.0 }
        }
    }
    
    -- Insert garage
    local success = MySQL.insert.await([[
        INSERT INTO garages (name, label, type, owner, coords, spawn_coords, heading, vehicle_types, max_vehicles, location_restricted, marker)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        garageData.name,
        garageData.label,
        garageData.type,
        garageData.owner,
        json.encode(garageData.coords),
        json.encode(garageData.spawn_coords),
        garageData.heading,
        json.encode(garageData.vehicle_types),
        garageData.max_vehicles,
        garageData.location_restricted,
        json.encode(garageData.marker)
    })
    
    if success then
        -- Update clients
        HousingSystem.RefreshGarages()
        
        Utils.Log(('Housing garage %s created for owner %s'):format(garageName, owner), 'INFO')
        return garageName
    else
        Utils.Log(('Failed to create housing garage %s'):format(garageName), 'ERROR')
        return false
    end
end

-- Remove housing garage
function RemoveHousingGarage(houseId)
    if not Config.Housing.enabled then
        return false
    end
    
    local garageName = 'house_' .. houseId
    
    -- Check if garage exists
    local garage = MySQL.single.await('SELECT * FROM garages WHERE name = ? AND type = "housing"', { garageName })
    if not garage then
        Utils.Log(('Housing garage %s not found'):format(garageName), 'WARN')
        return false
    end
    
    -- Move all vehicles to default garage
    local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE garage = ?', { garageName })
    if vehicleCount and vehicleCount > 0 then
        MySQL.update.await('UPDATE player_vehicles SET garage = "legion_garage" WHERE garage = ?', { garageName })
        Utils.Log(('Moved %d vehicles from housing garage %s to default garage'):format(vehicleCount, garageName), 'INFO')
    end
    
    -- Delete garage
    local success = MySQL.update.await('DELETE FROM garages WHERE name = ? AND type = "housing"', { garageName })
    
    if success then
        -- Update clients
        HousingSystem.RefreshGarages()
        
        Utils.Log(('Housing garage %s removed'):format(garageName), 'INFO')
        return true
    else
        Utils.Log(('Failed to remove housing garage %s'):format(garageName), 'ERROR')
        return false
    end
end

-- Update housing garage owner
function HousingSystem.UpdateGarageOwner(houseId, newOwner)
    if not Config.Housing.enabled then
        return false
    end
    
    local garageName = 'house_' .. houseId
    
    -- Update garage owner
    local success = MySQL.update.await('UPDATE garages SET owner = ? WHERE name = ? AND type = "housing"', {
        newOwner, garageName
    })
    
    if success then
        Utils.Log(('Housing garage %s owner updated to %s'):format(garageName, newOwner), 'INFO')
        return true
    else
        Utils.Log(('Failed to update housing garage %s owner'):format(garageName), 'ERROR')
        return false
    end
end

-- Get housing garage
function HousingSystem.GetHousingGarage(houseId)
    if not Config.Housing.enabled then
        return nil
    end
    
    local garageName = 'house_' .. houseId
    local garage = MySQL.single.await('SELECT * FROM garages WHERE name = ? AND type = "housing"', { garageName })
    
    if garage then
        garage.coords = json.decode(garage.coords)
        garage.spawn_coords = json.decode(garage.spawn_coords)
        garage.vehicle_types = json.decode(garage.vehicle_types)
        garage.marker = garage.marker and json.decode(garage.marker) or nil
    end
    
    return garage
end

-- Check if player owns housing garage
function HousingSystem.PlayerOwnsHousingGarage(identifier, houseId)
    if not Config.Housing.enabled then
        return false
    end
    
    local garageName = 'house_' .. houseId
    local garage = MySQL.single.await('SELECT owner FROM garages WHERE name = ? AND type = "housing"', { garageName })
    
    return garage and garage.owner == identifier
end

-- Get all housing garages for a player
function HousingSystem.GetPlayerHousingGarages(identifier)
    if not Config.Housing.enabled then
        return {}
    end
    
    local garages = MySQL.query.await('SELECT * FROM garages WHERE owner = ? AND type = "housing"', { identifier })
    
    if garages then
        for _, garage in pairs(garages) do
            garage.coords = json.decode(garage.coords)
            garage.spawn_coords = json.decode(garage.spawn_coords)
            garage.vehicle_types = json.decode(garage.vehicle_types)
            garage.marker = garage.marker and json.decode(garage.marker) or nil
        end
    end
    
    return garages or {}
end

-- Create private garage (for housing scripts that don't support garages)
function HousingSystem.CreatePrivateGarage(identifier, coords, spawn_coords, heading, capacity)
    if not Config.Housing.createPrivateIfNotSupported then
        return false
    end
    
    -- Generate unique garage name
    local garageName = 'private_' .. identifier .. '_' .. math.random(1000, 9999)
    
    -- Ensure uniqueness
    while MySQL.single.await('SELECT name FROM garages WHERE name = ?', { garageName }) do
        garageName = 'private_' .. identifier .. '_' .. math.random(1000, 9999)
    end
    
    capacity = capacity or Config.Housing.defaultCapacity
    heading = heading or 0.0
    
    -- Create garage data
    local garageData = {
        name = garageName,
        label = 'Private Garage',
        type = 'player',
        owner = identifier,
        coords = coords,
        spawn_coords = spawn_coords,
        heading = heading,
        vehicle_types = {'car'},
        max_vehicles = capacity,
        location_restricted = 1,
        blip = nil,
        marker = {
            type = 36,
            color = { r = 0, g = 255, b = 0 },
            scale = { x = 1.5, y = 1.5, z = 1.0 }
        }
    }
    
    -- Insert garage
    local success = MySQL.insert.await([[
        INSERT INTO garages (name, label, type, owner, coords, spawn_coords, heading, vehicle_types, max_vehicles, location_restricted, marker)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        garageData.name,
        garageData.label,
        garageData.type,
        garageData.owner,
        json.encode(garageData.coords),
        json.encode(garageData.spawn_coords),
        garageData.heading,
        json.encode(garageData.vehicle_types),
        garageData.max_vehicles,
        garageData.location_restricted,
        json.encode(garageData.marker)
    })
    
    if success then
        -- Update clients
        HousingSystem.RefreshGarages()
        
        Utils.Log(('Private garage %s created for %s'):format(garageName, identifier), 'INFO')
        return garageName
    else
        Utils.Log(('Failed to create private garage for %s'):format(identifier), 'ERROR')
        return false
    end
end

-- Refresh garages for all clients
function HousingSystem.RefreshGarages()
    local garages = MySQL.query.await('SELECT * FROM garages')
    if garages then
        for _, garage in pairs(garages) do
            garage.coords = json.decode(garage.coords)
            garage.spawn_coords = json.decode(garage.spawn_coords)
            garage.vehicle_types = json.decode(garage.vehicle_types)
            garage.blip = garage.blip and json.decode(garage.blip) or nil
            garage.marker = garage.marker and json.decode(garage.marker) or nil
            garage.shared_access = garage.shared_access and json.decode(garage.shared_access) or nil
        end
        
        TriggerClientEvent('garage:client:updateGarages', -1, garages)
    end
end

-- Housing script integration examples
if Config.Housing.script == 'qb-houses' then
    -- QB-Houses integration
    RegisterNetEvent('qb-houses:server:buyHouse', function(houseId, coords)
        -- Create garage when house is bought
        local source = source
        local identifier = Utils.GetIdentifier(source)
        
        if identifier then
            -- Calculate garage position (adjust as needed)
            local garageCoords = {
                x = coords.x + 5.0,
                y = coords.y + 5.0,
                z = coords.z
            }
            
            local spawnCoords = {
                x = coords.x + 8.0,
                y = coords.y + 8.0,
                z = coords.z
            }
            
            CreateHousingGarage(houseId, identifier, garageCoords, spawnCoords, 0.0, Config.Housing.defaultCapacity)
        end
    end)
    
    RegisterNetEvent('qb-houses:server:sellHouse', function(houseId)
        -- Remove garage when house is sold
        RemoveHousingGarage(houseId)
    end)
    
elseif Config.Housing.script == 'qs-housing' then
    -- QS-Housing integration
    -- Add similar events for QS-Housing
    
elseif Config.Housing.script == 'esx_property' then
    -- ESX Property integration
    -- Add similar events for ESX Property
    
end

-- Manual integration events
RegisterNetEvent('garage:server:housing:createGarage', function(houseId, coords, spawn_coords, heading, capacity)
    local source = source
    local identifier = Utils.GetIdentifier(source)
    
    if identifier then
        CreateHousingGarage(houseId, identifier, coords, spawn_coords, heading, capacity)
    end
end)

RegisterNetEvent('garage:server:housing:removeGarage', function(houseId)
    RemoveHousingGarage(houseId)
end)

RegisterNetEvent('garage:server:housing:updateOwner', function(houseId, newOwner)
    HousingSystem.UpdateGarageOwner(houseId, newOwner)
end)

-- Export wrapper functions (these are called by housing scripts)
function CreateHousingGarageExport(houseId, owner, coords, spawn_coords, heading, capacity)
    return CreateHousingGarage(houseId, owner, coords, spawn_coords, heading, capacity)
end

function RemoveHousingGarageExport(houseId)
    return RemoveHousingGarage(houseId)
end

function UpdateHousingGarageOwner(houseId, newOwner)
    return HousingSystem.UpdateGarageOwner(houseId, newOwner)
end

function GetHousingGarage(houseId)
    return HousingSystem.GetHousingGarage(houseId)
end

function PlayerOwnsHousingGarage(identifier, houseId)
    return HousingSystem.PlayerOwnsHousingGarage(identifier, houseId)
end

function GetPlayerHousingGarages(identifier)
    return HousingSystem.GetPlayerHousingGarages(identifier)
end

function CreatePrivateGarage(identifier, coords, spawn_coords, heading, capacity)
    return HousingSystem.CreatePrivateGarage(identifier, coords, spawn_coords, heading, capacity)
end

-- Server exports (called by other resources)
exports('CreateHousingGarage', CreateHousingGarageExport)
exports('RemoveHousingGarage', RemoveHousingGarageExport)
exports('UpdateHousingGarageOwner', UpdateHousingGarageOwner)
exports('GetHousingGarage', GetHousingGarage)
exports('PlayerOwnsHousingGarage', PlayerOwnsHousingGarage)
exports('GetPlayerHousingGarages', GetPlayerHousingGarages)
exports('CreatePrivateGarage', CreatePrivateGarage)