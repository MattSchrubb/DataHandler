----- GLOBALS -----

local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

----- Loaded Modules -----

local Remotes = require(game.ReplicatedStorage:WaitForChild("Remotes"))
local HelperFns = require(game.ReplicatedStorage:WaitForChild("HelperFns"))
local Variable = require(script:WaitForChild("Variable"))

----- Private Variables -----

local ACCESS_KEY = "SomeRandomKeyUsedForObjectAccess" -- Used to access the Variable Object instead of the Value
local getAllPlayerDataFn = Remotes.GetAllPlayerDataFn
local updatePlayerDataEv = Remotes.UpdatePlayerDataEv

----- Public Variables -----

local Player = game.Players.LocalPlayer

local ClientData = {}
ClientData.__index = ClientData

----- Private Functions -----

--[[ 
	Description: 
    	Function that returns a new Variable Object.
	Parameters:
    	defualtData(Optional): Default data used to set up the Variable Object with
		_debug(Optional): Used to debug where the creation is coming from
	Returns:
		Variable Object
]]
local function _CreateVariable(defaultData, _debug)
	if _debug and G.DEBUG then
		print("Variable created: " .. _debug)
	end
	return Variable.new(defaultData)
end


--[[
	Description:
		Function that checks if the ClientData Object has the specified
			Variable Object in _privateVariableList or _publicVariableList
			and returns it.
		If not, will create a new Variable Object and return it.
	Parameters:
		variableName(Required): Name of the Variable used to locate Variable Object
		defaultData(Optional): Default data used to set up the Variable Object. Used only by ClientData:_Update() for now
]]
function ClientData:_GetVariableObject(variableName, defaultData)
	if self[ACCESS_KEY .. variableName] ~= nil then
		return self[ACCESS_KEY .. variableName]
	else
		self[variableName] = _CreateVariable(defaultData, "_GetVariableObject " .. variableName)
		return self[ACCESS_KEY .. variableName]
	end
end


--[[
	Description:
		Function called when a Variable's Value is being updated.
		This will fire all callback functions specified for ClientData.
	Parameters:
		variableName(Required): name of the Variable who's Value is being updated
		newData(Required): new value to set the Variable's Value to
]]
function ClientData:_Update(dataName, newData)
	local var = self:_GetVariableObject(dataName, newData)

	local oldVal = var.Value -- Store the old value for use in the ClientData callbacks
	var:_Update(newData) -- Updates the Variable, and fires its own callbacks
	local newVal = var.Value -- Get the new value for use in the ClientData callbacks

	for _,callback in pairs(self._callbacks) do
		callback(dataName, oldVal, newVal) -- Fire each callback function set up for ClientData
	end
end

----- Public Functions -----

--[[
	Description:
		Function that adds a callback function to the specified Variable Object, or
			the ClientData Object as a whole.
		These functions are called when the Variable Object's _Update function is
			called to change its data.
	Parameters:
		variableName(Required): the name of the variable you want to add a callback to
		func(Required): the function to be added
	WARNING:
		If no variableName is specified, and the function is the first parameter
			then you are specifying that you want to know any time that
			ClientData is being updated for any reason.
]]
function ClientData:OnUpdate(variableName, func)
	if type(variableName) == "function" then -- Check if want to encompas all Variables
		table.insert(self._callbacks, variableName) -- Insert function into callbacks for the ClientData Object
	else
		local var = self:_GetVariableObject(variableName)
		if var ~= nil then
			var:OnUpdate(func)
		end
	end
end

----- Initialize -----

local function initialize()
	local self = {}

	----- Private Variables -----
	--[[
		Description:
			A table used to store data the server will be manipulating

			(Read-Only) for the Client
			
			Server is the only entity with access to change data here
			See MasterData:GetDefaultData() for more information
	]]
	local _privateVariableList = {
	--[[
		WARNING!!!
		DO NOT PUT ANYTHING HERE!!!
		THIS IS JUST AN EXAMPLE OF HOW IT WILL LOOK!!

		Coins = _CreateVariable(_allData.Coins),
		Items = _CreateVariable(_allData.Items),
	]]
	}
	-- Setup all data that will be stored in _privateVariableList
	for dataName, data in pairs(getAllPlayerDataFn:InvokeServer()) do
		_privateVariableList[dataName] = _CreateVariable(data, "getAllPlayerData " .. dataName) -- Remove 2nd parameter if you don't want to debug
	end


	--[[
		Description:
			Similar to _privateVariableList, except this data is created and accessed
				by the Client only

			(Read-Write) for the Client

			Doesn't need to be set up right away, but in some cases having the index 
				at startup is needed
	]]
	local _publicVariableList = {
	--[[
		WARNING!!!
			Make sure the keys are different from _privateVariableList keys!!
			Check MasterData:GetDefaultData() for more information

		You can put whatever you want here at any
			time during the Client's session.

		These will never be saved and are usefull only for this session.

		Example Data:
		UIOpen = _CreateVariable({}),
		KillStreak = _CreateVariable({})
	]]
	}


	-- Table of callback functions fired when the ClientData table is updated
	self._callbacks = {}

	----- Public Variables -----



	----- Connections -----
	--[[
		Description:
			Connections is mainly used to listen to messages sent by the Server.

			As a default, we include an updatePlayerDataEv to check when the
				Server wants to update/add _privateVariableList Variables.

			I usually set them up as local variables in the Private Variables
				section at the very top. But this is not neccessary, you can
				just use 'Remotes.EventName.OnClientEvent' instead.
	]]

	-- Remote event fired when the Server is updating/adding a _privateVariableList Variable
	updatePlayerDataEv.OnClientEvent:Connect(function(dataName, newData)
		if _privateVariableList[dataName] == nil then -- Check if it doesn't exist and create a new Variable Object
			_privateVariableList[dataName] = _CreateVariable(newData, "_privateVariableList" .. dataName .. "")
		end
		self:_Update(dataName, newData)
	end)

	----- Metamethods -----

	--[[
		Description:
			When 'self' is indexed by anything, it first checks to see if
				the index is part of the ClientData table.

			This is useful so that you can call ClientData functions while
				still giving functionality to Variables inside the
				_privateVariableList and _publicVariableList by not having
				them be actual keys under 'self'. 
	]]
	self.__index = setmetatable(ClientData, {__index = function(tbl, index) -- First checks if ClientData has the index otherwise, fires this function
		if string.match(index, ACCESS_KEY) then -- Check if trying to access the Variable Object
			
			index = string.gsub(index, ACCESS_KEY, "")

			if _privateVariableList[index] ~= nil then
				return _privateVariableList[index]
			elseif _publicVariableList[index] ~= nil then
				return _publicVariableList[index]
			end
		elseif _privateVariableList[index] ~= nil then -- Check if trying to access private Variable Value
			return _privateVariableList[index].Value
		elseif _publicVariableList[index] ~= nil then -- Check if trying to access public Variable Value
			return _publicVariableList[index].Value
		end
	end})

	--[[
		Description:
			When attempting to setup or change a Variable's Value, this function will be called.
			
			It will attempt to locate the Variable within _privateVariableList or _publicVariableList,
				and based on which, will either warn that the client doesn't have access to change
				a Variable under the _privateVariableList table, or will change or create a new Variable Object
				and store it under the _publicVariableList.
	]]
	self.__newindex = function(tbl, index, newValue)
		if _privateVariableList[index] ~= nil then -- Check if the index is under the _privateVariableList
			warn("Attempting to change a Read-Only variable within ClientData!")
		elseif _publicVariableList[index] ~= nil then
			self:_Update(index, newValue)
		else
			_publicVariableList[index] = _CreateVariable(newValue, "_publicVariableList " .. index) -- Creates a new public Variable
		end
	end

	return setmetatable(self, self)
end

local m = initialize()
return m
