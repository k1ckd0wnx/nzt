-- Premium Casino Client - Main Logic
-- Handles fd_laptop integration and UI communication

local isAppOpen = false
local nuiData = {}

-- Register with fd_laptop
CreateThread(function()
    Wait(1000) -- Wait for fd_laptop to initialize
    
    -- Register casino app with fd_laptop
    local success = pcall(function()
        exports["fd_laptop"]:RegisterApp("casino", {
            name = Config.CasinoName,
            icon = "fas fa-dice",
            category = "entertainment",
            description = "Premium Online Casino",
            version = "1.0.0"
        })
    end)
    
    if success then
        print("^2[Casino] Successfully registered with fd_laptop^0")
    else
        print("^1[Casino] Failed to register with fd_laptop - is fd_laptop running?^0")
    end
end)

-- Event Handlers from Server
RegisterNetEvent(Utils.Events.OPEN_APP, function()
    openCasinoApp()
end)

RegisterNetEvent(Utils.Events.UPDATE_UI, function(data)
    if isAppOpen then
        SendNUIMessage({
            type = "updateUI",
            data = data
        })
    end
    
    -- Store important data for when app reopens
    if data.action == "login_success" then
        nuiData.user = data.user
    elseif data.action == "balance_updated" then
        if nuiData.user then
            nuiData.user.balance = data.balance
        end
    end
end)

-- Functions
function openCasinoApp()
    if isAppOpen then return end
    
    isAppOpen = true
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    -- Send initial data to UI
    SendNUIMessage({
        type = "openApp",
        data = {
            config = {
                casinoName = Config.CasinoName,
                minBets = Config.MinBets,
                maxBets = Config.MaxBets,
                slotMachines = Config.SlotMachines
            },
            user = nuiData.user,
            events = Utils.Events
        }
    })
    
    print("^2[Casino] Casino app opened^0")
end

function closeCasinoApp()
    if not isAppOpen then return end
    
    isAppOpen = false
    
    -- Remove NUI focus
    SetNuiFocus(false, false)
    
    -- Send close message to UI
    SendNUIMessage({
        type = "closeApp"
    })
    
    print("^3[Casino] Casino app closed^0")
end

-- NUI Callbacks
RegisterNUICallback("closeApp", function(data, cb)
    closeCasinoApp()
    cb("ok")
end)

RegisterNUICallback("register", function(data, cb)
    if not data.username or not data.email or not data.password then
        cb({ success = false, message = "Missing required fields" })
        return
    end
    
    TriggerServerEvent(Utils.Events.REGISTER, data.username, data.email, data.password)
    cb({ success = true })
end)

RegisterNUICallback("login", function(data, cb)
    if not data.username or not data.password then
        cb({ success = false, message = "Missing username or password" })
        return
    end
    
    TriggerServerEvent(Utils.Events.LOGIN, data.username, data.password)
    cb({ success = true })
end)

RegisterNUICallback("logout", function(data, cb)
    nuiData.user = nil
    
    SendNUIMessage({
        type = "updateUI",
        data = { action = "logout_success" }
    })
    
    cb({ success = true })
end)

RegisterNUICallback("deposit", function(data, cb)
    if not data.amount or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Invalid amount" })
        return
    end
    
    TriggerServerEvent(Utils.Events.DEPOSIT, amount, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("withdraw", function(data, cb)
    if not data.amount or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Invalid amount" })
        return
    end
    
    TriggerServerEvent(Utils.Events.WITHDRAW, amount, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("getBalance", function(data, cb)
    if not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Not logged in" })
        return
    end
    
    TriggerServerEvent(Utils.Events.GET_BALANCE, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("getTransactions", function(data, cb)
    if not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Not logged in" })
        return
    end
    
    local limit = data.limit or 50
    local offset = data.offset or 0
    
    TriggerServerEvent(Utils.Events.GET_TRANSACTIONS, nuiData.user.sessionToken, limit, offset)
    cb({ success = true })
end)

-- Game-specific callbacks
RegisterNUICallback("slotsSpin", function(data, cb)
    if not data.machineType or not data.betAmount or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    local betAmount = tonumber(data.betAmount)
    if not betAmount or betAmount <= 0 then
        cb({ success = false, message = "Invalid bet amount" })
        return
    end
    
    TriggerServerEvent(Utils.Events.SLOTS_SPIN, data.machineType, betAmount, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("plinkoDrop", function(data, cb)
    if not data.betAmount or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    local betAmount = tonumber(data.betAmount)
    if not betAmount or betAmount <= 0 then
        cb({ success = false, message = "Invalid bet amount" })
        return
    end
    
    TriggerServerEvent(Utils.Events.PLINKO_DROP, betAmount, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("minesReveal", function(data, cb)
    if not data.position or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    TriggerServerEvent(Utils.Events.MINES_REVEAL, data.position, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("minesCashout", function(data, cb)
    if not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    TriggerServerEvent(Utils.Events.MINES_CASHOUT, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("aviatorBet", function(data, cb)
    if not data.betAmount or not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    local betAmount = tonumber(data.betAmount)
    if not betAmount or betAmount <= 0 then
        cb({ success = false, message = "Invalid bet amount" })
        return
    end
    
    local autoCashOut = data.autoCashOut and tonumber(data.autoCashOut) or nil
    
    TriggerServerEvent(Utils.Events.AVIATOR_BET, betAmount, autoCashOut, nuiData.user.sessionToken)
    cb({ success = true })
end)

RegisterNUICallback("aviatorCashout", function(data, cb)
    if not nuiData.user or not nuiData.user.sessionToken then
        cb({ success = false, message = "Invalid request" })
        return
    end
    
    TriggerServerEvent(Utils.Events.AVIATOR_CASHOUT, nuiData.user.sessionToken)
    cb({ success = true })
end)

-- Handle resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isAppOpen then
            closeCasinoApp()
        end
    end
end)

-- Debug command (remove in production)
RegisterCommand("casino", function()
    openCasinoApp()
end, false)

print("^2[Casino] Client initialized successfully!^0")