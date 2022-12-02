ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function sendToDiscord(msg)
    PerformHttpRequest(ConfigSV.Webhook, function(a,b,c)end, "POST", json.encode({embeds={{title=ConfigSV.WebhookName,description=msg:gsub("%^%d",""),color=15844367,}}}), {["Content-Type"]="application/json"})
end

-- Make sure all Vehicles are Stored on restart
MySQL.ready(function()
	if Config.Main.ParkVehicles then
		ParkVehicles()
	else
		if Config.Debug then
		print('esx_advancedgarage: Parking Vehicles on restart is currently set to false.')
		end
	end
end)

function ParkVehicles()
	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE `stored` = @stored', {
		['@stored'] = false
	}, function(rowsChanged)
		if rowsChanged > 0 then
			if Config.Debug then
			print(('esx_advancedgarage: %s vehicle(s) have been stored!'):format(rowsChanged))
			end
		end
	end)
end

-- Add Command for Getting Properties
if Config.Main.Commands then
	ESX.RegisterCommand('getgarages', 'user', function(xPlayer, args, showError)
		xPlayer.triggerEvent('esx_advancedgarage:getPropertiesC')
	end, true, {help = 'Get Private Garages', validate = false})
end

-- Add Print Command for Getting Properties
RegisterServerEvent('esx_advancedgarage:printGetProperties')
AddEventHandler('esx_advancedgarage:printGetProperties', function()
	if Config.Debug then
	print('Getting Properties')
	end
end)

-- Get Owned Properties
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedProperties', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local properties = {}

	MySQL.Async.fetchAll('SELECT * FROM owned_properties WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function(data)
		for _,v in pairs(data) do
			table.insert(properties, v.name)
		end
		cb(properties)
	end)
end)

-- Start of Ambulance Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedAmbulanceCars', function(source, cb)
	local ownedAmbulanceCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'ambulance'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAmbulanceCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAmbulanceCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'ambulance',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAmbulanceCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAmbulanceCars)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOwnedAmbulanceAircrafts', function(source, cb)
	local ownedAmbulanceAircrafts = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.AdvVehShop then
		if Config.Main.ShowVehLoc then
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'aircraft',
				['@job'] = 'ambulance'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedAmbulanceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'aircraft'})
				end
				cb(ownedAmbulanceAircrafts)
			end)
		else
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'aircraft',
				['@job'] = 'ambulance',
				['@stored'] = true
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedAmbulanceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'aircraft'})
				end
				cb(ownedAmbulanceAircrafts)
			end)
		end
	else
		if Config.Main.ShowVehLoc then
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'helicopter',
				['@job'] = 'ambulance'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedAmbulanceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'helicopter'})
				end
				cb(ownedAmbulanceAircrafts)
			end)
		else
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'helicopter',
				['@job'] = 'ambulance',
				['@stored'] = true
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedAmbulanceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'helicopter'})
				end
				cb(ownedAmbulanceAircrafts)
			end)
		end
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedAmbulanceCars', function(source, cb)
	local ownedAmbulanceCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND job = @job AND `stored` = @stored', {
		['@owner'] = xPlayer.identifier,
		['@job'] = 'ambulance',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedAmbulanceCars, vehicle)
		end
		cb(ownedAmbulanceCars)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyAmbulance', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Ambulance.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payAmbulance')
AddEventHandler('esx_advancedgarage:payAmbulance', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Ambulance.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Ambulance.PoundP)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Ambulance.PoundP)
		end)
	end
end)
-- End of Ambulance Code

-- Start of Police Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedPoliceCars', function(source, cb)
	local ownedPoliceCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'police'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedPoliceCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedPoliceCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'police',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedPoliceCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedPoliceCars)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOwnedPoliceAircrafts', function(source, cb)
	local ownedPoliceAircrafts = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.AdvVehShop then
		if Config.Main.ShowVehLoc then
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'aircraft',
				['@job'] = 'police'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedPoliceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'aircraft'})
				end
				cb(ownedPoliceAircrafts)
			end)
		else
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'aircraft',
				['@job'] = 'police',
				['@stored'] = true
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedPoliceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'aircraft'})
				end
				cb(ownedPoliceAircrafts)
			end)
		end
	else
		if Config.Main.ShowVehLoc then
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'helicopter',
				['@job'] = 'police'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedPoliceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'helicopter'})
				end
				cb(ownedPoliceAircrafts)
			end)
		else
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'helicopter',
				['@job'] = 'police',
				['@stored'] = true
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(ownedPoliceAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate, vtype = 'helicopter'})
				end
				cb(ownedPoliceAircrafts)
			end)
		end
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedPoliceCars', function(source, cb)
	local ownedPoliceCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND job = @job AND `stored` = @stored', {
		['@owner'] = xPlayer.identifier,
		['@job'] = 'police',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedPoliceCars, vehicle)
		end
		cb(ownedPoliceCars)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyPolice', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Police.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payPolice')
AddEventHandler('esx_advancedgarage:payPolice', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Police.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Police.PoundP)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Police.PoundP)
		end)
	end
end)
-- End of Police Code

-- Start of Mechanic Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedMechanicCars', function(source, cb)
	local ownedMechanicCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'mechanic'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedMechanicCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedMechanicCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'mechanic',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedMechanicCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedMechanicCars)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedMechanicCars', function(source, cb)
	local ownedMechanicCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND job = @job AND `stored` = @stored', {
		['@owner'] = xPlayer.identifier,
		['@job'] = 'mechanic',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedMechanicCars, vehicle)
		end
		cb(ownedMechanicCars)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyMechanic', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Mechanic.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payMechanic')
AddEventHandler('esx_advancedgarage:payMechanic', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Mechanic.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Mechanic.PoundP)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Mechanic.PoundP)
		end)
	end
end)
-- End of Mechanic Code

-- Start of Aircraft Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedAircrafts', function(source, cb)
	local ownedAircrafts = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'aircraft',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAircrafts)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'aircraft',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAircrafts)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOwnedAircraftsSociety', function(source, cb)
	local ownedAircrafts = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'aircraft',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAircrafts)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'aircraft',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedAircrafts, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedAircrafts)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedAircrafts', function(source, cb)
	local ownedAircrafts = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
		['@owner'] = xPlayer.identifier,
		['@Type'] = 'aircraft',
		['@job'] = 'civ',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedAircrafts, vehicle)
		end
		cb(ownedAircrafts)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyAircrafts', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Aircrafts.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payAircraft')
AddEventHandler('esx_advancedgarage:payAircraft', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Aircrafts.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Aircrafts.PoundP)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Aircrafts.PoundP)
		end)
	end
end)
-- End of Aircraft Code

-- Start of Boat Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedBoats', function(source, cb)
	local ownedBoats = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'boat',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedBoats, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedBoats)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'boat',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedBoats, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedBoats)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOwnedBoatsSociety', function(source, cb)
	local ownedBoats = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'boat',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedBoats, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedBoats)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'boat',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedBoats, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedBoats)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedBoats', function(source, cb)
	local ownedBoats = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
		['@owner'] = xPlayer.identifier,
		['@Type'] = 'boat',
		['@job'] = 'civ',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedBoats, vehicle)
		end
		cb(ownedBoats)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedBoatsSociety', function(source, cb)
	local ownedBoats = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
		['@owner'] = xPlayer.job.name,
		['@Type'] = 'boat',
		['@job'] = 'civ',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedBoats, vehicle)
		end
		cb(ownedBoats)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyBoats', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Boats.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payBoat')
AddEventHandler('esx_advancedgarage:payBoat', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Boats.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Boats.PoundP)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Boats.PoundP)
		end)
	end
end)
-- End of Boat Code

-- Start of Car Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedCars', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'car',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

-- Start of Society Car Code
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedCarsSociety', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.Main.ShowVehLoc then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'car',
			['@job'] = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
			['@owner'] = xPlayer.job.name,
			['@Type'] = 'car',
			['@job'] = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedCars', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
		['@owner'] = xPlayer.identifier,
		['@Type'] = 'car',
		['@job'] = 'civ',
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedCars, vehicle)
		end
		cb(ownedCars)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedCarsSociety', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @Type AND job = @job AND `stored` = @stored', { -- job = NULL
		['@owner'] = xPlayer.job.name,
		['@Type'] = 'car',
		['@job'] = 'civ',
		['@stored'] = 0
	}, function(data) 
		if Config.Debug then
		print(ESX.DumpTable(data))
		end
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedCars, vehicle)
		end
		cb(ownedCars)
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:checkMoneyCars', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= Config.Cars.PoundP then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_advancedgarage:payCar')
AddEventHandler('esx_advancedgarage:payCar', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.Cars.PoundP)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Cars.PoundP)
--	sendToDiscord('Player:\nJust do 1')
	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(Config.Cars.PoundP)
		--	sendToDiscord('Player:\nJust do 2')
		end)
	end
end)
-- End of Car Code

-- Store Vehicles
ESX.RegisterServerCallback('esx_advancedgarage:storeVehicle', function (source, cb, vehicleProps)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match("^%s*(.-)%s*$")
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT vehicle FROM owned_vehicles WHERE (owner = @owner OR owner = @jobOwned) AND @plate = plate', {
		['@owner'] = xPlayer.identifier,
		['@jobOwned'] = xPlayer.job.name,
		['@plate'] = vehicleProps.plate
	}, function (result)
		if result[1] ~= nil then
			local originalvehprops = json.decode(result[1].vehicle)
			if originalvehprops.model == vehiclemodel then
				MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE (owner = @owner OR owner = @jobOwned) AND plate = @plate', {
					['@owner'] = xPlayer.identifier,
					['@jobOwned'] = xPlayer.job.name,
					['@vehicle'] = json.encode(vehicleProps),
					['@plate'] = vehicleProps.plate
				}, function (rowsChanged)
					if rowsChanged == 0 then
						if Config.Debug then
						print(('esx_advancedgarage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
						end
					end
					cb(true)
				end)
				sendToDiscord('\n__**Stored vehicle**__\n\n**Player:** *'..GetPlayerName(source)..'*\n**Plate:** *'..vehplate..'*\n\n\n__Time: '..os.date('%H:%M - %d. %m. %Y', os.time())..'__') 
			else
				if Config.Main.KickCheaters then
					if Config.Main.CustomKickMsg then
						if Config.Debug then
						print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
						end
						DropPlayer(source, _U('custom_kick'))
						sendToDiscord('\n__**Stored vehicle**__\n\n**Player:** *'..GetPlayerName(source)..'*\n**Been kicked for:** *'.._U('custom_kick')..'*\n\n\n__Time: '..os.date('%H:%M - %d. %m. %Y', os.time())..'__') 
						cb(false)
					else
						if Config.Debug then
						print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
						end
						DropPlayer(source, 'You have been Kicked from the Server for Possible Garage Cheating!!!')
						sendToDiscord('\n__**Stored vehicle**__\n\n**Player:** *'..GetPlayerName(source)..'*\n**Been kicked for:** *You have been Kicked from the Server for Possible Garage Cheating!!!*\n\n\n__Time: '..os.date('%H:%M - %d. %m. %Y', os.time())..'__') 
						cb(false)
					end
				else
					if Config.Debug then
					print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
					end
					cb(false)
				end
			end
		else
			if Config.Debug then
			print(('esx_advancedgarage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
			end
			cb(false)
		end
	end)
end)

-- Pay to Return Broken Vehicles
RegisterServerEvent('esx_advancedgarage:payhealth')
AddEventHandler('esx_advancedgarage:payhealth', function(price)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(price)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. price)
	sendToDiscord('\n__**Pay for broken veh**__\n\n**Player:** *'..GetPlayerName(source)..'*\n**Price:** *'..price..'*\n\n\n__Time: '..os.date('%H:%M - %d. %m. %Y', os.time())..'__') 
	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(price)
		end)
		sendToDiscord('\n__**Pay for broken veh**__\n\n**Player:** *'..GetPlayerName(source)..'*\n**Price:** *'..price..'*\n\n\n__Time: '..os.date('%H:%M - %d. %m. %Y', os.time())..'__') 
	end
end)

-- Modify State of Vehicles
RegisterServerEvent('esx_advancedgarage:setVehicleState')
AddEventHandler('esx_advancedgarage:setVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			if Config.Debug then
			print(('esx_advancedgarage: %s exploited the garage!'):format(xPlayer.identifier))
			end
		end
	end)
end)

ESX.RegisterServerCallback('esx_advancedgarage:requestPlayerCars', function(source, cb, plate)

	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll(
		'SELECT plate FROM owned_vehicles WHERE owner = @identifier',
		{
			['@identifier'] = xPlayer.identifier
		},
		function(result)

			local found = false

			for i=1, #result, 1 do

				local resultPlate = result[i].plate

				if trim(resultPlate) == trim(plate) then
					found = true
					break
				end

			end

			if found then
				cb(true)
			else
				cb(false)
			end

		end
	)
end)

RegisterServerEvent('esx_advancedgarage:setvehicleWonerSociety')
AddEventHandler('esx_advancedgarage:setvehicleWonerSociety', function (vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET owner=@owner WHERE plate=@plate',
	{
		['@owner']   = xPlayer.job.name,
		['@plate']   = vehicleProps.plate
	},

	function (rowsChanged)

	end)
end)

function trim(plate)
    if s ~= nil then
		return s:match("^%s*(.-)%s*$")
	else
		return nil
    end
end

ESX.RegisterServerCallback('esx_advancedgarage:requestSocietyCars', function(source, cb, plate)

	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll(
		'SELECT plate FROM owned_vehicles WHERE owner = @identifier',
		{
			['@identifier'] = xPlayer.job.name
		},
		function(result)

			local found = false

			for i=1, #result, 1 do

				local resultPlate = result[i].plate

				if trim(resultPlate) == trim(plate) then
					found = true
					break
				end

			end

			if found then
				cb(true)
			else
				cb(false)
			end

		end
	)
end)

RegisterServerEvent('esx_advancedgarage:setVehiclePersonalyOwned')
AddEventHandler('esx_advancedgarage:setVehiclePersonalyOwned', function (vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if xPlayer.job.grade_name == "boss" then


		MySQL.Async.execute('UPDATE owned_vehicles SET owner=@owner WHERE plate=@plate',
		{
			['@owner']   = xPlayer.identifier,
			['@plate']   = vehicleProps.plate
		},

		function (rowsChanged)

		end)

	else
		if Config.Debug then
			print('!!! THIS IS SECURITY WARNING !!!')
			print('[esx_advancedgarage] Player %s tried executing blacklisted setVehiclePersonalyOwned event in the esx_advancedgarage and his identifier = %s', GetPlayerName(_source), xPlayer.identifier)
		end
		-- TriggerEvent('nlrp:ac:ban', source, 'You tried to trigger blocke event!\nIf you think, this was misstake, contact us on discord!')
	end

end)