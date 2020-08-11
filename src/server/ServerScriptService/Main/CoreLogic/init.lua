local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local onPlayerAdded = require(script:WaitForChild("OnPlayerAdded"))
local onPlayerRemoving = require(script:WaitForChild("OnPlayerRemoving"))

local CoreLogic = {}

CoreLogic.__index = CoreLogic
setmetatable(CoreLogic, {
	__call = function(cls, ...)
		return cls.new(...)
	end
})


function CoreLogic.new()
	local self = setmetatable({}, CoreLogic)
	
	game.Players.PlayerAdded:Connect(onPlayerAdded)
	game.Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Run the onPlayerAdded for any players who joined before the event handler was attached.
	for _,plr in pairs(game.Players:GetPlayers()) do
		onPlayerAdded(plr)
	end
	
	return self
end

-- NOTE: We are creating a single instance and returning it .
-- There must only be one instance of this module, ever.
local m = CoreLogic.new()
return m