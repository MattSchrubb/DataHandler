----- Loaded Modules -----

local ReplicaService = require(game.ServerStorage:WaitForChild("ReplicaService"))
local ProfileService = require(game.ServerStorage:WaitForChild("ProfileService"))

----- Private Variables -----

local ProfileTemplate = {
	ReplicatedData = {},
	PrivateData = {}
}

for _,mod in pairs(script.Parent:WaitForChild("DataModules"):GetChildren()) do
	if mod:IsA("ModuleScript") then
		mod = require(mod)
	
		if mod["_GetDefaultData"] then
			local replicatedData, privateData = mod._GetDefaultData()
			
			for dataName, defaultValue in pairs(replicatedData) do
				ProfileTemplate["ReplicatedData"][dataName] = defaultValue
			end
			
			for dataName, defaultValue in pairs(privateData) do
				ProfileTemplate["PrivateData"][dataName] = defaultValue
			end
		end
	end
end

local PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")
local GameProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)


local PlayerProfileFunctions
local PlayerProfiles = {}

----- Private Functions -----

local function OnPlayerAdded(plr)
	local profile = GameProfileStore:LoadProfileAsync(
		"Player_" .. plr.UserId,
		"ForceLoad"
	)

	if profile ~= nil then
		profile:Reconcile()
		profile:ListenToRelease(function()
			PlayerProfiles[plr].Replica:Destroy()
			PlayerProfiles[plr].PrivateReplica:Destroy()
			PlayerProfiles[plr] = nil
			plr:Kick()
		end)

		if plr:IsDescendantOf(game.Players) then
			local self = {
				Profile = profile,
				Replica = ReplicaService.NewReplica({
						ClassToken = PlayerProfileClassToken,
						Tags = {Player = plr},
						Data = profile.Data["ReplicatedData"],
						Replication = {[plr] = true} -- Change to "All" if you want to replicate every client's data to other clients for things like viewing inventory
				}),
				PrivateReplica = ReplicaService.NewReplica({
					ClassToken = PlayerProfileClassToken,
					Tags = {Player = plr},
					Data = profile.Data["PrivateData"],
					Replication = {},
				}),
				_player = plr,
			}

			self.__index = function(_, key)
				if PlayerProfileFunctions[key] then
					return PlayerProfileFunctions[key]
				end
				
				if self.Replica.Data[key] ~= nil then
					return self.Replica.Data[key]
				elseif self.PrivateReplica.Data[key] then
					return self.PrivateReplica.Data[key]
				end
			end

			setmetatable(self, self)

			PlayerProfiles[plr] = self
		end
	end
end

----- Public Functions -----

PlayerProfileFunctions = {}

function PlayerProfileFunctions:IsActive()
	return PlayerProfiles[self._player] ~= nil
end

function PlayerProfileFunctions:SetValue(path, new_value)
	local replicaType = self:GetValue(path, true)
	
	if replicaType == "Replica" then
		self.Replica:SetValue(path, new_value)
	elseif replicaType == "PrivateReplica" then
		self.PrivateReplica:SetValue(path, new_value)
	end
	
end

function PlayerProfileFunctions:SetValues(path, new_value)
	if type(new_value) ~= "table" then
		self:SetValue(path, new_value)
		return
	end
	
	local replicaType = self:GetValue(path, true)
	
	if replicaType == "Replica" then
		self.Replica:SetValues(path, new_value)
	elseif replicaType == "PrivateReplica" then
		self.PrivateReplica:SetValues(path, new_value)
	end
end

function PlayerProfileFunctions:GetValue(path, _checkReplicaType)
	local returnVal
	local replicaType = "Replica"
	
	if type(path) == "string" then
		local path_array = {}
		if path ~= "" then
			for s in string.gmatch(path, "[^%.]+") do
				table.insert(path_array, s)
			end
		end
		path = path_array
	end

	returnVal = self.Replica.Data[path[1]]
	
	if returnVal == nil then 
		returnVal = self.PrivateReplica.Data[path[1]]
		if returnVal ~= nil then
			replicaType = "PrivateReplica"
		end
	end
	
	if _checkReplicaType then
		return replicaType
	end
	
	for i,key in ipairs(path) do
		if i ~= 1 then
			returnVal = returnVal[key]
		end
	end
	
	return returnVal
end

function PlayerProfileFunctions:UpdateValue(path, func)
	self:SetValue(path, func(self:GetValue(path)))
end

function PlayerProfileFunctions:UpdateValues(path, func)
	self:SetValues(path, func(self:GetValue(path)))
end

----- Connections -----

game.Players.PlayerAdded:Connect(OnPlayerAdded)
for i,v in pairs(game.Players:GetChildren()) do
	OnPlayerAdded(v)
end

game.Players.PlayerRemoving:Connect(function(player)
	local player_profile = PlayerProfiles[player]
	if player_profile ~= nil then
		player_profile.Profile:Release()
	end
end)

----- Initiate -----

local ProfileHandler = {}

function ProfileHandler:GetPlayerProfile(plr)
	if PlayerProfiles[plr] ~= nil then
		return PlayerProfiles[plr]
	end
end

function ProfileHandler:GetAllPlayerProfiles()
	return PlayerProfiles
end

return ProfileHandler