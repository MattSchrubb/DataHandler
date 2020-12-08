--[[
	DATA MODULES:
		These are used to add functionality to your data. It also helps
			from cluttering up this script.
		There is a provided Template module that shows how to set up
			and use your own custom data types.
		WARNING:
			Make sure that you don't have multiple of the same public
			functions throughout all your DataModules.
			If you do, MasterData doesn't know what to call, and will
			fire the first one it comes by :/
]]
local DataModules = {}
local _cachedFunctions = {}

for _,mod in pairs(script.Parent:WaitForChild("DataModules"):GetChildren()) do
	DataModules[mod.Name] = require(mod)
	for index,var in pairs(DataModules[mod.Name]) do
		if type(var) == "function" then
			if index ~= "_GetDefaultData" and index ~= "_GetTempData" and index ~= "_UpdateAll" then
				_cachedFunctions[index] = {modName = mod.Name, mod = DataModules[mod.Name], func = var}
			else
				warn("MasterData: Attempting to override the reserved function '" .. index .. "' in '" .. mod.Name)
			end
		end
	end
end

_cachedFunctions["_UpdateAll"] = function(players, profiles, dataName, newData)
	for _,profile in pairs(profiles) do
		local data = profile.Data
		data[dataName] = newData
	end
end




local DataModulesHandler = {}

function DataModulesHandler:GetFunction(functionName)
	if _cachedFunctions[functionName] then
		return _cachedFunctions[functionName].func
	else
		return false
	end
end

--[[
	Description:
		DefaultData - is a table containing the default values for data being stored in ProfileService.
		TempData - is a table containing the default values for data that won't be stored in ProfileService,
					but is rather used in the MockProfile that gets set up every time they join.
]]
function DataModulesHandler:GetDefaultData()
	local DefaultData = {}
	for _,mod in pairs(DataModules) do
		if type(mod) ~= "function" and mod["_GetDefaultData"] then
			for _dataName,_data in pairs(mod:_GetDefaultData()) do
				assert(type(_dataName) == "string" or type(_dataName) == "number", "INVALID_KEY_TYPE_ERROR: " .. tostring(_dataName), type(_dataName) .. ". Key must be a 'string' or 'number' value!")
				assert(type(_data) ~= "userdata", "Attempting to store a 'userdata' value in the Player's Profile: " .. _dataName, typeof(_data) .. ". Use tempData instead.")
				assert(type(_data) ~= "function", "Attempting to store a 'function' value in the Player's Profile: " .. _dataName, type(_data))
				DefaultData[_dataName] = _data
			end
		end
	end
	return DefaultData
end

function DataModulesHandler:GetTempData()
	local TempData = {}
	for _,mod in pairs(DataModules) do
		if type(mod) ~= "function" and mod["_GetTempData"] then
			for _dataName,_data in pairs(mod:_GetTempData()) do
				TempData[_dataName] = _data
			end
		end
	end
	return TempData
end

return DataModulesHandler