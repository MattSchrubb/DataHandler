----- GLOBALS -----

local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

----- Loaded Modules -----

local ProfileService = require(game.ServerStorage:WaitForChild("ProfileService"))
local Remotes = require(game.ReplicatedStorage:WaitForChild("Remotes"))
local HelperFns = require(game.ReplicatedStorage:WaitForChild("HelperFns"))


--[[
	DATA MODULES:
		These are used to add functionality to your data. It also helps
			from cluttering up this script.

		There is a provided Template module that shows how to set up
			and use your own custom data types.

		WARNING:
			Make sure that you don't have multiple of the same public
			functions throughout all your DataModules.
			If you do, MasterData doesn't know what to call, and will
			fire the first one it comes by :/
]]
local DataModules = {}
for _,mod in pairs(script:GetChildren()) do
	DataModules[mod.Name] = require(mod) -- Itterate through every child module and add it to the list
end

----- Private Variables -----

local ProfileTemplate
local PlayerProfileStore

local DataVersion = "0.0.1"

local Profiles = {} -- [player] = profile


--[[
	Description:
		Sets up a metatable that when indexed, will first search through
		itself to find the index being referenced, otherwise it will search 
		through all DataModules until it finds the first matching index.
]]
local MasterData = setmetatable({}, {__index = function(tbl, index)
	print(index)

	local func
	for _,v in pairs(DataModules) do
		if v[index] then
			if type(v[index]) ~= "function" then -- Checks if the index is not a function
				return v[index]
			else
				func = v[index] -- Setup the function to be returned
				break
			end
		end
	end

	return function(_, plr, ...) -- Returns a function that calls func with plr, profile, ...
		if typeof(plr) == "Instance" and plr:IsA("Player") then -- Check if a Player is being passed to get the Profile
			local profile = Profiles[plr]
			func(_, plr, profile, ...)
		else
			func(_, plr, ...)
		end
	end
end})


local Players = game:GetService("Players")

----- Public Variables -----



----- Private Functions -----

--[[
	Description:
		Function that compares the profile with DataVersion and updates it accordingly
			if the profile is outdated
]]
local function CheckIfProfileNeedsUpdate(profile)
	if not profile:GetMetaTag("DataVersion") then
		-- First time setting up profile
		profile:SetMetaTag("DataVersion", DataVersion)
		print("New Player's Profile has been setup with DataVersion: " .. profile:GetMetaTag("DataVersion"))
	elseif profile:GetMetaTag("DataVersion") ~= DataVersion then
		--Remove unused/old data
		for dataName,_ in pairs(profile.Data) do
			if ProfileTemplate[dataName] == nil then
				profile.Data[dataName] = nil
				print("Removed " .. dataName)
			end
		end
		--Add in new data
		for dataName, defaultData in pairs(ProfileTemplate) do
			if profile.Data[dataName] == nil then
				profile.Data[dataName] = defaultData
			end
		end

		profile:SetMetaTag("DataVersion", DataVersion)
		print("Profile has been updated to new DataVersion: " .. profile:GetMetaTag("DataVersion"))
	end
end

----- Public Functions -----
--[[
	WARNING:
		ProfileService functionality that doesn't have to do with 'profile.Data' should
			should be handled here.

		You will still have access to the entire Profile in DataModules functions.
]]



--[[
	Description:
		Function that gets the player's profile and returns its Data table.
	Returns:
		Table of player's profile data
]]
function MasterData:GetProfileData(plr)
	local profile = Profiles[plr]

	if profile then
		return profile.Data
	end
end

--[[
	Description:
		Function that returns a table with default data from all DataModule modules.
		Each module should have an _GetDefaultData function if it will be used to
			as a data type reference.
	Returns:
		Table of default data
]]
function MasterData:GetDefaultData()
	local defaultData = {
		--[[
			Place here any data you want saved that wont be set up
				through the DataModules.
		]]
	}

	for _,mod in pairs(DataModules) do -- Search through each DataModule
		if mod["_GetDefaultData"] then
			for _dataName, _data in pairs(mod:_GetDefaultData()) do -- Loop through the table for all name,default pairs
				defaultData[_dataName] = _data
			end
		end
	end

	return defaultData
end

--[[
	Description:
		Function called when a player is added to the game.
		This function handles the setup of the players Profile.
]]
function MasterData:OnPlayerAdded(plr)
	local profile = PlayerProfileStore:LoadProfileAsync(
		"Player_" .. plr.UserId,
		"ForceLoad"
	)

	if profile ~= nil then
		profile:ListenToRelease(function() -- Setup a Release listener for when the player's Profile is released
			Profiles[plr] = nil

			plr:Kick() -- Kick the player to prevent any data loss
		end)

		if plr:IsDescendantOf(Players) == true then -- Check if the player is a descendant of Players
			Profiles[plr] = profile

			CheckIfProfileNeedsUpdate(profile) -- Check if the player's profile needs to be updated
		else
			profile:Release() -- If the player left, release it's profile
		end
	else
		plr:Kick()
	end
end

--[[
	Description:
		Function called when a player is being removed from the game
]]
function MasterData:OnPlayerRemoving(plr)
	local profile = Profiles[plr]

	if profile ~= nil then -- If the player's profile exists in this server
		profile:Release() -- Release it
	end
end

----- Connections -----
--[[
	Description:
		Connections are used to recieve messages from the client and do something with it.

		I typically denote RemoteFunctions with an Fn at the end, and
			RemoteEvents with an Ev at the end so I know what I'm
			working with.
]]


--[[
	Description:
		Event Fired when the player is asking for All of its data.
	Returns:
		Table of player's Profile data
]]
Remotes.GetAllPlayerDataFn.OnServerInvoke = function(plr)
	local profile = Profiles[plr]

	if profile then
		return profile.Data
	end
end

----- Initialize -----

--[[
	We initialize this here so MasterData can get all setup before calling
	MasterData:GetDefaultData()
]] 
ProfileTemplate = MasterData:GetDefaultData()
PlayerProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)

return MasterData
