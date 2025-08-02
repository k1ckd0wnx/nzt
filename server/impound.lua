-- Advanced Garage System - Impound System
local ImpoundSystem = {}

-- Impound a vehicle
function ImpoundSystem.ImpoundVehicle(source, plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
    local identifier = Utils.GetIdentifier(source)
    local job = Utils.GetPlayerJob(source)
    
    if not identifier then return false end
    
    -- Check if player can impound vehicles
    if not table.contains(Config.Impound.jobsCanImpound, job.name) and not Utils.HasPermission(source, 'admin') then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('invalid_vehicle'), 'error')
        return false
    end
    
    -- Get impound data
    local impound = MySQL.single.await('SELECT * FROM impounds WHERE name = ?', { impoundName })
    if not impound then
        Utils.Notify(source, 'Impound not found', 'error')
        return false
    end
    
    -- Check if vehicle is already impounded
    local existing = MySQL.single.await('SELECT * FROM impounded_vehicles WHERE plate = ? AND retrieved = 0', { plate })
    if existing then
        Utils.Notify(source, 'Vehicle is already impounded', 'error')
        return false
    end
    
    -- Set default values
    reason = reason or 'No reason provided'
    releaseTime = releaseTime or Config.Impound.defaultReleaseTime
    fee = fee or impound.retrieval_fee or Config.Impound.defaultFee
    canSelfRetrieve = canSelfRetrieve ~= nil and canSelfRetrieve or Config.Impound.canSelfRetrieve
    
    -- Calculate release timestamp
    local releaseAt = nil
    if releaseTime > 0 then
        releaseAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (releaseTime * 60))
    end
    
    -- Update vehicle state
    MySQL.update.await('UPDATE player_vehicles SET state = "impounded", garage = NULL WHERE plate = ?', { plate })
    
    -- Insert impound record
    MySQL.insert.await([[
        INSERT INTO impounded_vehicles (plate, impound, reason, impounded_by, release_at, fee, can_self_retrieve)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        plate, impoundName, reason, identifier, releaseAt, fee, canSelfRetrieve and 1 or 0
    })
    
    -- Delete vehicle from world
    TriggerClientEvent('garage:client:deleteVehicle', -1, plate)
    
    -- Notify impounding officer
    Utils.Notify(source, Utils.GetLocale('vehicle_impounded'), 'success')
    
    -- Notify vehicle owner if online
    local targetSource = GetPlayerFromIdentifier(vehicle.owner)
    if targetSource then
        Utils.Notify(targetSource, ('Your vehicle (%s) has been impounded. Reason: %s'):format(plate, reason), 'error')
    end
    
    Utils.Log(('Vehicle %s impounded by %s to %s'):format(plate, identifier, impoundName), 'INFO')
    return true
end

-- Release vehicle from impound
function ImpoundSystem.ReleaseVehicle(source, plate, coords, heading, forcedRelease)
    local identifier = Utils.GetIdentifier(source)
    local job = Utils.GetPlayerJob(source)
    
    if not identifier then return false end
    
    -- Get impound record
    local impoundRecord = MySQL.single.await([[
        SELECT iv.*, i.job, i.type, pv.owner 
        FROM impounded_vehicles iv
        JOIN impounds i ON iv.impound = i.name
        JOIN player_vehicles pv ON iv.plate = pv.plate
        WHERE iv.plate = ? AND iv.retrieved = 0
    ]], { plate })
    
    if not impoundRecord then
        Utils.Notify(source, 'Vehicle not found in impound', 'error')
        return false
    end
    
    local isOwner = identifier == impoundRecord.owner
    local isStaff = Utils.HasPermission(source, 'admin')
    local canRelease = false
    
    -- Check release permissions
    if forcedRelease and isStaff then
        canRelease = true
    elseif impoundRecord.type == 'public' then
        -- Public impound - owner can retrieve if allowed
        if isOwner and impoundRecord.can_self_retrieve == 1 then
            -- Check if release time has passed
            if impoundRecord.release_at then
                local releaseTime = os.time(impoundRecord.release_at)
                if os.time() >= releaseTime then
                    canRelease = true
                else
                    Utils.Notify(source, Utils.GetLocale('cannot_retrieve'), 'error')
                    return false
                end
            else
                canRelease = true
            end
        elseif table.contains(Config.Impound.jobsCanImpound, job.name) or isStaff then
            canRelease = true
        end
    elseif impoundRecord.type == 'job' then
        -- Job impound - only that job can release
        if job.name == impoundRecord.job or isStaff then
            canRelease = true
        end
    end
    
    if not canRelease then
        Utils.Notify(source, Utils.GetLocale('no_permission'), 'error')
        return false
    end
    
    -- Check and charge fee for self-retrieval
    if isOwner and impoundRecord.fee > 0 and not forcedRelease then
        local money = Utils.GetPlayerMoney(source)
        if money < impoundRecord.fee then
            Utils.Notify(source, Utils.GetLocale('insufficient_funds'), 'error')
            return false
        end
        
        Utils.RemovePlayerMoney(source, impoundRecord.fee, Config.Economy.currency, 'Impound Release Fee')
        Utils.Notify(source, Utils.GetLocale('impound_fee_paid', impoundRecord.fee), 'success')
    end
    
    -- Get vehicle data
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        Utils.Notify(source, Utils.GetLocale('invalid_vehicle'), 'error')
        return false
    end
    
    -- Update vehicle state
    MySQL.update.await('UPDATE player_vehicles SET state = "out" WHERE plate = ?', { plate })
    
    -- Mark as retrieved
    MySQL.update.await([[
        UPDATE impounded_vehicles 
        SET retrieved = 1, retrieved_by = ?, retrieved_at = NOW() 
        WHERE plate = ? AND retrieved = 0
    ]], { identifier, plate })
    
    -- Spawn vehicle
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
    
    Utils.Notify(source, Utils.GetLocale('vehicle_released'), 'success')
    Utils.Log(('Vehicle %s released from impound by %s'):format(plate, identifier), 'INFO')
    return true
end

-- Get impounded vehicles for a player
function ImpoundSystem.GetPlayerImpoundedVehicles(source)
    local identifier = Utils.GetIdentifier(source)
    if not identifier then return {} end
    
    local vehicles = MySQL.query.await([[
        SELECT iv.*, pv.vehicle, pv.nickname, i.label as impound_label, i.retrieval_fee
        FROM impounded_vehicles iv
        JOIN player_vehicles pv ON iv.plate = pv.plate
        JOIN impounds i ON iv.impound = i.name
        WHERE pv.owner = ? AND iv.retrieved = 0
    ]], { identifier })
    
    return vehicles or {}
end

-- Get all impounded vehicles (for staff)
function ImpoundSystem.GetAllImpoundedVehicles(source)
    if not Utils.HasPermission(source, 'admin') then return {} end
    
    local vehicles = MySQL.query.await([[
        SELECT iv.*, pv.vehicle, pv.owner, pv.nickname, i.label as impound_label
        FROM impounded_vehicles iv
        JOIN player_vehicles pv ON iv.plate = pv.plate
        JOIN impounds i ON iv.impound = i.name
        WHERE iv.retrieved = 0
    ]], {})
    
    return vehicles or {}
end

-- Check if player can access impound
function ImpoundSystem.CanAccessImpound(source, impound)
    local job = Utils.GetPlayerJob(source)
    
    if not impound then return false end
    
    -- Staff can access all impounds
    if Utils.HasPermission(source, 'admin') then
        return true
    end
    
    -- Check impound type
    if impound.type == 'public' then
        return true
    elseif impound.type == 'job' then
        return job.name == impound.job
    end
    
    return false
end

-- Get helper function to find player by identifier
function GetPlayerFromIdentifier(identifier)
    local players = GetPlayers()
    for _, playerId in pairs(players) do
        if Utils.GetIdentifier(playerId) == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Register events
RegisterNetEvent('garage:server:impoundVehicle', function(plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
    local source = source
    ImpoundSystem.ImpoundVehicle(source, plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
end)

RegisterNetEvent('garage:server:releaseVehicle', function(plate, coords, heading, forcedRelease)
    local source = source
    ImpoundSystem.ReleaseVehicle(source, plate, coords, heading, forcedRelease)
end)

RegisterNetEvent('garage:server:getImpoundedVehicles', function(getAll)
    local source = source
    local vehicles
    
    if getAll and Utils.HasPermission(source, 'admin') then
        vehicles = ImpoundSystem.GetAllImpoundedVehicles(source)
    else
        vehicles = ImpoundSystem.GetPlayerImpoundedVehicles(source)
    end
    
    TriggerClientEvent('garage:client:receiveImpoundedVehicles', source, vehicles)
end)

RegisterNetEvent('garage:server:checkImpoundAccess', function(impoundName)
    local source = source
    local impound = MySQL.single.await('SELECT * FROM impounds WHERE name = ?', { impoundName })
    
    if impound then
        impound.coords = json.decode(impound.coords)
        impound.spawn_coords = json.decode(impound.spawn_coords)
        impound.blip = impound.blip and json.decode(impound.blip) or nil
        impound.marker = impound.marker and json.decode(impound.marker) or nil
        
        local hasAccess = ImpoundSystem.CanAccessImpound(source, impound)
        TriggerClientEvent('garage:client:impoundAccessResult', source, impoundName, hasAccess, impound)
    else
        TriggerClientEvent('garage:client:impoundAccessResult', source, impoundName, false, nil)
    end
end)

-- Clean up old impound records (run daily)
CreateThread(function()
    while true do
        Wait(24 * 60 * 60 * 1000) -- 24 hours
        
        if Config.Impound.deleteAbandonedVehicles then
            local cutoffTime = os.date('%Y-%m-%d %H:%M:%S', os.time() - (Config.Impound.abandonedVehicleTime * 60))
            
            -- Get abandoned vehicles
            local abandonedVehicles = MySQL.query.await([[
                SELECT plate FROM impounded_vehicles 
                WHERE retrieved = 0 AND impounded_at < ?
            ]], { cutoffTime })
            
            if abandonedVehicles and #abandonedVehicles > 0 then
                for _, vehicle in pairs(abandonedVehicles) do
                    -- Delete vehicle record
                    MySQL.update.await('DELETE FROM player_vehicles WHERE plate = ?', { vehicle.plate })
                    
                    -- Mark impound record as retrieved
                    MySQL.update.await([[
                        UPDATE impounded_vehicles 
                        SET retrieved = 1, retrieved_by = 'SYSTEM_CLEANUP', retrieved_at = NOW() 
                        WHERE plate = ?
                    ]], { vehicle.plate })
                end
                
                Utils.Log(('Cleaned up %d abandoned vehicles'):format(#abandonedVehicles), 'INFO')
            end
        end
    end
end)

-- Export functions
function ImpoundVehicle(plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
    return ImpoundSystem.ImpoundVehicle(nil, plate, impoundName, reason, releaseTime, fee, canSelfRetrieve)
end

function ReleaseVehicle(plate, coords, heading, forcedRelease)
    return ImpoundSystem.ReleaseVehicle(nil, plate, coords, heading, forcedRelease)
end