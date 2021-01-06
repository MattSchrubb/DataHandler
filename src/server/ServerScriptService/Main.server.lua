local MasterData = require(game.ServerStorage:WaitForChild("MasterData"))

local LastPayout = os.clock()

game:GetService("RunService").Heartbeat:Connect(function()
	if os.clock() - LastPayout > 3 then
		LastPayout = os.clock()
		print("Payout!")
		for _, player in pairs(game.Players:GetChildren()) do
			MasterData:GiveCash(player, 100)
		end
	end
end)
-- Every 3 seconds it calls that function for every player's profile