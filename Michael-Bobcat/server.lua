local cooldown = false 

RegisterServerEvent('MB-BobCatHeist:StartHeist', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)

    local target = vector3(Config.BobCatHeist.StartHeist.x, Config.BobCatHeist.StartHeist.y, Config.BobCatHeist.StartHeist.z)
    local distance = #(playerCoords - target)

    if distance > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'BobCatHeist',
            description = 'You are too far away',
            type = 'error'
        })
        return
    end

    local license = GetPlayerIdentifierByType(src, 'license')
    LogToDiscord(  "BobCatHeist Started", ("Player Name: %s | License: %s has started the BobCat Heist."):format(player.PlayerData.name, license), 3066993)
    TriggerClientEvent('MB-BobCatHeist:client:StartHeist', src)
end)

RegisterNetEvent('MB-BobCatHeist:server:RemoveItem', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    exports.ox_inventory:RemoveItem(src, Config.BobCatHeist.DoorHackItem, 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'BobCatHeist', description = 'You have used 1 Thermite', type = 'success' })
    LogToDiscord("Item Removed",("Player: %s | License: %s | Removed %d × %s"):format(player.PlayerData.name,player.PlayerData.license,1,Config.BobCatHeist.DoorHackItem),3066993)
end)



RegisterServerEvent('MB-BobCatHeist:server:cooldown', function()
    if cooldown then return end
        cooldown = true
        local timer = Config.BobCatHeist.CooldownTime
        
        CreateThread(function()
            while timer > 0 do
                Wait(1000)
                timer = timer - 1000
            end
        cooldown = false
    end)
end)

lib.callback.register('MB-BobCatHeist:CheckCooldown', function(source)
    return cooldown
end)

lib.callback.register('MB-BobCatHeist:CheckPoliceCount', function()
    local policeCount = 0

    for _, playerId in pairs(GetPlayers()) do
        local player = exports.qbx_core:GetPlayer(tonumber(playerId))

        if player and player.PlayerData and player.PlayerData.job then
            for _, PoliceFucks in pairs(Config.BobCatHeist.PoliceJobs) do 
                if player.PlayerData.job.name == PoliceFucks and player.PlayerData.job.onduty then
                    policeCount = policeCount + 1
                    break
                end
            end
        end
    end
    return policeCount
end)


lib.callback.register('MB-BobCatHeist:ItemCheck', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local requireditem = Config.BobCatHeist.RequriedItem
    local itemData = player.Functions.GetItemByName(requireditem)

    if itemData and itemData.amount >= 1 then 
        exports.ox_inventory:RemoveItem(source, requireditem, 1)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'BobCatHeist',
            description = 'You have used the '..requireditem..' to start the heist',
            type = 'success'
        })
        return true
    end
    return false
end)


RegisterNetEvent('MB-BobCatHeist:server:GiveVaultReward', function(rewardType)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local rewardList = Config.BobCatHeist.VaultRewards[rewardType]



    local selectedReward = rewardList[math.random(1, #rewardList)]
    local amount = math.random(selectedReward.min, selectedReward.max)

    exports.ox_inventory:AddItem(src, selectedReward.item, amount)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Vault Reward',
        description = ('You received %d × %s!'):format(amount, selectedReward.item),
        type = 'success'
    })

    LogToDiscord("Vault Reward Claimed", ("Player: %s | License: %s | Looted %d × %s"):format(player.PlayerData.name, GetPlayerIdentifierByType(src, 'license'), amount, selectedReward.item), 3066993)
end)


RegisterNetEvent('MB-BobCatHeist:server:unlockDoor')
AddEventHandler('MB-BobCatHeist:server:unlockDoor', function(doorId, state)
exports.ox_doorlock:setDoorState(doorId, state)
end)

---Lock door event
RegisterNetEvent('MB-BobCatHeist:server:lockDoor')
AddEventHandler('MB-BobCatHeist:server:lockDoor', function(doorId)
    exports.ox_doorlock:setDoorState(doorId, true)
end)

function LogToDiscord(title, message, color)
    local webhook = Config.BobCatHeist.DiscordWebhook
    if not webhook or webhook == "" then return end

    local embed = {
        {
            ["title"] = title or "Log",
            ["description"] = message or "No message provided.",
            ["color"] = color or 16777215, 
            ["footer"] = {
                ["text"] = "BobCatHeist Log",
                ["icon_url"] = "https://r2.fivemanage.com/vX1zD2PhOMSTWwCKjKDXL/as_logo.png" 
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, "POST", json.encode({
        username = "BobCat Heist",
        embeds = embed, 
        avatar_url = "https://r2.fivemanage.com/vX1zD2PhOMSTWwCKjKDXL/as_logo.png" 
    }), {["Content-Type"] = "application/json"})
end

RegisterNetEvent("NERP-Bobcat:server:guarditem") 
AddEventHandler("NERP-Bobcat:server:guarditem", function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local chance = math.random(1, 100)

    if not player then return end

    if chance > Config.BobCatHeist.ItemChance then
        local selected = Config.BobCatHeist.RandomItems[math.random(1, #Config.BobCatHeist.RandomItems)]
        local itemName = selected.item
        local amount = selected.amount

        exports.ox_inventory:AddItem(src, itemName, amount)

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'BobCatHeist',
            description = ('You received %s x%d'):format(itemName, amount),
            type = 'success'
        })

        LogToDiscord("Item Given", ("Player: %s | License: %s | Received %d × %s"):format(player.PlayerData.name, GetPlayerIdentifierByType(src, 'license'), amount, itemName), 3066993)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'BobCatHeist',
            description = 'You did not receive an item this time.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('MB-BobCatHeist:server:CreateFirstDoorTarget', function()
    TriggerClientEvent('MB-BobCatHeist:client:CreateFirstDoorTarget', -1)
end)

RegisterNetEvent('MB-BobCatHeist:server:CreateSecondDoorTarget', function()
    TriggerClientEvent('MB-BobCatHeist:client:CreateSecondDoorTarget', -1)
end)

RegisterNetEvent('MB-BobCatHeist:server:CreateThirdDoorTarget', function()
    TriggerClientEvent('MB-BobCatHeist:client:CreateThirdDoorTarget', -1) 
end)

RegisterNetEvent('MB-BobCatHeist:server:vaultdoortarget', function()
    TriggerClientEvent('MB-BobCatHeist:client:vaultdoortarget', -1) 
end)

RegisterNetEvent('MB-BobCatHeist:server:ammorewardsync', function()
    TriggerClientEvent('MB-BobCatHeist:client:createAmmunationRewardTarget', -1) 
end)

RegisterNetEvent('MB-BobCatHeist:server:ammudoor1', function()
    TriggerClientEvent('MB-BobCatHeist:client:CreateAmmunationDoorTarget', -1) 
end)

RegisterNetEvent('MB-BobCatHeist:server:ammudoor2', function()
    TriggerClientEvent('MB-BobCatHeist:client:CreateAmmunationDoorTarget2', -1) 
end)

RegisterNetEvent('MB-BobCatHeist:server:synvaultdoor', function()
    TriggerClientEvent('MB-BobCatHeist:client:syncvaultdoor', -1)
end)


lib.addCommand('ResetBobcat', {
    help = 'Reset the Bobcat Heist (LSPD Only)',
    restricted = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        return player?.job?.name == 'lspd'
    end
}, function(source, args, raw)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    TriggerEvent('MB-BobCatHeist:server:resetheist', source)

    lib.notify(source, {
        title = 'LSPD Command',
        description = 'You have reset the Bobcat heist.',
        type = 'success'
    })
end)


RegisterNetEvent('MB-BobCatHeist:server:resetheist', function(data)
    local mlo = Config.BobCatHeist.MLO
    for k, v in pairs(Config.BobCatHeist.Locations[mlo].Doors) do
        exports.ox_doorlock:setDoorState(v, true)
    end
    if mlo == "Gabz" then
        TriggerClientEvent('MB-BobCatHeist:client:CloseVaultDoor', -1)
    end
end)