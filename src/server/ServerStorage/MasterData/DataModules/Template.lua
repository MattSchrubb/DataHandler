--[[
	This module is meant as a template for any data you are wanting to store and change in the server.
]]

----- Loaded Modules -----




local Remotes = game.ReplicatedStorage:WaitForChild("RemoteMessages")




----- Private Variables -----




local defaultData = {
	["Template"] = 5,
}
-- WARNING MAKE SURE THE KEYS ARE DIFFERENT FROM ANY OTHER DEFAULT OR TEMP DATA
--[[
	 TempData can be utilized as global data. Where every player's TempData variable is the same
	 Meaning that you can set the tempData value whenever you want and every player joining will have the new data.
	 Ex:
		 GameMode = "Intermission" -- Start value
		 -- 1 minute late the fight starts
		 GameModeHandler:SetGameMode("Battle") -- This function will set the GameMode variable's value to "Battle" and update it for every player
													 utilizing the _UpdateAll() function
		 -- Now every player that joins will automatically have their GameMode variable set to "Battle" until changed
]]
local tempData = {
	["TempData"] = 10
}




----- Public Variables -----




local Template = {}




----- Private Functions -----




--[[
	WARNING: THIS FUNCTION IS REQUIRED IF YOU WANT IT TO BE A PART OF THE DEFAULT DATA STRUCTURE
	Description:
		Function that returns the name and default data for this data type
]]
function Template:_GetDefaultData()
	return defaultData
end




--[[
	WARNING: THE DATA PASSED FROM HERE MUST NOT HAVE THE SAME NAME AS ANY OTHER DEFAULT OR TEMP DATA
	Description:
		Function that returns the name and default data for each data type the won't be saved
]]
function Template:_GetTempData()
	return tempData
end




--[[
	Description:
		Function called when the data of a player's profile is changed.
		Fires the UpdatePlayerEv function with the data name, and newData value
]]
local function _Update(plr, dataName, newData)
	Remotes.UpdatePlayerDataEv:FireClient(plr, dataName, newData)
end




--[[
	Description:
		Function called when the data of all players' profiles are changed.
			Main use is for Global Data changes as metioned above for tempData.
		Fires the UpdatePlayerEv function with the data name, and newData value.
]]
local function _UpdateAll(dataName, newData)
	Remotes.UpdateAllEv:Fire(dataName, newData)
	Remotes.UpdatePlayerDataEv:FireAllClients(dataName, newData)
end




----- Public Functions -----




--[[
	Description:
		Function that checks if the given profile's Template data is
			equal to val.
]]
function Template:TemplateEquals(plr, profile, val)
	-- Get the profile's Data
	local data = profile.Data
	-- Compare the Template index's value to val
	if data.Template == val then
		print(plr)
	end
end




--[[
	Function to add a value to the player's Template value and update it
]]
function Template:AddToTemplate(plr, profile, amt)
	-- Get the profile's Data
	local data = profile.Data
	-- Increment the Template index in data by amt
	data.Template = data.Template + amt
	-- Fire to the client that its "Template" value was changed
	_Update(plr, "Template", data.Template)
end




--[[
	Function that returns a palyer's Template value
]]
function Template:GetTemplate(plr, profile)
	-- Get the profile's Data
	local data = profile.Data
	-- Return the data's Template value
	return data.Template
end




--[[
	Function that is passed a table of players indexed numerically and prints out
		the player with the highest Template value.
]]
function Template:CompareTemplates(players, profiles)
	local highestPlr,highestData = false, false

	-- Iterrate through all players
	for _,plr in pairs(players) do
		-- Get the player's profile data
		local data = profiles[plr].Data

		if not highestPlr then
			highestPlr = plr
			highestData = data
		else
			if data.Template > highestData.Template then
				highestPlr = plr
				highestData = data
			end
		end
	end

	print(highestPlr.Name .. " has the highest Template value: " .. highestData.Template)
end




--[[
	Function that changes the value of TempData and updates it for all clients.
		This allows joining players to have the updated value of tempData["TempData"] as well.
]]
function Template:ManipulateTempData(players, profiles, val)
	tempData["TempData"] = val
	_UpdateAll("TempData", tempData["TempData"])
end




----- Initiate -----

return Template