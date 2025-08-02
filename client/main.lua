-- Premium Casino Client - Main Logic
-- Handles fd_laptop integration and UI communication

local isAppOpen = false
local nuiData = {}

-- Register with fd_laptop (moved to server-side as per fd_laptop docs)

-- Event Handlers from Server
RegisterNetEvent(Utils.Events.OPEN_APP, function()
    openCasinoApp()
end)

-- App initialization is now handled by React component

-- Function to handle UI updates
local function handleUIUpdate(data)
    print("^3[Casino] UPDATE_UI received with action: " .. (data.action or "no action") .. "^0")
    
    -- Always send to NUI - React app will handle appropriately
    SendNUIMessage({
        type = "updateUI",
        data = data
    })
    
    -- Store important data for when app reopens
    if data.action == "login_success" then
        nuiData.user = data.user
        print("^2[Casino] Stored user data for " .. data.user.username .. "^0")
    elseif data.action == "balance_updated" then
        if nuiData.user then
            nuiData.user.balance = data.balance
        end
    elseif data.action == "initialize_app" then
        -- Force app to be marked as open when initialization happens
        isAppOpen = true
    end
end

-- Register for Utils.Events.UPDATE_UI
RegisterNetEvent(Utils.Events.UPDATE_UI, handleUIUpdate)

-- Functions
function openCasinoApp()
    if isAppOpen then return end
    
    isAppOpen = true
    
    -- Send initial config to UI immediately when app opens
    SendNUIMessage({
        type = "initializeApp",
        data = {
            config = {
                casinoName = Config and Config.CasinoName or "Premium Casino",
                minBets = Config and Config.MinBets or { slots = 20, plinko = 10, mines = 10, aviator = 10 },
                maxBets = Config and Config.MaxBets or { slots = 10000, plinko = 5000, mines = 5000, aviator = 50000 },
                slotMachines = Config and Config.SlotMachines or {}
            },
            user = nuiData.user,
            events = Utils.Events
        }
    })
    
    print("^2[Casino] Casino app opened^0")
    
    -- Backup initialization - trigger server after a short delay
    CreateThread(function()
        Wait(1500) -- Wait 1.5 seconds for React to load
        print("^3[Casino] Triggering backup server initialization^0")
        TriggerServerEvent("casino:initializeApp")
    end)
end

function closeCasinoApp()
    if not isAppOpen then return end
    
    isAppOpen = false
    
    -- fd_laptop handles NUI focus, we just send close message
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

-- Initialize when app is accessed through fd_laptop
RegisterNUICallback("appLoaded", function(data, cb)
    print("^2[Casino] App loaded callback received from React^0")
    TriggerServerEvent("casino:initializeApp")
    cb("ok")
end)

RegisterNUICallback("register", function(data, cb)
    if not data.username or not data.password then
        cb({ success = false, message = "Missing required fields" })
        return
    end
    
    TriggerServerEvent(Utils.Events.REGISTER, data.username, data.password)
    cb({ success = true })
end)

RegisterNUICallback("login", function(data, cb)
    if not data.username or not data.password then
        cb({ success = false, message = "Missing username or password" })
        return
    end
    
    print("^3[Casino] Client sending login request to server^0")
    TriggerServerEvent(Utils.Events.LOGIN, data.username, data.password)
    
    -- Don't respond immediately - let server response handle success/failure
    cb({ success = true, message = "Logging in..." })
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

-- Export for fd_laptop (this will be called by fd_laptop when app is opened)
exports('openApp', function(source)
    print("^2[Casino] openApp export called by fd_laptop^0")
    openCasinoApp()
    
    -- Also trigger server initialization immediately
    TriggerServerEvent("casino:initializeApp")
end)

print("^2[Casino] Client initialized successfully!^0")