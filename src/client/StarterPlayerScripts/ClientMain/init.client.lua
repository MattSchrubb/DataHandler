--[[
	This is a test setup for handling ClientData
]]

local ClientData = require(script.Parent:WaitForChild("ClientData"))

-- Clients can create their own variables any time you want them to
ClientData:OnUpdate("TestVariable", function(newVal, oldVal)
	print(newVal, oldVal)
end)
ClientData.TestVariable = 5

-- You can't manipulate server created Variables
ClientData:OnUpdate("TempData", function(newVal, oldVal)
	print(newVal, oldVal)
end)
ClientData.TempData = 4