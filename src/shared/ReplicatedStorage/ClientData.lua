----- Loaded Modules -----

local ReplicaController = require(game.ReplicatedStorage:WaitForChild("ReplicaController"))

----- Private Variables -----

local PlayerProfiles = {}
local LocalProfile

----- Public Variables -----

local Player = game.Players.LocalPlayer

local ClientData = {}
ClientData.__index = ClientData

----- Private Functions -----

--[[ 
	Description: 
    	Function that sets up a new profile.
	Parameters:
    	replica: Replica object of player's profile data
]]
function newProfile(replica)
	PlayerProfiles[replica.Tags.Player] = replica
	if replica.Tags.Player == game.Players.LocalPlayer then
		--print("Setting up local profile")
		LocalProfile = PlayerProfiles[replica.Tags.Player]
	end
end


--[[
	Description:
		Function called to initialize the ReplicaConterollers data.
]]
function requestData()
	if ReplicaController.InitialDataReceived then
		return
	else
		ReplicaController.RequestData()
	end
end

----- Public Functions -----

--[[
	Description:
		Function called when wanting access to a Player's Profile Data.
	Parameters:
		plr(Required): the Player object to index by
	Returns:
		A table containing the Player's Profile Data.
]]
function ClientData:GetPlayerData(plr)
	if not PlayerProfiles[plr] then
		warn("You do not have access to " .. plr.Name .. "'s Profile.")
		return false
	end
	
	return PlayerProfiles[plr].Data
end

function ClientData:GetLocalPlayerData()
	local retries = 30
	while retries > 0 and not LocalProfile do
		wait(.1)
		retries -= 1
	end

	return LocalProfile.Data
end

function ClientData:GetPlayerProfile(plr)
	if not PlayerProfiles[plr] then
		warn("You do not have access to " .. plr.Name .. "'s Profile.")
		return false
	end

	return PlayerProfiles[plr]
end

function ClientData:GetLocalPlayerProfile()
	local retries = 30
	while retries > 0 and not LocalProfile do
		wait(.1)
		retries -= 1
	end
	
	return LocalProfile
end

----- Connections -----

ReplicaController.ReplicaOfClassCreated("PlayerProfile", newProfile)

if not ReplicaController.InitialDataReceived then
	local con 
	con	= ReplicaController.InitialDataReceivedSignal:Connect(function()
		con:Disconnect()
	end)
end

----- Initialize -----

--requestData()

return ClientData