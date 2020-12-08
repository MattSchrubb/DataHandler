----- Loaded Modules -----

local ProfileHandler = require(script:WaitForChild("ProfileHandler"))
local Promise = require(script:WaitForChild("Promise"))
local DataModulesHandler = require(script:WaitForChild("DataModulesHandler"))

----- Private Variables -----

local Remotes = game.ReplicatedStorage:WaitForChild("RemoteMessages")
local _OnUpdateCallbacks = {}

--[[
	Description:
		Sets up a metatable that when indexed, will first search through
		itself to find the index being referenced, otherwise it will search 
		through all DataModules until it finds the first matching index.
]]
local MasterData = setmetatable({}, {
	__index = function(tbl, index)
		return Promise.new(function(resolve, reject, onCancel)
			local func = DataModulesHandler:GetFunction(index)
			
			if func then
				resolve(function(_, plr, ...)
					local data = ...
					local succ, _returnVal, _err = Promise.new(function(_resolve, _reject, _onCancel)

						-- Check if plr is a Player Object
						if typeof(plr) == "Instance" and plr:IsA("Player") then
							local success, profile = ProfileHandler:GetProfile(plr):await()
							if success then
								_resolve(func(_, plr, profile, data))
							else
								_reject("ERROR: Could not find Player's profile! " .. plr.Name, profile)
							end	
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
									local success, profile = ProfileHandler:GetProfile(i):await()
									if success then
										profiles[i] = profile
									else
										_reject("ERROR: Could not find Player's profile! " .. i.Name, profile)
										profiles[i] = {}
									end
								elseif typeof(v) == "Instance" and v:IsA("Player") then
									if isPlayersIndex then
										isPlayersIndex = false
										isPlayersValue = false
										break
									else
										isPlayersValue = true
									end
									local success, profile = ProfileHandler:GetProfile(v):await()
									if success then
										profiles[v] = profile
									else
										_reject("ERROR: Could not find Player's profile! " .. v.Name, profile)
										profile[v] = {}
									end
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
					:await()

					if succ then
						return _returnVal
					elseif _err ~= nil then
						warn(_returnVal)
						error(_err)
					else
						warn(_returnVal)
					end
				end)
			else
				reject("WARNING: No function with name '" .. index .. "' found in MasterData!!", function(...)
					error("Attempt to call non-existing function '" .. index .. "' from MasterData!!")
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

----- Public Variables -----

----- Private Functions -----

----- Public Functions -----

function MasterData:OnUpdate(plr, dataName, callback)
	ProfileHandler:OnUpdate(plr, dataName, callback)
end


function MasterData:ResetData(plr)
	ProfileHandler:ResetData(plr)
end

--[[
	Description:
		Function called when a player is added to the game.
		This function handles the setup of the players Profile.
	Returns:
		The palyer's profile
]]
function MasterData:OnPlayerAdded(plr)
	local success, profile = ProfileHandler:OnPlayerAdded(plr):await()

	if not success then
		plr:Kick(profile)
		error(profile)
	end

	return profile
end

--[[
	Description:
		Function called when a player is being removed from the game
]]
function MasterData:OnPlayerRemoving(plr)
	local success, err = ProfileHandler:OnPlayerRemoving(plr):await()
	if not success then
		error(err)
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
	local success, profileData, mockData = ProfileHandler:GetProfileData(plr, true):await()

	if success then
		local tbl = {}
		
		for i,v in pairs(mockData) do
			tbl[i] = v
		end
	
		for i,v in pairs(profileData) do
			tbl[i] = v
		end
		
		return tbl
	else
		warn("WARNING: Could not find Player '" .. plr.Name .. "'s Profile Data! Kicking them now.")
		plr:Kick("Error loading your data. Please rejoin!!!")
		return
	end
end

Remotes:WaitForChild("UpdateAllEv").Event:Connect(function(dataName, newData)
	MasterData:_UpdateAll(game.Players:GetChildren(), dataName, newData)
end)

----- Initialize -----

return MasterData