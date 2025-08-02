-- Advanced Garage System - Admin Commands

-- Register garage admin command
lib.addCommand(Config.Staff.commands.garage, {
    help = 'Garage management command',
    params = {
        {
            name = 'action',
            type = 'string',
            help = 'Action to perform (create, delete, list, give, remove, plate, return)'
        },
        {
            name = 'target',
            type = 'string',
            help = 'Target (garage name, player id, plate, etc.)',
            optional = true
        },
        {
            name = 'value',
            type = 'string',
            help = 'Additional value for the action',
            optional = true
        },
        {
            name = 'extra',
            type = 'string',
            help = 'Extra parameter',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local action = args.action:lower()
    
    if action == 'create' then
        -- Create garage at player position
        if not args.target then
            Utils.Notify(source, 'Usage: /garage create <name> [type] [job/gang]', 'error')
            return
        end
        
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        local garageData = {
            name = args.target,
            label = args.target:gsub('_', ' '):gsub('^%l', string.upper),
            type = args.value or 'public',
            job = args.extra,
            gang = args.extra,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            spawn_coords = { x = coords.x + 5.0, y = coords.y, z = coords.z },
            heading = heading,
            vehicle_types = {'car'},
            max_vehicles = 10,
            blip = {
                sprite = 357,
                color = 3,
                scale = 0.7
            },
            marker = {
                type = 36,
                color = { r = 0, g = 100, b = 255 },
                scale = { x = 2.0, y = 2.0, z = 1.0 }
            }
        }
        
        TriggerEvent('garage:server:admin:createGarage', garageData)
        
    elseif action == 'delete' then
        -- Delete garage
        if not args.target then
            Utils.Notify(source, 'Usage: /garage delete <name>', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:deleteGarage', args.target)
        
    elseif action == 'list' then
        -- List all garages
        local garages = MySQL.query.await('SELECT name, label, type, job, gang FROM garages ORDER BY name')
        if garages and #garages > 0 then
            Utils.Notify(source, 'Garage List:', 'info')
            for _, garage in pairs(garages) do
                local info = ('%s (%s)'):format(garage.label, garage.name)
                if garage.type ~= 'public' then
                    info = info .. (' - %s'):format(garage.type)
                    if garage.job then
                        info = info .. (' [%s]'):format(garage.job)
                    elseif garage.gang then
                        info = info .. (' [%s]'):format(garage.gang)
                    end
                end
                Utils.Notify(source, info, 'info')
            end
        else
            Utils.Notify(source, 'No garages found', 'error')
        end
        
    elseif action == 'give' then
        -- Give vehicle to player
        if not args.target or not args.value then
            Utils.Notify(source, 'Usage: /garage give <player_id> <vehicle_model> [garage]', 'error')
            return
        end
        
        local targetId = tonumber(args.target)
        local targetPlayer = GetPlayerName(targetId)
        
        if not targetPlayer then
            Utils.Notify(source, 'Player not found', 'error')
            return
        end
        
        local identifier = Utils.GetIdentifier(targetId)
        if not identifier then
            Utils.Notify(source, 'Could not get player identifier', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:giveVehicle', identifier, args.value, args.extra)
        
    elseif action == 'remove' then
        -- Remove vehicle by plate
        if not args.target then
            Utils.Notify(source, 'Usage: /garage remove <plate>', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:removeVehicle', args.target)
        
    elseif action == 'plate' then
        -- Change vehicle plate
        if not args.target or not args.value then
            Utils.Notify(source, 'Usage: /garage plate <old_plate> <new_plate>', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:changeVehiclePlate', args.target, args.value)
        
    elseif action == 'return' then
        -- Return vehicle to garage
        if not args.target then
            Utils.Notify(source, 'Usage: /garage return <plate> [garage]', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:returnVehicle', args.target, args.value)
        
    else
        Utils.Notify(source, 'Available actions: create, delete, list, give, remove, plate, return', 'info')
    end
end)

-- Register impound admin command
lib.addCommand(Config.Staff.commands.impound, {
    help = 'Impound management command',
    params = {
        {
            name = 'action',
            type = 'string',
            help = 'Action to perform (create, vehicle, release, list)'
        },
        {
            name = 'target',
            type = 'string',
            help = 'Target (impound name, plate, etc.)',
            optional = true
        },
        {
            name = 'value',
            type = 'string',
            help = 'Additional value',
            optional = true
        },
        {
            name = 'extra',
            type = 'string',
            help = 'Extra parameter',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local action = args.action:lower()
    
    if action == 'create' then
        -- Create impound at player position
        if not args.target then
            Utils.Notify(source, 'Usage: /impound create <name> [type] [job]', 'error')
            return
        end
        
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        local impoundData = {
            name = args.target,
            label = args.target:gsub('_', ' '):gsub('^%l', string.upper),
            type = args.value or 'public',
            job = args.extra,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            spawn_coords = { x = coords.x + 5.0, y = coords.y, z = coords.z },
            heading = heading,
            retrieval_fee = Config.Impound.defaultFee,
            release_time = Config.Impound.defaultReleaseTime,
            blip = {
                sprite = 68,
                color = 1,
                scale = 0.7
            },
            marker = {
                type = 36,
                color = { r = 255, g = 0, b = 0 },
                scale = { x = 2.0, y = 2.0, z = 1.0 }
            }
        }
        
        TriggerEvent('garage:server:admin:createImpound', impoundData)
        
    elseif action == 'vehicle' then
        -- Impound a vehicle
        if not args.target or not args.value then
            Utils.Notify(source, 'Usage: /impound vehicle <plate> <impound_name> [reason]', 'error')
            return
        end
        
        local reason = args.extra or 'Impounded by administrator'
        TriggerEvent('garage:server:impoundVehicle', args.target, args.value, reason, 0, 0, true)
        
    elseif action == 'release' then
        -- Release vehicle from impound
        if not args.target then
            Utils.Notify(source, 'Usage: /impound release <plate>', 'error')
            return
        end
        
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        TriggerEvent('garage:server:releaseVehicle', args.target, coords, heading, true)
        
    elseif action == 'list' then
        -- List impounded vehicles
        local vehicles = MySQL.query.await([[
            SELECT iv.plate, iv.reason, iv.impounded_at, pv.vehicle, pv.owner, i.label as impound_label
            FROM impounded_vehicles iv
            JOIN player_vehicles pv ON iv.plate = pv.plate
            JOIN impounds i ON iv.impound = i.name
            WHERE iv.retrieved = 0
            ORDER BY iv.impounded_at DESC
        ]])
        
        if vehicles and #vehicles > 0 then
            Utils.Notify(source, 'Impounded Vehicles:', 'info')
            for i, vehicle in pairs(vehicles) do
                if i <= 10 then -- Limit to 10 results
                    local info = ('%s (%s) - %s - %s'):format(
                        vehicle.plate, 
                        vehicle.vehicle, 
                        vehicle.impound_label,
                        vehicle.reason
                    )
                    Utils.Notify(source, info, 'info')
                end
            end
            if #vehicles > 10 then
                Utils.Notify(source, ('... and %d more'):format(#vehicles - 10), 'info')
            end
        else
            Utils.Notify(source, 'No impounded vehicles found', 'error')
        end
        
    else
        Utils.Notify(source, 'Available actions: create, vehicle, release, list', 'info')
    end
end)

-- Register vehicle admin command
lib.addCommand(Config.Staff.commands.vehicle, {
    help = 'Vehicle management command',
    params = {
        {
            name = 'action',
            type = 'string',
            help = 'Action to perform (info, owner, transfer, delete, fix)'
        },
        {
            name = 'target',
            type = 'string',
            help = 'Target (plate or player id)',
            optional = true
        },
        {
            name = 'value',
            type = 'string',
            help = 'Additional value',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local action = args.action:lower()
    
    if action == 'info' then
        -- Get vehicle info
        if not args.target then
            Utils.Notify(source, 'Usage: /veh info <plate>', 'error')
            return
        end
        
        local vehicle = MySQL.single.await([[
            SELECT pv.*, COALESCE(iv.impound, 'Not Impounded') as impound_status
            FROM player_vehicles pv
            LEFT JOIN impounded_vehicles iv ON pv.plate = iv.plate AND iv.retrieved = 0
            WHERE pv.plate = ?
        ]], { args.target })
        
        if vehicle then
            Utils.Notify(source, ('Vehicle Info for %s:'):format(args.target), 'info')
            Utils.Notify(source, ('Model: %s'):format(vehicle.vehicle), 'info')
            Utils.Notify(source, ('Owner: %s'):format(vehicle.owner), 'info')
            Utils.Notify(source, ('State: %s'):format(vehicle.state), 'info')
            Utils.Notify(source, ('Garage: %s'):format(vehicle.garage or 'None'), 'info')
            Utils.Notify(source, ('Fuel: %d%%'):format(vehicle.fuel), 'info')
            Utils.Notify(source, ('Engine: %.1f'):format(vehicle.engine), 'info')
            Utils.Notify(source, ('Body: %.1f'):format(vehicle.body), 'info')
            if vehicle.nickname then
                Utils.Notify(source, ('Nickname: %s'):format(vehicle.nickname), 'info')
            end
            Utils.Notify(source, ('Impound: %s'):format(vehicle.impound_status), 'info')
        else
            Utils.Notify(source, 'Vehicle not found', 'error')
        end
        
    elseif action == 'owner' then
        -- Get vehicles owned by player
        if not args.target then
            Utils.Notify(source, 'Usage: /veh owner <player_id>', 'error')
            return
        end
        
        local targetId = tonumber(args.target)
        local targetPlayer = GetPlayerName(targetId)
        
        if not targetPlayer then
            Utils.Notify(source, 'Player not found', 'error')
            return
        end
        
        local identifier = Utils.GetIdentifier(targetId)
        if not identifier then
            Utils.Notify(source, 'Could not get player identifier', 'error')
            return
        end
        
        local vehicles = MySQL.query.await('SELECT plate, vehicle, state, garage FROM player_vehicles WHERE owner = ? ORDER BY plate', { identifier })
        
        if vehicles and #vehicles > 0 then
            Utils.Notify(source, ('Vehicles owned by %s:'):format(targetPlayer), 'info')
            for i, vehicle in pairs(vehicles) do
                if i <= 10 then -- Limit to 10 results
                    local info = ('%s (%s) - %s'):format(vehicle.plate, vehicle.vehicle, vehicle.state)
                    if vehicle.garage then
                        info = info .. (' @ %s'):format(vehicle.garage)
                    end
                    Utils.Notify(source, info, 'info')
                end
            end
            if #vehicles > 10 then
                Utils.Notify(source, ('... and %d more'):format(#vehicles - 10), 'info')
            end
        else
            Utils.Notify(source, 'Player has no vehicles', 'error')
        end
        
    elseif action == 'transfer' then
        -- Transfer vehicle ownership
        if not args.target or not args.value then
            Utils.Notify(source, 'Usage: /veh transfer <plate> <new_owner_id>', 'error')
            return
        end
        
        local targetId = tonumber(args.value)
        local targetPlayer = GetPlayerName(targetId)
        
        if not targetPlayer then
            Utils.Notify(source, 'New owner not found', 'error')
            return
        end
        
        local newOwner = Utils.GetIdentifier(targetId)
        if not newOwner then
            Utils.Notify(source, 'Could not get new owner identifier', 'error')
            return
        end
        
        local success = MySQL.update.await('UPDATE player_vehicles SET owner = ? WHERE plate = ?', { newOwner, args.target })
        
        if success then
            Utils.Notify(source, ('Vehicle %s transferred to %s'):format(args.target, targetPlayer), 'success')
            Utils.Notify(targetId, ('You have been given ownership of vehicle %s'):format(args.target), 'success')
        else
            Utils.Notify(source, 'Failed to transfer vehicle', 'error')
        end
        
    elseif action == 'delete' then
        -- Delete vehicle
        if not args.target then
            Utils.Notify(source, 'Usage: /veh delete <plate>', 'error')
            return
        end
        
        TriggerEvent('garage:server:admin:removeVehicle', args.target)
        
    elseif action == 'fix' then
        -- Fix vehicle health
        if not args.target then
            Utils.Notify(source, 'Usage: /veh fix <plate>', 'error')
            return
        end
        
        local success = MySQL.update.await('UPDATE player_vehicles SET engine = 1000.0, body = 1000.0, fuel = 100 WHERE plate = ?', { args.target })
        
        if success then
            Utils.Notify(source, ('Vehicle %s has been repaired'):format(args.target), 'success')
        else
            Utils.Notify(source, 'Failed to repair vehicle or vehicle not found', 'error')
        end
        
    else
        Utils.Notify(source, 'Available actions: info, owner, transfer, delete, fix', 'info')
    end
end)

-- Register admin panel command
lib.addCommand('garageadmin', {
    help = 'Open garage admin panel',
    restricted = 'group.admin'
}, function(source, args)
    TriggerClientEvent('garage:client:openAdminPanel', source)
end)

-- Register garage creation command for current position
lib.addCommand('creategarage', {
    help = 'Create garage at current position',
    params = {
        {
            name = 'name',
            type = 'string',
            help = 'Garage name'
        },
        {
            name = 'label',
            type = 'string',
            help = 'Garage display name',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local garageData = {
        name = args.name,
        label = args.label or args.name:gsub('_', ' '):gsub('^%l', string.upper),
        type = 'public',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        spawn_coords = { x = coords.x + 5.0, y = coords.y, z = coords.z },
        heading = heading,
        vehicle_types = {'car'},
        max_vehicles = 10,
        blip = {
            sprite = 357,
            color = 3,
            scale = 0.7
        },
        marker = {
            type = 36,
            color = { r = 0, g = 100, b = 255 },
            scale = { x = 2.0, y = 2.0, z = 1.0 }
        }
    }
    
    TriggerEvent('garage:server:admin:createGarage', garageData)
end)

-- Register spawner creation command
lib.addCommand('createspawner', {
    help = 'Create vehicle spawner at current position',
    params = {
        {
            name = 'name',
            type = 'string',
            help = 'Spawner name'
        },
        {
            name = 'type',
            type = 'string',
            help = 'Spawner type (job, gang, donator)'
        },
        {
            name = 'target',
            type = 'string',
            help = 'Job or gang name',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local spawnerData = {
        name = args.name,
        label = args.name:gsub('_', ' '):gsub('^%l', string.upper),
        type = args.type,
        job = args.type == 'job' and args.target or nil,
        gang = args.type == 'gang' and args.target or nil,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        spawn_coords = { x = coords.x + 5.0, y = coords.y, z = coords.z },
        heading = heading,
        vehicles = Config.DefaultVehicles[args.target] or {},
        vehicle_types = {'car'},
        blip = {
            sprite = 326,
            color = 2,
            scale = 0.7
        },
        marker = {
            type = 36,
            color = { r = 0, g = 255, b = 0 },
            scale = { x = 2.0, y = 2.0, z = 1.0 }
        }
    }
    
    TriggerEvent('garage:server:admin:createSpawner', spawnerData)
end)