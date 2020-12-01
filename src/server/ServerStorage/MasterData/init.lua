----- Loaded Modules -----

local _Addons = script:WaitForChild("_Addons")
local ProfileService = require(_Addons:WaitForChild("ProfileService"))
local Promise = require(_Addons:WaitForChild("Promise"))

local debug = true
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
local _cachedFunctions = {}
for _,mod in pairs(script:GetChildren()) do
	if mod.Name == "_Addons" or (mod.Name == "Template" and not debug) then
		-- do nothing
	else
		DataModules[mod.Name] = require(mod)
		for index,var in pairs(DataModules[mod.Name]) do
			if type(var) == "function" and index ~= "_GetDefaultData" and index ~= "_GetTempData" and index ~= "_GetResetableData" then
				_cachedFunctions[index] = {modName = mod.Name, mod = DataModules[mod.Name], func = var}
			end
		end
	end
end

----- Private Variables -----

local Remotes = game.ReplicatedStorage:WaitForChild("RemoteMessages")

--[[
	Description:
		Used to determine the current version of players' data.
		When changed, will attempt to correct each player's data
			by resetting keys that are defined to be reset, removing
			keys that have been removed, or adding new keys.
	WARNING:
		Changing to an older version will not revert the data.
]]
local DataVersion = "0.0.1"




-- TODO: Add a data version management system
--[[
	Each profile will store it's previous DataVersion

	PlayerDataVersions = {
		Data = {
			["0.0.1"] = true,
		}
		MetaTags = {
			DataVersion = "0.0.2"
		}
	}

	PlayerData_0.0.1 = {
		Data = {}
	}

	When updating, it will take the player's current version and save it to the new version, and update it.

	PlayerDataVersions = {
		Data = {
			["0.0.1"] = true,
			["0.0.2"] = true,
		}
		MetaTags = {
			DataVersion = "0.0.2"
		}
	}

	PlayerData_0.0.2 = {
		Data = { t = 5 }
	}

	When reverting to older data, it will check if specified player had data set up while that version was active.
	If not, it will find the closest version, take that data, and update it to whatever you have now.

	PlayerDataVersions = {
		Data = {
			["0.0.1"] = true,
			["0.0.2"] = true,
		}
		MetaTags = {
			DataVersion = "0.0.1"
		}
	}

	PlayerData_0.0.1 = {
		Data = {}
	}

	Any further updates to the data version will cause an override of the data if it was reverted from that version.
	Alternatively, we can just set it up to reuse the data already there, but i'm not sure that's the best way.
]]




--[[
	Description:
		DefaultData - is a table containing the default values for data being stored in ProfileService.
		TempData - is a table containing the default values for data that won't be stored in ProfileService,
					but is rather used in the MockProfile that gets set up every time they join.
		ResetableData - is a table containing keys coinciding with DefaultData that will be reset
						when the DataVersion is changed causing an update in the Profile.
]]


local function GetDefaultData()
	local DefaultData = {}
	for _,mod in pairs(DataModules) do
		if mod["_GetDefaultData"] then
			for _dataName,_data in pairs(mod:_GetDefaultData()) do
				DefaultData[_dataName] = _data
			end
		end
	end
	return DefaultData
end

local function GetTempData()
	local TempData = {}
	for _,mod in pairs(DataModules) do
		if mod["_GetTempData"] then
			for _dataName,_data in pairs(mod:_GetTempData()) do
				TempData[_dataName] = _data
			end
		end
	end
	return TempData
end

local _DefaultData = GetDefaultData()
-- Setup ProfileService Stores
local PlayerProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	_DefaultData
)
local PlayerMockProfileStore = ProfileService.GetProfileStore(
	"PlayerMockData",
	{}
)

-- A list of players and their profiles
local Profiles = {} -- [player] = profile


--[[
	Description:
		Sets up a metatable that when indexed, will first search through
		itself to find the index being referenced, otherwise it will search 
		through all DataModules until it finds the first matching index.
]]
local MasterData = setmetatable({}, {
	__index = function(tbl, index)
		return Promise.new(function(resolve, reject, onCancel)
			local func

			-- Check if the index is a function of one of the DataModules
			if _cachedFunctions[index] then
				func = _cachedFunctions[index].func
			elseif DataModules[index] then -- Check if you are trying to access the Module directly
				reject("You are attempting to access the module '" .. index ..  "' directly", DataModules[index])
			end
			
			if func then
				resolve(function(_, plr, ...)
					local data = ...
					return Promise.new(function(_resolve, _reject, _onCancel)

						-- Check if plr is a Player Object
						if typeof(plr) == "Instance" and plr:IsA("Player") then
							local profile = Profiles[plr]
							_resolve(func(_, plr, profile, data))
						elseif typeof(plr) == "table" then -- If plr is a table 
							local isPlayersIndex = false
							local isPlayersValue = false

							local profiles = {}

							-- Loop check through the table to make sure it's a table of Player Objects
							for i,v in pairs(plr) do
								if typeof(i) == "Instance" and i:IsA("Player") then
									if isPlayersValue then
										isPlayersValue = false
										isPlayersIndex = false
										break
									else
										isPlayersIndex = true
									end
									profiles[i] = Profiles[i]
								elseif typeof(v) == "Instance" and v:IsA("Player") then
									if isPlayersIndex then
										isPlayersIndex = false
										isPlayersValue = false
										break
									else
										isPlayersValue = true
									end
									profiles[v] = Profiles[v]
								else
									break
								end
							end
							
							-- If it is a table of players then their profiles will be sent as well, indexed by the Player
							if (isPlayersValue and not isPlayersIndex) or (isPlayersIndex and not isPlayersValue) then
								_resolve(func(_, plr, profiles, data))
							else
								_resolve(func(_, plr, data))
							end
						else
							_resolve(func(_, plr, data))
						end
					end)
					:catch(function(warning, returnVal)
						warn(warning)
						return returnVal
					end)
					:expect()
				end)
			else
				reject("WARNING: No function or Module with name '" .. index .. "' found in MasterData!!", function(...)
					warn("Attempt to call non-existing function '" .. index .. "' from MasterData!!")
				end)
			end
		end)
		:catch(function(warning, returnVal)
			warn(warning)
			return returnVal
		end)
		:expect()
	end
})

local Players = game:GetService("Players")

----- Public Variables -----



----- Private Functions -----

-- Function that shallow copys a table
-- http://lua-users.org/wiki/CopyTable
local function clone(tbl)
	local t = {}

	for key,value in pairs(tbl) do
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
		Function that compares the profile's DataVersion with the current DataVersion
			and updates it accordingly if the profile is outdated.
]]
local function CheckIfProfileNeedsUpdate(profile)
	if not profile:GetMetaTag("DataVersion") then
		-- First time setting up the profile
		profile:SetMetaTag("DataVersion", DataVersion)
	elseif profile:GetMetaTag("DataVersion") ~= DataVersion then
		-- DataVersion out of sync

		-- Remove unused keys
		for dataName,_ in pairs(profile.Data) do
			if _DefaultData[dataName] == nil then
				profile.Data[dataName] = nil
			end
		end

		-- Add new data
		for dataName,defaultData in pairs(_DefaultData) do
			if profile.Data[dataName] == nil then
				profile.Data[dataName] = defaultData
			end
		end

		-- Update DataVersion of the profile
		profile:SetMetaTag("DataVersion", DataVersion)
	end
end


--[[
Set up a way to have globally updating data stores tha you can change within studio without having to publish the game

local CodesVersion = 1
local CodesProfile = CodesProfileStore:ViewProfileAsync("Main")

-- First time setup for the CodesProfile
if not CodesProfile or not CodesProfile:GetMetaTag("Version") or CodesVersion > CodesProfile:GetMetaTag("Version") then
	CodesProfile = CodesProfileStore:LoadProfileAsync("Main", "Steal")
	CodesProfile.Data = _AllCodes
	CodesProfile:SetMetaTag("Version", CodesVersion)
	print(CodesProfile:GetMetaTag("Version"))

	CodesProfile:Release()

	CodesProfile = CodesProfileStore:ViewProfileAsync("Main")
end
-- Loops every 60 seconds to check for new codes being added
coroutine.resume(coroutine.create(function()
	while wait(90) do
		CodesProfile = CodesProfileStore:ViewProfileAsync("Main")
		if CodesProfile:GetMetaTag("Version") and CodesProfile:GetMetaTag("Version") > CodesVersion then
			CodesVersion = CodesProfile:GetMetaTag("Version")
			MasterData:_UpdateAllCodes(CodesProfile.Data)
		end
	end
end))
]]


----- Public Functions -----
--[[
	WARNING:
		ProfileService functionality that doesn't have to do with 'profile.Data' should
			should be handled here.
		You will still have access to the entire Profile in DataModules' functions.
]]



--[[
	Description:
		Function that gets the player's profile and returns its Data table.
	Returns:
		Table of player's profile data
]]
function MasterData:GetProfileData(plr)
	-- Check if the profile exists on the server
	if Profiles[plr] then
		return Promise.resolve(Profiles[plr].Profile.Data, Profiles[plr].Mock.Data)
	else
		-- Wait for the profile to be set up
		return Promise.new(function(resolve, reject, onCancel)
			local retries = 300
			while retries > 0 and not Profiles[plr] do
				retries = retries - 1
				wait(.1)
			end
		
			if Profiles[plr] then
				resolve(Profiles[plr].Profile.Data, Profiles[plr].Mock.Data)
			else
				reject()
			end
		end)
	end
end

--[[
	Description:
		Function called when a player is added to the game.
		This function handles the setup of the players Profile.
]]
function MasterData:OnPlayerAdded(plr)
	local profile = PlayerProfileStore:LoadProfileAsync(
		"Player_" .. plr.UserId,
		function(place_id, game_job_id)
			if game_job_id == game.JobId then
				return "Steal"
			else
				return "ForceLoad"
			end
		end
	)

	local mockProfile = PlayerMockProfileStore.Mock:LoadProfileAsync(
		"Player_" .. plr.UserId,
		function(place_id, game_job_id)
			if game_job_id == game.JobId then
				return "Steal"
			else
				return "ForceLoad"
			end
		end
	)
	-- Grab the TempData that could have been changed before the player joined the game
	for i,v in pairs(GetTempData()) do
		mockProfile.Data[i] = v
	end

	if profile ~= nil then
		profile:ListenToRelease(function() -- Setup a Release listener for when the player's Pofile is released
			Profiles[plr] = nil

			-- Kick player to prevent any data loss
			plr:Kick("Data Profile was released. Preventing Data Loss!")
		end)

		if plr:IsDescendantOf(Players) then
			local _Data = setmetatable({}, {
				__index = function(t, key)
					if profile.Data[key] then
						return profile.Data[key]
					elseif mockProfile.Data[key] then
						return mockProfile.Data[key]
					end
				end,
				__newindex = function(t, key, val)
					if typeof(key) ~= "string" and typeof(key) ~= "number" then
						warn("INVALID KEY TYPE WARNING: " .. typeof(key))
						return
					end

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
			CheckIfProfileNeedsUpdate(profileMT.Profile)
		else
			profile:Release()
			mockProfile:Release()
			PlayerMockProfileStore.Mock:WipeProfileAsync("Player_" .. plr.UserId)

			Profiles[plr] = nil
		end
	else
		plr:Kick("Error loading your data. Please rejoin!!!")
	end
end

--[[
	Description:
		Function called when a player is being removed from the game
]]
function MasterData:OnPlayerRemoving(plr)
	if Profiles[plr] then
		local profile = Profiles[plr].Profile
		local mock = Profiles[plr].Mock

		if profile ~= nil then
			profile:Release()
			mock:Release()
			PlayerMockProfileStore.Mock:WipeProfileAsync("Player_" .. plr.UserId)

			Profiles[plr] = nil
		end
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
	return MasterData:GetProfileData(plr)
	:andThen(function(profileData, mockData)
		local tbl = {}

		for i,v in pairs(mockData) do
			tbl[i] = v
		end
	
		for i,v in pairs(profileData) do
			tbl[i] = v
		end
	
		return tbl
	end)
	:catch(function(err, returnVal)
		warn("WARNING: Could not find Player '" .. plr.Name .. "'s Profile Data! Kicking them now.")
		plr:Kick("Error loading your data. Please rejoin!!!")
		return
	end)
	:expect()
end

----- Initialize -----

return MasterData