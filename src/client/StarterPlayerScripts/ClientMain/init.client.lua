--[[
	This is a test setup for handling ClientData
]]

local ClientData = require(script.Parent:WaitForChild("ClientData"))

print(ClientData.TestVariable)
ClientData.TestVariable = 5
print(ClientData.TestVariable)