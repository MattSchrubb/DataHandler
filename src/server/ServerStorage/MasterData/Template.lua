--[[
	This module is meant as a template for any data you are wanting to store and change in the server.
]]

----- Loaded Modules -----

local Remotes = require(game.ReplicatedStorage:WaitForChild("Remotes"))
local HelperFns = require(game.ReplicatedStorage:WaitForChild("HelperFns"))

----- Private Variables -----



----- Public Variables -----

local Template = {}
Template.__index = Template
----- Private Functions -----

--[[
	WARNING: THIS FUNCTION IS REQUIRED IF YOU WANT IT TO BE A PART OF THE DEFAULT DATA STRUCTURE
	Description:
		Function that returns the name and default data for this data type
]]
function Template:_GetDefaultData()
	local dataName = "Template"

	local defaultData = 5 
	--[[
		OR if there are multiple parts to this data structure then

		local dataName = {"Template Data Item 1", "Template Data Item 2"}

		local defaultData = {}
		defaultData["Template Data Item 1"] = "Temp1"
		defaultData["Template Data Item 2"] = "Temp2"

		Make sure your Keys are the same!!!
	]]

	return dataName, defaultData
end

--[[
	Description:
		Function called when the data of a player's profile is changed.
		Fires the UpdatePlayerEv function with the data name, and newData value
]]
local function _Update(plr, newData)
	Remotes.UpdatePlayerDataEv:FireClient(plr, "Template", newData)
end

----- Public Functions -----

--[[
	Description:
		Function that checks if the given profile's Template data is
			equal to otherData.
]]
function Template:TemplateFunc(plr, profile, otherData)
	if profile.Data.Template == otherData then
		print(plr)
	end
end

--[[
	Function to add a value to the player's Template value and update it
]]
function Template:AddToTemplate(plr, profile, amt)
	profile.Data.Template = profile.Data.Template + amt
	_Update(plr, profile.Data.Template)
end

----- Initiate -----

return Template