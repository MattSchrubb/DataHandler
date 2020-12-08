local Promise = require(script.Parent:WaitForChild("Promise"))
local ProfileService = require(script:WaitForChild("ProfileService"))
local DataModulesHandler = require(script.Parent:WaitForChild("DataModulesHandler"))

local _DefaultData = DataModulesHandler:GetDefaultData()
-- Setup ProfileService Stores
local PlayerProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	_DefaultData
)
local PlayerMockProfileStore = ProfileService.GetProfileStore(
	"PlayerMockData",
	{}
)
local _OnUpdateCallbacks = {}

local function clone(tbl)
	local t = {}

	for key,value in pairs(tbl) do
		assert(type(value) ~= "userdata", "Attempting to store a userdata value in the Player's Profile: " .. key,typeof(value))

		if type(value) == "table" then
			t[key] = clone(value)
		else
			t[key] = value
		end
	end

	return t
end


-- A list of players and their profiles
local Profiles = {} -- [player] = profile

local ProfileHandler = {}

function ProfileHandler:GetProfile(plr)
	return Promise.new(function(resolve, reject, onCancel)
		local canRetry = true

		onCancel(function()
			canRetry = false
		end)

		local profile = Profiles[plr]
		while not profile and canRetry do 
			wait() 
			profile = Profiles[plr]
		end
		
		if profile then
			resolve(Profiles[plr])
		end
	end)
	:timeout(30)
end

function ProfileHandler:GetProfileData(plr, _separated)
	return Promise.new(function(resolve, reject, onCancel)
		local canRetry = true

		onCancel(function()
			canRetry = false
		end)

		local profile = Profiles[plr]
		while not profile and canRetry do 
			wait() 
			profile = Profiles[plr]
		end
		
		if profile then
			if _separated then
				resolve(Profiles[plr].Profile.Data, Profiles[plr].Mock.Data)
			else
				resolve(Profiles[plr].Data)
			end
		end
	end)
	:timeout(30)
end

function ProfileHandler:ResetData(plr)
	local success, profileMT = ProfileHandler:GetProfile(plr):await()
	if success then
		local profile = profileMT.Profile
		for i,v in pairs(_DefaultData) do
			profile.Data[i] = v
		end
	else
		error(profileMT)
	end
end

function ProfileHandler:OnUpdate(plr, dataName, callback)
	if not _OnUpdateCallbacks[plr] then
		_OnUpdateCallbacks[plr] = {}
	end

	if not _OnUpdateCallbacks[plr][dataName] then
		_OnUpdateCallbacks[plr][dataName] = {}
	end
		
	table.insert(_OnUpdateCallbacks[plr][dataName], callback)
end

function ProfileHandler:OnPlayerAdded(plr)
	return Promise.new(function(resolve, reject)
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

		if profile ~= nil then
			profile:ListenToRelease(function() -- Setup a Release listener for when the player's Pofile is released
				Profiles[plr] = nil
	
				-- Kick player to prevent any data loss
				plr:Kick("Data Profile was released. Preventing Data Loss!")
			end)

			-- Reconcile the profile's data with updated data
			profile:Reconcile()
			-- Grab the TempData that could have been changed before the player joined the game
			for i,v in pairs(DataModulesHandler:GetTempData()) do
				mockProfile.Data[i] = v
			end

			if plr:IsDescendantOf(game.Players) then
				if not _OnUpdateCallbacks[plr] then
					_OnUpdateCallbacks[plr] = {}
				end

				local _Data = setmetatable({}, {
					__index = function(_, key)
						if profile.Data[key] ~= nil then
							return profile.Data[key]
						elseif mockProfile.Data[key] ~= nil then
							return mockProfile.Data[key]
						else
							return nil
						end
					end,
					__newindex = function(_, key, val)
						assert(type(key) == "string" or type(key) == "number", "INVALID_KEY_TYPE_ERROR: " .. key, type(key) .. ". Key must be a 'string' or 'number' value!")
						assert(type(val) ~= "userdata", "Attempting to store a 'userdata' value in the Player's Profile: " .. key, typeof(val))
						assert(type(val) ~= "function", "Attempting to store a 'function' value in the Player's Profile: " .. key, type(val))

						if type(val) == "table" then
							val = clone(val)
						end

						if profile.Data[key] ~= nil then
							local oldVal = profile.Data[key]
							profile.Data[key] = val

							if _OnUpdateCallbacks[plr][key] then
								for _,func in pairs(_OnUpdateCallbacks[plr][key]) do
									coroutine.resume(coroutine.create(func), plr, Profiles[plr], val, oldVal)
								end
							end
						elseif mockProfile.Data[key] ~= nil then
							local oldVal = mockProfile.Data[key]
							mockProfile.Data[key] = val
							
							if _OnUpdateCallbacks[plr][key] then
								for _,func in pairs(_OnUpdateCallbacks[plr][key]) do
									coroutine.resume(coroutine.create(func), plr, Profiles[plr], val, oldVal)
								end
							end
						else
							warn("NO_KEY_FOUND_WARNING: '" .. key .. "' not found in " .. plr.Name .. "'s Profile or MockProfile! Setting it up now!")
							local oldVal = mockProfile.Data[key]
							mockProfile.Data[key] = val

							if _OnUpdateCallbacks[plr][key] then
								for _,func in pairs(_OnUpdateCallbacks[plr][key]) do
									coroutine.resume(coroutine.create(func), plr, Profiles[plr], val, oldVal)
								end
							end
						end
					end
				})

				local profileMT = setmetatable({Profile = profile, Mock = mockProfile, Data = _Data}, {
					__index = function(_, key)
						if profile[key] ~= nil then
							return profile[key]
						else
							return _Data[key]
						end
					end,
					__newindex = function(_, key, val)
						_Data[key] = val
					end
				})

				Profiles[plr] = profileMT

				resolve(profileMT)
			else
				profile:Release()
				mockProfile:Release()
				PlayerMockProfileStore.Mock:WipeProfileAsync("Player_" .. plr.UserId)

				Profiles[plr] = nil
				reject("Player failed to load in.")
			end
		else
			reject("Profile failed to load! Please rejoin!!!")
		end
	end)
end

function ProfileHandler:OnPlayerRemoving(plr)
	return Promise.new(function(resolve, reject)
		if _OnUpdateCallbacks[plr] then
			_OnUpdateCallbacks[plr] = nil
		end
		
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

		resolve()
	end)
	
end
--[[
	WARNING:
		ProfileService functionality that doesn't have to do with 'profile.Data' should
			should be handled here.
		You will still have access to the entire Profile in DataModules' functions.
]]

return ProfileHandler