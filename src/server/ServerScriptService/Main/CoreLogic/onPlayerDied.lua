local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

local function newOnPlayerDied(plr)
	local function onPlayerDied()
		--Custom respawn functionality


		
		wait(5)
		plr:LoadCharacter()
	end
	
	return onPlayerDied
end

return newOnPlayerDied