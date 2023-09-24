ESX = exports["es_extended"]:getSharedObject()

lib.callback.register('sm_brigade:receiveTime', function()
	local _source = source
	local Inventory = exports.ox_inventory:Inventory()
	local amount = Config.Items.ItemCount
	local item = Config.Items.ItemName
	print ("payed" ..amount)
	Inventory.AddItem(_source, item, amount)
end)
