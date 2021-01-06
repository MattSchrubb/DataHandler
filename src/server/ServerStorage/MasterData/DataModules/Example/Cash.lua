-- !!!!! README !!!!! --
-- PLACE THIS UNDER THE DATA MODULES FOLDER FOR IT TO WORK --




----- Loaded Modules -----



----- Private Variables -----

--[[
	WARNING MAKE SURE THE KEYS ARE DIFFERENT FROM ANY OTHER _replicateData OR _privateData!!!
	
	_privateData can be utilized as a way to store server sided player data that will be
		saved in the Data Store, but won't be replicated to the client unlike _replicatedData.
]]
local _replicatedData = {
	Cash = 0
}

local _privateData = {
	
}

----- Public Variables -----

local Cash = {}

----- Private Functions -----

--[[
	WARNING: THIS FUNCTION IS REQUIRED IF YOU WANT IT TO BE A PART OF THE DEFAULT DATA STRUCTURE!!!
	Description:
		Function that returns the name and default data for this data type.
]]
function Cash:_GetDefaultData()
	return _replicatedData, _privateData
end

----- Public Functions -----

--[[
	Function that adds amt to the player's Temp value.
]]
function Cash:GiveCash(player, player_profile, value)
	player_profile:UpdateValue("Cash", function(old_value)
		return old_value + value
	end)
	
	-- Does the same thing as ^
	--local cash = player_profile:GetValue("Cash")
	--player_profile:SetValue("Cash", cash + value)
end

----- Initialize -----

return Cash