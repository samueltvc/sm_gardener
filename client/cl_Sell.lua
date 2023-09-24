ESX = exports["es_extended"]:getSharedObject()

addCommas = function(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,")
								  :gsub(",(%-?)$","%1"):reverse()
end

CreateBlip = function(coords, sprite, colour, text, scale)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
end

AddEventHandler('sm_brigade:sellItem', function(data)
    local data = data
    local input = lib.inputDialog('How Much?', {'Quantity'})
    if input then
        data.quantity = math.floor(tonumber(input[1]))
        if data.quantity < 1 then
            lib.notify({
                title = Config.Lib.Title,
                description = 'Please enter a valid amount!',
                type = 'error'
            })
        else
            local done = lib.callback.await('sm_brigade:sellItem', 100, data)
            if not done then
                lib.notify({
                    title = Config.Lib.Title,
                    description = 'You missed the items you wanted for sale!',
                    type = 'error'
                })
            else
                lib.notify({
                    title = 'Success',
                    description = 'You sold your items and made money from them $'..addCommas(done),
                    type = 'success'
                })
            end
        end
    else
        lib.notify({
            title = Config.Lib.Title,
            description = 'Please enter a valid amount!',
            type = 'error'
        })
    end
end)

AddEventHandler('sm_brigade:interact', function(data)
    local storeData = data.store
    local items = storeData.items
    local Options = {}
    for i=1, #items do
        table.insert(Options, {
            title = items[i].label,
            description = 'Price: $'..items[i].price,
            event = 'sm_brigade:sellItem',
            args = { item = items[i].item, price = items[i].price, currency = items[i].currency }
        })
    end
    lib.registerContext({
        id = 'storeInteract',
        title = storeData.label,
        options = Options
    })
    lib.showContext('storeInteract')
end)

-- Blips/Targets
CreateThread(function()
    for i=1, #Config.SellShops do
        exports.qtarget:AddBoxZone(i.."_sell_shop", Config.SellShops[i].coords, 1.0, 1.0, {
            name=i.."_sell_shop",
            heading=Config.SellShops[i].blip.heading,
            debugPoly=false,
            minZ=Config.SellShops[i].coords.z-1.5,
            maxZ=Config.SellShops[i].coords.z+1.5
        }, {
            options = {
                {
                    event = 'sm_brigade:interact',
                    icon = 'fas fa-hand-paper',
                    label = 'Shop',
                    store = Config.SellShops[i]
                }
            },
            --job = 'all',
            distance = 1.5
        })
        if Config.SellShops[i].blip.enabled then
            CreateBlip(Config.SellShops[i].coords, Config.SellShops[i].blip.sprite, Config.SellShops[i].blip.color, Config.SellShops[i].label, Config.SellShops[i].blip.scale)
        end
    end
end)

-- Ped spawn thread
local pedSpawned = {}
local pedPool = {}
CreateThread(function()
	while true do
		local sleep = 1500
        local playerPed = cache.ped
        local pos = GetEntityCoords(playerPed)
		for i=1, #Config.SellShops do
			local dist = #(pos - Config.SellShops[i].coords)
			if dist <= 20 and not pedSpawned[i] then
				pedSpawned[i] = true
                lib.requestModel(Config.SellShops[i].ped, 100)
                lib.requestAnimDict('mini@strip_club@idles@bouncer@base', 100)
				pedPool[i] = CreatePed(28, Config.SellShops[i].ped, Config.SellShops[i].coords.x, Config.SellShops[i].coords.y, Config.SellShops[i].coords.z, Config.SellShops[i].heading, false, false)
				FreezeEntityPosition(pedPool[i], true)
				SetEntityInvincible(pedPool[i], true)
				SetBlockingOfNonTemporaryEvents(pedPool[i], true)
				TaskPlayAnim(pedPool[i], 'mini@strip_club@idles@bouncer@base','base', 8.0, 0.0, -1, 1, 0, 0, 0, 0)
			elseif dist >= 21 and pedSpawned[i] then
				local model = GetEntityModel(pedPool[i])
				SetModelAsNoLongerNeeded(model)
				DeletePed(pedPool[i])
				SetPedAsNoLongerNeeded(pedPool[i])
                pedPool[i] = nil
				pedSpawned[i] = false
			end
		end
		Wait(sleep)
	end
end)
