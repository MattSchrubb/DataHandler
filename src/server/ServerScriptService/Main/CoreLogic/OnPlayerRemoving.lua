local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local MasterData = require(game.ServerStorage:WaitForChild("MasterData"))

local function onPlayerRemoving(plr)
	MasterData:OnPlayerRemoving(plr)
end

return onPlayerRemoving