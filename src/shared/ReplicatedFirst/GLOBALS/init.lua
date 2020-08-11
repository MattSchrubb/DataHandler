local G = {}

for _,property in pairs(script:GetChildren()) do
	G[property.Name] = property.Value
end

return G