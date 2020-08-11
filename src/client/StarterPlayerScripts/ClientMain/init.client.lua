local ClientData = require(script.Parent:WaitForChild("ClientData"))

print(ClientData.TestVariable)
ClientData.TestVariable = 5
print(ClientData.TestVariable)