local CurrentActionData, PlayerData, userProperties, this_Garage, vehInstance, BlipList, PrivateBlips, JobBlips = {}, {}, {}, {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, WasInPound, WasinJPound = false, false, false
local LastZone, CurrentAction, CurrentActionMsg
ESX = nil


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end


	if Config.Debug then
		if Config.DrawHelp == 'ESX' then
			print('Using ESX notify as drawing style')
		elseif Config.DrawHelp == '3DText' then
			print('Using 3D Text as drawing style')
		elseif Config.DrawHelp == 'IM' then
			print('Drawing interaction menu as help')
		end
	end


	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	while not GetResourceState('esx_menu_default') == 'started' do
		Citizen.Wait(200)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	CreateBlips()
	RefreshJobBlips()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	if Config.Pvt.Garages then
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedProperties', function(properties)
			userProperties = properties
			DeletePrivateBlips()
			RefreshPrivateBlips()
		end)
	end

	ESX.PlayerData = xPlayer

	RefreshJobBlips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job

	DeleteJobBlips()
	RefreshJobBlips()
end)

RegisterNetEvent('esx_advancedgarage:getPropertiesC')
AddEventHandler('esx_advancedgarage:getPropertiesC', function(xPlayer)
	if Config.Pvt.Garages then
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedProperties', function(properties)
			userProperties = properties
			DeletePrivateBlips()
			RefreshPrivateBlips()
		end)

		ESX.ShowNotification(_U('get_properties'))
		TriggerServerEvent('esx_advancedgarage:printGetProperties')
	end
end)

local function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

-- Start of Ambulance Code
function ListOwnedAmbulanceMenu()
	local elements = {}

	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - <span style="color:red;">%s</span> |'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:red;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	ESX.TriggerServerCallback('esx_advancedgarage:getOwnedAmbulanceCars', function(ownedAmbulanceCars)
		if #ownedAmbulanceCars == 0 then
			ESX.ShowNotification(_U('garage_no_ambulance'))
		else
			for _,v in pairs(ownedAmbulanceCars) do
				local hashVehicule = v.vehicle.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
				local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

				if Config.Main.ShowVehLoc then
					if v.stored then
						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
					else
						labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
					end
				else
					if v.stored then
						labelvehicle = labelvehicle3
					else
						labelvehicle = labelvehicle3
					end
				end

				table.insert(elements, {label = labelvehicle, value = v})
			end
		end

		table.insert(elements, {label = _U('spacer2'), value = nil})

		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedAmbulanceAircrafts', function(ownedAmbulanceAircrafts)
			if #ownedAmbulanceAircrafts == 0 then
				ESX.ShowNotification(_U('garage_no_ambulance_aircraft'))
			else
				for _,v in pairs(ownedAmbulanceAircrafts) do
					local hashVehicule = v.vehicle.model
					local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
					local vehicleName = GetLabelText(aheadVehName)
					local plate = v.plate
					local labelvehicle
					local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
					local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

					if Config.Main.ShowVehLoc then
						if v.stored then
							labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
						else
							labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
						end
					else
						if v.stored then
							labelvehicle = labelvehicle3
						else
							labelvehicle = labelvehicle3
						end
					end

					table.insert(elements, {label = labelvehicle, value = v})
				end
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_ambulance', {
				title = _U('garage_ambulance'),
				align = Config.Main.MenuAlign,
				elements = elements
			}, function(data, menu)
				if data.current.value == nil then
				elseif data.current.value.vtype == 'aircraft' or data.current.value.vtype == 'helicopter' then
					if data.current.value.stored then
						menu.close()
						SpawnVehicle2(data.current.value.vehicle, data.current.value.plate)
					else
						ESX.ShowNotification(_U('ambulance_is_impounded'))
					end
				else
					if data.current.value.stored then
						menu.close()
						SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
					else
						ESX.ShowNotification(_U('ambulance_is_impounded'))
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end)
	end)
end

function StoreOwnedAmbulanceMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Ambulance.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Ambulance.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedAmbulanceMenu()
	if WasinJPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.JPoundWait))
	else
		ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedAmbulanceCars', function(ownedAmbulanceCars)
			local elements = {}

			if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
				local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
				table.insert(elements, {label = spacer, value = nil})
			end

			for _,v in pairs(ownedAmbulanceCars) do
				local hashVehicule = v.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

				labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

				table.insert(elements, {label = labelvehicle, value = v})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_ambulance', {
				title = _U('pound_ambulance', ESX.Math.GroupDigits(Config.Ambulance.PoundP)),
				align = Config.Main.MenuAlign,
				elements = elements
			}, function(data, menu)
				local doesVehicleExist = false

				for k,v in pairs (vehInstance) do
					if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
						if DoesEntityExist(v.vehicleentity) then
							doesVehicleExist = true
						else
							table.remove(vehInstance, k)
							doesVehicleExist = false
						end
					end
				end

				if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
					ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyAmbulance', function(hasEnoughMoney)
						if hasEnoughMoney then
							if data.current.value == nil then
							else
								SpawnVehicle(data.current.value, data.current.value.plate)
								TriggerServerEvent('esx_advancedgarage:payAmbulance')
								if Config.Main.JPoundTimer then
									WasinJPound = true
								end
							end
						else
							ESX.ShowNotification(_U('not_enough_money'))
						end
					end)
				else
					ESX.ShowNotification(_U('cant_take_out'))
				end
			end, function(data, menu)
				menu.close()
			end)
		end)
	end
end
-- End of Ambulance Code

-- Start of Police Code
function ListOwnedPoliceMenu()
	local elements = {}

	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - <span style="color:red;">%s</span> |'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:red;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	ESX.TriggerServerCallback('esx_advancedgarage:getOwnedPoliceCars', function(ownedPoliceCars)
		if #ownedPoliceCars == 0 then
			ESX.ShowNotification(_U('garage_no_police'))
		else
			for _,v in pairs(ownedPoliceCars) do
				local hashVehicule = v.vehicle.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
				local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

				if Config.Main.ShowVehLoc then
					if v.stored then
						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
					else
						labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
					end
				else
					if v.stored then
						labelvehicle = labelvehicle3
					else
						labelvehicle = labelvehicle3
					end
				end

				table.insert(elements, {label = labelvehicle, value = v})
			end
		end

		table.insert(elements, {label = _U('spacer2'), value = nil})

		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedPoliceAircrafts', function(ownedPoliceAircrafts)
			if #ownedPoliceAircrafts == 0 then
				ESX.ShowNotification(_U('garage_no_police_aircraft'))
			else
				for _,v in pairs(ownedPoliceAircrafts) do
					local hashVehicule = v.vehicle.model
					local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
					local vehicleName = GetLabelText(aheadVehName)
					local plate = v.plate
					local labelvehicle
					local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
					local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

					if Config.Main.ShowVehLoc then
						if v.stored then
							labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
						else
							labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
						end
					else
						if v.stored then
							labelvehicle = labelvehicle3
						else
							labelvehicle = labelvehicle3
						end
					end

					table.insert(elements, {label = labelvehicle, value = v})
				end
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_police', {
				title = _U('garage_police'),
				align = Config.Main.MenuAlign,
				elements = elements
			}, function(data, menu)
				if data.current.value == nil then
				elseif data.current.value.vtype == 'aircraft' or data.current.value.vtype == 'helicopter' then
					if data.current.value.stored then
						menu.close()
						SpawnVehicle2(data.current.value.vehicle, data.current.value.plate)
					else
						ESX.ShowNotification(_U('police_is_impounded'))
					end
				else
					if data.current.value.stored then
						menu.close()
						SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
					else
						ESX.ShowNotification(_U('police_is_impounded'))
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end)
	end)
end

function StoreOwnedPoliceMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Police.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Police.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedPoliceMenu()
	if WasinJPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.JPoundWait))
	else
		ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedPoliceCars', function(ownedPoliceCars)
			local elements = {}

			if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
				local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
				table.insert(elements, {label = spacer, value = nil})
			end

			for _,v in pairs(ownedPoliceCars) do
				local hashVehicule = v.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

				labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

				table.insert(elements, {label = labelvehicle, value = v})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_police', {
				title = _U('pound_police', ESX.Math.GroupDigits(Config.Police.PoundP)),
				align = Config.Main.MenuAlign,
				elements = elements
			}, function(data, menu)
				local doesVehicleExist = false

				for k,v in pairs (vehInstance) do
					if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
						if DoesEntityExist(v.vehicleentity) then
							doesVehicleExist = true
						else
							table.remove(vehInstance, k)
							doesVehicleExist = false
						end
					end
				end

				if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
					ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyPolice', function(hasEnoughMoney)
						if hasEnoughMoney then
							if data.current.value == nil then
							else
								SpawnVehicle(data.current.value, data.current.value.plate)
								TriggerServerEvent('esx_advancedgarage:payPolice')
								if Config.Main.JPoundTimer then
									WasinJPound = true
								end
							end
						else
							ESX.ShowNotification(_U('not_enough_money'))
						end
					end)
				else
					ESX.ShowNotification(_U('cant_take_out'))
				end
			end, function(data, menu)
				menu.close()
			end)
		end)
	end
end
-- End of Police Code

-- Start of Mechanic Code
function ListOwnedMechanicMenu()
	local elements = {}

	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - <span style="color:red;">%s</span> |'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:red;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	ESX.TriggerServerCallback('esx_advancedgarage:getOwnedMechanicCars', function(ownedMechanicCars)
		if #ownedMechanicCars == 0 then
			ESX.ShowNotification(_U('garage_no_mechanic'))
		else
			for _,v in pairs(ownedMechanicCars) do
				local hashVehicule = v.vehicle.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
				local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

				if Config.Main.ShowVehLoc then
					if v.stored then
						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
					else
						labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
					end
				else
					if v.stored then
						labelvehicle = labelvehicle3
					else
						labelvehicle = labelvehicle3
					end
				end

				table.insert(elements, {label = labelvehicle, value = v})
			end
		end
		
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_mechanic', {
			title = _U('garage_mechanic'),
			align = Config.Main.MenuAlign,
			elements = elements
		}, function(data, menu)
			if data.current.value == nil then
			else
				if data.current.value.stored then
					menu.close()
					SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
				else
					ESX.ShowNotification(_U('mechanic_is_impounded'))
				end
			end
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function StoreOwnedMechanicMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Mechanic.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Mechanic.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedMechanicMenu()
	if WasinJPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.JPoundWait))
	else
		ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedMechanicCars', function(ownedMechanicCars)
			local elements = {}

			if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
				local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
				table.insert(elements, {label = spacer, value = nil})
			end

			for _,v in pairs(ownedMechanicCars) do
				local hashVehicule = v.model
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				local plate = v.plate
				local labelvehicle
				local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

				labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

				table.insert(elements, {label = labelvehicle, value = v})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_mechanic', {
				title = _U('pound_mechanic', ESX.Math.GroupDigits(Config.Mechanic.PoundP)),
				align = Config.Main.MenuAlign,
				elements = elements
			}, function(data, menu)
				local doesVehicleExist = false

				for k,v in pairs (vehInstance) do
					if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
						if DoesEntityExist(v.vehicleentity) then
							doesVehicleExist = true
						else
							table.remove(vehInstance, k)
							doesVehicleExist = false
						end
					end
				end

				if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
					ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyMechanic', function(hasEnoughMoney)
						if hasEnoughMoney then
							if data.current.value == nil then
							else
								SpawnVehicle(data.current.value, data.current.value.plate)
								TriggerServerEvent('esx_advancedgarage:payMechanic')
								if Config.Main.JPoundTimer then
									WasinJPound = true
								end
							end
						else
							ESX.ShowNotification(_U('not_enough_money'))
						end
					end)
				else
					ESX.ShowNotification(_U('cant_take_out'))
				end
			end, function(data, menu)
				menu.close()
			end)
		end)
	end
end
-- End of Mechanic Code

-- Start of Aircraft Code
function ListOwnedAircraftsMenu()
	local elements = {}


	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - <span style="color:red;">%s</span> |'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:red;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	local jobElements = {
		{label = _U("society_owned"), value = "society_owned"},
		{label = _U("personaly_owned"), value = "personaly_owned"}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_car_elements_job_owned', {
		title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
		align = Config.Main.MenuAlign,
		elements = jobElements
	}, function(data1, menu1)

		if data.currenct.value == "personaly_owned" then

			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedAircrafts', function(ownedAircrafts)
				if #ownedAircrafts == 0 then
					ESX.ShowNotification(_U('garage_no_aircrafts'))
				else
					for _,v in pairs(ownedAircrafts) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
						local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end

						table.insert(elements, {label = labelvehicle, value = v})
					end
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_aircraft', {
					title = _U('garage_aircrafts'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data, menu)
					if data.current.value == nil then
					else
						if data.current.value.stored then
							menu.close()
							SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
						else
							ESX.ShowNotification(_U('aircraft_is_impounded'))
						end
					end
				end, function(data, menu)
					menu.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedAircraftsMenu()
				end)
			end)

		else

			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedAircraftsSociety', function(ownedAircrafts)
				if #ownedAircrafts == 0 then
					ESX.ShowNotification(_U('garage_no_aircrafts'))
				else
					for _,v in pairs(ownedAircrafts) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
						local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end

						table.insert(elements, {label = labelvehicle, value = v})
					end
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_aircraft', {
					title = _U('garage_aircrafts'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data, menu)
					if data.current.value == nil then
					else
						if data.current.value.stored then
							menu.close()
							SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
						else
							ESX.ShowNotification(_U('aircraft_is_impounded'))
						end
					end
				end, function(data, menu)
					menu.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedAircraftsMenu()
				end)
			end)

		end
	end, function(data1, menu1)
		menu1.close()
	end)
end

function StoreOwnedAircraftsMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Aircrafts.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Aircrafts.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedAircraftsMenu()
	if WasInPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.PoundWait))
	else

		local jobElements = {
			{label = _U("society_owned"), value = "society_owned"},
			{label = _U("personaly_owned"), value = "personaly_owned"}
		}

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_car_elements_job_owned', {
			title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
			align = Config.Main.MenuAlign,
			elements = jobElements
		}, function(data1, menu1)

			if data1.current.value == "personaly_owned" then

				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedAircrafts', function(ownedAircrafts)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedAircrafts) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_aircraft', {
						title = _U('pound_aircrafts', ESX.Math.GroupDigits(Config.Aircrafts.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data, menu)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyAircrafts', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data.current.value == nil then
									else
										SpawnVehicle(data.current.value, data.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payAircraft')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data, menu)
						menu.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedAircraftsMenu()
					end)
				end)

			else

				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedAircraftsSociety', function(ownedAircrafts)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedAircrafts) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_aircraft_society', {
						title = _U('pound_aircrafts', ESX.Math.GroupDigits(Config.Aircrafts.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data3, menu3)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyAircrafts', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data.current.value == nil then
									else
										SpawnVehicle(data.current.value, data.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payAircraft')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data3, menu3)
						menu3.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedAircraftsMenu()
					end)
				end)

			end
		end, function(data1, menu1)
			menu1.close()
		end)
	end
end
-- End of Aircraft Code

-- Start of Boat Code
function ListOwnedBoatsMenu()
	local elements = {}

	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - <span style="color:red;">%s</span> |'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:red;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	local jobElements = {
		{label = _U("society_owned"), value = "society_owned"},
		{label = _U("personaly_owned"), value = "personaly_owned"}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_boat_menu', {
		title = _U('garage_boats'),
		align = Config.Main.MenuAlign,
		elements = jobElements
	}, function(data1, menu1)

		if data1.current.value == "personaly_owned" then

			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedBoats', function(ownedBoats)
				if #ownedBoats == 0 then
					ESX.ShowNotification(_U('garage_no_boats'))
				else
					for _,v in pairs(ownedBoats) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
						local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end

						table.insert(elements, {label = labelvehicle, value = v})
					end
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_boat_personal', {
					title = _U('garage_boats'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data, menu)
					if data.current.value == nil then
					else
						if data.current.value.stored then
							menu.close()
							SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
						else
							ESX.ShowNotification(_U('boat_is_impounded'))
						end
					end
				end, function(data, menu)
					menu.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedBoatsMenu()
				end)
			end)
		else
			
			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedBoatsSociety', function(ownedBoats)
				if #ownedBoats == 0 then
					ESX.ShowNotification(_U('garage_no_boats'))
				else
					for _,v in pairs(ownedBoats) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)
						local labelvehicle3 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> | '):format(plate, vehicleName)

						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('loc_garage'))
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:red;">%s</span> |'):format(_U('loc_pound'))
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end

						table.insert(elements, {label = labelvehicle, value = v})
					end
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_boat_society', {
					title = _U('garage_boats'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data2, menu2)
					if data2.current.value == nil then
					else
						if data2.current.value.stored then
							menu2.close()
							SpawnVehicle(data2.current.value.vehicle, data2.current.value.plate)
						else
							ESX.ShowNotification(_U('boat_is_impounded'))
						end
					end
				end, function(data2, menu2)
					menu2.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedBoatsMenu()
				end)
			end)

		end
	end, function(data1, menu1)
		menu1.close()
	end)
end

function StoreOwnedBoatsMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Boats.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Boats.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedBoatsMenu()
	if WasInPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.PoundWait))
	else

		local jobElements = {
			{label = _U("society_owned"), value = "society_owned"},
			{label = _U("personaly_owned"), value = "personaly_owned"}
		}

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_boats_impoundmenu', {
			title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
			align = Config.Main.MenuAlign,
			elements = jobElements
		}, function(data1, menu1)

			if data1.current.value == "personaly_owned" then


				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedBoats', function(ownedBoats)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedBoats) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_boat_personaly_owned', {
						title = _U('pound_boats', ESX.Math.GroupDigits(Config.Boats.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data2, menu2)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data2.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data2.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyBoats', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data2.current.value == nil then
									else
										SpawnVehicle(data2.current.value, data2.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payBoat')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data2, menu2)
						menu2.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedBoatsMenu()
					end)
				end)

			else

				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedBoatsSociety', function(ownedBoats)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedBoats) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_boat_society', {
						title = _U('pound_boats', ESX.Math.GroupDigits(Config.Boats.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data3, menu3)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data3.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data3.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyBoats', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data3.current.value == nil then
									else
										SpawnVehicle(data3.current.value, data3.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payBoat')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data3, menu3)
						menu3.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedBoatsMenu()
					end)
				end)
			end
		end, function(data1, menu1)
			menu1.close()
		end)
	end
end
-- End of Boat Code

-- IDK if it will work xDD just .. thinking 
--[[
Citizen.CreateThread(function()
	while ESX.PlayerLoaded do
		Citizen.Wait(Config.EngineCheckTime)
		local ped = PlayerPedId()
		local current = GetPlayersLastVehicle(ped, true)
		local engineHealth = GetVehicleEngineHealth(current)
	
		for k,v in pairs(engineHealth) do
			if engineHealth < 990 then
				--- dobré
			elseif engineHealth < 550 then
				--- poškožené
			elseif engineHealth < 50 then
				--- nepojizdé
			end
		end

	end
end)]]



-- Start of Car Code
function ListOwnedCarsMenu()
	local elements = {}


	if Config.Main.ShowVehLoc and Config.Main.Spacers then
		local spacer = ('<b><u><span style="color:white;">%s</span> - <span style="color:white;">%s</span> - <span style="color:white;">%s</span></b></u>'):format(_U('plate'), _U('vehicle'), _U('location'))
		table.insert(elements, {label = spacer, value = nil})
	elseif Config.Main.ShowVehLoc == false and Config.Main.Spacers then
		local spacer = ('<span style="color:white;">%s</span> - <span style="color:white;">%s</span>'):format(_U('plate'), _U('vehicle'))
		table.insert(elements, {label = ('<span style="color:white;">%s</span>'):format(_U('spacer1')), value = nil})
		table.insert(elements, {label = spacer, value = nil})
	end

	-- Part of choosing 

	local jobElements = {
		{label = _U("society_owned"), value = "society_owned"},
		{label = _U("personaly_owned"), value = "personaly_owned"}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_car', {
		title = _U('garage_cars'),
		align = Config.Main.MenuAlign,
		elements = jobElements
	}, function(data, menu)
		if data.current.value == "society_owned" then
			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedCarsSociety', function(ownedCars)
				if #ownedCars == 0 then
					ESX.ShowNotification(_U('garage_no_cars'))
				else
					for _,v in pairs(ownedCars) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('<span style="color:green; font-size: 16px;">%s</span> - <span style="color:darkgoldenrod; font-size: 16px;">(%s)</span> - '):format(vehicleName, plate)
						local labelvehicle3 = ('<span style="color:green; font-size: 16px;">%s</span> - <span style="color:darkgoldenrod; font-size: 16px;">(%s)</span>'):format(vehicleName, plate)
						
		
						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green; font-size: 16px;">%s</span>'):format(_U('loc_garage')..' (Stav: POJÍZDNÉ )')
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:#5654e4; font-size: 16px;">%s</span>'):format(_U('loc_pound')..' ($'..Config.Cars.PoundP..')')
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end
		
						table.insert(elements, {label = labelvehicle, value = v})
					end
				end
		
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_car_personal', {
					title = _U('garage_cars'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data2, menu2)
					if data2.current.value == nil then
					else
						if data2.current.value.stored then
							menu.close()
							SpawnVehicle(data2.current.value.vehicle, data2.current.value.plate)
							exports['mythic_notify']:DoHudText('success', 'Vozidlo vytaženo z garáže')
						else
							ESX.ShowNotification(_U('car_is_impounded'))
						end
					end
				end, function(data2, menu2)
					menu2.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedCarsMenu()
				end)
			end)
		else
			ESX.TriggerServerCallback('esx_advancedgarage:getOwnedCars', function(ownedCars)
				if #ownedCars == 0 then
					ESX.ShowNotification(_U('garage_no_cars'))
				else
					for _,v in pairs(ownedCars) do
						local hashVehicule = v.vehicle.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('<span style="color:green; font-size: 16px;">%s</span> - <span style="color:darkgoldenrod; font-size: 16px;">(%s)</span> - '):format(vehicleName, plate)
						local labelvehicle3 = ('<span style="color:green; font-size: 16px;">%s</span> - <span style="color:darkgoldenrod; font-size: 16px;">(%s)</span>'):format(vehicleName, plate)
		
						if Config.Main.ShowVehLoc then
							if v.stored then
								labelvehicle = labelvehicle2 .. ('<span style="color:green; font-size: 16px;">%s</span>'):format(_U('loc_garage')..' (Stav: POJIZDNÉ)')
							else
								labelvehicle = labelvehicle2 .. ('<span style="color:#5654e4; font-size: 16px;">%s</span>'):format(_U('loc_pound')..' ($'..Config.Cars.PoundP..')')
							end
						else
							if v.stored then
								labelvehicle = labelvehicle3
							else
								labelvehicle = labelvehicle3
							end
						end
		
						table.insert(elements, {label = labelvehicle, value = v})
					end
				end
		
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_car_society', {
					title = _U('garage_cars'),
					align = Config.Main.MenuAlign,
					elements = elements
				}, function(data1, menu1)
					if data1.current.value == nil then
					else
						if data1.current.value.stored then
							menu.close()
							SpawnVehicle(data1.current.value.vehicle, data1.current.value.plate)
						else
							ESX.ShowNotification(_U('car_is_impounded'))
						end
					end
				end, function(data1, menu1)
					menu1.close()
					elements = {}
					ESX.UI.Menu.CloseAll()
					ListOwnedCarsMenu()
				end)
			end)
		end
	end, function(data, menu)
		menu.close()
	end)

end

function StoreOwnedCarsMenu()
	local playerPed  = PlayerPedId()

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(PlayerPedId(), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Cars.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Cars.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end

function ReturnOwnedCarsMenu()
	if WasInPound then
		ESX.ShowNotification(_U('must_wait', Config.Main.PoundWait))
	else

		local jobElements = {
			{label = _U("society_owned"), value = "society_owned"},
			{label = _U("personaly_owned"), value = "personaly_owned"}
		}

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_car_elements_job_owned', {
			title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
			align = Config.Main.MenuAlign,
			elements = jobElements
		}, function(data1, menu1)

			if data1.current.value == "society_owned" then

				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedCarsSociety', function(ownedCars)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedCars) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_car_society', {
						title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data, menu)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyCars', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data.current.value == nil then
									else
										SpawnVehicle(data.current.value, data.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payCar')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data, menu)
						menu.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedCarsMenu()
					end)
				end)

			else

				ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedCars', function(ownedCars)
					local elements = {}

					if Config.Main.ShowVehLoc == false and Config.Main.Spacers then
						local spacer = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> |'):format(_U('plate'), _U('vehicle'))
						table.insert(elements, {label = spacer, value = nil})
					end

					for _,v in pairs(ownedCars) do
						local hashVehicule = v.model
						local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
						local vehicleName = GetLabelText(aheadVehName)
						local plate = v.plate
						local labelvehicle
						local labelvehicle2 = ('| <span style="color:red;">%s</span> - <span style="color:darkgoldenrod;">%s</span> - '):format(plate, vehicleName)

						labelvehicle = labelvehicle2 .. ('<span style="color:green;">%s</span> |'):format(_U('return'))

						table.insert(elements, {label = labelvehicle, value = v})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_owned_car_personal', {
						title = _U('pound_cars', ESX.Math.GroupDigits(Config.Cars.PoundP)),
						align = Config.Main.MenuAlign,
						elements = elements
					}, function(data, menu)
						local doesVehicleExist = false

						for k,v in pairs (vehInstance) do
							if ESX.Math.Trim(v.plate) == ESX.Math.Trim(data.current.value.plate) then
								if DoesEntityExist(v.vehicleentity) then
									doesVehicleExist = true
								else
									table.remove(vehInstance, k)
									doesVehicleExist = false
								end
							end
						end

						if not doesVehicleExist and not DoesAPlayerDrivesVehicle(data.current.value.plate) then
							ESX.TriggerServerCallback('esx_advancedgarage:checkMoneyCars', function(hasEnoughMoney)
								if hasEnoughMoney then
									if data.current.value == nil then
									else
										SpawnVehicle(data.current.value, data.current.value.plate)
										TriggerServerEvent('esx_advancedgarage:payCar')
										if Config.Main.PoundTimer then
											WasInPound = true
										end
									end
								else
									ESX.ShowNotification(_U('not_enough_money'))
								end
							end)
						else
							ESX.ShowNotification(_U('cant_take_out'))
						end
					end, function(data, menu)
						menu.close()
						elements = {}
						ESX.UI.Menu.CloseAll()
						ReturnOwnedCarsMenu()
					end)
				end)

			end
		end, function(data1, menu1)
			menu1.close()
		end)
	end
end
-- End of Car Code

-- WasInPound & WasinJPound Code
Citizen.CreateThread(function()
	while true do
		local sleep = 2000

		if Config.Main.PoundTimer then
			if WasInPound then
				sleep = 1
				Citizen.Wait(Config.Main.PoundWait * 60000)
				WasInPound = false
				
			end
		end

		if Config.Main.JPoundTimer then
			if WasinJPound then
				sleep = 1
				Citizen.Wait(Config.Main.JPoundWait * 60000)
				WasinJPound = false
			end
		end
		Wait(sleep)
	end
end)

-- Repair Vehicles
function RepairVehicle(apprasial, vehicle, vehicleProps)
	if Config.DecideToRepair == 'default' then

	ESX.UI.Menu.CloseAll()
	local elements = {
		{label = _U('return_vehicle').." ($"..apprasial..")", value = 'yes'},
		{label = _U('see_mechanic'), value = 'no'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'delete_menu', {
		title = _U('damaged_vehicle'),
		align = Config.Main.MenuAlign,
		elements = elements
	}, function(data, menu)
		menu.close()

		if data.current.value == 'yes' then
			TriggerServerEvent('esx_advancedgarage:payhealth', apprasial)
			vehicleProps.bodyHealth = 1000.0
			vehicleProps.engineHealth = 1000
			StoreVehicle(vehicle, vehicleProps)
		elseif data.current.value == 'no' then
			ESX.ShowNotification(_U('visit_mechanic'))
		end
	end, function(data, menu)
		menu.close()
	end)

	elseif Config.DecideToRepair == 'broken_save_pay' then
		TriggerServerEvent('esx_advancedgarage:payhealth', apprasial)
		StoreVehicle(vehicle, vehicleProps)
	elseif Config.DecideToRepair == 'repair_save_pay' then
		TriggerServerEvent('esx_advancedgarage:payhealth', apprasial)
		vehicleProps.bodyHealth = 1000.0 
		vehicleProps.engineHealth = 1000
		StoreVehicle(vehicle, vehicleProps)
	elseif Config.DecideToRepair == 'only_store' then
		StoreVehicle(vehicle, vehicleProps)
	end
end

-- Store Vehicles
function StoreVehicle(vehicle, vehicleProps)
	for k,v in pairs (vehInstance) do
		if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehicleProps.plate) then
			table.remove(vehInstance, k)
		end
	end

	DeleteEntity(vehicle)
	TriggerServerEvent('esx_advancedgarage:setVehicleState', vehicleProps.plate, true)
	ESX.ShowNotification(_U('vehicle_in_garage'))
end

-- Spawn Vehicles
function SpawnVehicle(vehicle, plate)
	ESX.Game.SpawnVehicle(vehicle.model, this_Garage.Spawner, this_Garage.Heading, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
		SetVehRadioStation(callback_vehicle, "OFF")
		SetVehicleFixed(callback_vehicle)
		SetVehicleDeformationFixed(callback_vehicle)
		SetVehicleUndriveable(callback_vehicle, false)
		SetVehicleEngineOn(callback_vehicle, true, true)
		--SetVehicleEngineHealth(callback_vehicle, 1000) -- Might not be needed
		--SetVehicleBodyHealth(callback_vehicle, 1000) -- Might not be needed
		local carplate = GetVehicleNumberPlateText(callback_vehicle)
		table.insert(vehInstance, {vehicleentity = callback_vehicle, plate = carplate})
		TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
	end)

	TriggerServerEvent('esx_advancedgarage:setVehicleState', plate, false)
end

function SpawnVehicle2(vehicle, plate)
	ESX.Game.SpawnVehicle(vehicle.model, this_Garage.Spawner2, this_Garage.Heading2, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
		SetVehRadioStation(callback_vehicle, "OFF")
		SetVehicleFixed(callback_vehicle)
		SetVehicleDeformationFixed(callback_vehicle)
		SetVehicleUndriveable(callback_vehicle, false)
		SetVehicleEngineOn(callback_vehicle, true, true)
		--SetVehicleEngineHealth(callback_vehicle, 1000) -- Might not be needed
		--SetVehicleBodyHealth(callback_vehicle, 1000) -- Might not be needed
		local carplate = GetVehicleNumberPlateText(callback_vehicle)
		table.insert(vehInstance, {vehicleentity = callback_vehicle, plate = carplate})
		TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
	end)

	TriggerServerEvent('esx_advancedgarage:setVehicleState', plate, false)
end

-- Check Vehicles
function DoesAPlayerDrivesVehicle(plate)
	local isVehicleTaken = false
	local players = ESX.Game.GetPlayers() --ESX.GetExtendedPlayers() - need ESX legacy, maybe next update
	for i=1, #players, 1 do
		local target = GetPlayerPed(players[i])
		if target ~= PlayerPedId() then
			local plate1 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, true))
			local plate2 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, false))
			if plate == plate1 or plate == plate2 then
				isVehicleTaken = true
				break
			end
		end
	end
	return isVehicleTaken
end

-- Entered Marker
AddEventHandler('esx_advancedgarage:hasEnteredMarker', function(zone)
	if zone == 'ambulance_garage_point' then
		CurrentAction = 'ambulance_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'ambulance_store_point' then
		CurrentAction = 'ambulance_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'ambulance_pound_point' then
		CurrentAction = 'ambulance_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'police_garage_point' then
		CurrentAction = 'police_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'police_store_point' then
		CurrentAction = 'police_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'police_pound_point' then
		CurrentAction = 'police_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'mechanic_garage_point' then
		CurrentAction = 'mechanic_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'mechanic_store_point' then
		CurrentAction = 'mechanic_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'mechanic_pound_point' then
		CurrentAction = 'mechanic_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'aircraft_garage_point' then
		CurrentAction = 'aircraft_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'aircraft_store_point' then
		CurrentAction = 'aircraft_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'aircraft_pound_point' then
		CurrentAction = 'aircraft_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'boat_garage_point' then
		CurrentAction = 'boat_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'boat_store_point' then
		CurrentAction = 'boat_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'boat_pound_point' then
		CurrentAction = 'boat_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'car_garage_point' then
		CurrentAction = 'car_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'car_store_point' then
		CurrentAction = 'car_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'car_pound_point' then
		CurrentAction = 'car_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	end
end)

-- Exited Marker
AddEventHandler('esx_advancedgarage:hasExitedMarker', function()
	ESX.UI.Menu.CloseAll()
	lib.hideTextUI()
	CurrentAction = nil
end)

-- Resource Stop
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		ESX.UI.Menu.CloseAll()
	end
end)

-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		local sleep = 2000
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true

		if Config.Ambulance.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
				for k,v in pairs(Config.AmbulanceGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)
					local distance3 = #(playerCoords - v.Deleter2)
					local coords = GetEntityCoords(PlayerPedId())
        			local player = PlayerPedId()

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Ambulance.Markers.Points.Type ~= -1 and IsPedOnFoot(player, true) then
						--	DrawMarker(Config.Ambulance.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Points.x, Config.Ambulance.Markers.Points.y, Config.Ambulance.Markers.Points.z, Config.Ambulance.Markers.Points.r, Config.Ambulance.Markers.Points.g, Config.Ambulance.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Ambulance.Markers.Points.x and IsPedOnFoot(player, true) then
							isInMarker, this_Garage, currentZone = true, v, 'ambulance_garage_point'
							if Config.DrawHelp == '3DText' then
               					DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevřít Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end

					if distance2 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Ambulance.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						--	DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Delete.x, Config.Ambulance.Markers.Delete.y, Config.Ambulance.Markers.Delete.z, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
							DisableControlAction(0, 22, true)
                			DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
						else
							DrawMarker(Config.Ambulance.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Ambulance.Markers.Points.r, Config.Ambulance.Markers.Points.g, Config.Ambulance.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
						end

						if distance2 < Config.Ambulance.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
							isInMarker, this_Garage, currentZone = true, v, 'ambulance_store_point'
							DisableControlAction(0, 22, true)
							if Config.DrawHelp == '3DText' then
                				DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Uložení auta do', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end

					if distance3 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Ambulance.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						--	DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Delete.x, Config.Ambulance.Markers.Delete.y, Config.Ambulance.Markers.Delete.z, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
							DisableControlAction(0, 22, true)
                			DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
						else
							DrawMarker(Config.Ambulance.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Ambulance.Markers.Points.r, Config.Ambulance.Markers.Points.g, Config.Ambulance.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
						end

						if distance3 < Config.Ambulance.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
							isInMarker, this_Garage, currentZone = true, v, 'ambulance_store_point'
							DisableControlAction(0, 22, true)
							if Config.DrawHelp == '3DText' then
                				DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Uložení auta do Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end

				end
			end
		end

		if Config.Ambulance.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
				for k,v in pairs(Config.AmbulancePounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Ambulance.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Ambulance.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Pounds.x, Config.Ambulance.Markers.Pounds.y, Config.Ambulance.Markers.Pounds.z, Config.Ambulance.Markers.Pounds.r, Config.Ambulance.Markers.Pounds.g, Config.Ambulance.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Ambulance.Markers.Pounds.x then
							isInMarker, this_Garage, currentZone = true, v, 'ambulance_pound_point'
						end
						if distance < 2 then
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevření Odtahovky', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end
				end
			end
		end

		if Config.Police.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				for k,v in pairs(Config.PoliceGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)
					local distance3 = #(playerCoords - v.Deleter2)
					local coords = GetEntityCoords(PlayerPedId())
       				local player = PlayerPedId()

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Police.Markers.Points.Type ~= -1  and IsPedOnFoot(player, true) then
						--	DrawMarker(Config.Police.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Points.x, Config.Police.Markers.Points.y, Config.Police.Markers.Points.z, Config.Police.Markers.Points.r, Config.Police.Markers.Points.g, Config.Police.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Police.Markers.Points.x  and IsPedOnFoot(player, true) then
							isInMarker, this_Garage, currentZone = true, v, 'police_garage_point'
							DisableControlAction(0, 22, true)
							if Config.DrawHelp == '3DText' then
                				DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevření Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end

					if distance2 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Police.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						--	DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Delete.x, Config.Police.Markers.Delete.y, Config.Police.Markers.Delete.z, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
							DisableControlAction(0, 22, true)
                			DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
						else
							DrawMarker(Config.Police.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Police.Markers.Points.r, Config.Police.Markers.Points.g, Config.Police.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
						end

						if distance2 < Config.Police.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
							DisableControlAction(0, 22, true)
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Uložení auta do Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
							isInMarker, this_Garage, currentZone = true, v, 'police_store_point'
						end
					end

					if distance3 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Police.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						--	DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Delete.x, Config.Police.Markers.Delete.y, Config.Police.Markers.Delete.z, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
							DisableControlAction(0, 22, true)
                			DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
						else
							DrawMarker(Config.Police.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Police.Markers.Points.r, Config.Police.Markers.Points.g, Config.Police.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
						end

						if distance3 < Config.Police.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
							DisableControlAction(0, 22, true)
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Uložení auta do Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
							isInMarker, this_Garage, currentZone = true, v, 'police_store_point'
						end
					end
				end
			end
		end

		if Config.Police.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				for k,v in pairs(Config.PolicePounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Police.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Police.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Pounds.x, Config.Police.Markers.Pounds.y, Config.Police.Markers.Pounds.z, Config.Police.Markers.Pounds.r, Config.Police.Markers.Pounds.g, Config.Police.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Police.Markers.Pounds.x then
							isInMarker, this_Garage, currentZone = true, v, 'police_pound_point'
						end
						if distance < 2 then
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevření Odtahovky', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end
				end
			end
		end

		if Config.Mechanic.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
				for k,v in pairs(Config.MechanicGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Mechanic.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Points.x, Config.Mechanic.Markers.Points.y, Config.Mechanic.Markers.Points.z, Config.Mechanic.Markers.Points.r, Config.Mechanic.Markers.Points.g, Config.Mechanic.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Mechanic.Markers.Points.x then
							isInMarker, this_Garage, currentZone = true, v, 'mechanic_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Mechanic.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Delete.x, Config.Mechanic.Markers.Delete.y, Config.Mechanic.Markers.Delete.z, Config.Mechanic.Markers.Delete.r, Config.Mechanic.Markers.Delete.g, Config.Mechanic.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Mechanic.Markers.Delete.x then
							isInMarker, this_Garage, currentZone = true, v, 'mechanic_store_point'
						end
					end
				end
			end
		end

		if Config.Mechanic.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
				for k,v in pairs(Config.MechanicPounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Mechanic.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Pounds.x, Config.Mechanic.Markers.Pounds.y, Config.Mechanic.Markers.Pounds.z, Config.Mechanic.Markers.Pounds.r, Config.Mechanic.Markers.Pounds.g, Config.Mechanic.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Mechanic.Markers.Pounds.x then
							isInMarker, this_Garage, currentZone = true, v, 'mechanic_pound_point'
						end
						if distance < 2 then
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevření Odtahovky', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end
				end
			end
		end

		if Config.Aircrafts.Garages then
			for k,v in pairs(Config.AircraftGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)
				local coords = GetEntityCoords(PlayerPedId())
        		local player = PlayerPedId()

				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Aircrafts.Markers.Points.Type ~= -1 and IsPedOnFoot(player, true) then
					--	DrawMarker(Config.Aircrafts.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Aircrafts.Markers.Points.x, Config.Aircrafts.Markers.Points.y, Config.Aircrafts.Markers.Points.z, Config.Aircrafts.Markers.Points.r, Config.Aircrafts.Markers.Points.g, Config.Aircrafts.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Aircrafts.Markers.Points.x and IsPedOnFoot(player, true) then
						DisableControlAction(0, 22, true)
						isInMarker, this_Garage, currentZone = true, v, 'aircraft_garage_point'
						if Config.DrawHelp == '3DText' then
                			DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevřít Garáže', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end

				if distance2 < Config.Main.DrawDistance then
					sleep = 1

					if Config.Aircrafts.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						DrawMarker(Config.Aircrafts.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Aircrafts.Markers.Delete.r, Config.Aircrafts.Markers.Delete.g, Config.Aircrafts.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
					else
						DrawMarker(Config.Aircrafts.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Aircrafts.Markers.Points.r, Config.Aircrafts.Markers.Points.g, Config.Aircrafts.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
					end

					if distance2 < Config.Aircrafts.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
						isInMarker, this_Garage, currentZone = true, v, 'aircraft_store_point'
						if Config.DrawHelp == '3DText' then
                			DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Uložení auta do Garáže', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end
			end

			for k,v in pairs(Config.AircraftPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Aircrafts.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Aircrafts.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Aircrafts.Markers.Pounds.x, Config.Aircrafts.Markers.Pounds.y, Config.Aircrafts.Markers.Pounds.z, Config.Aircrafts.Markers.Pounds.r, Config.Aircrafts.Markers.Pounds.g, Config.Aircrafts.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Aircrafts.Markers.Pounds.x then
						isInMarker, this_Garage, currentZone = true, v, 'aircraft_pound_point'
					end
					if distance < 2 then
						if Config.DrawHelp == '3DText' then
							DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevřít Odtahovku', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end
			end
		end

		if Config.Boats.Garages then
			for k,v in pairs(Config.BoatGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)
				local coords = GetEntityCoords(PlayerPedId())
        		local player = PlayerPedId()
				
				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Boats.Markers.Points.Type ~= -1 and IsPedOnFoot(player, true) then
					--	DrawMarker(Config.Boats.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Points.x, Config.Boats.Markers.Points.y, Config.Boats.Markers.Points.z, Config.Boats.Markers.Points.r, Config.Boats.Markers.Points.g, Config.Boats.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Boats.Markers.Points.x and IsPedOnFoot(player, true) then
						isInMarker, this_Garage, currentZone = true, v, 'boat_garage_point'
						if Config.DrawHelp == '3DText' then
                			DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevření Odtahovky', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end

				if distance2 < Config.Main.DrawDistance then
					sleep = 1

					if Config.Boats.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						DrawMarker(Config.Boats.Markers.Delete.Type, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Cars.Markers.Delete.r, Config.Cars.Markers.Delete.g, Config.Cars.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
					--	DrawMarker(Config.Boats.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Delete.x, Config.Boats.Markers.Delete.y, Config.Boats.Markers.Delete.z, Config.Boats.Markers.Delete.r, Config.Boats.Markers.Delete.g, Config.Boats.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
					else
						DrawMarker(Config.Boats.Markers.Points.Type, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Boats.Markers.Points.r, Config.Boats.Markers.Points.g, Config.Boats.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
					end

					if distance2 < Config.Boats.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
						DisableControlAction(0, 22, true)
						if Config.DrawHelp == '3DText' then
                			DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Uložení auta do Garáže', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
						isInMarker, this_Garage, currentZone = true, v, 'boat_store_point'
					end
				end
			end

			for k,v in pairs(Config.BoatPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Boats.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Boats.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Pounds.x, Config.Boats.Markers.Pounds.y, Config.Boats.Markers.Pounds.z, Config.Boats.Markers.Pounds.r, Config.Boats.Markers.Pounds.g, Config.Boats.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Boats.Markers.Pounds.x then
						isInMarker, this_Garage, currentZone = true, v, 'boat_pound_point'
					end
					if distance < 2 then
						if Config.DrawHelp == '3DText' then
							DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevřít Odtahovku', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end
			end
		end

		if Config.Cars.Garages then
			for k,v in pairs(Config.CarGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)
				local coords = GetEntityCoords(PlayerPedId())
				local player = PlayerPedId()

				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Cars.Markers.Points.Type ~= -1 and IsPedOnFoot(player, true) then
					end

					if distance < Config.Cars.Markers.Points.x and IsPedOnFoot(player, true) then
						isInMarker, this_Garage, currentZone = true, v, 'car_garage_point'
						if Config.DrawHelp == '3DText' then
							DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevřít Garáž', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end
				end

				if distance2 < Config.Main.DrawDistance then
					sleep = 1

					if Config.Cars.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
						DrawMarker(21, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Cars.Markers.Delete.r, Config.Cars.Markers.Delete.g, Config.Cars.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
					else
						DrawMarker(21, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Cars.Markers.Points.r, Config.Cars.Markers.Points.g, Config.Cars.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
					end

					if distance2 < Config.Cars.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
						if Config.DrawHelp == '3DText' then
							DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Uložení auta do Garáže', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
						isInMarker, this_Garage, currentZone = true, v, 'car_store_point'
					end

				end
			end

			if Config.BezBlipu then
				for k,v in pairs(Config.BezBlipu) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)
					local coords = GetEntityCoords(PlayerPedId())
					local player = PlayerPedId()
	
					if distance < Config.Main.DrawDistance then
						sleep = 1
	
						if Config.Cars.Markers.Points.Type ~= -1 and IsPedOnFoot(player, true) then
						end
	
						if distance < Config.Cars.Markers.Points.x and IsPedOnFoot(player, true) then
							isInMarker, this_Garage, currentZone = true, v, 'car_garage_point'
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 1.2, tostring(_U('3d_press_to_enter')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Otevřít Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
						end
					end
	
					if distance2 < Config.Main.DrawDistance then
						sleep = 1
	
						if Config.Cars.Markers.Delete.Type ~= -1 and IsPedInAnyVehicle(player, true) then
							DrawMarker(21, v.Deleter.x, v.Deleter.y, v.Deleter.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, -0.7, Config.Cars.Markers.Delete.r, Config.Cars.Markers.Delete.g, Config.Cars.Markers.Delete.b, 100, true, true, 2, false, nil, nil, false)
						else
							DrawMarker(21, v.Marker.x, v.Marker.y, v.Marker.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.Cars.Markers.Points.r, Config.Cars.Markers.Points.g, Config.Cars.Markers.Points.b, 100, true, true, 2, false, nil, nil, false)	
						end
	
						if distance2 < Config.Cars.Markers.Delete.x and IsPedInAnyVehicle(player, true) then
							if Config.DrawHelp == '3DText' then
								DrawText3Dx(v.Deleter.x, v.Deleter.y, v.Deleter.z + 1.2, tostring(_U('3d_press_to_delete')))
							elseif Config.DrawHelp == 'IM' then 
								inZone  = true
								lib.showTextUI('[E] - Uložit auto do Garáže', {
									position = "top-center",
									icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
									style = {
										borderRadius = 6,
										color = 'grey'
									}
								})
							end
							isInMarker, this_Garage, currentZone = true, v, 'car_store_point'
						end
					end
				end

			for k,v in pairs(Config.CarPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					sleep = 1

					if Config.Cars.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Cars.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Cars.Markers.Pounds.x, Config.Cars.Markers.Pounds.y, Config.Cars.Markers.Pounds.z, Config.Cars.Markers.Pounds.r, Config.Cars.Markers.Pounds.g, Config.Cars.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < 2 then
						if Config.DrawHelp == '3DText' then
							DrawText3Dx(v.Marker.x, v.Marker.y, v.Marker.z + 0.2, tostring(_U('3d_press_to_impound')))
						elseif Config.DrawHelp == 'IM' then 
							inZone  = true
							lib.showTextUI('[E] - Otevření Odtahovky', {
								position = "top-center",
								icon = 'hand', -- <font-awesome-icon icon="fa-solid fa-garage" />
								style = {
									borderRadius = 6,
									color = 'grey'
								}
							})
						end
					end

					if distance < Config.Cars.Markers.Pounds.x then
						isInMarker, this_Garage, currentZone = true, v, 'car_pound_point'
					end
				end
			end
		end


		if Config.Pvt.Garages then
			for k,v in pairs(Config.PrivateCarGarages) do
				if not v.Private or has_value(userProperties, v.Private) then
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)

					if distance < Config.Main.DrawDistance then
						sleep = 1

						if Config.Pvt.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Pvt.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Pvt.Markers.Points.x, Config.Pvt.Markers.Points.y, Config.Pvt.Markers.Points.z, Config.Pvt.Markers.Points.r, Config.Pvt.Markers.Points.g, Config.Pvt.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Pvt.Markers.Points.x then
							isInMarker, this_Garage, currentZone = true, v, 'car_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						sleep = 1

						if Config.Pvt.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Pvt.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Pvt.Markers.Delete.x, Config.Pvt.Markers.Delete.y, Config.Pvt.Markers.Delete.z, Config.Pvt.Markers.Delete.r, Config.Pvt.Markers.Delete.g, Config.Pvt.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Pvt.Markers.Delete.x then
							isInMarker, this_Garage, currentZone = true, v, 'car_store_point'
						end
					end
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			LastZone = currentZone
			TriggerEvent('esx_advancedgarage:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_advancedgarage:hasExitedMarker', LastZone)
		end
		Wait(sleep)
	end
	-- yoinked from cd TriHard
	if inZone and not alreadyEnteredZone then
		alreadyEnteredZone = true
	end
	if not inZone and alreadyEnteredZone then
		alreadyEnteredZone = false
		lib.hideTextUI()
	end
end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local playerVeh = GetVehiclePedIsIn(playerPed, false)
		local model = GetEntityModel(playerVeh)

		if CurrentAction then
			if Config.DrawHelp == 'ESX' and Config.Draw ~- 'IM' then
				ESX.ShowHelpNotification(CurrentActionMsg)
			else
				if Config.Debug then
					print('Drawing ESX notification for garages')
				end
			end

			if IsControlJustReleased(0, 38) then
				
				if CurrentAction == 'ambulance_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						ListOwnedAmbulanceMenu()
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'ambulance_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedAmbulanceMenu()
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'ambulance_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						ReturnOwnedAmbulanceMenu()
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'police_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						ListOwnedPoliceMenu()
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'police_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedPoliceMenu()
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'police_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						ReturnOwnedPoliceMenu()
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'mechanic_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						ListOwnedMechanicMenu()
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'mechanic_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedMechanicMenu()
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'mechanic_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						ReturnOwnedMechanicMenu()
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'aircraft_garage_point' then
					ListOwnedAircraftsMenu()
				elseif CurrentAction == 'aircraft_store_point' then
					if IsThisModelAHeli(model) or IsThisModelAPlane(model) then
						if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
							StoreOwnedAircraftsMenu()
						else
							ESX.ShowNotification(_U('driver_seat'))
						end
					else
						ESX.ShowNotification(_U('not_correct_veh'))
					end
				elseif CurrentAction == 'aircraft_pound_point' then
					ReturnOwnedAircraftsMenu()
				elseif CurrentAction == 'boat_garage_point' then
					ListOwnedBoatsMenu()
				elseif CurrentAction == 'boat_store_point' then
					if IsThisModelABoat(model) then
						if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
							StoreOwnedBoatsMenu()
						else
							ESX.ShowNotification(_U('driver_seat'))
						end
					else
						ESX.ShowNotification(_U('not_correct_veh'))
					end
				elseif CurrentAction == 'boat_pound_point' then
					ReturnOwnedBoatsMenu()
				elseif CurrentAction == 'car_garage_point' then
					ListOwnedCarsMenu()
				elseif CurrentAction == 'car_store_point' then
					if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model) then
						if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
							StoreOwnedCarsMenu()
						else
							ESX.ShowNotification(_U('driver_seat'))
						end
					else
						ESX.ShowNotification(_U('not_correct_veh'))
					end
				elseif CurrentAction == 'car_pound_point' then
					ReturnOwnedCarsMenu()
				end

				CurrentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)


-- Create Blips
function CreateBlips()
	if Config.Aircrafts.Garages and Config.Aircrafts.Blips then
		for k,v in pairs(Config.AircraftGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.AircraftPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end

	if Config.Boats.Garages and Config.Boats.Blips then
		for k,v in pairs(Config.BoatGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.BoatPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end

	if Config.Cars.Garages and Config.Cars.Blips then
		for k,v in pairs(Config.CarGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.CarPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end
end

-- Handles Private Blips
function DeletePrivateBlips()
	if PrivateBlips[1] ~= nil then
		for i=1, #PrivateBlips, 1 do
			RemoveBlip(PrivateBlips[i])
			PrivateBlips[i] = nil
		end
	end
end

function RefreshPrivateBlips()
	for zoneKey,zoneValues in pairs(Config.PrivateCarGarages) do
		if zoneValues.Private and has_value(userProperties, zoneValues.Private) then
			local blip = AddBlipForCoord(zoneValues.Marker)

			SetBlipSprite (blip, Config.Blips.PGarages.Sprite)
			SetBlipColour (blip, Config.Blips.PGarages.Color)
			SetBlipDisplay(blip, Config.Blips.PGarages.Display)
			SetBlipScale  (blip, Config.Blips.PGarages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage_private'))
			EndTextCommandSetBlipName(blip)
			table.insert(PrivateBlips, blip)
		end
	end
end

-- Handles Job Blips
function DeleteJobBlips()
	if JobBlips[1] ~= nil then
		for i=1, #JobBlips, 1 do
			RemoveBlip(JobBlips[i])
			JobBlips[i] = nil
		end
	end
end

function RefreshJobBlips()
	if Config.Ambulance.Garages and Config.Ambulance.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			for k,v in pairs(Config.AmbulanceGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_ambulance_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Ambulance.Pounds and Config.Ambulance.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			for k,v in pairs(Config.AmbulancePounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_ambulance_pound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Police.Garages and Config.Police.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			for k,v in pairs(Config.PoliceGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_police_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Police.Pounds and Config.Police.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			for k,v in pairs(Config.PolicePounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_police_pound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Mechanic.Garages and Config.Mechanic.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			for k,v in pairs(Config.MechanicGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_mechanic_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Mechanic.Pounds and Config.Mechanic.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			for k,v in pairs(Config.MechanicPounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_mechanic_pound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end
end

function giveCarKeystoSociety()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsPedInAnyVehicle(playerPed,  false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)			
    else
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 7.0, 0, 70)
    end

	local plate = tostring(GetVehicleNumberPlateText(vehicle))
	local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos_prosnalsociety', {
		title    = _U('transfering_car'),
		align    = 'left',
		elements = {
			{label = _U('no'), value = 0},
			{label = _U('no'),   value = 1},
			{label = _U('yes'),   value = 'yes'},
			{label = _U('no'), value = 2},
			{label = _U('no'), value = 3}
		}}, function(data, menu)
		menu.close()

	    if data.current.value == 'yes' then

                ESX.TriggerServerCallback('esx_advancedgarage:requestPlayerCars', function(isOwnedVehicle)

					if isOwnedVehicle then
                    
                    	ESX.ShowNotification(_U('transfering_car'))
                    	TriggerServerEvent('esx_advancedgarage:setvehicleWonerSociety', vehicleProps)
                	end
                
            end, plate)

        end

	end)
end

if Config.CanTakeToSociety then
	RegisterCommand(Config.CommandToAddSociety, function()
		if Config.OnlyGradeCanAdd and ESX.PlayerData.job.grade_name == Config.GradeToAddsociety then
			giveCarKeystoSociety()
		elseif Config.OnlyGradeCanAdd == false then
			giveCarKeystoSociety()
		else
			ESX.ShowNotification(_U('not_boss'))
		end
	end, false)
end

if Config.BossCanWithDrawVehicle then

	RegisterCommand(Config.CommandToTakeFromSociety, function()
		
		if Config.OnlyGradeCanTake and ESX.PlayerData.job.grade_name == Config.GradeToTakeFromSociety then
			getSocietyVehicle()
		elseif Config.OnlyGradeCanTake == false then
			getSocietyVehicle()
		else
			ESX.ShowNotification(_U('not_boss'))
		end
		
	end, false)
	
	function getSocietyVehicle()
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
	
		if IsPedInAnyVehicle(playerPed,  false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)			
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 7.0, 0, 70)
		end
	
		local plate = tostring(GetVehicleNumberPlateText(vehicle))
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
	
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos_societypersonal', {
			title    = _U('withdrawing_car'),
			align    = 'left',
			elements = {
				{label = _U('no'), value = 0},
				{label = _U('no'),   value = 1},
				{label = _U('yes'),   value = 'yes'},
				{label = _U('no'), value = 2},
				{label = _U('no'), value = 3},
			}}, function(data, menu)
			menu.close()
	
			if data.current.value == 'yes' then
					ESX.TriggerServerCallback('esx_advancedgarage:requestSocietyCars', function(isOwnedVehicle)
						if isOwnedVehicle then
							ESX.ShowNotification(_U('withdrawing_car'))
							TriggerServerEvent('esx_advancedgarage:setVehiclePersonalyOwned', vehicleProps)
						end
				end, plate)
			end
		end)
	end
end

function DrawText3Dx(x,y,z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
      SetTextScale(0.65, 0.41)
      SetTextFont(13)
  
      SetTextDropshadow(10, 100, 100, 100, 255)
      SetTextProportional(1)
      SetTextColour(255, 255, 255, 215)
      SetTextEntry("STRING")
      SetTextCentre(1)
      AddTextComponentString(text)
      DrawText(_x,_y)
        local factor = (string.len(text)) / 250
        DrawRect(_x,_y+0.0135, 0.025+ factor, 0, 0, 0, 0, 68)
    end
end
