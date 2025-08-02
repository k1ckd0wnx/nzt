-- Advanced Garage System - Client Main
local GarageClient = {}

-- Local variables
local garages = {}
local impounds = {}
local spawners = {}
local nearbyGarages = {}
local nearbyImpounds = {}
local nearbySpawners = {}
local currentVehicle = nil
local isInVehicle = false
local playerData = {}

-- Initialize client
function GarageClient.Init()
    -- Get player data
    playerData = Utils.GetPlayerData()
    
    -- Set up target system
    GarageClient.SetupTargets()
    
    -- Start proximity checks
    GarageClient.StartProximityCheck()
    
    -- Set up keybinds
    GarageClient.SetupKeybinds()
    
    Utils.Log('Garage Client initialized', 'INFO')
end

-- Set up targeting system
function GarageClient.SetupTargets()
    if Config.Target == 'qb-target' then
        -- QBTarget implementation will be added when needed
    elseif Config.Target == 'ox_target' then
        -- OX Target implementation will be added when needed
    end
end

-- Set up keybinds
function GarageClient.SetupKeybinds()
    if lib then
        lib.addKeybind({
            name = 'garage_open',
            description = 'Open Garage Menu',
            defaultKey = Config.Keybinds.openGarage,
            onPressed = function()
                GarageClient.HandleInteraction()
            end
        })
        
        lib.addKeybind({
            name = 'garage_store',
            description = 'Store Vehicle',
            defaultKey = Config.Keybinds.storeVehicle,
            onPressed = function()
                GarageClient.StoreNearestVehicle()
            end
        })
    end
end

-- Start proximity checking
function GarageClient.StartProximityCheck()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local sleep = 1000
            
            -- Check current vehicle status
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and vehicle ~= currentVehicle then
                currentVehicle = vehicle
                isInVehicle = true
                GarageClient.OnEnterVehicle(vehicle)
            elseif vehicle == 0 and currentVehicle then
                GarageClient.OnExitVehicle(currentVehicle)
                currentVehicle = nil
                isInVehicle = false
            end
            
            -- Check nearby garages
            nearbyGarages = {}
            for _, garage in pairs(garages) do
                local distance = Utils.GetDistance(coords, garage.coords)
                if distance <= Config.UI.maxDistance then
                    table.insert(nearbyGarages, {
                        garage = garage,
                        distance = distance
                    })
                    sleep = 100
                end
            end
            
            -- Check nearby impounds
            nearbyImpounds = {}
            for _, impound in pairs(impounds) do
                local distance = Utils.GetDistance(coords, impound.coords)
                if distance <= Config.UI.maxDistance then
                    table.insert(nearbyImpounds, {
                        impound = impound,
                        distance = distance
                    })
                    sleep = 100
                end
            end
            
            -- Check nearby spawners
            nearbySpawners = {}
            for _, spawner in pairs(spawners) do
                local distance = Utils.GetDistance(coords, spawner.coords)
                if distance <= Config.UI.maxDistance then
                    table.insert(nearbySpawners, {
                        spawner = spawner,
                        distance = distance
                    })
                    sleep = 100
                end
            end
            
            -- Draw markers and handle interactions
            if #nearbyGarages > 0 or #nearbyImpounds > 0 or #nearbySpawners > 0 then
                GarageClient.DrawMarkers()
                GarageClient.HandleInteractionPrompts()
            end
            
            Wait(sleep)
        end
    end)
end

-- Draw markers for nearby locations
function GarageClient.DrawMarkers()
    for _, data in pairs(nearbyGarages) do
        local garage = data.garage
        if garage.marker then
            GarageClient.DrawMarker(garage.coords, garage.marker, 'garage')
        end
    end
    
    for _, data in pairs(nearbyImpounds) do
        local impound = data.impound
        if impound.marker then
            GarageClient.DrawMarker(impound.coords, impound.marker, 'impound')
        end
    end
    
    for _, data in pairs(nearbySpawners) do
        local spawner = data.spawner
        if spawner.marker then
            GarageClient.DrawMarker(spawner.coords, spawner.marker, 'spawner')
        end
    end
end

-- Draw individual marker
function GarageClient.DrawMarker(coords, marker, type)
    local markerConfig = Config.Markers[type] or Config.Markers.garage
    
    DrawMarker(
        marker.type or markerConfig.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        marker.scale.x or markerConfig.scale.x,
        marker.scale.y or markerConfig.scale.y,
        marker.scale.z or markerConfig.scale.z,
        marker.color.r or markerConfig.color.r,
        marker.color.g or markerConfig.color.g,
        marker.color.b or markerConfig.color.b,
        100,
        markerConfig.bobUpAndDown or false,
        true,
        2,
        markerConfig.rotate or false
    )
end

-- Handle interaction prompts
function GarageClient.HandleInteractionPrompts()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Find closest interaction point
    local closest = nil
    local closestDistance = Config.UI.maxDistance
    local interactionType = nil
    
    for _, data in pairs(nearbyGarages) do
        if data.distance < closestDistance then
            closest = data.garage
            closestDistance = data.distance
            interactionType = 'garage'
        end
    end
    
    for _, data in pairs(nearbyImpounds) do
        if data.distance < closestDistance then
            closest = data.impound
            closestDistance = data.distance
            interactionType = 'impound'
        end
    end
    
    for _, data in pairs(nearbySpawners) do
        if data.distance < closestDistance then
            closest = data.spawner
            closestDistance = data.distance
            interactionType = 'spawner'
        end
    end
    
    if closest and closestDistance <= 2.0 then
        -- Show interaction prompt
        local label = closest.label or 'Interaction'
        lib.showTextUI(`[E] ${label}`)
        
        -- Store current interaction
        GarageClient.currentInteraction = {
            type = interactionType,
            data = closest
        }
    else
        lib.hideTextUI()
        GarageClient.currentInteraction = nil
    end
end

-- Handle interaction
function GarageClient.HandleInteraction()
    if not GarageClient.currentInteraction then return end
    
    local interaction = GarageClient.currentInteraction
    
    if interaction.type == 'garage' then
        GarageClient.OpenGarageMenu(interaction.data)
    elseif interaction.type == 'impound' then
        GarageClient.OpenImpoundMenu(interaction.data)
    elseif interaction.type == 'spawner' then
        GarageClient.OpenSpawnerMenu(interaction.data)
    end
end

-- Open garage menu
function GarageClient.OpenGarageMenu(garage)
    -- Check access first
    TriggerServerEvent('garage:server:checkAccess', garage.name)
end

-- Open impound menu
function GarageClient.OpenImpoundMenu(impound)
    -- Check access first
    TriggerServerEvent('garage:server:checkImpoundAccess', impound.name)
end

-- Open spawner menu
function GarageClient.OpenSpawnerMenu(spawner)
    -- Check access first
    TriggerServerEvent('garage:server:checkSpawnerAccess', spawner.name)
end

-- Spawn vehicle
function GarageClient.SpawnVehicle(vehicleData)
    local ped = PlayerPedId()
    local coords = vehicleData.coords
    local heading = vehicleData.heading
    
    -- Request model
    local model = GetHashKey(vehicleData.model)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        lib.notify({
            title = 'Error',
            description = 'Invalid vehicle model',
            type = 'error'
        })
        return
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    -- Create vehicle
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    
    -- Set vehicle properties
    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    
    -- Apply modifications
    if vehicleData.mods then
        GarageClient.ApplyVehicleMods(vehicle, vehicleData.mods)
    end
    
    -- Set fuel level
    if vehicleData.fuel then
        GarageClient.SetVehicleFuel(vehicle, vehicleData.fuel)
    end
    
    -- Set health
    if vehicleData.engine then
        SetVehicleEngineHealth(vehicle, vehicleData.engine)
    end
    if vehicleData.body then
        SetVehicleBodyHealth(vehicle, vehicleData.body)
    end
    
    -- Put player in vehicle
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    
    SetModelAsNoLongerNeeded(model)
    
    lib.notify({
        title = 'Success',
        description = 'Vehicle spawned successfully',
        type = 'success'
    })
end

-- Apply vehicle modifications
function GarageClient.ApplyVehicleMods(vehicle, mods)
    if not mods then return end
    
    -- Apply basic mods
    for i = 0, 49 do
        if mods[tostring(i)] then
            SetVehicleMod(vehicle, i, mods[tostring(i)], false)
        end
    end
    
    -- Apply extras
    if mods.extras then
        for extra, enabled in pairs(mods.extras) do
            SetVehicleExtra(vehicle, tonumber(extra), not enabled)
        end
    end
    
    -- Apply neon
    if mods.neon then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, mods.neon[tostring(i)] or false)
        end
        if mods.neoncolor then
            SetVehicleNeonLightsColour(vehicle, mods.neoncolor[1], mods.neoncolor[2], mods.neoncolor[3])
        end
    end
    
    -- Apply window tint
    if mods.windowtint then
        SetVehicleWindowTint(vehicle, mods.windowtint)
    end
    
    -- Apply license plate
    if mods.plateIndex then
        SetVehicleNumberPlateTextIndex(vehicle, mods.plateIndex)
    end
end

-- Set vehicle fuel
function GarageClient.SetVehicleFuel(vehicle, fuel)
    -- Try different fuel systems
    if exports['LegacyFuel'] then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
    elseif exports['ps-fuel'] then
        exports['ps-fuel']:SetFuel(vehicle, fuel)
    elseif exports['ox_fuel'] then
        Entity(vehicle).state.fuel = fuel
    else
        -- Fallback to native
        SetVehicleFuelLevel(vehicle, fuel)
    end
end

-- Store nearest vehicle
function GarageClient.StoreNearestVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        vehicle = GarageClient.GetClosestVehicle()
    end
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'No vehicle nearby',
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local coords = GetEntityCoords(vehicle)
    
    -- Find nearest garage
    local nearestGarage = nil
    local nearestDistance = math.huge
    
    for _, garage in pairs(garages) do
        local distance = Utils.GetDistance(coords, garage.coords)
        if distance < nearestDistance then
            nearestGarage = garage
            nearestDistance = distance
        end
    end
    
    if not nearestGarage or nearestDistance > 50.0 then
        lib.notify({
            title = 'Error',
            description = 'No garage nearby',
            type = 'error'
        })
        return
    end
    
    -- Get vehicle modifications
    local mods = GarageClient.GetVehicleMods(vehicle)
    local fuel = GarageClient.GetVehicleFuel(vehicle)
    local engine = GetVehicleEngineHealth(vehicle)
    local body = GetVehicleBodyHealth(vehicle)
    
    -- Store vehicle
    TriggerServerEvent('garage:server:storeVehicle', plate, nearestGarage.name, {
        coords = coords,
        mods = mods,
        fuel = fuel,
        engine = engine,
        body = body
    })
end

-- Get vehicle modifications
function GarageClient.GetVehicleMods(vehicle)
    local mods = {}
    
    -- Get all modifications
    for i = 0, 49 do
        local mod = GetVehicleMod(vehicle, i)
        if mod ~= -1 then
            mods[tostring(i)] = mod
        end
    end
    
    -- Get extras
    mods.extras = {}
    for i = 1, 20 do
        if DoesExtraExist(vehicle, i) then
            mods.extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    
    -- Get neon
    mods.neon = {}
    for i = 0, 3 do
        mods.neon[tostring(i)] = IsVehicleNeonLightEnabled(vehicle, i)
    end
    
    local r, g, b = GetVehicleNeonLightsColour(vehicle)
    mods.neoncolor = {r, g, b}
    
    -- Get window tint
    mods.windowtint = GetVehicleWindowTint(vehicle)
    
    -- Get license plate
    mods.plateIndex = GetVehicleNumberPlateTextIndex(vehicle)
    
    return mods
end

-- Get vehicle fuel
function GarageClient.GetVehicleFuel(vehicle)
    -- Try different fuel systems
    if exports['LegacyFuel'] then
        return exports['LegacyFuel']:GetFuel(vehicle)
    elseif exports['ps-fuel'] then
        return exports['ps-fuel']:GetFuel(vehicle)
    elseif exports['ox_fuel'] then
        return Entity(vehicle).state.fuel or 100
    else
        -- Fallback to native
        return GetVehicleFuelLevel(vehicle)
    end
end

-- Get closest vehicle
function GarageClient.GetClosestVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closest = 0
    local closestDistance = math.huge
    
    for _, vehicle in pairs(vehicles) do
        local distance = #(coords - GetEntityCoords(vehicle))
        if distance < closestDistance and distance < 5.0 then
            closest = vehicle
            closestDistance = distance
        end
    end
    
    return closest
end

-- Handle entering vehicle
function GarageClient.OnEnterVehicle(vehicle)
    -- Check if vehicle should be despawned on exit
    if Config.Vehicle.despawnOnExit then
        CreateThread(function()
            while currentVehicle == vehicle do
                Wait(100)
            end
            
            -- Vehicle was exited
            if Config.Vehicle.despawnDelay > 0 then
                Wait(Config.Vehicle.despawnDelay)
                
                -- Check if player is still away from vehicle
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)
                local vehicleCoords = GetEntityCoords(vehicle)
                
                if #(playerCoords - vehicleCoords) > 50.0 and GetVehiclePedIsIn(ped, false) ~= vehicle then
                    -- Delete vehicle
                    DeleteVehicle(vehicle)
                end
            end
        end)
    end
end

-- Handle exiting vehicle
function GarageClient.OnExitVehicle(vehicle)
    -- Vehicle exit logic handled in OnEnterVehicle thread
end

-- Register network events
RegisterNetEvent('garage:client:updateGarages', function(data)
    garages = data
    GarageClient.CreateBlips()
end)

RegisterNetEvent('garage:client:updateImpounds', function(data)
    impounds = data
    GarageClient.CreateBlips()
end)

RegisterNetEvent('garage:client:updateSpawners', function(data)
    spawners = data
    GarageClient.CreateBlips()
end)

RegisterNetEvent('garage:client:spawnVehicle', function(vehicleData)
    GarageClient.SpawnVehicle(vehicleData)
end)

RegisterNetEvent('garage:client:spawnSpawnerVehicle', function(vehicleData)
    GarageClient.SpawnVehicle(vehicleData)
end)

RegisterNetEvent('garage:client:deleteVehicle', function(plate)
    GarageClient.DeleteVehicleByPlate(plate)
end)

RegisterNetEvent('garage:client:accessResult', function(garageName, hasAccess, garage)
    if hasAccess then
        -- Open garage UI
        GarageClient.OpenGarageUI(garage)
    else
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have access to this garage',
            type = 'error'
        })
    end
end)

RegisterNetEvent('garage:client:impoundAccessResult', function(impoundName, hasAccess, impound)
    if hasAccess then
        -- Open impound UI
        GarageClient.OpenImpoundUI(impound)
    else
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have access to this impound',
            type = 'error'
        })
    end
end)

RegisterNetEvent('garage:client:spawnerAccessResult', function(spawnerName, hasAccess, spawner)
    if hasAccess then
        -- Open spawner UI
        GarageClient.OpenSpawnerUI(spawner)
    else
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have access to this spawner',
            type = 'error'
        })
    end
end)

-- Delete vehicle by plate
function GarageClient.DeleteVehicleByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in pairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            DeleteVehicle(vehicle)
            break
        end
    end
end

-- Create blips
function GarageClient.CreateBlips()
    -- Remove existing blips
    for _, blip in pairs(GarageClient.blips or {}) do
        RemoveBlip(blip)
    end
    GarageClient.blips = {}
    
    -- Create garage blips
    for _, garage in pairs(garages) do
        if garage.blip then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, garage.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale)
            SetBlipColour(blip, garage.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garage.label)
            EndTextCommandSetBlipName(blip)
            table.insert(GarageClient.blips, blip)
        end
    end
    
    -- Create impound blips
    for _, impound in pairs(impounds) do
        if impound.blip then
            local blip = AddBlipForCoord(impound.coords.x, impound.coords.y, impound.coords.z)
            SetBlipSprite(blip, impound.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, impound.blip.scale)
            SetBlipColour(blip, impound.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(impound.label)
            EndTextCommandSetBlipName(blip)
            table.insert(GarageClient.blips, blip)
        end
    end
    
    -- Create spawner blips
    for _, spawner in pairs(spawners) do
        if spawner.blip then
            local blip = AddBlipForCoord(spawner.coords.x, spawner.coords.y, spawner.coords.z)
            SetBlipSprite(blip, spawner.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, spawner.blip.scale)
            SetBlipColour(blip, spawner.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(spawner.label)
            EndTextCommandSetBlipName(blip)
            table.insert(GarageClient.blips, blip)
        end
    end
end

-- Open UI functions (these will be connected to the React UI)
function GarageClient.OpenGarageUI(garage)
    SendNUIMessage({
        type = 'openGarage',
        garage = garage
    })
    SetNuiFocus(true, true)
end

function GarageClient.OpenImpoundUI(impound)
    SendNUIMessage({
        type = 'openImpound',
        impound = impound
    })
    SetNuiFocus(true, true)
end

function GarageClient.OpenSpawnerUI(spawner)
    SendNUIMessage({
        type = 'openSpawner',
        spawner = spawner
    })
    SetNuiFocus(true, true)
end

-- Initialize when player loads
CreateThread(function()
    while not playerData.citizenid and not playerData.identifier do
        playerData = Utils.GetPlayerData()
        Wait(1000)
    end
    
    GarageClient.Init()
end)