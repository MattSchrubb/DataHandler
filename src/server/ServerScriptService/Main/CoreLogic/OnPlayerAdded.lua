local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local MasterData = require(game.ServerStorage:WaitForChild("MasterData"))
local newOnCharacterAddedFn = require(script.Parent:WaitForChild("OnCharacterAdded"))

local function onPlayerAdded(plr)
	MasterData:OnPlayerAdded(plr)

	local onCharacterAdded = newOnCharacterAddedFn(plr)
	plr.CharacterAdded:Connect(onCharacterAdded)
	
	plr:LoadCharacter()
end

return onPlayerAdded