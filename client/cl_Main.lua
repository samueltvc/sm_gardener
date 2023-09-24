local Keys = {
  ["E"] = 38
}

ESX = exports["es_extended"]:getSharedObject()
local PlayerData = {}
local onDuty = false
local Blips = {}
local OnJob = false
local Done = false

function SelectGarden()
  local index = GetRandomIntInRange(1, #Config.Garden)

  for k, v in pairs(Config.Zones) do
    if v.Pos.x == Config.Garden[index].x and v.Pos.y == Config.Garden[index].y and v.Pos.z == Config.Garden[index].z then
      return k
    end
  end
end

function StartNPCJob()
  NPCTargetGarden = SelectGarden()
  local zone = Config.Zones[NPCTargetGarden]
  Blips['NPCTargetGarden'] = AddBlipForCoord(zone.Pos.x, zone.Pos.y, zone.Pos.z)
  SetBlipRoute(Blips['NPCTargetGarden'], true)
  lib.notify({
    title = Config.Lib.Label,
    description = Config.Lib.StartJob,
    type = 'success'
})
  Done = true
end

function StopNPCJob(cancel, data, data2,data3)
  if Blips['NPCTargetGarden'] ~= nil then
    RemoveBlip(Blips['NPCTargetGarden'])
    Blips['NPCTargetGarden'] = nil
  end

  OnJob = false

  if cancel then
    lib.notify({
      title = Config.Lib.Label,
      description = Config.Lib.StopJob,
      type = 'success'
  })
  else
    local coords 
    print(data)
    lib.callback('sm_brigade:receiveTime')
    StartNPCJob()
    Done = true
  end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  ESX.PlayerData = xPlayer
  onDuty = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  ESX.PlayerData.job = job
  onDuty = false
end)

function openJobMenu()
  lib.registerContext({
    id = 'gardener:open',
    title = Config.Lib.Options,
    onExit = function()
    end,
    options = {
        {
            title = Config.Lib.Start,
            icon = 'fa-solid fa-check',
            onSelect = function(args)              

              lib.progressCircle({
                duration = Config.Lib.Duration,
                label = Config.Lib.Entering,
                position = 'bottom',
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                },
                anim = {
                  dict = 'misscarsteal4@actor',
                  clip = 'actor_berating_loop'
                },
            })

            local playerPed = PlayerPedId()
            ClearPedBloodDamage(playerPed)
            ResetPedVisibleDamage(playerPed)
            ClearPedLastWeaponDamage(playerPed)

            end,
            event = 'sm_brigade:startJob'     
        },

  {
      title = Config.Lib.End,
      icon = 'fa-solid fa-x',
      onSelect = function(args)

        lib.progressCircle({
          duration = Config.Lib.Duration,
          label = Config.Lib.Leaving,
          position = 'bottom',
          useWhileDead = false,
          canCancel = false,
          disable = {
              car = true,
          },
          anim = {
            dict = 'misscarsteal4@actor',
            clip = 'actor_berating_loop'
          },
      })

      end,
      event = 'sm_brigade:stopJob'     
  }
}
})
lib.showContext('gardener:open')
end

AddEventHandler('sm_brigade:startJob', function(data)
  StartNPCJob()
end)

AddEventHandler('sm_brigade:stopJob', function(data)
  StopNPCJob(true)
end)

Citizen.CreateThread(function()
  while true do
    local sleep = 500

    if NPCTargetGarden ~= nil then
      local coords = GetEntityCoords(PlayerPedId())
      local zone = Config.Zones[NPCTargetGarden]
      local playerPed = PlayerPedId()

      if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < 3 then
        sleep = 5
        lib.showTextUI(Config.Lib.Blow)

        if IsControlJustReleased(1, Keys["E"]) and ESX.PlayerData.job ~= nil then
          TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_LEAF_BLOWER", 0, true)
          Wait(17000)
          StopNPCJob(false, zone.Pos.x, zone.Pos.y, zone.Pos.z)
          Wait(3000)
          ClearPedTasksImmediately(playerPed)
          Done = false
          lib.hideTextUI()
        end
      end
    end
    Citizen.Wait(sleep)
  end
end)

local blips = {
  {title = "<FONT FACE='Fire Sans'>Gardener Brigade", colour = 0, id = 85, x = -1148.932, y = -215.603, z = 37.954},
}

function SpawnPed(model, coords, options)
  lib.requestModel(model, 2000)
  local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  if options ~= nil then
      exports.ox_target:addLocalEntity(ped, options)
  end
  return ped
end

SpawnPed(`ig_siemonyetarian`, Config.Ped, {
  {
      icon = 'fa-solid fa-hand',
      label = Config.Lib.Label,
      name = 'gardenerjob',
      onSelect = function()
        openJobMenu()
      end
  }
})

Citizen.CreateThread(function()
  for _, info in pairs(blips) do
    info.blip = AddBlipForCoord(info.x, info.y, info.z)
    SetBlipSprite(info.blip, info.id)
    SetBlipDisplay(info.blip, 4)
    SetBlipScale(info.blip, 0.7)
    SetBlipColour(info.blip, info.colour)
    SetBlipAsShortRange(info.blip, true)
	  BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(info.title)
    EndTextCommandSetBlipName(info.blip)
  end
end)