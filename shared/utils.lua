-- Shared utility functions for Premium Casino

Utils = {}

-- Generate a secure random string
function Utils.generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. string.sub(chars, rand, rand)
    end
    
    return result
end

-- Generate a secure hash for sessions/transactions
function Utils.generateHash(data)
    local hash = ""
    local time = os.time()
    local random = Utils.generateRandomString(16)
    
    -- Simple hash function (in production, use proper crypto)
    local combined = tostring(data) .. tostring(time) .. random
    
    for i = 1, #combined do
        local byte = string.byte(combined, i)
        hash = hash .. string.format("%02x", byte)
    end
    
    return hash:sub(1, 64) -- Limit to 64 characters
end

-- Validate bet amount
function Utils.validateBetAmount(amount, gameType)
    local minBet = Config.MinBets[gameType]
    local maxBet = Config.MaxBets[gameType]
    
    if not minBet or not maxBet then
        return false, "Invalid game type"
    end
    
    if type(amount) ~= "number" then
        return false, "Bet amount must be a number"
    end
    
    if amount <= 0 then
        return false, "Bet amount must be greater than $0"
    end
    
    if amount < minBet then
        return false, "Bet amount too low (minimum: $" .. minBet .. ")"
    end
    
    if amount > maxBet then
        return false, "Bet amount too high (maximum: $" .. maxBet .. ")"
    end
    
    return true, "Valid bet amount"
end

-- Format currency display
function Utils.formatCurrency(amount)
    if not amount or type(amount) ~= "number" then
        return "$0.00"
    end
    
    return "$" .. string.format("%.2f", amount)
end

-- Validate username format
function Utils.validateUsername(username)
    if not username or type(username) ~= "string" then
        return false, "Username must be a string"
    end
    
    if #username < 3 or #username > 20 then
        return false, "Username must be 3-20 characters"
    end
    
    if not string.match(username, "^[a-zA-Z0-9_]+$") then
        return false, "Username can only contain letters, numbers, and underscores"
    end
    
    return true, "Valid username"
end

-- Validate email format
function Utils.validateEmail(email)
    if not email or type(email) ~= "string" then
        return false, "Email must be a string"
    end
    
    local pattern = "^[%w%._%+%-]+@[%w%._%+%-]+%.%w+$"
    if not string.match(email, pattern) then
        return false, "Invalid email format"
    end
    
    return true, "Valid email"
end

-- Validate password strength
function Utils.validatePassword(password)
    if not password or type(password) ~= "string" then
        return false, "Password must be a string"
    end
    
    if #password < 6 then
        return false, "Password must be at least 6 characters"
    end
    
    if #password > 100 then
        return false, "Password too long"
    end
    
    return true, "Valid password"
end

-- Calculate RTP-based win probability
function Utils.calculateWinProbability(rtp, betAmount, potentialPayout)
    if potentialPayout <= betAmount then
        return 0.95 -- Almost guaranteed win for small payouts
    end
    
    local expectedReturn = betAmount * rtp
    local probability = expectedReturn / potentialPayout
    
    -- Ensure probability is between 0 and 1
    return math.max(0, math.min(1, probability))
end

-- Generate cryptographically secure random number (simulation)
function Utils.generateSecureRandom(min, max)
    -- In production, this would use a proper CSPRNG
    math.randomseed(os.time() + os.clock() * 1000000)
    
    if min and max then
        return math.random(min, max)
    else
        return math.random()
    end
end

-- Deep copy table
function Utils.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.deepCopy(orig_key)] = Utils.deepCopy(orig_value)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Serialize table to JSON-like string
function Utils.serializeTable(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    
    local result = "{"
    local first = true
    
    for k, v in pairs(tbl) do
        if not first then
            result = result .. ","
        end
        first = false
        
        local key = type(k) == "string" and '"' .. k .. '"' or tostring(k)
        local value
        
        if type(v) == "table" then
            value = Utils.serializeTable(v)
        elseif type(v) == "string" then
            value = '"' .. v .. '"'
        else
            value = tostring(v)
        end
        
        result = result .. key .. ":" .. value
    end
    
    return result .. "}"
end

-- Check if table is empty
function Utils.isEmpty(tbl)
    if type(tbl) ~= "table" then
        return true
    end
    
    return next(tbl) == nil
end

-- Round number to specified decimal places
function Utils.round(num, decimals)
    if not decimals then decimals = 0 end
    local mult = 10^decimals
    return math.floor(num * mult + 0.5) / mult
end

-- Time utilities
function Utils.getCurrentTimestamp()
    return os.time() * 1000 -- Return in milliseconds
end

function Utils.isTimestampExpired(timestamp, duration)
    local current = Utils.getCurrentTimestamp()
    return (current - timestamp) > duration
end

-- Logging levels
Utils.LogLevels = {
    INFO = "info",
    WARNING = "warning", 
    ERROR = "error",
    CRITICAL = "critical"
}

-- Event names for client-server communication
Utils.Events = {
    -- Authentication
    REGISTER = "casino:register",
    LOGIN = "casino:login",
    LOGOUT = "casino:logout",
    SESSION_VALIDATE = "casino:validateSession",
    
    -- Banking
    DEPOSIT = "casino:deposit",
    WITHDRAW = "casino:withdraw",
    GET_BALANCE = "casino:getBalance",
    GET_TRANSACTIONS = "casino:getTransactions",
    
    -- Games
    SLOTS_SPIN = "casino:slots:spin",
    PLINKO_DROP = "casino:plinko:drop",
    MINES_REVEAL = "casino:mines:reveal",
    MINES_CASHOUT = "casino:mines:cashout",
    AVIATOR_BET = "casino:aviator:bet",
    AVIATOR_CASHOUT = "casino:aviator:cashout",
    
    -- UI
    OPEN_APP = "casino:openApp",
    CLOSE_APP = "casino:closeApp",
    UPDATE_UI = "casino:updateUI"
}