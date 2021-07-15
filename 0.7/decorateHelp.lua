-- decorateHelp - Release 5 custom - For tes3mp v0.7.0-alpha
-- To be used with kanaFurniture release 5 custom that features minor QoL changes and selected object highlighting
-- Alter positions of items using a GUI
-- Added option to align selected object with another

--[[ INSTALLATION:
1) Save this file as "decorateHelp.lua" in server/scripts/custom
2) Add [ decorateHelp = require("custom.decorateHelp") ] to customScripts.lua
]]

------
local config = {}

config.MainId = 31359
config.PromptId = 31360
config.ScaleMin = 0.5
config.ScaleMax = 2.0

config.AlignId = 31361
config.ChooseAlignObjectId = 31362

------

local Methods = {}

tableHelper = require("tableHelper")

--
Methods.playerSelectedObject = {}
local playerCurrentMode = {}

local playerAlignOptions = {}
Methods.playerSelectedAlignObject = {}

local playerActionHistory = {}
--

local function resendPlaceToAll(refIndex, cell)
	local object = kanaFurniture.getObject(refIndex, cell)
	
	if not object then
		return false
	end
	
	local refId = object.refId
	local count = object.count or 1
	local charge = object.charge or -1
	local posX, posY, posZ = object.location.posX, object.location.posY, object.location.posZ
	local rotX, rotY, rotZ = object.location.rotX, object.location.rotY, object.location.rotZ
	local refIndex = refIndex
	local scale = object.scale or 1
	
	local inventory = object.inventory or nil
	
	local splitIndex = refIndex:split("-")
	
	for pid, pdata in pairs(Players) do
		if Players[pid]:IsLoggedIn() then
			--First, delete the original
			tes3mp.InitializeEvent(pid)
			tes3mp.SetEventCell(cell)
			tes3mp.SetObjectRefNumIndex(0)
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.AddWorldObject() --?
			tes3mp.SendObjectDelete()
			
			--Now remake it
			tes3mp.InitializeEvent(pid)
			tes3mp.SetEventCell(cell)
			tes3mp.SetObjectRefId(refId)
			tes3mp.SetObjectCount(count)
			tes3mp.SetObjectCharge(charge)
			tes3mp.SetObjectPosition(posX, posY, posZ)
			tes3mp.SetObjectRotation(rotX, rotY, rotZ)
			tes3mp.SetObjectRefNumIndex(0)
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.SetObjectScale(scale)
			if inventory then
				for itemIndex, item in pairs(inventory) do
					tes3mp.SetContainerItemRefId(item.refId)
					tes3mp.SetContainerItemCount(item.count)
					tes3mp.SetContainerItemCharge(item.charge)

					tes3mp.AddContainerItem()
				end
			end
			
			tes3mp.AddWorldObject()
			tes3mp.SendObjectPlace()
			tes3mp.SendObjectScale()
			if inventory then
				tes3mp.SendContainer()
			end
		end
	end
	
	-- Make sure to save a scale packet if this object has a non-default scale.
	if scale ~= 1 then
		tableHelper.insertValueIfMissing(LoadedCells[cell].data.packets.scale, refIndex)
	end
	LoadedCells[cell]:QuicksaveToDrive() --Not needed, but it's nice to do anyways
end

--Align functions
local function OnPlayerAuthentifiedHandler(pid)
	if not playerActionHistory[pid] then playerActionHistory[pid] = {} end
end

local function chooseAlignObjectGUI(pid)
	local pname = tes3mp.GetName(pid)
	
	local cell = tes3mp.GetCell(pid)
	local options = kanaFurniture.PlacedInCell(pname, cell)
	
	local list = "* CLOSE *\n"
	local newOptions = {}
	
	if options and #options > 0 then
		for i = 1, #options do
			--Make sure the object still exists, and get its data
			local object = kanaFurniture.getObject(options[i], cell)
			
			if object and options[i] ~= Methods.playerSelectedObject[pname] then -- Object exists and is not selected
				local furnData = kanaFurniture.FurnitureData(object.refId)
				
				list = list .. furnData.name .. " (at " .. math.floor(object.location.posX + 0.5) .. ", "  ..  math.floor(object.location.posY + 0.5) .. ", " .. math.floor(object.location.posZ + 0.5) .. ")"
				if not(i == #options) then
					list = list .. "\n"
				end
				
				table.insert(newOptions, {refIndex = options[i], refId = object.refId})
			end
		end
	end
	
	playerAlignOptions[pname] = newOptions
	tes3mp.ListBox(pid, config.ChooseAlignObjectId, "Choose a piece of furniture to align selected object with.", list)
end

local function onChooseAlignObject(pid, loc)
	local pname = tes3mp.GetName(pid)
	local cell = tes3mp.GetCell(pid)
	Methods.playerSelectedAlignObject[pname] = playerAlignOptions[pname][loc].refIndex
	
	kanaFurniture.OnStartHighlight(pid, cell, Methods.playerSelectedAlignObject[pname])
end

local function showAlignGUI(pid)
	local cell = tes3mp.GetCell(pid)
	local pname = tes3mp.GetName(pid)
	
	local selectedObject = kanaFurniture.getObject(Methods.playerSelectedObject[pname], cell)
	local alignToObject = kanaFurniture.getObject(Methods.playerSelectedAlignObject[pname], cell)
	
	if selectedObject and alignToObject then --If they have an entry and it isn't gone
		local flSelectedX = math.floor(selectedObject.location.posX + 0.5)
		local flSelectedY = math.floor(selectedObject.location.posY + 0.5)
		local flAlignX = math.floor(alignToObject.location.posX + 0.5)
		local flAlignY = math.floor(alignToObject.location.posY + 0.5)
		local message = "Offset X: " .. tostring(math.abs(flSelectedX - flAlignX)) .. "\nOffset Y: " .. tostring(math.abs(flSelectedY - flAlignY))
		tes3mp.CustomMessageBox(pid, config.AlignId, message, "Align X;Align Y;Align Z;Undo;Close")
	end
end

local function onAlign(pid, data)
	local cell = tes3mp.GetCell(pid)
	local selectedRefIndex = Methods.GetSelectedRefIndex(pid)
	local alignRefIndex = Methods.GetSelectedAlignRefIndex(pid)
	
	local selectedObject = kanaFurniture.getObject(selectedRefIndex, cell)
	local alignToObject = kanaFurniture.getObject(alignRefIndex, cell)

	--Temporarily save selected object's location in case of UNDO action
	playerActionHistory[pid][selectedRefIndex] = {
		location = {posX = selectedObject.location.posX, posY = selectedObject.location.posY, posZ = selectedObject.location.posZ}
	}
	
	if data == 0 then
		local alignToPosX = alignToObject.location.posX
		selectedObject.location.posX = alignToPosX
	elseif data == 1 then
		local alignToPosY = alignToObject.location.posY
		selectedObject.location.posY = alignToPosY
	elseif data == 2 then
		local alignToPosZ = alignToObject.location.posZ
		selectedObject.location.posZ = alignToPosZ
	end
	
	resendPlaceToAll(selectedRefIndex, cell)
end

local function onAlignUndo(pid)
	local cell = tes3mp.GetCell(pid)
	local selectedRefIndex = Methods.GetSelectedRefIndex(pid)
	local selectedObject = kanaFurniture.getObject(selectedRefIndex, cell)

	if playerActionHistory[pid][selectedRefIndex] then
		selectedObject.location.posX = playerActionHistory[pid][selectedRefIndex].location.posX
		selectedObject.location.posY = playerActionHistory[pid][selectedRefIndex].location.posY
		selectedObject.location.posZ = playerActionHistory[pid][selectedRefIndex].location.posZ

		resendPlaceToAll(selectedRefIndex, cell)
		playerActionHistory[pid][selectedRefIndex] = nil
	end
end

-----------

local function showPromptGUI(pid)
	local message = "[" .. playerCurrentMode[tes3mp.GetName(pid)] .. "] - Enter a number."
	local pname = tes3mp.GetName(pid)
	local cell = tes3mp.GetCell(pid)
	
	if playerCurrentMode[pname] == "Fine Tune Scale" then
		local object = kanaFurniture.getObject(Methods.playerSelectedObject[pname], cell)
		local scale = object.scale or 1
		tes3mp.InputDialog(pid, config.PromptId, message, "Current scale: " .. scale .. "\nMinimum value: " .. config.ScaleMin .. "\nMaximum value: " .. config.ScaleMax)
	else
		tes3mp.InputDialog(pid, config.PromptId, message, "Enter a number to add/subtract.\nPositives increase.\nNegatives decrease.")
	end
end

local function onEnterPrompt(pid, data)
	local cell = tes3mp.GetCell(pid)
	local pname = tes3mp.GetName(pid)
	local mode = playerCurrentMode[pname]
	local data = tonumber(data) or 0
	
	local object = kanaFurniture.getObject(Methods.playerSelectedObject[pname], cell)
	
	if not object then
		--The object no longer exists, so we should bail out now
		return false
	end
	
	local scale = object.scale or 1
	
	if mode == "Rotate X" then
		local curDegrees = math.deg(object.location.rotX)
		local newDegrees = (curDegrees + data) % 360
		object.location.rotX = math.rad(newDegrees)
	elseif mode == "Rotate Y" then
		local curDegrees = math.deg(object.location.rotY)
		local newDegrees = (curDegrees + data) % 360
		object.location.rotY = math.rad(newDegrees)
	elseif mode == "Rotate Z" then
		local curDegrees = math.deg(object.location.rotZ)
		local newDegrees = (curDegrees + data) % 360
		object.location.rotZ = math.rad(newDegrees)
	elseif mode == "Fine Tune North" then
		object.location.posY = object.location.posY + data
	elseif mode == "Fine Tune East" then
		object.location.posX = object.location.posX + data
	elseif mode == "Fine Tune Height" then
		object.location.posZ = object.location.posZ + data
	elseif mode == "Raise" then
		object.location.posZ = object.location.posZ + 10
	elseif mode == "Lower" then
		object.location.posZ = object.location.posZ - 10
	elseif mode == "Move East" then
		object.location.posX = object.location.posX + 10
	elseif mode == "Move West" then
		object.location.posX = object.location.posX - 10
	elseif mode == "Move North" then
		object.location.posY = object.location.posY + 10
	elseif mode == "Move South" then
		object.location.posY = object.location.posY - 10
	elseif mode == "Scale Up" then
		if scale + 0.1 <= config.ScaleMax then 
			object.scale = scale + 0.1
		end
	elseif mode == "Scale Down" then
		if scale - 0.1 >= config.ScaleMin then
			object.scale = scale - 0.1
		end
	elseif mode == "Fine Tune Scale" then
		if data <= config.ScaleMax and data >= config.ScaleMin then
			object.scale = data
		end
	elseif mode == "Align" then
		return chooseAlignObjectGUI(pid)
	elseif mode == "return" then
		object.location.posY = object.location.posY
		return
	end
	
	resendPlaceToAll(Methods.playerSelectedObject[pname], cell)
end

local function showMainGUI(pid)
	--Determine if the player has an item
	local currentItem = "None" --default
	local selected = Methods.playerSelectedObject[tes3mp.GetName(pid)]
	local object = kanaFurniture.getObject(selected, tes3mp.GetCell(pid))
	
	if selected and object then --If they have an entry and it isn't gone
		currentItem = object.refId .. " (" .. selected .. ")"
	end
	
	local message = "Select an option. Your current item is: " .. currentItem
	tes3mp.CustomMessageBox(pid, config.MainId, message, "Select Furniture;Fine Tune North;Fine Tune East;Fine Tune Height;Rotate X;Rotate Y;Rotate Z;Raise;Lower;Move East;Move West;Move North;Move South;Scale Up;Scale Down;Fine Tune Scale;Align with;Exit")
end

local function setSelectedObject(pid, refIndex)
	Methods.playerSelectedObject[tes3mp.GetName(pid)] = refIndex
end

Methods.SetSelectedObject = function(pid, refIndex)
	setSelectedObject(pid, refIndex)
end

Methods.OnObjectPlace = function(pid, cellDescription)
	--Get the last event, which should hopefully be the place packet
	tes3mp.ReadLastEvent()
	
	--Get the refIndex of the first item in the object place packet (in theory, there should only by one)
	local refIndex = tes3mp.getObjectRefNumIndex(0) .. "-" .. tes3mp.getObjectMpNum(0)
	
	--Record that item as the last one the player interacted with in this cell
	setSelectedObject(pid, refIndex)
end

Methods.OnGUIAction = function(pid, idGui, data)
	local pname = tes3mp.GetName(pid)
	
	if idGui == config.MainId then
		if tonumber(data) == 0 then --View Furniture Emporium
			playerCurrentMode[pname] = "Select Furniture"
			kanaFurniture.OnStopHighlight(pid, Methods.playerSelectedObject[pname])
			kanaFurniture.OnView(pid)
			return true
		elseif tonumber(data) == 1 then --Move North
			playerCurrentMode[pname] = "Fine Tune North"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 2 then --Move East
			playerCurrentMode[pname] = "Fine Tune East"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 3 then --Move Up
			playerCurrentMode[pname] = "Fine Tune Height"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 4 then --Rotate X
			playerCurrentMode[pname] = "Rotate X"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 5 then --Rotate Y
			playerCurrentMode[pname] = "Rotate Y"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 6 then --Rotate Z
			playerCurrentMode[pname] = "Rotate Z"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 7 then --,Ascend
			playerCurrentMode[pname] = "Raise"
			onEnterPrompt(pid, 0)			
			return true, showMainGUI(pid)
		elseif tonumber(data) == 8 then --Descend
			playerCurrentMode[pname] = "Lower"
			onEnterPrompt(pid, 0)			
			return true, showMainGUI(pid)
		elseif tonumber(data) == 9 then --East
			playerCurrentMode[pname] = "Move East"
			onEnterPrompt(pid, 0)			
			return true, showMainGUI(pid)	
		elseif tonumber(data) == 10 then --West
			playerCurrentMode[pname] = "Move West"
			onEnterPrompt(pid, 0)			
			return true, showMainGUI(pid)
		elseif tonumber(data) == 11 then --North
			playerCurrentMode[pname] = "Move North"
			onEnterPrompt(pid, 0)			
			return true, showMainGUI(pid)
		elseif tonumber(data) == 12 then --South
			playerCurrentMode[pname] = "Move South"
			onEnterPrompt(pid, 0)
			return true, showMainGUI(pid)
		elseif tonumber(data) == 13 then -- Scale up by 0.1
			playerCurrentMode[pname] = "Scale Up"
			onEnterPrompt(pid, 0)
			return true, showMainGUI(pid)
		elseif tonumber(data) == 14 then -- Scale down by 0.1
			playerCurrentMode[pname] = "Scale Down"
			onEnterPrompt(pid, 0)
			return true, showMainGUI(pid)
		elseif tonumber(data) == 15 then -- Scale
			playerCurrentMode[pname] = "Fine Tune Scale"
			showPromptGUI(pid)
			return true
		elseif tonumber(data) == 16 then -- Align
			--Exit if no object selected prior to this menu
			if not Methods.GetSelectedRefIndex(pid) then
				showMainGUI(pid)
			else
				playerCurrentMode[pname] = "Align"
				onEnterPrompt(pid, 0)
			end
			return true 
		elseif tonumber(data) == 17 then --Exit
			--Do nothing
			kanaFurniture.OnStopHighlight(pid, Methods.playerSelectedObject[pname])
			return true
		end
	elseif idGui == config.PromptId then
		if data ~= nil and data ~= "" and tonumber(data) then
			onEnterPrompt(pid, data)
		end
		
		playerCurrentMode[tes3mp.GetName(pid)] = nil
		return true, showMainGUI(pid)
	elseif idGui == config.ChooseAlignObjectId then
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
			showMainGUI(pid)
			return true
		else
			onChooseAlignObject(pid, tonumber(data))
			showAlignGUI(pid)
			return true
		end
	elseif idGui == config.AlignId then
		if tonumber(data) == 3 then
			onAlignUndo(pid)
			showAlignGUI(pid)
			return true
		elseif tonumber(data) == 4 then
			kanaFurniture.OnStopHighlight(pid, Methods.playerSelectedAlignObject[pname])
			Methods.playerSelectedAlignObject[pname] = nil
			showMainGUI(pid)
			return true
		else
			onAlign(pid, tonumber(data))
			showAlignGUI(pid)
			return true
		end
	end
end

Methods.OnPlayerCellChange = function(pid)
	Methods.playerSelectedObject[tes3mp.GetName(pid)] = nil
	Methods.playerSelectedAlignObject[tes3mp.GetName(pid)] = nil
end

Methods.OnCommand = function(pid)
	local cell = tes3mp.GetCell(pid)
	local refIndex = Methods.GetSelectedRefIndex(pid)
	if refIndex then
		kanaFurniture.OnStartHighlight(pid, cell, refIndex)
	end
	showMainGUI(pid)
end

Methods.GetSelectedRefIndex = function(pid)
	local pname = tes3mp.GetName(pid)
	return Methods.playerSelectedObject[pname]
end

Methods.GetSelectedAlignRefIndex = function(pid)
	local pname = tes3mp.GetName(pid)
	return Methods.playerSelectedAlignObject[pname]
end

customCommandHooks.registerCommand("decorator", function(pid, cmd) decorateHelp.OnCommand(pid) end)
customCommandHooks.registerCommand("decorate", function(pid, cmd) decorateHelp.OnCommand(pid) end)
customCommandHooks.registerCommand("dh", function(pid, cmd) decorateHelp.OnCommand(pid) end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	OnPlayerAuthentifiedHandler(pid)
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	decorateHelp.OnGUIAction(pid, idGui, data)
end)

customEventHooks.registerHandler("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
	decorateHelp.OnObjectPlace(pid, cellDescription)
end)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, previousCellDescription, currentCellDescription)
	decorateHelp.OnPlayerCellChange(pid)
end)

return Methods
