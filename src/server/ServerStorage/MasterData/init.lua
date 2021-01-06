local ProfileHandler = require(script:WaitForChild("ProfileHandler"))
local DataModules = script:WaitForChild("DataModules")

local cachedFunctions = {}
for _,mod in pairs(DataModules:GetChildren()) do
	for name,func in pairs(require(mod)) do
		if type(func) == "function" then
			if name ~= "_GetDefaultData" then
				cachedFunctions[name] = func
			end
		end
	end
end

local MasterData = setmetatable({}, {
	__index = function(_, key)
		if ProfileHandler[key] then
			return ProfileHandler[key]
		end
		
		local func = cachedFunctions[key]
		if func then
			return function(_, plr, ...)
				local args = table.pack(...)
				
				-- Check if plr is a Player Object
				if typeof(plr) == "Instance" and plr:IsA("Player") then
					local profile = ProfileHandler:GetPlayerProfile(plr)
					if profile then
						return func(_, plr, profile, table.unpack(args))
					else
						warn("ERROR: Could not find Player's profile! " .. plr.Name)
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
							local profile = ProfileHandler:GetPlayerProfile(i)
							if profile then
								profiles[i] = profile
							else
								warn("ERROR: Could not find Player's profile! " .. i.Name)
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
							local profile = ProfileHandler:GetPlayerProfile(v)
							if profile then
								profiles[v] = profile
							else
								warn("ERROR: Could not find Player's profile! " .. v.Name)
								profile[v] = {}
							end
						else
							break
						end
					end

					-- If it is a table of players then their profiles will be sent as well, indexed by the Player
					if (isPlayersValue and not isPlayersIndex) or (isPlayersIndex and not isPlayersValue) then
						return func(_, plr, profiles, table.unpack(args))
					else
						return func(_, plr, table.unpack(args))
					end
				else
					return func(_, plr, table.unpack(args))
				end
			end
		end
	end
})

function MasterData:IsActive(plr)
	return ProfileHandler:GetPlayerProfile(plr) ~= nil
end

function MasterData:SetValue(plr, path, new_value)
	if MasterData:IsActive(plr) then
		ProfileHandler:GetPlayerProfile(plr):SetValue(path, new_value)
	end
end

function MasterData:SetValues(plr, path, new_value)
	if MasterData:IsActive(plr) then
		ProfileHandler:GetPlayerProfile(plr):SetValues(path, new_value)
	end
end

function MasterData:GetValue(plr, path, _checkReplicaType)
	if MasterData:IsActive(plr) then
		return ProfileHandler:GetPlayerProfile(plr):GetValue(path, _checkReplicaType)
	end
end

function MasterData:UpdateValue(plr, path, func)
	if MasterData:IsActive(plr) then
		return ProfileHandler:GetPlayerProfile(plr):UpdateValue(path, func)
	end
end

function MasterData:UpdateValues(plr, path, func)
	if MasterData:IsActive(plr) then
		return ProfileHandler:GetPlayerProfile(plr):UpdateValues(path, func)
	end
end

return MasterData