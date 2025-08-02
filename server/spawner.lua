-- Advanced Garage System - Spawner System
local SpawnerSystem = {}

-- Track spawned vehicles per player
local spawnedVehicles = {}

-- Spawn a vehicle from spawner
function SpawnerSystem.SpawnVehicle(source, spawnerName, vehicleModel, coords, heading)
    local identifier = Utils.GetIdentifier(source)
    local job = Utils.GetPlayerJob(source)
    local gang = Utils.GetPlayerGang(source)
    
    if not identifier then return false end
    
    -- Get spawner data
    local spawner = MySQL.single.await('SELECT * FROM spawners WHERE name = ?', { spawnerName })
    if not spawner then
        Utils.Notify(source, 'Spawner not found', 'error')
        return false
    end
    
    spawner.vehicles = json.decode(spawner.vehicles)
    spawner.vehicle_types = json.decode(spawner.vehicle_types)
    
    -- Check if player can access spawner
    if not SpawnerSystem.CanAccessSpawner(source, spawner) then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Check if vehicle is available in spawner
    local vehicleFound = false
    for _, vehicle in pairs(spawner.vehicles) do
        if vehicle.model == vehicleModel then
            vehicleFound = true
            break
        end
    end
    
    if not vehicleFound then
        Utils.Notify(source, 'Vehicle not available in this spawner', 'error')
        return false
    end
    
    -- Check spawned vehicle limit
    spawnedVehicles[identifier] = spawnedVehicles[identifier] or {}
    if #spawnedVehicles[identifier] >= Config.Spawner.maxSpawnedPerPlayer then
        Utils.Notify(source, 'Maximum spawned vehicles reached', 'error')
        return false
    end
    
    -- Generate temporary plate
    local plate = 'SPAWNER' .. math.random(1000, 9999)
    
    -- Check if plate already exists
    while GetVehicleFromPlate(plate) do
        plate = 'SPAWNER' .. math.random(1000, 9999)
    end
    
    -- Spawn vehicle
    TriggerClientEvent('garage:client:spawnSpawnerVehicle', source, {
        model = vehicleModel,
        plate = plate,
        coords = coords,
        heading = heading,
        fuel = Config.Spawner.fuelLevel,
        spawnerType = spawner.type,
        allowCustomization = Config.Spawner.allowCustomization
    })
    
    -- Track spawned vehicle
    table.insert(spawnedVehicles[identifier], {
        plate = plate,
        model = vehicleModel,
        spawner = spawnerName,
        spawnTime = os.time()
    })
    
    Utils.Notify(source, Utils.GetLocale('vehicle_spawned_job'), 'success')
    Utils.Log(('Vehicle %s spawned from %s by %s'):format(vehicleModel, spawnerName, identifier), 'INFO')
    return true
end

-- Check if player can access spawner
function SpawnerSystem.CanAccessSpawner(source, spawner)
    local job = Utils.GetPlayerJob(source)
    local gang = Utils.GetPlayerGang(source)
    
    if not spawner then return false end
    
    -- Staff can access all spawners
    if Utils.HasPermission(source, 'admin') then
        return true
    end
    
    -- Check spawner type
    if spawner.type == 'job' then
        if job.name == spawner.job then
            -- Check grade requirement if set
            if spawner.grade and spawner.grade > 0 then
                return job.grade and job.grade.level >= spawner.grade
            end
            return true
        end
    elseif spawner.type == 'gang' then
        if gang.name == spawner.gang then
            -- Check grade requirement if set
            if spawner.grade and spawner.grade > 0 then
                return gang.grade and gang.grade.level >= spawner.grade
            end
            return true
        end
    elseif spawner.type == 'donator' then
        -- Check if player is donator (implement your own logic)
        return SpawnerSystem.IsDonator(source)
    end
    
    return false
end

-- Check if player is donator (customize this function)
function SpawnerSystem.IsDonator(source)
    -- Implement your own donator check logic here
    -- This could check a database, framework metadata, etc.
    return false
end

-- Get available vehicles for spawner
function SpawnerSystem.GetSpawnerVehicles(source, spawnerName)
    local spawner = MySQL.single.await('SELECT * FROM spawners WHERE name = ?', { spawnerName })
    if not spawner then return {} end
    
    spawner.vehicles = json.decode(spawner.vehicles)
    
    -- Check if player can access spawner
    if not SpawnerSystem.CanAccessSpawner(source, spawner) then
        return {}
    end
    
    return spawner.vehicles
end

-- Despawn spawner vehicle
function SpawnerSystem.DespawnVehicle(source, plate)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    if not spawnedVehicles[identifier] then return false end
    
    -- Find and remove vehicle from tracking
    for i, vehicle in pairs(spawnedVehicles[identifier]) do
        if vehicle.plate == plate then
            table.remove(spawnedVehicles[identifier], i)
            
            -- Delete vehicle from world
            TriggerClientEvent('garage:client:deleteVehicle', source, plate)
            
            Utils.Notify(source, 'Spawner vehicle despawned', 'success')
            return true
        end
    end
    
    return false
end

-- Get spawned vehicles for player
function SpawnerSystem.GetSpawnedVehicles(source)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return {} end
    
    return spawnedVehicles[identifier] or {}
end

-- Clean up spawned vehicles on job change
function SpawnerSystem.OnJobChange(source, newJob, oldJob)
    if not Config.Spawner.despawnOnJobChange then return end
    
    local identifier = Utils.GetIdentifier(source)
    if not identifier or not spawnedVehicles[identifier] then return end
    
    local vehiclesToRemove = {}
    
    for i, vehicle in pairs(spawnedVehicles[identifier]) do
        local spawner = MySQL.single.await('SELECT * FROM spawners WHERE name = ?', { vehicle.spawner })
        if spawner and spawner.type == 'job' and spawner.job == oldJob.name then
            -- Delete vehicle from world
            TriggerClientEvent('garage:client:deleteVehicle', source, vehicle.plate)
            table.insert(vehiclesToRemove, i)
        end
    end
    
    -- Remove vehicles from tracking (in reverse order to maintain indices)
    for i = #vehiclesToRemove, 1, -1 do
        table.remove(spawnedVehicles[identifier], vehiclesToRemove[i])
    end
    
    if #vehiclesToRemove > 0 then
        Utils.Notify(source, ('Despawned %d job vehicles due to job change'):format(#vehiclesToRemove), 'info')
    end
end

-- Helper function to get vehicle from plate
function GetVehicleFromPlate(plate)
    local vehicles = GetAllVehicles()
    for _, vehicle in pairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            return vehicle
        end
    end
    return nil
end

-- Register events
RegisterNetEvent('garage:server:spawnSpawnerVehicle', function(spawnerName, vehicleModel, coords, heading)
    local source = source
    SpawnerSystem.SpawnVehicle(source, spawnerName, vehicleModel, coords, heading)
end)

RegisterNetEvent('garage:server:despawnSpawnerVehicle', function(plate)
    local source = source
    SpawnerSystem.DespawnVehicle(source, plate)
end)

RegisterNetEvent('garage:server:getSpawnerVehicles', function(spawnerName)
    local source = source
    local vehicles = SpawnerSystem.GetSpawnerVehicles(source, spawnerName)
    TriggerClientEvent('garage:client:receiveSpawnerVehicles', source, vehicles)
end)

RegisterNetEvent('garage:server:getSpawnedVehicles', function()
    local source = source
    local vehicles = SpawnerSystem.GetSpawnedVehicles(source)
    TriggerClientEvent('garage:client:receiveSpawnedVehicles', source, vehicles)
end)

RegisterNetEvent('garage:server:checkSpawnerAccess', function(spawnerName)
    local source = source
    local spawner = MySQL.single.await('SELECT * FROM spawners WHERE name = ?', { spawnerName })
    
    if spawner then
        spawner.coords = json.decode(spawner.coords)
        spawner.spawn_coords = json.decode(spawner.spawn_coords)
        spawner.vehicles = json.decode(spawner.vehicles)
        spawner.vehicle_types = json.decode(spawner.vehicle_types)
        spawner.blip = spawner.blip and json.decode(spawner.blip) or nil
        spawner.marker = spawner.marker and json.decode(spawner.marker) or nil
        
        local hasAccess = SpawnerSystem.CanAccessSpawner(source, spawner)
        TriggerClientEvent('garage:client:spawnerAccessResult', source, spawnerName, hasAccess, spawner)
    else
        TriggerClientEvent('garage:client:spawnerAccessResult', source, spawnerName, false, nil)
    end
end)

-- Handle player disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    local identifier = Utils.GetIdentifier(source)
    
    if identifier and spawnedVehicles[identifier] then
        -- Clean up spawned vehicles
        spawnedVehicles[identifier] = nil
    end
end)

-- Framework specific job change events
if Utils.Framework == 'qb' then
    RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        if Player then
            SpawnerSystem.OnJobChange(source, job, Player.PlayerData.job)
        end
    end)
elseif Utils.Framework == 'esx' then
    RegisterNetEvent('esx:setJob', function(source, job, lastJob)
        SpawnerSystem.OnJobChange(source, job, lastJob)
    end)
end

-- Export functions
function SpawnSpawnerVehicle(source, spawnerName, vehicleModel, coords, heading)
    return SpawnerSystem.SpawnVehicle(source, spawnerName, vehicleModel, coords, heading)
end

function DespawnSpawnerVehicle(source, plate)
    return SpawnerSystem.DespawnVehicle(source, plate)
end