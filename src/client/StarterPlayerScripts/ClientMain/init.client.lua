local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientData"))

local Player = game.Players.LocalPlayer
local CashGui = Player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Frame"):WaitForChild("Cash")



local player_profile = ClientData:GetLocalPlayerProfile()
local player_data = player_profile.Data or ClientData:GetLocalPlayerData() -- Either way will give you the player's data

CashGui.Text = "Cash: " .. player_data.Cash
player_profile:ListenToChange("Cash", function(new_value, old_value)
	print(game.Players.LocalPlayer.Name .. " Cash changed: " .. old_value .. " -> " .. player_data.Cash or new_value)
	CashGui.Text = "Cash: " .. new_value
end)