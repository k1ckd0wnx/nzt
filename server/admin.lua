-- Advanced Garage System - Admin Tools
local AdminSystem = {}

-- Create garage
function AdminSystem.CreateGarage(source, garageData)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Validate required fields
    if not garageData.name or not garageData.label or not garageData.coords or not garageData.spawn_coords then
        Utils.Notify(source, 'Missing required garage data', 'error')
        return false
    end
    
    -- Check if garage name already exists
    local existing = MySQL.single.await('SELECT name FROM garages WHERE name = ?', { garageData.name })
    if existing then
        Utils.Notify(source, 'Garage name already exists', 'error')
        return false
    end
    
    -- Set default values
    garageData.type = garageData.type or 'public'
    garageData.heading = garageData.heading or 0.0
    garageData.vehicle_types = garageData.vehicle_types or {'car'}
    garageData.max_vehicles = garageData.max_vehicles or 10
    garageData.location_restricted = garageData.location_restricted or 0
    
    -- Insert garage
    local success = MySQL.insert.await([[
        INSERT INTO garages (name, label, type, job, gang, owner, coords, spawn_coords, heading, vehicle_types, max_vehicles, blip, marker, location_restricted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        garageData.name,
        garageData.label,
        garageData.type,
        garageData.job,
        garageData.gang,
        garageData.owner,
        json.encode(garageData.coords),
        json.encode(garageData.spawn_coords),
        garageData.heading,
        json.encode(garageData.vehicle_types),
        garageData.max_vehicles,
        garageData.blip and json.encode(garageData.blip) or nil,
        garageData.marker and json.encode(garageData.marker) or nil,
        garageData.location_restricted and 1 or 0
    })
    
    if success then
        -- Reload garages for all clients
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
        
        Utils.Notify(source, 'Garage created successfully', 'success')
        Utils.Log(('Garage %s created by %s'):format(garageData.name, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to create garage', 'error')
        return false
    end
end

-- Delete garage
function AdminSystem.DeleteGarage(source, garageName)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Check if garage exists
    local garage = MySQL.single.await('SELECT name FROM garages WHERE name = ?', { garageName })
    if not garage then
        Utils.Notify(source, Utils.GetLocale('garage_not_found'), 'error')
        return false
    end
    
    -- Move all vehicles from this garage to default garage
    MySQL.update.await('UPDATE player_vehicles SET garage = "legion_garage" WHERE garage = ?', { garageName })
    
    -- Delete garage
    local success = MySQL.update.await('DELETE FROM garages WHERE name = ?', { garageName })
    
    if success then
        -- Reload garages for all clients
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
        
        Utils.Notify(source, 'Garage deleted successfully', 'success')
        Utils.Log(('Garage %s deleted by %s'):format(garageName, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to delete garage', 'error')
        return false
    end
end

-- Create impound
function AdminSystem.CreateImpound(source, impoundData)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Validate required fields
    if not impoundData.name or not impoundData.label or not impoundData.coords or not impoundData.spawn_coords then
        Utils.Notify(source, 'Missing required impound data', 'error')
        return false
    end
    
    -- Check if impound name already exists
    local existing = MySQL.single.await('SELECT name FROM impounds WHERE name = ?', { impoundData.name })
    if existing then
        Utils.Notify(source, 'Impound name already exists', 'error')
        return false
    end
    
    -- Set default values
    impoundData.type = impoundData.type or 'public'
    impoundData.heading = impoundData.heading or 0.0
    impoundData.retrieval_fee = impoundData.retrieval_fee or Config.Impound.defaultFee
    impoundData.release_time = impoundData.release_time or Config.Impound.defaultReleaseTime
    
    -- Insert impound
    local success = MySQL.insert.await([[
        INSERT INTO impounds (name, label, type, job, coords, spawn_coords, heading, retrieval_fee, release_time, blip, marker)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        impoundData.name,
        impoundData.label,
        impoundData.type,
        impoundData.job,
        json.encode(impoundData.coords),
        json.encode(impoundData.spawn_coords),
        impoundData.heading,
        impoundData.retrieval_fee,
        impoundData.release_time,
        impoundData.blip and json.encode(impoundData.blip) or nil,
        impoundData.marker and json.encode(impoundData.marker) or nil
    })
    
    if success then
        -- Reload impounds for all clients
        local impounds = MySQL.query.await('SELECT * FROM impounds')
        if impounds then
            for _, impound in pairs(impounds) do
                impound.coords = json.decode(impound.coords)
                impound.spawn_coords = json.decode(impound.spawn_coords)
                impound.blip = impound.blip and json.decode(impound.blip) or nil
                impound.marker = impound.marker and json.decode(impound.marker) or nil
            end
            TriggerClientEvent('garage:client:updateImpounds', -1, impounds)
        end
        
        Utils.Notify(source, 'Impound created successfully', 'success')
        Utils.Log(('Impound %s created by %s'):format(impoundData.name, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to create impound', 'error')
        return false
    end
end

-- Create spawner
function AdminSystem.CreateSpawner(source, spawnerData)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Validate required fields
    if not spawnerData.name or not spawnerData.label or not spawnerData.coords or not spawnerData.spawn_coords then
        Utils.Notify(source, 'Missing required spawner data', 'error')
        return false
    end
    
    -- Check if spawner name already exists
    local existing = MySQL.single.await('SELECT name FROM spawners WHERE name = ?', { spawnerData.name })
    if existing then
        Utils.Notify(source, 'Spawner name already exists', 'error')
        return false
    end
    
    -- Set default values
    spawnerData.type = spawnerData.type or 'job'
    spawnerData.heading = spawnerData.heading or 0.0
    spawnerData.vehicles = spawnerData.vehicles or {}
    spawnerData.vehicle_types = spawnerData.vehicle_types or {'car'}
    
    -- Insert spawner
    local success = MySQL.insert.await([[
        INSERT INTO spawners (name, label, type, job, gang, grade, coords, spawn_coords, heading, vehicles, vehicle_types, blip, marker)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        spawnerData.name,
        spawnerData.label,
        spawnerData.type,
        spawnerData.job,
        spawnerData.gang,
        spawnerData.grade,
        json.encode(spawnerData.coords),
        json.encode(spawnerData.spawn_coords),
        spawnerData.heading,
        json.encode(spawnerData.vehicles),
        json.encode(spawnerData.vehicle_types),
        spawnerData.blip and json.encode(spawnerData.blip) or nil,
        spawnerData.marker and json.encode(spawnerData.marker) or nil
    })
    
    if success then
        -- Reload spawners for all clients
        local spawners = MySQL.query.await('SELECT * FROM spawners')
        if spawners then
            for _, spawner in pairs(spawners) do
                spawner.coords = json.decode(spawner.coords)
                spawner.spawn_coords = json.decode(spawner.spawn_coords)
                spawner.vehicles = json.decode(spawner.vehicles)
                spawner.vehicle_types = json.decode(spawner.vehicle_types)
                spawner.blip = spawner.blip and json.decode(spawner.blip) or nil
                spawner.marker = spawner.marker and json.decode(spawner.marker) or nil
            end
            TriggerClientEvent('garage:client:updateSpawners', -1, spawners)
        end
        
        Utils.Notify(source, 'Spawner created successfully', 'success')
        Utils.Log(('Spawner %s created by %s'):format(spawnerData.name, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to create spawner', 'error')
        return false
    end
end

-- Give vehicle to player
function AdminSystem.GiveVehicle(source, targetIdentifier, vehicleModel, garage)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    garage = garage or 'legion_garage'
    local plate = Utils.GeneratePlate()
    
    local success = MySQL.insert.await([[
        INSERT INTO player_vehicles (owner, plate, vehicle, hash, mods, garage, state, fuel, engine, body)
        VALUES (?, ?, ?, ?, '{}', ?, 'garaged', 100, 1000.0, 1000.0)
    ]], {
        targetIdentifier,
        plate,
        vehicleModel,
        GetHashKey(vehicleModel)
    })
    
    if success then
        Utils.Notify(source, ('Vehicle %s given to player with plate %s'):format(vehicleModel, plate), 'success')
        
        -- Notify target player if online
        local targetSource = GetPlayerFromIdentifier(targetIdentifier)
        if targetSource then
            Utils.Notify(targetSource, ('You have been given a %s by an administrator'):format(vehicleModel), 'success')
        end
        
        Utils.Log(('Vehicle %s given to %s by %s'):format(vehicleModel, targetIdentifier, Utils.GetIdentifier(source)), 'INFO')
        return plate
    else
        Utils.Notify(source, 'Failed to give vehicle', 'error')
        return false
    end
end

-- Remove vehicle
function AdminSystem.RemoveVehicle(source, plate)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('invalid_vehicle'), 'error')
        return false
    end
    
    -- Delete vehicle
    local success = MySQL.update.await('DELETE FROM player_vehicles WHERE plate = ?', { plate })
    
    if success then
        -- Delete from world if spawned
        TriggerClientEvent('garage:client:deleteVehicle', -1, plate)
        
        Utils.Notify(source, ('Vehicle %s removed successfully'):format(plate), 'success')
        Utils.Log(('Vehicle %s removed by %s'):format(plate, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to remove vehicle', 'error')
        return false
    end
end

-- Change vehicle plate
function AdminSystem.ChangeVehiclePlate(source, oldPlate, newPlate)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Check if old plate exists
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { oldPlate })
    if not vehicle then
        Utils.Notify(source, 'Vehicle with old plate not found', 'error')
        return false
    end
    
    -- Check if new plate already exists
    local existing = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ?', { newPlate })
    if existing then
        Utils.Notify(source, 'New plate already exists', 'error')
        return false
    end
    
    -- Update plate
    local success = MySQL.update.await('UPDATE player_vehicles SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
    
    if success then
        -- Update impound records
        MySQL.update.await('UPDATE impounded_vehicles SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
        
        -- Update transfer records
        MySQL.update.await('UPDATE vehicle_transfers SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
        
        Utils.Notify(source, ('Vehicle plate changed from %s to %s'):format(oldPlate, newPlate), 'success')
        Utils.Log(('Vehicle plate changed from %s to %s by %s'):format(oldPlate, newPlate, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to change vehicle plate', 'error')
        return false
    end
end

-- Return vehicle to garage
function AdminSystem.ReturnVehicleToGarage(source, plate, garage)
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    garage = garage or 'legion_garage'
    
    -- Update vehicle state
    local success = MySQL.update.await('UPDATE player_vehicles SET state = "garaged", garage = ? WHERE plate = ?', {
        garage, plate
    })
    
    if success then
        -- Delete from world
        TriggerClientEvent('garage:client:deleteVehicle', -1, plate)
        
        -- Remove from impound if impounded
        MySQL.update.await('UPDATE impounded_vehicles SET retrieved = 1, retrieved_by = ?, retrieved_at = NOW() WHERE plate = ? AND retrieved = 0', {
            Utils.GetIdentifier(source), plate
        })
        
        Utils.Notify(source, ('Vehicle %s returned to %s'):format(plate, garage), 'success')
        Utils.Log(('Vehicle %s returned to %s by %s'):format(plate, garage, Utils.GetIdentifier(source)), 'INFO')
        return true
    else
        Utils.Notify(source, 'Failed to return vehicle to garage', 'error')
        return false
    end
end

-- Get all garages
function AdminSystem.GetAllGarages()
    local garages = MySQL.query.await('SELECT * FROM garages ORDER BY name')
    if garages then
        for _, garage in pairs(garages) do
            garage.coords = json.decode(garage.coords)
            garage.spawn_coords = json.decode(garage.spawn_coords)
            garage.vehicle_types = json.decode(garage.vehicle_types)
            garage.blip = garage.blip and json.decode(garage.blip) or nil
            garage.marker = garage.marker and json.decode(garage.marker) or nil
            garage.shared_access = garage.shared_access and json.decode(garage.shared_access) or nil
        end
    end
    return garages or {}
end

-- Get all impounds
function AdminSystem.GetAllImpounds()
    local impounds = MySQL.query.await('SELECT * FROM impounds ORDER BY name')
    if impounds then
        for _, impound in pairs(impounds) do
            impound.coords = json.decode(impound.coords)
            impound.spawn_coords = json.decode(impound.spawn_coords)
            impound.blip = impound.blip and json.decode(impound.blip) or nil
            impound.marker = impound.marker and json.decode(impound.marker) or nil
        end
    end
    return impounds or {}
end

-- Get all spawners
function AdminSystem.GetAllSpawners()
    local spawners = MySQL.query.await('SELECT * FROM spawners ORDER BY name')
    if spawners then
        for _, spawner in pairs(spawners) do
            spawner.coords = json.decode(spawner.coords)
            spawner.spawn_coords = json.decode(spawner.spawn_coords)
            spawner.vehicles = json.decode(spawner.vehicles)
            spawner.vehicle_types = json.decode(spawner.vehicle_types)
            spawner.blip = spawner.blip and json.decode(spawner.blip) or nil
            spawner.marker = spawner.marker and json.decode(spawner.marker) or nil
        end
    end
    return spawners or {}
end

-- Helper function to get player by identifier
function GetPlayerFromIdentifier(identifier)
    local players = GetPlayers()
    for _, playerId in pairs(players) do
        if Utils.GetIdentifier(playerId) == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Register admin events
RegisterNetEvent('garage:server:admin:createGarage', function(garageData)
    local source = source
    AdminSystem.CreateGarage(source, garageData)
end)

RegisterNetEvent('garage:server:admin:deleteGarage', function(garageName)
    local source = source
    AdminSystem.DeleteGarage(source, garageName)
end)

RegisterNetEvent('garage:server:admin:createImpound', function(impoundData)
    local source = source
    AdminSystem.CreateImpound(source, impoundData)
end)

RegisterNetEvent('garage:server:admin:createSpawner', function(spawnerData)
    local source = source
    AdminSystem.CreateSpawner(source, spawnerData)
end)

RegisterNetEvent('garage:server:admin:giveVehicle', function(targetIdentifier, vehicleModel, garage)
    local source = source
    AdminSystem.GiveVehicle(source, targetIdentifier, vehicleModel, garage)
end)

RegisterNetEvent('garage:server:admin:removeVehicle', function(plate)
    local source = source
    AdminSystem.RemoveVehicle(source, plate)
end)

RegisterNetEvent('garage:server:admin:changeVehiclePlate', function(oldPlate, newPlate)
    local source = source
    AdminSystem.ChangeVehiclePlate(source, oldPlate, newPlate)
end)

RegisterNetEvent('garage:server:admin:returnVehicle', function(plate, garage)
    local source = source
    AdminSystem.ReturnVehicleToGarage(source, plate, garage)
end)

RegisterNetEvent('garage:server:admin:getData', function()
    local source = source
    
    if not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return
    end
    
    local data = {
        garages = AdminSystem.GetAllGarages(),
        impounds = AdminSystem.GetAllImpounds(),
        spawners = AdminSystem.GetAllSpawners()
    }
    
    TriggerClientEvent('garage:client:admin:receiveData', source, data)
end)

-- Export functions
function CreateGarage(garageData)
    return AdminSystem.CreateGarage(nil, garageData)
end

function DeleteGarage(garageName)
    return AdminSystem.DeleteGarage(nil, garageName)
end