
local spawnedEntities = {}
local lootedGuards = {}
local lootedVaults = {}
local mlo = Config.BobCatHeist.MLO
local vaultDoor = Config.BobCatHeist.Locations[mlo].VaultDoor
local GuardSpawnLocations = Config.BobCatHeist.Locations[mlo].GuardSpawnLocations
local doorIds = Config.BobCatHeist.Locations[mlo].Doors

AddEventHandler('onResourceStop', function(resourceName)
     if resourceName == GetCurrentResourceName() then
          for _, entity in ipairs(spawnedEntities) do
               if DoesEntityExist(entity) then
                    DeleteEntity(entity)
               end
          end
          spawnedEntities = {}
     end
end)
 
local function waitFor(cond)
     while not cond() do Wait(0) end
 end
local function loadAnimDict(dict)
     if not dict then return end
     RequestAnimDict(dict)
     waitFor(function() return HasAnimDictLoaded(dict) end)
 end
 
 local function removeAnimDict(dict)
     if dict and HasAnimDictLoaded(dict) then
         RemoveAnimDict(dict)
     end
 end
 
 local function loadModel(model)
     if not model then return nil end
     local hash = type(model) == "string" and GetHashKey(model) or model
     if not HasModelLoaded(hash) then
         RequestModel(hash)
         waitFor(function() return HasModelLoaded(hash) end)
     end
     return hash
 end
 
 local function releaseModel(model)
     if not model then return end
     local hash = type(model) == "string" and GetHashKey(model) or model
     if DoesEntityExist(hash) then
         SetModelAsNoLongerNeeded(hash)
     end
 end
 

local function createSyncedBagScene(ped, pos, heading)
    local dict = "anim@heists@ornate_bank@thermal_charge"
    loadAnimDict(dict)
    local bagModel = loadModel("hei_p_m_bag_var22_arm_s")
    local bag = CreateObject(bagModel, pos.x, pos.y, pos.z, true, true, false)
    SetEntityCollision(bag, false, true)
    local scene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, heading, 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, scene, dict, "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, scene, dict, "bag_thermal_charge", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(scene)
    return bag, bagModel, dict
end

local function createThermiteObjectAt(pos)
    local thermiteModel = loadModel("hei_prop_heist_thermite")
    local thermite = CreateObject(thermiteModel, pos.x, pos.y, pos.z, true, true, true)
    FreezeEntityPosition(thermite, true)
    SetEntityCollision(thermite, false, true)
    return thermite, thermiteModel
end

CreateThread(function()
     local model = Config.BobCatHeist.PedModel
     RequestModel(model)
     while not HasModelLoaded(model) do
         Wait(100)
     end

     StartPed = CreatePed(5, Config.BobCatHeist.PedModel, Config.BobCatHeist.StartHeist.x, Config.BobCatHeist.StartHeist.y, Config.BobCatHeist.StartHeist.z - 1.0, 0.0, true, true)
     TaskStartScenarioInPlace(StartPed, 'WOLD_HUMAN_STAND_MOBILE', 0, true)
     FreezeEntityPosition(StartPed, true)
     SetEntityInvincible(StartPed, true)
     SetBlockingOfNonTemporaryEvents(StartPed, true)
     
     exports.ox_target:addLocalEntity(StartPed, {
          {
               name = 'BobCatHeist',
               label = 'Talk to Gregory',
               icon = 'fa-solid fa-user',
               onSelect = function()
                    local policeCount = lib.callback.await('MB-BobCatHeist:CheckPoliceCount', false)
                    if policeCount < Config.BobCatHeist.PoliceCount then
                         lib.notify({title = 'BobCatHeist', description = 'Not enough police on duty', type = 'error'})
                         return
                    end
                    TriggerServerEvent('MB-BobCatHeist:StartHeist')
                end
          }
     })
end)

RegisterNetEvent('MB-BobCatHeist:client:StartHeist', function()
     local isCooldown = lib.callback.await('MB-BobCatHeist:CheckCooldown', false)
     if isCooldown then 
          lib.notify({title = 'BobCatHeist', description = 'Heist is on cooldown', type = 'error'})
          return
     end

     lib.progressBar({
          duration = 5000,
          label = 'Starting Heist',
          useWhileDead = false,
          canCancel = false,
          disable = {
               car = true,
               move = true,
               combat = true,
               mouse = true,
               aim = true
          },
          anim = {
               dict = 'amb@prop_human_atm@male@idle_a',
               clip = 'idle_a'
          }
     })

     Wait(5000)
     lib.notify({title = 'BobCatHeist', description = 'Heist started! Get ready!', type = 'success'})
     TriggerServerEvent('MB-BobCatHeist:server:CreateFirstDoorTarget')
     TriggerServerEvent('MB-BobCatHeist:server:StartCooldown')
     SetNewWaypoint(Config.BobCatHeist.StartHeist.x, Config.BobCatHeist.StartHeist.y)
end)

function CreateFirstDoorTarget()
     local door = Config.BobCatHeist.Locations[mlo].FirstDoor
     exports.ox_target:addSphereZone({
          name = 'BobCatHeistDoor1',
          coords = door.coords,
          radius = door.radius,
          debug = Config.BobCatHeist.drawZones,
          options = {
               {
                    name = 'BobCatHeist',
                    label = 'Blow the door',
                    icon = 'fa-solid fa-user',
                    onSelect = function()
                         TriggerEvent('MB-BobCatHeist:client:ElectricBox')
                    end
               }
          }
     })
end
 
RegisterNetEvent('MB-BobCatHeist:client:ElectricBox', function()
     local playerPed = PlayerPedId()

     local hasItem = exports.ox_inventory:Search('count', Config.BobCatHeist.DoorHackItem) >= 1
 
     if not hasItem then 
         lib.notify({title = 'BobCatHeist', description = 'You don\'t have the required item!', type = 'error'})
         return 
     end
 
     local door = Config.BobCatHeist.Locations[mlo].FirstDoor
     local doorCords = vector3(door.coords.x, door.coords.y, door.coords.z)
     local heading = GetEntityHeading(playerPed)
 
     TaskGoStraightToCoord(playerPed, doorCords.x, doorCords.y, doorCords.z, 1.0, 8000, heading, 0.0)
     while #(GetEntityCoords(playerPed) - doorCords) > 1.0 do Wait(100) end
     ClearPedTasksImmediately(playerPed)
 
     local bag, bagModel, dict = createSyncedBagScene(playerPed, doorCords, heading)
     Wait(1500)
     local thermite, thermiteModel = createThermiteObjectAt(doorCords)
 
     exports["memorygame"]:thermiteminigame(10, 3, 3, 10, function() -- Success
         lib.notify({title = 'BobCatHeist', description = 'You successfully hacked the system!', type = 'success'})
 
         RequestNamedPtfxAsset("scr_ornate_heist")
         while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(0) end
         UseParticleFxAssetNextCall("scr_ornate_heist")
         local fxHandle = StartParticleFxLoopedOnEntity("scr_heist_ornate_thermal_burn", thermite, 0.0, 0.95, -0.2, 0.0, 0.0, 0.0, 1.0, false, false, false)
         Wait(5000)
         StopParticleFxLooped(fxHandle, 0)
         PoliceAlert()
         exports.ox_target:removeZone('BobCatHeistDoor1')
         TriggerServerEvent('MB-BobCatHeist:server:CreateSecondDoorTarget')
         TriggerServerEvent('MB-BobCatHeist:server:RemoveItem')
         TriggerServerEvent('MB-BobCatHeist:server:unlockDoor',Config.BobCatHeist.Locations[mlo].Doors.FirstMainDoors,false)
         DeleteEntity(thermite)
         DeleteEntity(bag)
         releaseModel(bagModel)
         releaseModel(thermiteModel)
         removeAnimDict(dict)
     end, function()
         lib.notify({title = 'BobCatHeist', description = 'You failed the hack!', type = 'error'})
         DeleteEntity(thermite)
         DeleteEntity(bag)
         releaseModel(bagModel)
         releaseModel(thermiteModel)
         removeAnimDict(dict)
     end)
 end)
 

function CreateSecondDoorTarget()
     local door = Config.BobCatHeist.Locations[mlo].SecondDoor
     exports.ox_target:addSphereZone({
          name = 'BobCatHeist2',
          coords = door.coords,
          radius = door.radius,
          debug = Config.BobCatHeist.drawZones,
          options = {
               {
                    name = 'BobCatHeist2',
                    label = door.label,
                    icon = 'fa-solid fa-bomb',
                    onSelect = function()
                         SecondDoor()
                    end
               }
          }
     })
end

function SecondDoor()
     local playerPed = PlayerPedId()
     local coords = GetEntityCoords(playerPed)
     local hasItem = exports.ox_inventory:Search('count', Config.BobCatHeist.DoorHackItem) >= 1
 
     if not hasItem then 
          lib.notify({title = 'BobCatHeist', description = 'You don\'t have the required item!', type = 'error'})
          return 
     end

     local door = Config.BobCatHeist.Locations[mlo].SecondDoor
     local doorCords = vector3(door.coords.x, door.coords.y, door.coords.z) 
     local heading = GetEntityHeading(playerPed)

     TaskGoStraightToCoord(playerPed, doorCords.x, doorCords.y, doorCords.z, 1.0, 8000, heading, 0.0)
     while #(GetEntityCoords(playerPed) - doorCords) > 2.0 do
         Wait(100)
     end
     ClearPedTasksImmediately(playerPed)
 
     
     local bag, bagModel, dict = createSyncedBagScene(playerPed, doorCords, heading)
     Wait(1500)
     local thermite, thermiteModel = createThermiteObjectAt(doorCords)
     exports["memorygame"]:thermiteminigame(10, 3, 3, 10, function()
          lib.notify({title = 'BobCatHeist',description = 'You have successfully hacked the system!',type = 'success'})
          
          RequestNamedPtfxAsset("scr_ornate_heist")
          while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(0) end
          UseParticleFxAssetNextCall("scr_ornate_heist")
          local fxHandle = StartParticleFxLoopedOnEntity("scr_heist_ornate_thermal_burn", thermite, 0.0, 0.95, -0.2, 0.0, 0.0, 0.0, 1.0, false, false, false)
          Wait(5000)
          StopParticleFxLooped(fxHandle, 0)
          TriggerServerEvent('MB-BobCatHeist:server:unlockDoor',Config.BobCatHeist.Locations[mlo].Doors.SecondMainDoors,false)
          TriggerServerEvent('MB-BobCatHeist:server:CreateThirdDoorTarget')
          exports.ox_target:removeZone('BobCatHeist2')
          TriggerServerEvent('MB-BobCatHeist:server:RemoveItem')
          RemoveAnimDict("anim@heists@ornate_bank@thermal_charge")
          DeleteEntity(thermite)
          DeleteEntity(bag)
          releaseModel(bagModel)
          releaseModel(thermiteModel)
          removeAnimDict(dict)

     end,function()
          lib.notify({title = 'BobCatHeist',description = 'You have failed to hack the system!',type = 'error'})
          RemoveAnimDict("anim@heists@ornate_bank@thermal_charge")
          DeleteEntity(thermite)
          DeleteEntity(bag)
          releaseModel(bagModel)
          releaseModel(thermiteModel)
          removeAnimDict(dict)
     end)
end

function CreateThirdDoorTarget()
     local door = Config.BobCatHeist.Locations[mlo].ThirdDoor
     exports.ox_target:addSphereZone({
          name = 'BobCatHeist3',
          coords = door.coords,
          radius = door.radius,
          debug = Config.BobCatHeist.drawZones,
          options = {
               {
                    name = 'BobCatHeist3',
                    label = door.label,
                    icon = 'fa-solid fa-bomb',
                    onSelect = function()
                         ThirdDoor()
                    end
               }
          }
     })
end
function ThirdDoor()
     local playerPed = PlayerPedId()
     local coords = GetEntityCoords(playerPed)
     local hasItem = exports.ox_inventory:Search('count', Config.BobCatHeist.DoorHackItem) >= 1
 
     if not hasItem then 
          lib.notify({title = 'BobCatHeist', description = 'You don\'t have the required item!', type = 'error'})
          return 
     end

     local door = Config.BobCatHeist.Locations[mlo].ThirdDoor
     local doorCords = vector3(door.coords.x, door.coords.y, door.coords.z)
     local heading = GetEntityHeading(playerPed)

     TaskGoStraightToCoord(playerPed, doorCords.x, doorCords.y, doorCords.z, 1.0, 8000, heading, 0.0)
     while #(GetEntityCoords(playerPed) - doorCords) > 1.0 do
         Wait(100)
     end
     ClearPedTasksImmediately(playerPed)
 
     
     local bag, bagModel, dict = createSyncedBagScene(playerPed, doorCords, heading)
     Wait(1500)
     local thermite, thermiteModel = createThermiteObjectAt(doorCords)
     exports["memorygame"]:thermiteminigame(10, 3, 3, 10, function()
          lib.notify({title = 'BobCatHeist',description = 'You have successfully hacked the system!',type = 'success'})
          RequestNamedPtfxAsset("scr_ornate_heist")
          while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(0) end
          UseParticleFxAssetNextCall("scr_ornate_heist")
          local fxHandle = StartParticleFxLoopedOnEntity("scr_heist_ornate_thermal_burn", thermite, 0.0, 0.95, -0.2, 0.0, 0.0, 0.0, 1.0, false, false, false)
          SpawnGuards()
          Wait(5000)
          StopParticleFxLooped(fxHandle, 0)
          TriggerServerEvent('MB-BobCatHeist:server:unlockDoor', doorIds.ThirdMainDoors, false)
          DeleteEntity(thermite)
          DeleteEntity(bag)
          releaseModel(bagModel)
          releaseModel(thermiteModel)
          removeAnimDict(dict)
          TriggerServerEvent('MB-BobCatHeist:server:vaultdoortarget')
          exports.ox_target:removeZone('BobCatHeist3')
          TriggerServerEvent('MB-BobCatHeist:server:RemoveItem')
     end, function()
          lib.notify({title = 'BobCatHeist',description = 'You have failed to hack the system!',type = 'error'})
          DeleteEntity(thermite)
          DeleteEntity(bag)
          releaseModel(bagModel)
          releaseModel(thermiteModel)
          removeAnimDict(dict)
     end)
end

CreateVaultDoorTarget = function()
     exports.ox_target:addSphereZone({
          name = 'BobCatVaultDoor',
          coords = vaultDoor.coords,
          radius = vaultDoor.radius,
          debug = Config.BobCatHeist.drawZones,
          options = {
               {
                    name = 'BobCatVaultDoor',
                    label = vaultDoor.label,
                    icon = 'fa-solid fa-user-secret',
                    onSelect = function()
                         SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                         VaultDoor()
                    end
               }
          }
     })
end

function VaultDoor()
     local playerPed = PlayerPedId()
     local coords = GetEntityCoords(playerPed)
     local hasItem = exports.ox_inventory:Search('count', Config.BobCatHeist.DoorHackItem) >= 1
 
     if not hasItem then 
          lib.notify({title = 'BobCatHeist', description = 'You don\'t have the required item!', type = 'error'})
          return 
     end

     local door = Config.BobCatHeist.Locations[mlo].VaultDoor
     local doorCords = vector3(door.coords.x, door.coords.y, door.coords.z)
     local heading = GetEntityHeading(playerPed)
     TaskGoStraightToCoord(playerPed, doorCords.x, doorCords.y, doorCords.z, 1.0, 4000, heading, 0.0)
     while #(GetEntityCoords(playerPed) - doorCords) > 2.0 do
         Wait(100)
     end
     ClearPedTasksImmediately(playerPed)
 
     RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
     while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") do Wait(5) end

         local bagModel = GetHashKey("hei_p_m_bag_var22_arm_s")
 
         local bag = CreateObject(bagModel, coords.x, coords.y, coords.z, true, true, false)
         SetEntityCollision(bag, false, true)
         local bagScene = NetworkCreateSynchronisedScene(doorCords.x, doorCords.y, doorCords.z, 0.0, 0.0, heading, 2, false, false, 1065353216, 0, 1.3)
         NetworkAddPedToSynchronisedScene(playerPed, bagScene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
         NetworkAddEntityToSynchronisedScene(bag, bagScene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
         NetworkStartSynchronisedScene(bagScene)
         Citizen.Wait(2000)
         exports["memorygame"]:thermiteminigame(10,3,3,10, function()
          lib.notify({title = 'BobCatHeist', description = 'The door is about to explode!', type = 'success'})
          Wait(15000)
          local vaultCoords = vector3(doorCords.x, doorCords.y, doorCords.z) 
          AddExplosion(vaultCoords.x, vaultCoords.y, vaultCoords.z, 2, 4.0, true, false, 1.0)
          TriggerServerEvent('MB-BobCatHeist:server:unlockDoor', doorIds.VaultDoor, false)
          RemoveAnimDict("anim@heists@ornate_bank@thermal_charge")
          SetModelAsNoLongerNeeded(bagModel)
          DeleteEntity(bag)
          VaultRewardTargets()
          exports.ox_target:removeZone('BobCatVaultDoor')
          TriggerServerEvent('MB-BobCatHeist:server:RemoveItem')
         end,
         function()
          lib.notify({title = 'BobCatHeist', description = 'You have failed to hack the system!', type = 'error'})
          RemoveAnimDict("anim@heists@ornate_bank@thermal_charge")
          SetModelAsNoLongerNeeded(bagModel)
          DeleteEntity(bag)
     end)
 end
 
 VaultRewardTargets = function()
     for k, v in pairs(Config.BobCatHeist.Locations[mlo].vaultLocations) do
         local zoneName = 'BobCatVaultReward' .. k
 
         exports.ox_target:addSphereZone({
             name = zoneName,
             coords = v.coords,
             radius = v.radius,
             debug = Config.BobCatHeist.drawZones,
             options = {
                 {
                     name = zoneName,
                     label = 'Collect ' .. v.label,
                     icon = 'fa-solid fa-money-bill',
                     onSelect = function()
                         if lootedVaults[k] then
                             lib.notify({
                                 title = 'BobCat Heist',
                                 description = 'Already looted!',
                                 type = 'error'
                             })
                             exports.ox_target:removeZone(zoneName)
                             return
                         end
 
                         lib.progressBar({
                             duration = 5000,
                             label = 'Collecting Loot',
                             useWhileDead = false,
                             canCancel = false,
                             disable = {
                                 car = true,
                                 move = true,
                                 combat = true,
                                 mouse = true,
                                 aim = true
                             },
                             anim = {
                                 dict = 'anim@heists@ornate_bank@grab_cash',
                                 clip = 'grab'
                             }
                         })

                         TriggerServerEvent('MB-BobCatHeist:server:GiveVaultReward', v.rewardType)

 
                         lootedVaults[k] = true
                         exports.ox_target:removeZone(zoneName)
                     end
                 }
             }
         })
     end
 end
 


function AddTargetToGuard(guard)
     exports.ox_target:addLocalEntity(guard, {
         {
             name = 'search_dead_guard',
             label = 'Search Body',
             icon = 'fa-solid fa-shield-halved',
             canInteract = function(_, distance, coords, entity)
                 return not lootedGuards[entity]
             end,
             onSelect = function(data)
                 local entity = data.entity
                 local src = NetworkGetEntityOwner(entity)
                 if not src or lootedGuards[entity] then return end
 
                 lootedGuards[entity] = true
                 TriggerServerEvent('NERP-Bobcat:server:guarditem')
             end
         }
     })
 end

function SpawnGuards()
     local guardModel = Config.BobCatHeist.GuardModel
     local guardRelationship = 'BOBCAT_GUARDS'

     AddRelationshipGroup(guardRelationship)

     local modelHash = GetHashKey(guardModel)
     RequestModel(modelHash)
     while not HasModelLoaded(modelHash) do
          Wait(10)
     end

     for i, spawnCoords in ipairs(GuardSpawnLocations) do
          if spawnCoords then
          local guardPed = CreatePed(5, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, spawnCoords.w or 0.0, false, true)

          GiveWeaponToPed(guardPed, GetHashKey('WEAPON_PISTOL'), 100, false, true)

          SetPedFleeAttributes(guardPed, 0, false)
          SetPedCombatMovement(guardPed, 2)
          SetPedCombatAbility(guardPed, 100)
          SetPedCombatRange(guardPed, 3)
          SetPedAlertness(guardPed, 3)
          SetPedSeeingRange(guardPed, 100.0)
          SetPedHearingRange(guardPed, 200.0)

          SetPedAsEnemy(guardPed, true)
          SetPedRelationshipGroupHash(guardPed, GetHashKey(guardRelationship))

          local playerPed = PlayerPedId()
          TaskCombatPed(guardPed, playerPed, 0, 16)

          CreateThread(function()
               while DoesEntityExist(guardPed) and not IsEntityDead(guardPed) do
                    if not IsPedInCombat(guardPed, playerPed) then
                        TaskCombatPed(guardPed, playerPed, 0, 16)
                    end
                    Wait(1000)
                  end
               end)

               SetEntityAsMissionEntity(guardPed, true, false)
               table.insert(spawnedEntities, guardPed)


               CreateThread(function()
                    while DoesEntityExist(guardPed) and not IsEntityDead(guardPed) do
                         Wait(100)
                    end
                    if DoesEntityExist(guardPed) then
                         AddTargetToGuard(guardPed)
                    end
               end)
          else
               print(string.format("Spawn location %d is missing or invalid!", i))
          end
     end
     SetModelAsNoLongerNeeded(modelHash)
end
 


RegisterNetEvent('MB-BobCatHeist:client:CreateFirstDoorTarget', function()
     CreateFirstDoorTarget()
end)
RegisterNetEvent('MB-BobCatHeist:client:CreateSecondDoorTarget', function()
     CreateSecondDoorTarget()
end)
RegisterNetEvent('MB-BobCatHeist:client:CreateThirdDoorTarget', function()
     CreateThirdDoorTarget()
end)
RegisterNetEvent('MB-BobCatHeist:client:vaultdoortarget', function()
     CreateVaultDoorTarget()
end)
RegisterNetEvent('MB-BobCatHeist:client:CreateVaultRewardTarget', function()
     VaultRewardTargets()
end)
