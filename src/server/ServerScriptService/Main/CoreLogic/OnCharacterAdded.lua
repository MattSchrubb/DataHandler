local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local newOnPlayerDied = require(script.Parent:WaitForChild("OnPlayerDied"))

local function newOnCharacterAddedFn(plr)
	local function onCharacterAdded(chr)
		
		-- Find the humanoid, and detect when it dies
		local hum = chr:WaitForChild("Humanoid")
		if hum then
			hum.Died:Connect(newOnPlayerDied(plr))
		end
	end
	
	return onCharacterAdded
end

return newOnCharacterAddedFn