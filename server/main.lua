-- Premium Casino Server - Main Logic
-- Handles all server-side operations, security, and banking integration

local QBCore = exports['qb-core']:GetCoreObject()

-- Server state
local CasinoServer = {
    activeSessions = {},
    rateLimits = {},
    lastCleanup = 0
}

-- Initialize database tables on resource start
CreateThread(function()
    Wait(1000) -- Wait for MySQL to be ready
    
    -- Check if tables exist, create if not
    local result = MySQL.query.await('SHOW TABLES LIKE "casino_users"')
    if not result or #result == 0 then
        print("^3[Casino] Database tables not found. Please run install.sql to set up the database.^0")
    else
        print("^2[Casino] Database connection established successfully.^0")
    end
    
    -- Clean up expired sessions every 5 minutes
    SetInterval(function()
        CasinoServer.cleanupExpiredSessions()
    end, 300000)
end)

-- Banking Bridge Functions
local function getBankingInterface()
    local bankingScript = Config.BankingScript
    local interface = Config.BankingExports[bankingScript]
    
    if not interface then
        print("^1[Casino] Banking script '" .. bankingScript .. "' not configured!^0")
        return nil
    end
    
    return interface
end

local function getPlayerBalance(source)
    local banking = getBankingInterface()
    if not banking then return 0 end
    
    local success, balance = pcall(banking.getBalance, source)
    if success and balance then
        return math.floor(balance * 100) / 100 -- Round to 2 decimals
    end
    
    return 0
end

local function removePlayerMoney(source, amount)
    local banking = getBankingInterface()
    if not banking then return false end
    
    local success, result = pcall(banking.removeMoney, source, amount)
    return success and result
end

local function addPlayerMoney(source, amount)
    local banking = getBankingInterface()
    if not banking then return false end
    
    local success, result = pcall(banking.addMoney, source, amount)
    return success and result
end

-- Security Functions
local function isRateLimited(source, action)
    local identifier = GetPlayerIdentifiers(source)[1]
    local key = identifier .. ":" .. action
    local current = GetGameTimer()
    
    if not CasinoServer.rateLimits[key] then
        CasinoServer.rateLimits[key] = current
        return false
    end
    
    local timeDiff = current - CasinoServer.rateLimits[key]
    if timeDiff < Config.Security.antiSpamCooldown then
        return true
    end
    
    CasinoServer.rateLimits[key] = current
    return false
end

local function logAction(source, action, category, level, message, data)
    local citizenid = nil
    local player = QBCore.Functions.GetPlayer(source)
    
    if player then
        citizenid = player.PlayerData.citizenid
    end
    
    MySQL.insert('INSERT INTO casino_logs (user_id, citizenid, action, category, level, message, data) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        nil, -- user_id will be filled when we have user system
        citizenid,
        action,
        category,
        level,
        message,
        json.encode(data)
    })
    
    -- Also print to server console for immediate visibility
    local logColor = level == "error" and "^1" or level == "warning" and "^3" or "^2"
    print(logColor .. "[Casino:" .. category .. "] " .. message .. "^0")
end

-- User Management Functions
local function hashPassword(password)
    -- Simple hash function (in production, use bcrypt)
    local hash = ""
    for i = 1, #password do
        local byte = string.byte(password, i)
        hash = hash .. string.format("%02x", byte * 17 + 42)
    end
    return hash
end

local function createUser(citizenid, username, email, password)
    local passwordHash = hashPassword(password)
    
    local result = MySQL.insert.await('INSERT INTO casino_users (citizenid, username, email, password_hash) VALUES (?, ?, ?, ?)', {
        citizenid,
        username,
        email,
        passwordHash
    })
    
    return result and result > 0
end

local function authenticateUser(username, password)
    local passwordHash = hashPassword(password)
    
    local result = MySQL.query.await('SELECT * FROM casino_users WHERE username = ? AND password_hash = ? AND is_active = TRUE', {
        username,
        passwordHash
    })
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

local function createSession(userId, citizenid)
    local sessionToken = Utils.generateHash(userId .. citizenid .. os.time())
    local expiresAt = Utils.getCurrentTimestamp() + Config.SessionTimeout
    
    MySQL.update('UPDATE casino_users SET session_token = ?, session_expires = ?, last_login = NOW() WHERE id = ?', {
        sessionToken,
        expiresAt,
        userId
    })
    
    CasinoServer.activeSessions[sessionToken] = {
        userId = userId,
        citizenid = citizenid,
        expires = expiresAt,
        lastActivity = Utils.getCurrentTimestamp()
    }
    
    return sessionToken
end

local function validateSession(sessionToken)
    local session = CasinoServer.activeSessions[sessionToken]
    if not session then return nil end
    
    if Utils.isTimestampExpired(session.expires, 0) then
        CasinoServer.activeSessions[sessionToken] = nil
        return nil
    end
    
    -- Update last activity
    session.lastActivity = Utils.getCurrentTimestamp()
    return session
end

local function getUserByCitizenId(citizenid)
    local result = MySQL.query.await('SELECT * FROM casino_users WHERE citizenid = ? AND is_active = TRUE', {
        citizenid
    })
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

-- Transaction Functions
local function createTransaction(userId, citizenid, transactionType, amount, gameType, gameData)
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { userId })
    if not user or #user == 0 then return false end
    
    local balanceBefore = user[1].balance
    local balanceAfter = balanceBefore
    
    if transactionType == "deposit" or transactionType == "game_win" then
        balanceAfter = balanceBefore + amount
    elseif transactionType == "withdrawal" or transactionType == "game_bet" or transactionType == "game_loss" then
        balanceAfter = balanceBefore - amount
    end
    
    local transactionHash = Utils.generateHash(userId .. transactionType .. amount .. os.time())
    
    local transactionId = MySQL.insert.await('INSERT INTO casino_transactions (user_id, citizenid, type, amount, balance_before, balance_after, game_type, game_data, transaction_hash, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        userId,
        citizenid,
        transactionType,
        amount,
        balanceBefore,
        balanceAfter,
        gameType,
        json.encode(gameData),
        transactionHash,
        'completed'
    })
    
    if transactionId then
        -- Update user balance
        MySQL.update('UPDATE casino_users SET balance = ? WHERE id = ?', { balanceAfter, userId })
        
        -- Update totals
        if transactionType == "deposit" then
            MySQL.update('UPDATE casino_users SET total_deposited = total_deposited + ? WHERE id = ?', { amount, userId })
        elseif transactionType == "withdrawal" then
            MySQL.update('UPDATE casino_users SET total_withdrawn = total_withdrawn + ? WHERE id = ?', { amount, userId })
        elseif transactionType == "game_bet" then
            MySQL.update('UPDATE casino_users SET total_wagered = total_wagered + ? WHERE id = ?', { amount, userId })
        elseif transactionType == "game_win" then
            MySQL.update('UPDATE casino_users SET total_won = total_won + ? WHERE id = ?', { amount, userId })
        end
        
        return transactionId, balanceAfter
    end
    
    return false
end

-- Cleanup Functions
function CasinoServer.cleanupExpiredSessions()
    local current = Utils.getCurrentTimestamp()
    local expired = {}
    
    for token, session in pairs(CasinoServer.activeSessions) do
        if Utils.isTimestampExpired(session.expires, 0) then
            table.insert(expired, token)
        end
    end
    
    for _, token in ipairs(expired) do
        CasinoServer.activeSessions[token] = nil
    end
    
    if #expired > 0 then
        print("^3[Casino] Cleaned up " .. #expired .. " expired sessions^0")
    end
end

-- Exported Functions
function openApp(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    logAction(source, "app_opened", "system", "info", "Player opened casino app", { citizenid = citizenid })
    
    -- Trigger client to open the app
    TriggerClientEvent(Utils.Events.OPEN_APP, source)
end

-- Event Handlers
RegisterNetEvent(Utils.Events.REGISTER, function(username, email, password)
    local source = source
    
    if isRateLimited(source, "register") then
        TriggerClientEvent('QBCore:Notify', source, 'Too many registration attempts. Please wait.', 'error')
        return
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Validate inputs
    local validUsername, usernameMsg = Utils.validateUsername(username)
    local validEmail, emailMsg = Utils.validateEmail(email)
    local validPassword, passwordMsg = Utils.validatePassword(password)
    
    if not validUsername then
        TriggerClientEvent('QBCore:Notify', source, usernameMsg, 'error')
        return
    end
    
    if not validEmail then
        TriggerClientEvent('QBCore:Notify', source, emailMsg, 'error')
        return
    end
    
    if not validPassword then
        TriggerClientEvent('QBCore:Notify', source, passwordMsg, 'error')
        return
    end
    
    -- Check if user already exists
    local existingUser = getUserByCitizenId(citizenid)
    if existingUser then
        TriggerClientEvent('QBCore:Notify', source, 'You already have a casino account!', 'error')
        return
    end
    
    -- Check if username is taken
    local usernameTaken = MySQL.query.await('SELECT id FROM casino_users WHERE username = ?', { username })
    if usernameTaken and #usernameTaken > 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Username already taken!', 'error')
        return
    end
    
    -- Create user
    local success = createUser(citizenid, username, email, password)
    if success then
        logAction(source, "user_registered", "auth", "info", "New user registered", { 
            citizenid = citizenid, 
            username = username 
        })
        TriggerClientEvent('QBCore:Notify', source, 'Casino account created successfully!', 'success')
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, { action = "registration_success" })
    else
        TriggerClientEvent('QBCore:Notify', source, 'Failed to create account. Please try again.', 'error')
    end
end)

RegisterNetEvent(Utils.Events.LOGIN, function(username, password)
    local source = source
    
    if isRateLimited(source, "login") then
        TriggerClientEvent('QBCore:Notify', source, 'Too many login attempts. Please wait.', 'error')
        return
    end
    
    local user = authenticateUser(username, password)
    if not user then
        logAction(source, "login_failed", "auth", "warning", "Failed login attempt", { username = username })
        TriggerClientEvent('QBCore:Notify', source, 'Invalid username or password!', 'error')
        return
    end
    
    local sessionToken = createSession(user.id, user.citizenid)
    
    logAction(source, "user_login", "auth", "info", "User logged in", { 
        citizenid = user.citizenid, 
        username = user.username 
    })
    
    TriggerClientEvent(Utils.Events.UPDATE_UI, source, { 
        action = "login_success",
        user = {
            id = user.id,
            username = user.username,
            balance = user.balance,
            sessionToken = sessionToken
        }
    })
end)

RegisterNetEvent(Utils.Events.DEPOSIT, function(amount, sessionToken)
    local source = source
    
    if isRateLimited(source, "deposit") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before making another deposit.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    if type(amount) ~= "number" or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid deposit amount!', 'error')
        return
    end
    
    if amount > Config.Security.maxDepositPerHour then
        TriggerClientEvent('QBCore:Notify', source, 'Deposit amount exceeds hourly limit!', 'error')
        return
    end
    
    -- Check bank balance
    local bankBalance = getPlayerBalance(source)
    if bankBalance < amount then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient bank funds!', 'error')
        return
    end
    
    -- Remove money from bank
    if not removePlayerMoney(source, amount) then
        TriggerClientEvent('QBCore:Notify', source, 'Banking transaction failed!', 'error')
        return
    end
    
    -- Create transaction record
    local transactionId, newBalance = createTransaction(session.userId, session.citizenid, "deposit", amount)
    
    if transactionId then
        logAction(source, "deposit", "banking", "info", "Player deposited money", { 
            amount = amount,
            newBalance = newBalance
        })
        
        TriggerClientEvent('QBCore:Notify', source, 'Deposited ' .. Utils.formatCurrency(amount) .. ' successfully!', 'success')
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, { 
            action = "balance_updated",
            balance = newBalance
        })
    else
        -- Refund the money if transaction failed
        addPlayerMoney(source, amount)
        TriggerClientEvent('QBCore:Notify', source, 'Deposit failed. Money refunded.', 'error')
    end
end)

RegisterNetEvent(Utils.Events.WITHDRAW, function(amount, sessionToken)
    local source = source
    
    if isRateLimited(source, "withdraw") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before making another withdrawal.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    if type(amount) ~= "number" or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid withdrawal amount!', 'error')
        return
    end
    
    if amount > Config.Security.maxWithdrawPerHour then
        TriggerClientEvent('QBCore:Notify', source, 'Withdrawal amount exceeds hourly limit!', 'error')
        return
    end
    
    -- Check casino balance
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    if not user or #user == 0 or user[1].balance < amount then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient casino balance!', 'error')
        return
    end
    
    -- Create transaction record (this will deduct from casino balance)
    local transactionId, newBalance = createTransaction(session.userId, session.citizenid, "withdrawal", amount)
    
    if transactionId then
        -- Add money to bank
        if addPlayerMoney(source, amount) then
            logAction(source, "withdrawal", "banking", "info", "Player withdrew money", { 
                amount = amount,
                newBalance = newBalance
            })
            
            TriggerClientEvent('QBCore:Notify', source, 'Withdrew ' .. Utils.formatCurrency(amount) .. ' successfully!', 'success')
            TriggerClientEvent(Utils.Events.UPDATE_UI, source, { 
                action = "balance_updated",
                balance = newBalance
            })
        else
            -- Reverse the transaction if banking failed
            createTransaction(session.userId, session.citizenid, "deposit", amount)
            TriggerClientEvent('QBCore:Notify', source, 'Banking transaction failed. Please try again.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Withdrawal failed. Please try again.', 'error')
    end
end)

RegisterNetEvent(Utils.Events.GET_BALANCE, function(sessionToken)
    local source = source
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, { action = "session_expired" })
        return
    end
    
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    if user and #user > 0 then
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, { 
            action = "balance_updated",
            balance = user[1].balance
        })
    end
end)

RegisterNetEvent(Utils.Events.GET_TRANSACTIONS, function(sessionToken, limit, offset)
    local source = source
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, { action = "session_expired" })
        return
    end
    
    limit = limit or 50
    offset = offset or 0
    
    local transactions = MySQL.query.await('SELECT * FROM casino_transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?', {
        session.userId,
        limit,
        offset
    })
    
    TriggerClientEvent(Utils.Events.UPDATE_UI, source, { 
        action = "transactions_loaded",
        transactions = transactions
    })
end)

-- Export the main function
exports('openApp', openApp)

print("^2[Casino] Server initialized successfully!^0")