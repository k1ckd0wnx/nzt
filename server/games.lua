-- Premium Casino Games Server Engine
-- All game logic runs server-side for security and validation

-- Wait for Config to be available
CreateThread(function()
    while not Config do
        Wait(100)
    end
end)

local GameEngine = {}

-- Slot Machine Engine
GameEngine.Slots = {}

function GameEngine.Slots.generateOutcome(machineType, betAmount)
    -- Safety check for Config availability
    if not Config or not Config.SlotMachines or not Config.RTP then
        return nil
    end
    
    local config = Config.SlotMachines[machineType]
    if not config then return nil end
    
    local rtp = Config.RTP.slots[machineType]
    local symbols = config.symbols
    local wilds = config.wilds
    
    -- Generate 3 reels
    local reels = {}
    local wildCount = 0
    
    for i = 1, 3 do
        local symbolIndex = Utils.generateSecureRandom(1, #symbols)
        local symbol = symbols[symbolIndex]
        reels[i] = symbol
        
        -- Count wilds
        for _, wild in ipairs(wilds) do
            if symbol == wild then
                wildCount = wildCount + 1
                break
            end
        end
    end
    
    -- Calculate win
    local isWin = false
    local multiplier = 0
    local winType = "none"
    
    -- Check for three of a kind (including wilds)
    if reels[1] == reels[2] and reels[2] == reels[3] then
        isWin = true
        winType = "three_of_kind"
        local symbol = reels[1]
        
        -- Get payout for this symbol
        if config.payouts.three_of_kind[symbol] then
            multiplier = config.payouts.three_of_kind[symbol] / betAmount
        else
            multiplier = 2 -- Default multiplier
        end
        
        -- Jackpot check
        if symbol == wilds[1] then -- Wild symbol jackpot
            multiplier = config.payouts.jackpot / betAmount
            winType = "jackpot"
        end
    elseif wildCount >= 2 then
        -- Two wilds is a smaller win
        isWin = true
        winType = "wild_pair"
        multiplier = 3
    elseif wildCount == 1 then
        -- One wild is a small win
        isWin = true
        winType = "wild_single"
        multiplier = 1.5
    end
    
    -- Apply RTP adjustment
    if isWin then
        local winProbability = Utils.calculateWinProbability(rtp, betAmount, betAmount * multiplier)
        local randomChance = Utils.generateSecureRandom()
        
        if randomChance > winProbability then
            -- Force loss to maintain RTP
            isWin = false
            multiplier = 0
            winType = "none"
            
            -- Reshuffle reels to ensure no winning combination
            while reels[1] == reels[2] and reels[2] == reels[3] do
                local newIndex = Utils.generateSecureRandom(1, #symbols)
                reels[3] = symbols[newIndex]
            end
        end
    end
    
    return {
        reels = reels,
        isWin = isWin,
        multiplier = multiplier,
        winType = winType,
        payout = isWin and (betAmount * multiplier) or 0
    }
end

-- Plinko Engine
GameEngine.Plinko = {}

function GameEngine.Plinko.simulateDrop(betAmount)
    -- Safety check for Config availability
    if not Config or not Config.Plinko or not Config.RTP then
        return { finalPosition = 1, multiplier = 0, payout = 0, path = {} }
    end
    
    local config = Config.Plinko
    local rtp = Config.RTP.plinko
    
    -- Determine bet scaling factor based on bet amount
    local scalingFactor = 1.0
    if betAmount >= config.betScaling.maxBet then
        scalingFactor = config.betScaling.scalingFactors.max
    elseif betAmount >= config.betScaling.highBet then
        scalingFactor = config.betScaling.scalingFactors.high
    elseif betAmount >= config.betScaling.midBet then
        scalingFactor = config.betScaling.scalingFactors.mid
    else
        scalingFactor = config.betScaling.scalingFactors.low
    end
    
    -- More realistic Plinko physics simulation
    local position = math.floor(#config.multipliers / 2) -- Start in middle
    
    -- Simulate ball bouncing through pegs (more realistic)
    for row = 1, config.rows do
        -- Natural tendency to move toward center (gravity effect)
        local centerPull = (#config.multipliers / 2) - position
        local gravityInfluence = centerPull * 0.1 -- Weak center pull
        
        -- Random bounce direction with slight center bias
        local randomBounce = Utils.generateSecureRandom() - 0.5 + gravityInfluence
        
        if randomBounce > 0.1 then
            position = position + 1
        elseif randomBounce < -0.1 then
            position = position - 1
        end
        -- else stay in same position (rare)
        
        -- Apply additional randomness for realism
        if Utils.generateSecureRandom() > 0.85 then
            position = position + (Utils.generateSecureRandom() > 0.5 and 1 or -1)
        end
        
        -- Keep within bounds
        position = math.max(1, math.min(#config.multipliers, position))
    end
    
    local baseMultiplier = config.multipliers[position]
    
    -- Apply bet scaling to reduce multipliers for higher bets
    local effectiveMultiplier = baseMultiplier * scalingFactor
    
    -- Additional house edge - make big wins much rarer
    local houseEdgeCheck = Utils.generateSecureRandom()
    
    -- If trying to win big (10x+ multiplier), apply harsh house edge
    if effectiveMultiplier >= 10 then
        -- Only 2% chance to actually get the big multiplier
        if houseEdgeCheck > 0.02 then
            -- Force to a losing or break-even position
            local badPositions = {}
            for i, mult in ipairs(config.multipliers) do
                if mult <= 1.0 then
                    table.insert(badPositions, {index = i, mult = mult * scalingFactor})
                end
            end
            
            if #badPositions > 0 then
                local randomBad = badPositions[Utils.generateSecureRandom(1, #badPositions)]
                position = randomBad.index
                effectiveMultiplier = randomBad.mult
            end
        end
    elseif effectiveMultiplier >= 4 then
        -- Medium wins (4x-9x) have 15% chance
        if houseEdgeCheck > 0.15 then
            -- Force to lower multiplier
            local lowerPositions = {}
            for i, mult in ipairs(config.multipliers) do
                if mult <= 2.0 then
                    table.insert(lowerPositions, {index = i, mult = mult * scalingFactor})
                end
            end
            
            if #lowerPositions > 0 then
                local randomLower = lowerPositions[Utils.generateSecureRandom(1, #lowerPositions)]
                position = randomLower.index
                effectiveMultiplier = randomLower.mult
            end
        end
    elseif effectiveMultiplier >= 2 then
        -- Small wins (2x-3x) have 35% chance
        if houseEdgeCheck > 0.35 then
            -- Force to break-even or loss
            local breakEvenPositions = {}
            for i, mult in ipairs(config.multipliers) do
                if mult <= 1.5 then
                    table.insert(breakEvenPositions, {index = i, mult = mult * scalingFactor})
                end
            end
            
            if #breakEvenPositions > 0 then
                local randomBreakEven = breakEvenPositions[Utils.generateSecureRandom(1, #breakEvenPositions)]
                position = randomBreakEven.index
                effectiveMultiplier = randomBreakEven.mult
            end
        end
    end
    
    -- Final payout calculation
    local payout = betAmount * effectiveMultiplier
    
    return {
        finalPosition = position,
        multiplier = effectiveMultiplier,
        payout = payout,
        baseMultiplier = baseMultiplier,
        scalingFactor = scalingFactor,
        path = {} -- Could store the full path for animation
    }
end

-- Mines Engine
GameEngine.Mines = {}

function GameEngine.Mines.createGame(betAmount, mineCount)
    -- Safety check for Config availability
    if not Config or not Config.Mines then
        return nil
    end
    
    local config = Config.Mines
    
    if mineCount < 1 or mineCount >= config.gridSize then
        return nil
    end
    
    -- Generate mine positions
    local mines = {}
    local minePositions = {}
    
    while #minePositions < mineCount do
        local position = Utils.generateSecureRandom(1, config.gridSize)
        if not mines[position] then
            mines[position] = true
            table.insert(minePositions, position)
        end
    end
    
    return {
        mines = mines,
        minePositions = minePositions,
        mineCount = mineCount,
        revealedSafe = 0,
        isActive = true,
        betAmount = betAmount
    }
end

function GameEngine.Mines.revealTile(gameSession, position)
    if not gameSession.isActive then
        return { success = false, reason = "Game not active" }
    end
    
    if gameSession.mines[position] then
        -- Hit a mine!
        gameSession.isActive = false
        return {
            success = true,
            isMine = true,
            gameOver = true,
            payout = 0
        }
    else
        -- Safe tile
        gameSession.revealedSafe = gameSession.revealedSafe + 1
        
        local config = Config and Config.Mines
        local multiplier = (config and config.multipliers and config.multipliers[gameSession.revealedSafe]) or 1.0
        local currentPayout = gameSession.betAmount * multiplier
        
        return {
            success = true,
            isMine = false,
            gameOver = false,
            revealedSafe = gameSession.revealedSafe,
            currentMultiplier = multiplier,
            currentPayout = currentPayout
        }
    end
end

function GameEngine.Mines.cashOut(gameSession)
    if not gameSession.isActive or gameSession.revealedSafe == 0 then
        return { success = false, reason = "Cannot cash out" }
    end
    
    local config = Config and Config.Mines
    local multiplier = (config and config.multipliers and config.multipliers[gameSession.revealedSafe]) or 1.0
    local payout = gameSession.betAmount * multiplier
    
    -- Apply RTP check
    local rtp = (Config and Config.RTP and Config.RTP.mines) or 0.97
    local winProbability = Utils.calculateWinProbability(rtp, gameSession.betAmount, payout)
    local randomChance = Utils.generateSecureRandom()
    
    if randomChance > winProbability and multiplier > 1.0 then
        -- Reduce payout to maintain RTP
        multiplier = multiplier * 0.8
        payout = gameSession.betAmount * multiplier
    end
    
    gameSession.isActive = false
    
    return {
        success = true,
        finalPayout = payout,
        finalMultiplier = multiplier,
        revealedSafe = gameSession.revealedSafe
    }
end

-- Aviator Engine
GameEngine.Aviator = {}
local aviatorState = {
    isActive = false,
    currentMultiplier = 1.0,
    crashed = false,
    startTime = 0,
    activeBets = {}
}

function GameEngine.Aviator.startRound()
    if aviatorState.isActive then return false end
    
    -- Safety check for Config availability
    if not Config or not Config.Aviator or not Config.RTP then
        return false
    end
    
    local config = Config.Aviator
    aviatorState.isActive = true
    aviatorState.currentMultiplier = 1.0
    aviatorState.crashed = false
    aviatorState.startTime = GetGameTimer()
    aviatorState.activeBets = {}
    
    -- Determine crash point
    local rtp = Config.RTP.aviator
    local crashMultiplier = Utils.generateSecureRandom(config.minMultiplier, config.maxMultiplier)
    
    -- Adjust crash point based on RTP
    local avgBet = 100 -- Assumed average bet
    local expectedPayout = avgBet * crashMultiplier
    local winProbability = Utils.calculateWinProbability(rtp, avgBet, expectedPayout)
    
    if Utils.generateSecureRandom() > winProbability then
        crashMultiplier = Utils.generateSecureRandom(1.0, 2.0) -- Force early crash
    end
    
    aviatorState.targetCrash = crashMultiplier
    
    return true
end

function GameEngine.Aviator.placeBet(userId, betAmount, autoCashOut)
    if not aviatorState.isActive or aviatorState.currentMultiplier > 1.01 then
        return { success = false, reason = "Cannot place bet now" }
    end
    
    local config = Config and Config.Aviator
    if not config then
        return { success = false, reason = "Game configuration not available" }
    end
    
    if autoCashOut and autoCashOut > config.autoCashoutMax then
        autoCashOut = config.autoCashoutMax
    end
    
    aviatorState.activeBets[userId] = {
        betAmount = betAmount,
        autoCashOut = autoCashOut,
        cashedOut = false
    }
    
    return { success = true }
end

function GameEngine.Aviator.cashOut(userId)
    local bet = aviatorState.activeBets[userId]
    if not bet or bet.cashedOut or aviatorState.crashed then
        return { success = false, reason = "Cannot cash out" }
    end
    
    bet.cashedOut = true
    bet.cashOutMultiplier = aviatorState.currentMultiplier
    bet.payout = bet.betAmount * aviatorState.currentMultiplier
    
    return {
        success = true,
        multiplier = aviatorState.currentMultiplier,
        payout = bet.payout
    }
end

function GameEngine.Aviator.updateRound()
    if not aviatorState.isActive or aviatorState.crashed then return end
    
    -- Safety check for Config availability
    if not Config or not Config.Aviator then
        return { crashed = true, crashMultiplier = 1.0 }
    end
    
    local config = Config.Aviator
    local elapsed = GetGameTimer() - aviatorState.startTime
    
    -- Calculate current multiplier based on time
    local timeMultiplier = 1.0 + (elapsed / 1000.0) * 0.1 -- 0.1x per second
    aviatorState.currentMultiplier = math.min(timeMultiplier, config.maxMultiplier)
    
    -- Check for crash
    if aviatorState.currentMultiplier >= aviatorState.targetCrash then
        aviatorState.crashed = true
        aviatorState.isActive = false
        
        -- Process all active bets
        for userId, bet in pairs(aviatorState.activeBets) do
            if not bet.cashedOut then
                bet.lost = true
                bet.payout = 0
            end
        end
        
        return { crashed = true, crashMultiplier = aviatorState.targetCrash }
    end
    
    -- Check auto cash-outs
    for userId, bet in pairs(aviatorState.activeBets) do
        if not bet.cashedOut and bet.autoCashOut and aviatorState.currentMultiplier >= bet.autoCashOut then
            GameEngine.Aviator.cashOut(userId)
        end
    end
    
    return { 
        crashed = false, 
        currentMultiplier = aviatorState.currentMultiplier,
        activeBets = aviatorState.activeBets
    }
end

function GameEngine.Aviator.getRoundState()
    return {
        isActive = aviatorState.isActive,
        currentMultiplier = aviatorState.currentMultiplier,
        crashed = aviatorState.crashed,
        activeBets = aviatorState.activeBets
    }
end

-- Game Event Handlers
RegisterNetEvent(Utils.Events.SLOTS_SPIN, function(machineType, betAmount, sessionToken)
    local source = source
    
    if isRateLimited(source, "slots_spin") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before spinning again.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local validBet, betMsg = Utils.validateBetAmount(betAmount, "slots")
    if not validBet then
        TriggerClientEvent('QBCore:Notify', source, betMsg, 'error')
        return
    end
    
    -- Check balance
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    if not user or #user == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Convert balance to number to avoid string comparison issues
    local userBalance = tonumber(user[1].balance) or 0
    if userBalance < betAmount then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Generate slot outcome
    local outcome = GameEngine.Slots.generateOutcome(machineType, betAmount)
    if not outcome then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid slot machine!', 'error')
        return
    end
    
    -- Process bet transaction
    local betTransactionId = createTransaction(session.userId, session.citizenid, "game_bet", betAmount, "slots", {
        machineType = machineType,
        outcome = outcome
    })
    
    if not betTransactionId then
        TriggerClientEvent('QBCore:Notify', source, 'Transaction failed!', 'error')
        return
    end
    
    local newBalance = user[1].balance - betAmount
    
    -- Process win if applicable
    if outcome.isWin and outcome.payout > 0 then
        local winTransactionId = createTransaction(session.userId, session.citizenid, "game_win", outcome.payout, "slots", {
            machineType = machineType,
            outcome = outcome
        })
        
        if winTransactionId then
            newBalance = newBalance + outcome.payout
        end
    end
    
    -- Log the game
    logAction(source, "slots_spin", "game", "info", "Slot machine spin", {
        machineType = machineType,
        betAmount = betAmount,
        payout = outcome.payout,
        isWin = outcome.isWin
    })
    
    -- Send result to client
    TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
        action = "slots_result",
        machineType = machineType,
        outcome = outcome,
        balance = newBalance
    })
end)

RegisterNetEvent(Utils.Events.PLINKO_DROP, function(betAmount, sessionToken)
    local source = source
    
    if isRateLimited(source, "plinko_drop") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before dropping again.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local validBet, betMsg = Utils.validateBetAmount(betAmount, "plinko")
    if not validBet then
        TriggerClientEvent('QBCore:Notify', source, betMsg, 'error')
        return
    end
    
    -- Check balance
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    if not user or #user == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Convert balance to number to avoid string comparison issues
    local userBalance = tonumber(user[1].balance) or 0
    if userBalance < betAmount then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Generate plinko outcome
    local outcome = GameEngine.Plinko.simulateDrop(betAmount)
    
    -- Process bet transaction (deducts from casino balance)
    local betTransactionId = createTransaction(session.userId, session.citizenid, "game_bet", betAmount, "plinko", outcome)
    if not betTransactionId then
        TriggerClientEvent('QBCore:Notify', source, 'Transaction failed!', 'error')
        return
    end
    
    -- Get updated balance after bet deduction
    local updatedUser = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    local newBalance = updatedUser[1].balance
    
    -- Process win if applicable (adds to casino balance)
    if outcome.payout > 0 then
        local winTransactionId = createTransaction(session.userId, session.citizenid, "game_win", outcome.payout, "plinko", outcome)
        
        if winTransactionId then
            -- Get final balance after win
            local finalUser = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
            newBalance = finalUser[1].balance
        end
    end
    
    -- Log the game
    logAction(source, "plinko_drop", "game", "info", "Plinko drop", {
        betAmount = betAmount,
        payout = outcome.payout,
        multiplier = outcome.multiplier
    })
    
    -- Send result to client
    TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
        action = "plinko_result",
        outcome = outcome,
        balance = newBalance
    })
end)

-- Mines event handlers
local activeMinesGames = {} -- Store active mines games per user

RegisterNetEvent(Utils.Events.MINES_REVEAL, function(position, sessionToken)
    local source = source
    
    if isRateLimited(source, "mines_reveal") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before revealing another tile.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local gameSession = activeMinesGames[session.userId]
    if not gameSession then
        TriggerClientEvent('QBCore:Notify', source, 'No active mines game found.', 'error')
        return
    end
    
    local result = GameEngine.Mines.revealTile(gameSession, position)
    
    if result.success then
        if result.isMine then
            -- Game over - player hit a mine
            activeMinesGames[session.userId] = nil
            
            logAction(source, "mines_mine_hit", "game", "info", "Player hit a mine", {
                position = position,
                revealedSafe = gameSession.revealedSafe
            })
        end
        
        -- Send result to client
        TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
            action = "mines_result",
            result = result,
            gameSession = gameSession
        })
    else
        TriggerClientEvent('QBCore:Notify', source, result.reason or 'Invalid move.', 'error')
    end
end)

RegisterNetEvent(Utils.Events.MINES_CASHOUT, function(sessionToken)
    local source = source
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local gameSession = activeMinesGames[session.userId]
    if not gameSession then
        TriggerClientEvent('QBCore:Notify', source, 'No active mines game found.', 'error')
        return
    end
    
    local result = GameEngine.Mines.cashOut(gameSession)
    
    if result.success then
        activeMinesGames[session.userId] = nil
        
        -- Process win transaction
        local winAmount = result.finalPayout - gameSession.betAmount
        if winAmount > 0 then
            local winTransactionId = createTransaction(session.userId, session.citizenid, "game_win", winAmount, "mines", {
                finalPayout = result.finalPayout,
                revealedSafe = result.revealedSafe
            })
            
            if winTransactionId then
                local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
                local newBalance = user[1].balance + winAmount
                
                TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
                    action = "mines_cashout_success",
                    result = result,
                    balance = newBalance
                })
                
                logAction(source, "mines_cashout", "game", "info", "Player cashed out mines game", {
                    payout = result.finalPayout,
                    revealedSafe = result.revealedSafe
                })
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, result.reason or 'Cannot cash out.', 'error')
    end
end)

-- Aviator event handlers
RegisterNetEvent(Utils.Events.AVIATOR_BET, function(betAmount, autoCashOut, sessionToken)
    local source = source
    
    if isRateLimited(source, "aviator_bet") then
        TriggerClientEvent('QBCore:Notify', source, 'Please wait before placing another bet.', 'error')
        return
    end
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local validBet, betMsg = Utils.validateBetAmount(betAmount, "aviator")
    if not validBet then
        TriggerClientEvent('QBCore:Notify', source, betMsg, 'error')
        return
    end
    
    -- Check balance
    local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
    if not user or #user == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Convert balance to number to avoid string comparison issues
    local userBalance = tonumber(user[1].balance) or 0
    if userBalance < betAmount then
        TriggerClientEvent('QBCore:Notify', source, 'Insufficient balance!', 'error')
        return
    end
    
    -- Place bet
    local result = GameEngine.Aviator.placeBet(session.userId, betAmount, autoCashOut)
    
    if result.success then
        -- Process bet transaction
        local betTransactionId = createTransaction(session.userId, session.citizenid, "game_bet", betAmount, "aviator", {
            autoCashOut = autoCashOut
        })
        
        if betTransactionId then
            local newBalance = user[1].balance - betAmount
            
            TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
                action = "aviator_bet_placed",
                betAmount = betAmount,
                autoCashOut = autoCashOut,
                balance = newBalance
            })
            
            logAction(source, "aviator_bet", "game", "info", "Player placed aviator bet", {
                betAmount = betAmount,
                autoCashOut = autoCashOut
            })
        end
    else
        TriggerClientEvent('QBCore:Notify', source, result.reason or 'Cannot place bet now.', 'error')
    end
end)

RegisterNetEvent(Utils.Events.AVIATOR_CASHOUT, function(sessionToken)
    local source = source
    
    local session = validateSession(sessionToken)
    if not session then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid session. Please log in again.', 'error')
        return
    end
    
    local result = GameEngine.Aviator.cashOut(session.userId)
    
    if result.success then
        -- Process win transaction
        local winTransactionId = createTransaction(session.userId, session.citizenid, "game_win", result.payout, "aviator", {
            multiplier = result.multiplier,
            payout = result.payout
        })
        
        if winTransactionId then
            local user = MySQL.query.await('SELECT balance FROM casino_users WHERE id = ?', { session.userId })
            local newBalance = user[1].balance + result.payout
            
            TriggerClientEvent(Utils.Events.UPDATE_UI, source, {
                action = "aviator_cashout_success",
                result = result,
                balance = newBalance
            })
            
            logAction(source, "aviator_cashout", "game", "info", "Player cashed out from aviator", {
                multiplier = result.multiplier,
                payout = result.payout
            })
        end
    else
        TriggerClientEvent('QBCore:Notify', source, result.reason or 'Cannot cash out.', 'error')
    end
end)

-- Initialize Aviator rounds
CreateThread(function()
    -- Wait for Config to be available before starting
    while not Config or not Config.Aviator do
        Wait(1000)
    end
    
    
    while true do
        if not aviatorState.isActive then
            Wait(5000) -- Wait 5 seconds between rounds
            GameEngine.Aviator.startRound()
            
            -- Only broadcast to players with active casino sessions
            for sessionToken, session in pairs(CasinoServer.activeSessions) do
                if session.source then
                    TriggerClientEvent(Utils.Events.UPDATE_UI, session.source, {
                        action = "aviator_round_start"
                    })
                end
            end
        else
            local result = GameEngine.Aviator.updateRound()
            
            -- Only broadcast to players with active casino sessions
            for sessionToken, session in pairs(CasinoServer.activeSessions) do
                if session.source then
                    TriggerClientEvent(Utils.Events.UPDATE_UI, session.source, {
                        action = "aviator_update",
                        state = result
                    })
                end
            end
            
            if result.crashed then
                -- Process all losing bets
                for userId, bet in pairs(aviatorState.activeBets) do
                    if not bet.cashedOut then
                        -- No transaction needed for losses as bet was already deducted
                        logAction(nil, "aviator_loss", "game", "info", "Player lost aviator bet", {
                            userId = userId,
                            betAmount = bet.betAmount,
                            crashMultiplier = result.crashMultiplier
                        })
                    end
                end
                
                -- Broadcast crash to active casino players only
                for sessionToken, session in pairs(CasinoServer.activeSessions) do
                    if session.source then
                        TriggerClientEvent(Utils.Events.UPDATE_UI, session.source, {
                            action = "aviator_crashed",
                            crashMultiplier = result.crashMultiplier
                        })
                    end
                end
            end
        end
        
        Wait(Config and Config.Aviator and Config.Aviator.updateInterval or 100)
    end
end)

-- Export game engine for other files
_G.GameEngine = GameEngine