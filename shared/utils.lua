Utils = {}

-- Framework detection and functions
Utils.Framework = nil
Utils.FrameworkObject = nil

if Config.Framework == 'qb-core' then
    Utils.Framework = 'qb'
    Utils.FrameworkObject = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    Utils.Framework = 'esx'
    Utils.FrameworkObject = exports['es_extended']:getSharedObject()
end

-- Get player data
function Utils.GetPlayerData()
    if Utils.Framework == 'qb' then
        return Utils.FrameworkObject.Functions.GetPlayerData()
    elseif Utils.Framework == 'esx' then
        return Utils.FrameworkObject.GetPlayerData()
    end
    return {}
end

-- Get player identifier
function Utils.GetIdentifier(source)
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        return Player and Player.identifier or nil
    end
    return GetPlayerIdentifiers(source)[1]
end

-- Get player job
function Utils.GetPlayerJob(source)
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        return Player and Player.PlayerData.job or {}
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        return Player and Player.job or {}
    end
    return {}
end

-- Get player gang (QB-Core only)
function Utils.GetPlayerGang(source)
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        return Player and Player.PlayerData.gang or {}
    end
    return {}
end

-- Get player money
function Utils.GetPlayerMoney(source, moneyType)
    moneyType = moneyType or Config.Economy.currency
    
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        return Player and Player.PlayerData.money[moneyType] or 0
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        if moneyType == 'cash' then
            return Player and Player.getMoney() or 0
        elseif moneyType == 'bank' then
            return Player and Player.getAccount('bank').money or 0
        end
    end
    return 0
end

-- Remove player money
function Utils.RemovePlayerMoney(source, amount, moneyType, reason)
    moneyType = moneyType or Config.Economy.currency
    
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.RemoveMoney(moneyType, amount, reason)
        end
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        if Player then
            if moneyType == 'cash' then
                Player.removeMoney(amount)
            elseif moneyType == 'bank' then
                Player.removeAccountMoney('bank', amount)
            end
            return true
        end
    end
    return false
end

-- Add player money
function Utils.AddPlayerMoney(source, amount, moneyType, reason)
    moneyType = moneyType or Config.Economy.currency
    
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.AddMoney(moneyType, amount, reason)
        end
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        if Player then
            if moneyType == 'cash' then
                Player.addMoney(amount)
            elseif moneyType == 'bank' then
                Player.addAccountMoney('bank', amount)
            end
            return true
        end
    end
    return false
end

-- Send notification
function Utils.Notify(source, message, type, duration)
    type = type or 'success'
    duration = duration or Config.Notifications.duration
    
    if Config.Notifications.type == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage System',
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Notifications.type == 'qb-core' then
        TriggerClientEvent('QBCore:Notify', source, message, type, duration)
    elseif Config.Notifications.type == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    end
end

-- Check if player has permission
function Utils.HasPermission(source, permission)
    if Utils.Framework == 'qb' then
        local Player = Utils.FrameworkObject.Functions.GetPlayer(source)
        if Player then
            local group = Utils.FrameworkObject.Functions.GetPermission(source)
            return group and table.contains(Config.Staff.groups, group.group)
        end
    elseif Utils.Framework == 'esx' then
        local Player = Utils.FrameworkObject.GetPlayerFromId(source)
        if Player then
            return table.contains(Config.Staff.groups, Player.getGroup())
        end
    end
    return false
end

-- Distance calculation
function Utils.GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return 0 end
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

-- Table contains check
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Round number to specified decimal places
function Utils.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Format currency
function Utils.FormatCurrency(amount)
    return '$' .. tostring(amount)
end

-- Get vehicle class name
function Utils.GetVehicleClass(vehicleClass)
    local classes = {
        [0] = 'Compacts',
        [1] = 'Sedans',
        [2] = 'SUVs',
        [3] = 'Coupes',
        [4] = 'Muscle',
        [5] = 'Sports Classics',
        [6] = 'Sports',
        [7] = 'Super',
        [8] = 'Motorcycles',
        [9] = 'Off-road',
        [10] = 'Industrial',
        [11] = 'Utility',
        [12] = 'Vans',
        [13] = 'Cycles',
        [14] = 'Boats',
        [15] = 'Helicopters',
        [16] = 'Planes',
        [17] = 'Service',
        [18] = 'Emergency',
        [19] = 'Military',
        [20] = 'Commercial',
        [21] = 'Trains'
    }
    return classes[vehicleClass] or 'Unknown'
end

-- Get vehicle type from class
function Utils.GetVehicleType(vehicleClass)
    for type, data in pairs(Config.VehicleTypes) do
        if table.contains(data.class, vehicleClass) then
            return type
        end
    end
    return 'car'
end

-- Validate coordinates
function Utils.ValidateCoords(coords)
    return coords and coords.x and coords.y and coords.z
end

-- Generate unique plate
function Utils.GeneratePlate()
    local plate = ''
    for i = 1, 8 do
        if math.random(1, 2) == 1 then
            plate = plate .. string.char(math.random(65, 90)) -- A-Z
        else
            plate = plate .. tostring(math.random(0, 9)) -- 0-9
        end
    end
    return plate
end

-- Log function
function Utils.Log(message, type)
    if Config.Debug then
        print(('[%s] [%s] %s'):format(GetCurrentResourceName(), type or 'INFO', message))
    end
end

-- Deep copy table
function Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- String trim
function Utils.Trim(s)
    return s:match('^%s*(.-)%s*$')
end

-- Time formatting
function Utils.FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format('%d:%02d:%02d', hours, minutes, secs)
    else
        return string.format('%d:%02d', minutes, secs)
    end
end

-- Check if garage supports vehicle type
function Utils.SupportsVehicleType(garage, vehicleType)
    if not garage.vehicle_types then return true end
    for _, supportedType in pairs(garage.vehicle_types) do
        if supportedType == vehicleType then
            return true
        end
    end
    return false
end

-- Get locale string
function Utils.GetLocale(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales.en
    local text = locale[key] or key
    
    if ... then
        return string.format(text, ...)
    end
    
    return text
end