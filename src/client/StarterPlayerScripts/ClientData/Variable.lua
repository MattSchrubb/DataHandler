local Variable = {}
Variable.__index = Variable

function Variable:OnUpdate(func)
	table.insert(self._callbacks, func)
end

function Variable:_Update(data)
	local oldVal = self.Value
	self.Value = data

	for _,func in pairs(self._callbacks) do
		func(self.Value, oldVal)
	end
end

function Variable.new(value)
	local self = setmetatable({}, Variable)

	self._callbacks = {}
	
	self.Value = value

	return self
end

return Variable
