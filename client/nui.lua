-- Advanced Garage System - NUI Callbacks

-- Close UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Get vehicles
RegisterNUICallback('getVehicles', function(data, cb)
    TriggerServerEvent('garage:server:getVehicles', data.garage)
    
    -- Wait for response
    local timeout = 0
    while not vehicleResponseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    cb(lastVehicleResponse or {})
    vehicleResponseReceived = false
    lastVehicleResponse = nil
end)

-- Spawn vehicle
RegisterNUICallback('spawnVehicle', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Find spawn coords (try nearby or use garage spawn coords)
    local spawnCoords = coords
    local spawnHeading = heading
    
    TriggerServerEvent('garage:server:spawnVehicle', data.plate, spawnCoords, spawnHeading)
    cb('ok')
end)

-- Toggle favorite
RegisterNUICallback('toggleFavorite', function(data, cb)
    TriggerServerEvent('garage:server:toggleFavorite', data.plate)
    cb('ok')
end)

-- Rename vehicle
RegisterNUICallback('renameVehicle', function(data, cb)
    TriggerServerEvent('garage:server:renameVehicle', data.plate, data.newName)
    cb('ok')
end)

-- Transfer vehicle
RegisterNUICallback('transferVehicle', function(data, cb)
    TriggerServerEvent('garage:server:transferVehicle', data.plate, data.targetGarage)
    cb('ok')
end)

-- Store response variables
local vehicleResponseReceived = false
local lastVehicleResponse = nil

-- Handle vehicle response
RegisterNetEvent('garage:client:receiveVehicles', function(vehicles)
    lastVehicleResponse = vehicles
    vehicleResponseReceived = true
end)