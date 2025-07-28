local playerData = {}
local currentVehicle = nil
local isMenuOpen = false

-- ESX Support
if Config.UseESX then
    ESX = nil
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
        
        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end
        
        playerData = ESX.GetPlayerData()
    end)
    
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        playerData = xPlayer
    end)
    
    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        playerData.job = job
    end)
end

-- Utility Functions
function debugPrint(message)
    if Config.Debug then
        print("[VehicleSpawner] " .. tostring(message))
    end
end

function showNotification(message, type)
    if type == "error" then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"[VehicleSpawner]", message}
        })
    elseif type == "success" then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"[VehicleSpawner]", message}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 255},
            multiline = true,
            args = {"[VehicleSpawner]", message}
        })
    end
end

function hasPermission()
    -- Check if player has permission to use the script
    local hasPermission = false
    
    -- Trigger server event to check permissions
    TriggerServerEvent('vehiclespawner:checkPermission')
    
    -- For now, return true (you can implement proper permission checking)
    return true
end

function getPlayerCoords()
    local ped = PlayerPedId()
    return GetEntityCoords(ped)
end

function getPlayerHeading()
    local ped = PlayerPedId()
    return GetEntityHeading(ped)
end

function getSpawnPosition()
    local coords = getPlayerCoords()
    local heading = getPlayerHeading()
    
    -- Calculate spawn position in front of player
    local x = coords.x + math.cos(math.rad(heading)) * Config.SpawnSettings.maxDistance
    local y = coords.y + math.sin(math.rad(heading)) * Config.SpawnSettings.maxDistance
    local z = coords.z
    
    return vector3(x, y, z), heading
end

function deleteCurrentVehicle()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
        debugPrint("Deleted current vehicle")
    end
end

function spawnVehicle(vehicleModel)
    if not hasPermission() then
        showNotification("You don't have permission to spawn vehicles!", "error")
        return
    end
    
    local model = GetHashKey(vehicleModel)
    
    if not IsModelInCdimage(model) then
        showNotification("Vehicle model not found: " .. vehicleModel, "error")
        return
    end
    
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    
    -- Delete old vehicle if setting is enabled
    if Config.SpawnSettings.deleteOldVehicle then
        deleteCurrentVehicle()
    end
    
    local spawnPos, spawnHeading = getSpawnPosition()
    
    -- Create vehicle
    local vehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, spawnHeading, true, false)
    
    if DoesEntityExist(vehicle) then
        currentVehicle = vehicle
        
        -- Set vehicle properties
        SetVehicleOnGroundProperly(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        
        -- Upgrade vehicle if setting is enabled
        if Config.SpawnSettings.spawnUpgraded then
            SetVehicleModKit(vehicle, 0)
            SetVehicleMod(vehicle, 11, 3, false) -- Engine
            SetVehicleMod(vehicle, 12, 2, false) -- Brakes
            SetVehicleMod(vehicle, 13, 2, false) -- Transmission
            SetVehicleMod(vehicle, 15, 3, false) -- Suspension
            SetVehicleMod(vehicle, 16, 4, false) -- Armor
            ToggleVehicleMod(vehicle, 18, true)  -- Turbo
        end
        
        -- Put player in vehicle if setting is enabled
        if Config.SpawnSettings.spawnInVehicle then
            local ped = PlayerPedId()
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
        end
        
        showNotification("Vehicle spawned: " .. vehicleModel, "success")
        debugPrint("Spawned vehicle: " .. vehicleModel)
    else
        showNotification("Failed to spawn vehicle: " .. vehicleModel, "error")
    end
    
    SetModelAsNoLongerNeeded(model)
end

-- UI Functions
function openMenu()
    if not hasPermission() then
        showNotification("You don't have permission to use this menu!", "error")
        return
    end
    
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openMenu",
        categories = Config.VehicleCategories
    })
end

function closeMenu()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeMenu"
    })
end

-- NUI Callbacks
RegisterNUICallback('spawnVehicle', function(data, cb)
    spawnVehicle(data.model)
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    deleteCurrentVehicle()
    showNotification("Vehicle deleted!", "success")
    cb('ok')
end)

-- Key Controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, 167) then -- F6 key
            if isMenuOpen then
                closeMenu()
            else
                openMenu()
            end
        end
        
        if IsControlJustPressed(0, 322) then -- ESC key
            if isMenuOpen then
                closeMenu()
            end
        end
    end
end)

-- Commands
RegisterCommand(Config.Commands.spawnVehicle, function(source, args, rawCommand)
    if #args < 1 then
        showNotification("Usage: /" .. Config.Commands.spawnVehicle .. " [vehicle_model]", "error")
        return
    end
    
    local vehicleModel = args[1]
    spawnVehicle(vehicleModel)
end, false)

RegisterCommand(Config.Commands.deleteVehicle, function(source, args, rawCommand)
    deleteCurrentVehicle()
    showNotification("Vehicle deleted!", "success")
end, false)

RegisterCommand(Config.Commands.openMenu, function(source, args, rawCommand)
    if isMenuOpen then
        closeMenu()
    else
        openMenu()
    end
end, false)

-- Vehicle cleanup on player disconnect
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
        end
        
        if isMenuOpen then
            closeMenu()
        end
    end
end)

-- Display help text
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if not isMenuOpen then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("Press ~INPUT_SELECT_CHARACTER_TREVOR~ to open Vehicle Spawner")
            EndTextCommandDisplayHelp(0, false, true, -1)
        end
    end
end)