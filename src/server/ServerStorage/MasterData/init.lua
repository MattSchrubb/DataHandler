----- GLOBALS -----

local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

----- Loaded Modules -----

local ProfileService = require(script:WaitForChild("ProfileService"))
local Remotes = game.ReplicatedStorage:WaitForChild("RemoteMessages")
local HelperFns = game.ReplicatedStorage:WaitForChild("HelperFns")

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
	if mod.Name ~= "ProfileService" then
		DataModules[mod.Name] = require(mod) -- Itterate through every child module and add it to the list
	end
end

----- Private Variables -----

local ProfileTemplate
local ProfileMockTemplate
local PlayerProfileStore
local PlayerMockProfileStore

local DataVersion = "0.0.1" 
--print("DATA VERSION: " .. DataVersion)

local Profiles = {} -- [player] = profile


--[[
	Description:
		Sets up a metatable that when indexed, will first search through
		itself to find the index being referenced, otherwise it will search 
		through all DataModules until it finds the first matching index.
]]
local MasterData = setmetatable({}, {__index = function(tbl, index)
	--print(index)
	
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
			return func(_, plr, profile, ...)
		else
			return func(_, plr, ...) -- plr is 
		end
	end
end})


local Players = game:GetService("Players")

----- Public Variables -----



----- Private Functions -----

-- Function that shallow copys a table
-- http://lua-users.org/wiki/CopyTable
local function clone(tbl)
	local t = {}
	
	for key, value in pairs(tbl) do
		if typeof(value) == "table" then
			t[key] = clone(value)
		else
			t[key] = value
		end
	end

	return t
end

--[[
	Description:
		Function that compares the profile with DataVersion and updates it accordingly
			if the profile is outdated
]]
local function CheckIfProfileNeedsUpdate(profile)
	--if G.DEBUG then
	--	--Add in new data
	--	for dataName, defaultData in pairs(ProfileTemplate) do
	--		profile.Data[dataName] = defaultData
	--	end
	--elseif not profile:GetMetaTag("DataVersion") then
	if not profile:GetMetaTag("DataVersion") then
		-- First time setting up profile
		profile:SetMetaTag("DataVersion", DataVersion)
		--print("New Player's Profile has been setup with DataVersion: " .. profile:GetMetaTag("DataVersion"))
	elseif profile:GetMetaTag("DataVersion") ~= DataVersion then
		--Remove unused/old data
		for dataName,_ in pairs(profile.Data) do
			if ProfileTemplate[dataName] == nil then
				profile.Data[dataName] = nil
				--print("Removed " .. dataName)
			end
		end
		--Add in new data
		for dataName, defaultData in pairs(ProfileTemplate) do
			if profile.Data[dataName] == nil then
				profile.Data[dataName] = defaultData
			end
		end
		
		profile:SetMetaTag("DataVersion", DataVersion)
		--print("Profile has been updated to new DataVersion: " .. profile:GetMetaTag("DataVersion"))
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
	local retries = 30
	while retries > 0 and not Profiles[plr] do
		retries = retries - 1
		wait()
	end
	
	if not Profiles[plr] then
		warn("Profile could not be found")
		return {}
	end
	
	local profile = Profiles[plr].Profile
	local mockProfile = Profiles[plr].Mock
	
	if profile then
		return profile.Data, mockProfile.Data
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
	
	local tempData = {
		
	}
	
	for _,mod in pairs(DataModules) do -- Search through each DataModule
		if mod["_GetDefaultData"] then
			for _dataName, _data in pairs(mod:_GetDefaultData()) do -- Loop through the table for all name,default pairs
				defaultData[_dataName] = _data
			end
		end
		
		if mod["_GetTempData"] then
			for _dataName, _data in pairs(mod:_GetTempData()) do
				tempData[_dataName] = _data
			end
		end
	end
	
	return defaultData, tempData
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
	
	local mockProfile = PlayerMockProfileStore.Mock:LoadProfileAsync(
		"Player_" .. plr.UserId, 
		"ForceLoad"
	)
	
	if profile ~= nil then
		profile:ListenToRelease(function() -- Setup a Release listener for when the player's Profile is released
			Profiles[plr] = nil
			
			plr:Kick() -- Kick the player to prevent any data loss
		end)
		
		if plr:IsDescendantOf(Players) == true then -- Check if the player is a descendant of Players
			local _Data = setmetatable({}, {
				__index = function(t, key)
					if profile.Data[key] then
						return profile.Data[key]
					elseif mockProfile.Data[key] then
						return mockProfile.Data[key]
					end
				end,
				__newindex = function(t, key, val)
					if typeof(val) == "table" then
						val = clone(val)
					end
					
					if profile.Data[key] then
						profile.Data[key] = val
					elseif mockProfile.Data[key] then
						mockProfile.Data[key] = val
					else
						warn("NO KEY FOUND WARNING: '" .. key .. "' not found in " .. plr.Name .. "'s Profile or MockProfile! Setting it up now!")
						mockProfile.Data[key] = val
					end
				end
			})
			
			local profileMT = setmetatable({Profile = profile, Mock = mockProfile}, {
				__index = function(t, key)
					if key == "Data" then
						return _Data
					elseif profile[key] then
						return profile[key]
					end
				end,
				__newindex = function(t, key, val)
					if _Data[key] then
						_Data[key] = val
					end
				end
			})
			
			Profiles[plr] = profileMT
			
			CheckIfProfileNeedsUpdate(profileMT.Profile) -- Check if the player's profile needs to be updated
		else
			profile:Release() -- If the player left, release it's profile
			PlayerProfileStore.Mock:WipeProfile("Player_" .. plr.UserId)
			
			Profiles[plr] = nil
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
	local profile = Profiles[plr].Profile
	
	if profile ~= nil then -- If the player's profile exists in this server
		profile:Release() -- Release it
		PlayerProfileStore.Mock:WipeProfile("Player_" .. plr.UserId) -- Release mock profile to prevent memory leaks
		
		Profiles[plr] = nil
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
Remotes:WaitForChild("GetAllPlayerDataFn").OnServerInvoke = function(plr)
	local profileData, mockData = MasterData:GetProfileData(plr)
	local tbl = {}
	
	for i,v in pairs(profileData) do
		tbl[i] = v
	end
	
	for i,v in pairs(mockData) do
		tbl[i] = v
	end
	
	return tbl
end

----- Initialize -----

--[[
	We initialize this here so MasterData can get all setup before calling
	MasterData:GetDefaultData()
]] 
ProfileTemplate, ProfileMockTemplate = MasterData:GetDefaultData()
PlayerProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)
PlayerMockProfileStore = ProfileService.GetProfileStore(
	"PlayerMockData",
	ProfileMockTemplate
)

return MasterData
