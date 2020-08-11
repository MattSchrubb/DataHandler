local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local newOnCharacterAddedFn = require(script.Parent:WaitForChild("OnCharacterAdded"))

local function onPlayerAdded(plr)
	local onCharacterAdded = newOnCharacterAddedFn(plr)
	plr.CharacterAdded:Connect(onCharacterAdded)
	
	plr:LoadCharacter()
end

return onPlayerAdded