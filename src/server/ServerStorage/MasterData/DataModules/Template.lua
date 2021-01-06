--[[
	README:
		In order for data to actually be changed you MUST call one of these functions:
			player_profile:SetValue(path [string], new_value [any])
			player_profile:SetValues(path [string], {key = new_value} [dictionary])
			player_profile:UpdateValue(path [string], function(old_value) return new_value end [function] -> [any])
			player_profile:UpdateValues(path [string], function(old_value) return {key = new_value} end [function] -> [dictionary])
]]

----- Loaded Modules -----



----- Private Variables -----

--[[
	WARNING MAKE SURE THE KEYS ARE DIFFERENT FROM ANY OTHER _replicateData OR _privateData!!!
	
	_privateData can be utilized as a way to store server sided player data that will be
		saved in the Data Store, but won't be replicated to the client unlike _replicatedData.
]]
local _replicatedData = {
	Temp = 0
}

local _privateData = {
	PrivateTemp = 10
}

----- Public Variables -----

local Template = {}

----- Private Functions -----

--[[
	WARNING: THIS FUNCTION IS REQUIRED IF YOU WANT IT TO BE A PART OF THE DEFAULT DATA STRUCTURE!!!
	Description:
		Function that returns the name and default data for this data type.
]]
function Template:_GetDefaultData()
	return _replicatedData, _privateData
end

----- Public Functions -----

--[[
	Function that adds amt to the player's Temp value.
]]
function Template:AddToTemp(player, player_profile, amt)
	player_profile:UpdateValue("Temp", function(old_value)
		return old_value + amt
	end)

	-- Does the same thing as ^
	--player_profile:SetValue("Temp", player_profile.Temp + value)
end

--[[
	Function that is passed a table of players indexed numerically and prints out
		the player with the highest Temp value.
]]
function Template:CompareTemps(players, player_profiles)
	local highestPlr,highestTemp = false, false

	-- Iterrate through all players
	for i,plr in pairs(players) do
		-- Get the player's profile data
		local temp = player_profiles[plr].Temp
		
		if not highestPlr then
			highestPlr = plr
			highestTemp = temp
		else
			if temp > highestTemp then
				highestPlr = plr
				highestTemp = temp
			end
		end
	end

	print(highestPlr.Name .. " has the highest Temp value: " .. highestTemp)
end

--[[
	Function that returns a random number between min and max.
]]
function Template:GenerateRandomNumber(min, max)
	return math.random(min, max)
end

----- Initialize -----

return Template