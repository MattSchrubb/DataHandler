local HelperFns = {}

wait()
for _,func in pairs(script:GetChildren()) do
	HelperFns[func.Name] = require(func)
end

return HelperFns