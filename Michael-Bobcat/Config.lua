Config = {}

Config.BobCatHeist = {
    MLO = "AS", -- Options: "AS", "", etc.
    DiscordWebhook = 'https://discord.com/api/webhooks/1378499141478518895/oERE4alQvhYFsby5Josv3qBUfa1PbwYdo3DXCUzNbqrmz-AD26TFz17oDIeS1j_vVWbN',
    drawZones = true,
    Notify = 'ox', -- Options: okok, qb, ox
    PDAlerts = 'ps', -- Options: ps, cd, ox
    PedModel = 'a_f_m_prolhost_01',
    GuardModel = 's_m_m_marine_01', -- Guard model for the heist
    StartHeist = vector3(768.91, -1407.21, 26.52),
    CooldownTime = 0,
    PoliceCount = 0,
    PoliceJobs = {'police','sheriff','statepolice','fbi','lspd','bcso'},
    DoorHackItem = 'thermite',
   
    ItemChance = 0.5,
    RandomItems = {
        { item = 'diamond', amount = math.random(1,3) },
        { item = 'ruby', amount = math.random(1,3) },
        { item = 'black_money', amount = math.random(1000,3000)}
    },
    Locations = {
        ["AS"] = {
            Doors = {
                FirstMainDoors = 2890, -- Set to the correct door IDs for your MLO
                SecondMainDoors = 2886,
                ThirdMainDoors = 2087,
                VaultDoor = 0,
            },
            GuardSpawnLocations = {
                vector4(735.07, -1393.18, 27.11, 343.99),
                vector4(735.28, -1388.23, 27.11, 267.61),
                vector4(727.89, -1402.45, 27.11, 286.91),
                vector4(719.57, -1401.95, 27.11, 285.08)
            },
            VaultDoor = {
                coords = vec3(726.85, -1399.0, 27.45),
                radius = 0.35,
                label = "Hack Vault Door"
            },
            FirstDoor = {
                coords = vec3(776.55, -1399.6, 26.8),
                radius = 0.25,
                label = "Blow the first door"
            },
            SecondDoor = {
                coords = vec3(752.75, -1387.1, 27.25),
                radius = 0.25,
                label = "Blow the second door"
            },
            ThirdDoor = {
                coords = vec3(748.9, -1388.35, 27.2),
                radius = 0.25,
                label = "Blow the third door"
            },
            vaultLocations = {
            [1] = { coords = vec3(729.25, -1395.2, 27.1), radius = 0.3, label = "Cash Trolley", rewardType = "cash" },
            [2] = { coords = vec3(728.85, -1389.2, 27.1), radius = 0.3, label = "Cash Trolley", rewardType = "cash" },
            [3] = { coords = vec3(723.9, -1394.75, 26.8), radius = 0.3, label = "Ammo Crate", rewardType = "miscellaneous" },
            [4] = { coords = vec3(723.95, -1393.6, 26.7), radius = 0.3, label = "Ammo Crate", rewardType = "miscellaneous" },
            [5] = { coords = vec3(724.95, -1392.7, 26.75), radius = 0.3, label = "Ammo Crate", rewardType = "miscellaneous" },
            [6] = { coords = vec3(725.35, -1391.35, 26.75), radius = 0.3, label = "Ammo Crate", rewardType = "miscellaneous" },
        },

       --[[[""] = {
            Doors = {
                FirstMainDoors = 2890, -- Set to the correct door IDs for your MLO
                SecondMainDoors = 2886,
                ThirdMainDoors = 2087,
                VaultDoor = 0,
            },
            FirstDoor = {
                coords = vec3(0.0, 0.0, 0.0),
                radius = 0.25,
                label = "Blow the first door"
            },
            SecondDoor = {
                coords = vec3(0.0, 0.0, 0.0),
                radius = 0.25,
                label = "Blow the second door"
            },
            ThirdDoor = {
                coords = vec3(0.0, 0.0, 0.0),
                radius = 0.25,
                label = "Blow the third door"
            },
            GuardSpawnLocations = {
                vector4(0.0, 0.0, 0.0, 0.0), -- Replace with actual coords
                vector4(0.0, 0.0, 0.0, 0.0),
                vector4(0.0, 0.0, 0.0, 0.0),
                vector4(0.0, 0.0, 0.0, 0.0)
            },
            VaultDoor = {
                coords = vec3(0.0, 0.0, 0.0), -- Replace with actual coords
                radius = 0.35,
                label = "Hack Vault Door"
            },
            vaultLocations = {
                [1] = { coords = vec3(0.0, 0.0, 0.0), radius = 2.0, label = "Cash Trolley", rewardType = "cash" },
                [2] = { coords = vec3(0.0, 0.0, 0.0), radius = 2.0, label = "Ammo Crate", rewardType = "miscellaneous" },
                [3] = { coords = vec3(0.0, 0.0, 0.0), radius = 2.0, label = "Cash Trolley", rewardType = "cash" },
                [4] = { coords = vec3(0.0, 0.0, 0.0), radius = 2.0, label = "Ammo Crate", rewardType = "miscellaneous" },
            },]]
        }
    },

    VaultRewards = {
        cash = {
            { item = 'black_money', min = 1000, max = 5000 }
        },
        miscellaneous = {
            { item = 'ammo-rifle2-box', min = 1, max = 3 },
            { item = 'ammo-50-box', min = 1, max = 2 },
            { item = 'ammo-shotgun-box', min = 2, max = 5 }
        }
    },
}

function PoliceAlert()
    if Config.BobCatHeist.PDAlerts == "ps" then 
        exports['ps-dispatch']:SuspiciousActivity()
    elseif Config.BobCatHeist.PDAlerts == "cd" then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'lspd', 'bcso', 'lsco', 'sasp', 'comm'},
            coords = data.coords,
            title = 'BobCat Robbery',
            message = 'A '..data.sex..' started a bomb at '..data.street,
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 480, 
                scale = 0.8, 
                colour = 0,
                flashes = true, 
                text = '911 - Suspicious Person',
                time = 5,
                radius = 0,
            }
        })
    else 
        print("Please change your Config.BobCat.PDAlerts to match one of the dispatch scripts.")
    end
end
