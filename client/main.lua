-- Premium Casino Client - Main Logic
-- Handles fd_laptop integration and UI communication

local isAppOpen = false
local nuiData = {}
local pendingLoginCallback = nil

-- Register with fd_laptop (moved to server-side as per fd_laptop docs)

-- Event Handlers from Server
RegisterNetEvent(Utils.Events.OPEN_APP, function()
    openCasinoApp()
end)

-- App initialization is now handled by React component

-- Function to handle UI updates
local function handleUIUpdate(data)
    print("^3[Casino] UPDATE_UI received with action: " .. (data.action or "no action") .. "^0")
    print("^3[Casino] Full data received: " .. json.encode(data) .. "^0")
    
    -- Always send to NUI - React app will handle appropriately
    local message = {
        type = "updateUI",
        data = data
    }
    print("^3[Casino] Sending to NUI: " .. json.encode(message) .. "^0")
    
    -- Try multiple message formats to ensure fd_laptop compatibility
    SendNUIMessage(message)
    
    -- Also try fd_laptop compatible format
    local fdMessage = {
        action = "casino_updateUI",
        data = data
    }
    print("^3[Casino] Also sending fd_laptop format: " .. json.encode(fdMessage) .. "^0")
    SendNUIMessage(fdMessage)
    
    -- Try direct window message format
    local windowMessage = {
        source = "casino",
        action = data.action,
        payload = data
    }
    print("^3[Casino] Also sending window format: " .. json.encode(windowMessage) .. "^0")
    SendNUIMessage(windowMessage)
    
    -- Store important data for when app reopens
    if data.action == "login_success" then
        nuiData.user = data.user
        print("^2[Casino] Stored user data for " .. data.user.username .. "^0")
        
        -- Respond to pending login callback with direct user data
        if pendingLoginCallback then
            print("^3[Casino] Responding to pending login callback with user data^0")
            pendingLoginCallback({
                success = true,
                action = "directLogin",
                user = data.user,
                message = "Login successful"
            })
            pendingLoginCallback = nil
        end
    elseif data.action == "balance_updated" then
        if nuiData.user then
            nuiData.user.balance = data.balance
        end
    elseif data.action == "initialize_app" or data.action == "initializeApp" then
        -- Force app to be marked as open when initialization happens
        isAppOpen = true
        print("^2[Casino] App marked as open due to initialization^0")
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
    
    -- Send initialization data directly in the callback response
    local player = QBCore.Functions.GetPlayer(GetPlayerServerId(PlayerId()))
    if player then
        local citizenid = player.PlayerData.citizenid
        
        -- Get user data if exists
        local hasUser = nuiData.user ~= nil
        local userData = nuiData.user
        
        print("^3[Casino] Sending initialization data in callback response^0")
        cb({
            success = true,
            action = "directInit",
            config = {
                casinoName = "Premium Casino",
                minBets = { slots = 20, plinko = 10, mines = 10, aviator = 10 },
                maxBets = { slots = 10000, plinko = 5000, mines = 5000, aviator = 50000 },
                slotMachines = Config and Config.SlotMachines or {}
            },
            user = userData,
            hasStoredUser = hasUser
        })
    else
        cb("ok")
    end
end)

RegisterNUICallback("debugMessage", function(data, cb)
    print("^3[Casino] DEBUG from React: " .. json.encode(data) .. "^0")
    cb("ok")
end)

RegisterNUICallback("pollForData", function(data, cb)
    print("^3[Casino] React polling for data: " .. json.encode(data) .. "^0")
    
    -- Force trigger server to send fresh data
    TriggerServerEvent("casino:initializeApp")
    
    -- Also send any stored user data directly
    if nuiData.user then
        print("^3[Casino] Sending stored user data to React^0")
        
        -- Try to send user data in a format that might work
        local userData = {
            action = "login_success",
            user = nuiData.user
        }
        
        -- Use the same multi-format approach
        SendNUIMessage({type = "updateUI", data = userData})
        SendNUIMessage({action = "casino_updateUI", data = userData})
        SendNUIMessage({source = "casino", action = "login_success", payload = userData})
    end
    
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
    
    -- Store callback for direct response
    pendingLoginCallback = cb
    
    TriggerServerEvent(Utils.Events.LOGIN, data.username, data.password)
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