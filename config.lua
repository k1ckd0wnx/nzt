Config = {}

-- Casino General Settings
Config.CasinoName = "Premium Casino"
Config.MinimumAge = 18
Config.SessionTimeout = 30 * 60000 -- 30 minutes in milliseconds

-- Localization Settings
Config.Locale = 'en' -- Default language: 'en' = English, 'bg' = Bulgarian
Config.AvailableLocales = {
    ['en'] = 'English',
    ['bg'] = 'Български'
}

-- Banking Bridge Configuration
Config.BankingScript = "RxBanking" -- Change this to switch banking scripts
Config.BankingExports = {
    RxBanking = {
        getBalance = function(source)
            -- Get player identifier for RxBanking
            local player = QBCore.Functions.GetPlayer(source)
            if not player then 
                print("^1[Casino] No QBCore player found for source: " .. source .. "^0")
                return 0 
            end
            
            local identifier = player.PlayerData.citizenid
            print("^3[Casino] Getting balance for citizen ID: " .. identifier .. "^0")
            
            local success, account = pcall(function()
                return exports['RxBanking']:GetPlayerPersonalAccount(identifier)
            end)
            
            if not success then
                print("^1[Casino] Error calling GetPlayerPersonalAccount: " .. tostring(account) .. "^0")
                return 0
            end
            
            if not account then
                print("^1[Casino] No personal account found for citizen ID: " .. identifier .. "^0")
                return 0
            end
            
            local balance = tonumber(account.balance) or 0
            print("^2[Casino] Retrieved balance: $" .. balance .. " for citizen ID: " .. identifier .. "^0")
            return balance
        end,
        removeMoney = function(source, amount)
            -- Remove money from player's personal account
            local player = QBCore.Functions.GetPlayer(source)
            if not player then 
                print("^1[Casino] No QBCore player found for source: " .. source .. "^0")
                return false 
            end
            
            local identifier = player.PlayerData.citizenid
            print("^3[Casino] Attempting to remove $" .. amount .. " from citizen ID: " .. identifier .. "^0")
            
            local success, account = pcall(function()
                return exports['RxBanking']:GetPlayerPersonalAccount(identifier)
            end)
            
            if not success or not account or not account.iban then
                print("^1[Casino] Failed to get account for money removal: " .. identifier .. "^0")
                return false
            end
            
            print("^3[Casino] Using IBAN: " .. account.iban .. " for removal^0")
            
            -- Remove money from the account using the exact export you provided
            local removeSuccess, result = pcall(function()
                return exports['RxBanking']:RemoveAccountMoney(
                    account.iban, 
                    amount, 
                    'casino', 
                    'Casino withdrawal', 
                    nil -- No target iban for casino
                )
            end)
            
            if removeSuccess and result then
                print("^2[Casino] Successfully removed $" .. amount .. " from " .. identifier .. "^0")
                return true
            else
                print("^1[Casino] Failed to remove money: " .. tostring(result) .. "^0")
                return false
            end
        end,
        addMoney = function(source, amount)
            -- Add money to player's personal account
            local player = QBCore.Functions.GetPlayer(source)
            if not player then 
                print("^1[Casino] No QBCore player found for source: " .. source .. "^0")
                return false 
            end
            
            local identifier = player.PlayerData.citizenid
            print("^3[Casino] Attempting to add $" .. amount .. " to citizen ID: " .. identifier .. "^0")
            
            local success, account = pcall(function()
                return exports['RxBanking']:GetPlayerPersonalAccount(identifier)
            end)
            
            if not success or not account or not account.iban then
                print("^1[Casino] Failed to get account for money addition: " .. identifier .. "^0")
                return false
            end
            
            print("^3[Casino] Using IBAN: " .. account.iban .. " for addition^0")
            
            -- Add money to the account using the exact export you provided
            local addSuccess, result = pcall(function()
                return exports['RxBanking']:AddAccountMoney(
                    account.iban, 
                    amount, 
                    'casino', 
                    'Casino deposit', 
                    nil -- No source iban for casino
                )
            end)
            
            if addSuccess and result then
                print("^2[Casino] Successfully added $" .. amount .. " to " .. identifier .. "^0")
                return true
            else
                print("^1[Casino] Failed to add money: " .. tostring(result) .. "^0")
                return false
            end
        end
    },
    -- Add more banking scripts here as needed
    qb_banking = {
        getBalance = function(source)
            return exports["qb-banking"]:GetAccountBalance(source, "checking")
        end,
        removeMoney = function(source, amount)
            return exports["qb-banking"]:RemoveMoney(source, "checking", amount)
        end,
        addMoney = function(source, amount)
            return exports["qb-banking"]:AddMoney(source, "checking", amount)
        end
    }
}

-- Game Minimum Bets
Config.MinBets = {
    slots = 20,
    plinko = 10,
    mines = 10,
    aviator = 10
}

-- Game Maximum Bets
Config.MaxBets = {
    slots = 10000,
    plinko = 5000,
    mines = 5000,
    aviator = 50000
}

-- RTP (Return to Player) Settings
Config.RTP = {
    slots = {
        cyberpunk = 0.96,
        mafia = 0.95,
        retro = 0.94,
        ocean = 0.97,
        egypt = 0.96
    },
    plinko = 0.98,
    mines = 0.97,
    aviator = 0.97
}

-- Slot Machine Configurations
Config.SlotMachines = {
    cyberpunk = {
        name = "Cyber Rush",
        theme = "cyberpunk",
        symbols = {
            "cyber_skull", "neon_circuit", "cyber_eye", "digital_coin", 
            "hack_symbol", "cyber_heart", "data_stream", "neural_chip"
        },
        payouts = {
            three_of_kind = {
                cyber_skull = 500,
                neon_circuit = 300,
                cyber_eye = 250,
                digital_coin = 200,
                hack_symbol = 150,
                cyber_heart = 100,
                data_stream = 75,
                neural_chip = 50
            },
            jackpot = 10000
        },
        wilds = {"cyber_skull"},
        sounds = {
            spin = "cyber_spin.ogg",
            win = "cyber_win.ogg",
            jackpot = "cyber_jackpot.ogg"
        }
    },
    mafia = {
        name = "Mafia Fortune",
        theme = "mafia",
        symbols = {
            "don_portrait", "tommy_gun", "briefcase_money", "poker_chip",
            "fedora_hat", "vintage_car", "cigar", "dice"
        },
        payouts = {
            three_of_kind = {
                don_portrait = 500,
                tommy_gun = 300,
                briefcase_money = 250,
                poker_chip = 200,
                fedora_hat = 150,
                vintage_car = 100,
                cigar = 75,
                dice = 50
            },
            jackpot = 10000
        },
        wilds = {"don_portrait"},
        sounds = {
            spin = "mafia_spin.ogg",
            win = "mafia_win.ogg",
            jackpot = "mafia_jackpot.ogg"
        }
    },
    retro = {
        name = "Retro Reels",
        theme = "retro",
        symbols = {
            "arcade_coin", "neon_seven", "retro_cherry", "disco_ball",
            "cassette_tape", "rubiks_cube", "pac_ghost", "space_invader"
        },
        payouts = {
            three_of_kind = {
                arcade_coin = 500,
                neon_seven = 300,
                retro_cherry = 250,
                disco_ball = 200,
                cassette_tape = 150,
                rubiks_cube = 100,
                pac_ghost = 75,
                space_invader = 50
            },
            jackpot = 10000
        },
        wilds = {"neon_seven"},
        sounds = {
            spin = "retro_spin.ogg",
            win = "retro_win.ogg",
            jackpot = "retro_jackpot.ogg"
        }
    },
    ocean = {
        name = "Ocean Treasures",
        theme = "ocean",
        symbols = {
            "treasure_chest", "golden_anchor", "pearl_shell", "seahorse",
            "starfish", "coral_reef", "submarine", "ship_wheel"
        },
        payouts = {
            three_of_kind = {
                treasure_chest = 500,
                golden_anchor = 300,
                pearl_shell = 250,
                seahorse = 200,
                starfish = 150,
                coral_reef = 100,
                submarine = 75,
                ship_wheel = 50
            },
            jackpot = 10000
        },
        wilds = {"treasure_chest"},
        sounds = {
            spin = "ocean_spin.ogg",
            win = "ocean_win.ogg",
            jackpot = "ocean_jackpot.ogg"
        }
    },
    egypt = {
        name = "Pharaoh's Gold",
        theme = "egypt",
        symbols = {
            "pharaoh_mask", "golden_scarab", "pyramid", "ankh_symbol",
            "hieroglyph", "sphinx", "mummy", "egyptian_cat"
        },
        payouts = {
            three_of_kind = {
                pharaoh_mask = 500,
                golden_scarab = 300,
                pyramid = 250,
                ankh_symbol = 200,
                hieroglyph = 150,
                sphinx = 100,
                mummy = 75,
                egyptian_cat = 50
            },
            jackpot = 10000
        },
        wilds = {"pharaoh_mask"},
        sounds = {
            spin = "egypt_spin.ogg",
            win = "egypt_win.ogg",
            jackpot = "egypt_jackpot.ogg"
        }
    }
}

-- Plinko Configuration
Config.Plinko = {
    rows = 16,
    -- More balanced multipliers - harder to win big
    multipliers = {100, 26, 9, 4, 2, 1.5, 1, 0.5, 0.2, 0.5, 1, 1.5, 2, 4, 9, 26, 100},
    -- Bet-dependent multiplier scaling
    betScaling = {
        -- Higher bets get lower effective multipliers
        lowBet = 100,    -- Bets under $100 get full multipliers
        midBet = 500,    -- Bets $100-500 get 75% multipliers  
        highBet = 1000,  -- Bets $500-1000 get 50% multipliers
        maxBet = 5000,   -- Bets over $1000 get 25% multipliers
        scalingFactors = {
            low = 1.0,     -- 100% multipliers for small bets
            mid = 0.75,    -- 75% multipliers for medium bets
            high = 0.5,    -- 50% multipliers for high bets
            max = 0.25     -- 25% multipliers for max bets
        }
    },
    physics = {
        gravity = 0.5,
        bounce = 0.3,
        friction = 0.99
    }
}

-- Mines Configuration
Config.Mines = {
    gridSize = 25, -- 5x5 grid
    maxMines = 24,
    multipliers = {
        [1] = 1.1, [2] = 1.3, [3] = 1.6, [4] = 2.0, [5] = 2.5,
        [6] = 3.2, [7] = 4.0, [8] = 5.1, [9] = 6.4, [10] = 8.2,
        [11] = 10.5, [12] = 13.4, [13] = 17.1, [14] = 21.9, [15] = 28.0,
        [16] = 35.8, [17] = 45.8, [18] = 58.6, [19] = 75.0, [20] = 96.0,
        [21] = 122.9, [22] = 157.3, [23] = 201.3, [24] = 257.7
    }
}

-- Aviator Configuration
Config.Aviator = {
    minMultiplier = 1.0,
    maxMultiplier = 100.0,
    crashChance = 0.03, -- 3% chance per 0.1x increase
    updateInterval = 100, -- milliseconds
    autoCashoutMax = 50.0
}

-- Security Settings
Config.Security = {
    maxBetPerMinute = 10,
    maxDepositPerHour = 100000,
    maxWithdrawPerHour = 50000,
    antiSpamCooldown = 1000, -- 1 second between actions
    sessionValidationInterval = 60000, -- 1 minute
    logRetentionDays = 30
}

-- Database Settings
Config.Database = {
    table_users = "casino_users",
    table_transactions = "casino_transactions", 
    table_game_sessions = "casino_game_sessions",
    table_logs = "casino_logs"
}

-- Debug: Confirm config loaded
print("^2[Casino] Config.lua loaded successfully^0")