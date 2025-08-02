-- Advanced Garage System - Server Main
local GarageSystem = {}

-- Initialize the garage system
function GarageSystem.Init()
    CreateThread(function()
        -- Initialize database tables
        GarageSystem.InitializeDatabase()
        
        -- Load garages, impounds, and spawners
        GarageSystem.LoadGarages()
        GarageSystem.LoadImpounds()
        GarageSystem.LoadSpawners()
        
        Utils.Log('Garage System initialized successfully', 'SUCCESS')
    end)
end

-- Initialize database
function GarageSystem.InitializeDatabase()
    if Config.UseOxMySQL then
        -- Check if tables exist, create if not
        local success = MySQL.query.await('SHOW TABLES LIKE "garages"')
        if not success or #success == 0 then
            Utils.Log('Database tables not found, please run database.sql', 'ERROR')
        end
    end
end

-- Load garages from database
function GarageSystem.LoadGarages()
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
        Utils.Log(('Loaded %d garages'):format(#garages), 'INFO')
    end
end

-- Load impounds from database
function GarageSystem.LoadImpounds()
    local impounds = MySQL.query.await('SELECT * FROM impounds')
    if impounds then
        for _, impound in pairs(impounds) do
            impound.coords = json.decode(impound.coords)
            impound.spawn_coords = json.decode(impound.spawn_coords)
            impound.blip = impound.blip and json.decode(impound.blip) or nil
            impound.marker = impound.marker and json.decode(impound.marker) or nil
        end
        
        TriggerClientEvent('garage:client:updateImpounds', -1, impounds)
        Utils.Log(('Loaded %d impounds'):format(#impounds), 'INFO')
    end
end

-- Load spawners from database
function GarageSystem.LoadSpawners()
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
        Utils.Log(('Loaded %d spawners'):format(#spawners), 'INFO')
    end
end

-- Get player vehicles
function GarageSystem.GetPlayerVehicles(source, garage)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return {} end
    
    local query = 'SELECT * FROM player_vehicles WHERE owner = ?'
    local params = { identifier }
    
    if garage then
        query = query .. ' AND garage = ?'
        table.insert(params, garage)
    end
    
    local vehicles = MySQL.query.await(query, params)
    
    if vehicles then
        for _, vehicle in pairs(vehicles) do
            vehicle.mods = json.decode(vehicle.mods)
            vehicle.last_coords = vehicle.last_coords and json.decode(vehicle.last_coords) or nil
        end
    end
    
    return vehicles or {}
end

-- Check if player can access garage
function GarageSystem.CanAccessGarage(source, garage)
    local identifier = Utils.GetIdentifier(source)
    local job = Utils.GetPlayerJob(source)
    local gang = Utils.GetPlayerGang(source)
    
    if not garage then return false end
    
    -- Staff can bypass restrictions
    if Config.Staff.canBypassRestrictions and Utils.HasPermission(source, 'admin') then
        return true
    end
    
    -- Check garage type
    if garage.type == 'public' then
        return true
    elseif garage.type == 'job' then
        return job.name == garage.job
    elseif garage.type == 'gang' then
        return gang.name == garage.gang
    elseif garage.type == 'player' then
        return identifier == garage.owner
    elseif garage.type == 'housing' then
        return identifier == garage.owner
    elseif garage.type == 'shared' then
        -- Check shared access
        local hasAccess = MySQL.scalar.await('SELECT COUNT(*) FROM shared_garage_access WHERE garage = ? AND identifier = ?', {
            garage.name, identifier
        })
        
        if hasAccess and hasAccess > 0 then
            return true
        end
        
        -- Check job/gang access
        if job.name then
            local jobAccess = MySQL.scalar.await('SELECT COUNT(*) FROM shared_garage_access WHERE garage = ? AND identifier = ? AND access_type = "job"', {
                garage.name, job.name
            })
            if jobAccess and jobAccess > 0 then return true end
        end
        
        if gang.name then
            local gangAccess = MySQL.scalar.await('SELECT COUNT(*) FROM shared_garage_access WHERE garage = ? AND identifier = ? AND access_type = "gang"', {
                garage.name, gang.name
            })
            if gangAccess and gangAccess > 0 then return true end
        end
    end
    
    return false
end

-- Spawn vehicle
function GarageSystem.SpawnVehicle(source, plate, coords, heading)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND owner = ?', {
        plate, identifier
    })
    
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_owned'), 'error')
        return false
    end
    
    if vehicle.state ~= 'garaged' then
        Utils.Notify(source, Utils.GetLocale('vehicle_exists'), 'error')
        return false
    end
    
    -- Update vehicle state
    MySQL.update.await('UPDATE player_vehicles SET state = "out", last_coords = ? WHERE plate = ?', {
        json.encode(coords), plate
    })
    
    -- Trigger client spawn
    TriggerClientEvent('garage:client:spawnVehicle', source, {
        model = vehicle.vehicle,
        plate = plate,
        mods = json.decode(vehicle.mods),
        fuel = vehicle.fuel,
        engine = vehicle.engine,
        body = vehicle.body,
        coords = coords,
        heading = heading
    })
    
    Utils.Notify(source, Utils.GetLocale('vehicle_spawned'), 'success')
    return true
end

-- Store vehicle
function GarageSystem.StoreVehicle(source, plate, garage, coords)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND owner = ?', {
        plate, identifier
    })
    
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_owned'), 'error')
        return false
    end
    
    if vehicle.state ~= 'out' then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_out'), 'error')
        return false
    end
    
    -- Check garage capacity
    local garageData = MySQL.single.await('SELECT * FROM garages WHERE name = ?', { garage })
    if garageData then
        local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE garage = ?', { garage })
        if vehicleCount >= garageData.max_vehicles then
            Utils.Notify(source, Utils.GetLocale('garage_full'), 'error')
            return false
        end
    end
    
    -- Update vehicle
    MySQL.update.await('UPDATE player_vehicles SET state = "garaged", garage = ?, last_coords = ? WHERE plate = ?', {
        garage, json.encode(coords), plate
    })
    
    -- Delete vehicle from world
    TriggerClientEvent('garage:client:deleteVehicle', source, plate)
    
    Utils.Notify(source, Utils.GetLocale('vehicle_stored'), 'success')
    return true
end

-- Transfer vehicle
function GarageSystem.TransferVehicle(source, plate, targetGarage)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND owner = ?', {
        plate, identifier
    })
    
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_owned'), 'error')
        return false
    end
    
    if vehicle.state ~= 'garaged' then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_garaged'), 'error')
        return false
    end
    
    if vehicle.garage == targetGarage then
        Utils.Notify(source, Utils.GetLocale('same_garage'), 'error')
        return false
    end
    
    -- Get target garage data
    local garage = MySQL.single.await('SELECT * FROM garages WHERE name = ?', { targetGarage })
    if not garage then
        Utils.Notify(source, Utils.GetLocale('garage_not_found'), 'error')
        return false
    end
    
    -- Check if player can access target garage
    garage.coords = json.decode(garage.coords)
    garage.spawn_coords = json.decode(garage.spawn_coords)
    garage.vehicle_types = json.decode(garage.vehicle_types)
    
    if not GarageSystem.CanAccessGarage(source, garage) then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Check transfer fee
    local fee = Config.Vehicle.transferFee
    if fee > 0 then
        local money = Utils.GetPlayerMoney(source)
        if money < fee then
            Utils.Notify(source, Utils.GetLocale('insufficient_funds'), 'error')
            return false
        end
        
        Utils.RemovePlayerMoney(source, fee, Config.Economy.currency, 'Vehicle Transfer Fee')
    end
    
    -- Transfer vehicle
    MySQL.update.await('UPDATE player_vehicles SET garage = ? WHERE plate = ?', {
        targetGarage, plate
    })
    
    -- Log transfer
    MySQL.insert.await('INSERT INTO vehicle_transfers (plate, from_garage, to_garage, transferred_by, fee) VALUES (?, ?, ?, ?, ?)', {
        plate, vehicle.garage, targetGarage, identifier, fee
    })
    
    Utils.Notify(source, Utils.GetLocale('vehicle_transferred'), 'success')
    return true
end

-- Rename vehicle
function GarageSystem.RenameVehicle(source, plate, newName)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    -- Validate name
    newName = Utils.Trim(newName)
    if not newName or newName == '' or #newName > 50 then
        Utils.Notify(source, 'Invalid vehicle name', 'error')
        return false
    end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND owner = ?', {
        plate, identifier
    })
    
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_owned'), 'error')
        return false
    end
    
    -- Check rename fee
    local fee = Config.Vehicle.renameFee
    if fee > 0 then
        local money = Utils.GetPlayerMoney(source)
        if money < fee then
            Utils.Notify(source, Utils.GetLocale('insufficient_funds'), 'error')
            return false
        end
        
        Utils.RemovePlayerMoney(source, fee, Config.Economy.currency, 'Vehicle Rename Fee')
    end
    
    -- Update vehicle name
    MySQL.update.await('UPDATE player_vehicles SET nickname = ? WHERE plate = ?', {
        newName, plate
    })
    
    Utils.Notify(source, 'Vehicle renamed successfully', 'success')
    return true
end

-- Toggle favorite vehicle
function GarageSystem.ToggleFavorite(source, plate)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return false end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND owner = ?', {
        plate, identifier
    })
    
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('vehicle_not_owned'), 'error')
        return false
    end
    
    local newFavorite = vehicle.favorite == 0 and 1 or 0
    
    -- Update favorite status
    MySQL.update.await('UPDATE player_vehicles SET favorite = ? WHERE plate = ?', {
        newFavorite, plate
    })
    
    local message = newFavorite == 1 and 'Vehicle added to favorites' or 'Vehicle removed from favorites'
    Utils.Notify(source, message, 'success')
    return true
end

-- Register events
RegisterNetEvent('garage:server:getVehicles', function(garage)
    local source = source
    local vehicles = GarageSystem.GetPlayerVehicles(source, garage)
    TriggerClientEvent('garage:client:receiveVehicles', source, vehicles)
end)

RegisterNetEvent('garage:server:spawnVehicle', function(plate, coords, heading)
    local source = source
    GarageSystem.SpawnVehicle(source, plate, coords, heading)
end)

RegisterNetEvent('garage:server:storeVehicle', function(plate, garage, coords)
    local source = source
    GarageSystem.StoreVehicle(source, plate, garage, coords)
end)

RegisterNetEvent('garage:server:transferVehicle', function(plate, targetGarage)
    local source = source
    GarageSystem.TransferVehicle(source, plate, targetGarage)
end)

RegisterNetEvent('garage:server:renameVehicle', function(plate, newName)
    local source = source
    GarageSystem.RenameVehicle(source, plate, newName)
end)

RegisterNetEvent('garage:server:toggleFavorite', function(plate)
    local source = source
    GarageSystem.ToggleFavorite(source, plate)
end)

RegisterNetEvent('garage:server:checkAccess', function(garageName)
    local source = source
    local garage = MySQL.single.await('SELECT * FROM garages WHERE name = ?', { garageName })
    
    if garage then
        garage.coords = json.decode(garage.coords)
        garage.spawn_coords = json.decode(garage.spawn_coords)
        garage.vehicle_types = json.decode(garage.vehicle_types)
        garage.blip = garage.blip and json.decode(garage.blip) or nil
        garage.marker = garage.marker and json.decode(garage.marker) or nil
        
        local hasAccess = GarageSystem.CanAccessGarage(source, garage)
        TriggerClientEvent('garage:client:accessResult', source, garageName, hasAccess, garage)
    else
        TriggerClientEvent('garage:client:accessResult', source, garageName, false, nil)
    end
end)

-- Export functions
function GetPlayerVehicles(identifier, garage)
    return GarageSystem.GetPlayerVehicles(nil, garage, identifier)
end

function AddVehicleToGarage(identifier, vehicleData, garage)
    if not identifier or not vehicleData then return false end
    
    local plate = vehicleData.plate or Utils.GeneratePlate()
    
    MySQL.insert.await([[
        INSERT INTO player_vehicles (owner, plate, vehicle, hash, mods, garage, state, fuel, engine, body)
        VALUES (?, ?, ?, ?, ?, ?, 'garaged', ?, ?, ?)
    ]], {
        identifier,
        plate,
        vehicleData.model,
        vehicleData.hash or GetHashKey(vehicleData.model),
        json.encode(vehicleData.mods or {}),
        garage or 'legion_garage',
        vehicleData.fuel or 100,
        vehicleData.engine or 1000.0,
        vehicleData.body or 1000.0
    })
    
    return plate
end

function RemoveVehicleFromGarage(plate)
    local success = MySQL.update.await('DELETE FROM player_vehicles WHERE plate = ?', { plate })
    return success and success > 0
end

-- Initialize system
CreateThread(function()
    Wait(1000) -- Wait for database to be ready
    GarageSystem.Init()
end)

-- Handle player disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    local identifier = Utils.GetIdentifier(source)
    
    if identifier and Config.Vehicle.returnToGarageOnDisconnect then
        -- Return all out vehicles to garage
        MySQL.update.await('UPDATE player_vehicles SET state = "garaged" WHERE owner = ? AND state = "out"', {
            identifier
        })
    end
end)